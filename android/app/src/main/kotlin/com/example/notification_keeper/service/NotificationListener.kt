package com.example.notification_keeper.service

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Person
import android.content.Intent
import android.os.Build
import android.os.Bundle
import android.service.notification.NotificationListenerService
import android.service.notification.StatusBarNotification
import androidx.core.app.NotificationCompat
import com.example.notification_keeper.app.MainActivity
import com.example.notification_keeper.app.R
import com.example.notification_keeper.data.database.AppDatabase
import com.example.notification_keeper.data.entity.NotificationEntity
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import android.util.Log
import java.util.Calendar
import java.util.regex.Pattern

class NotificationListener : NotificationListenerService() {
    private val serviceScope = CoroutineScope(Dispatchers.IO)
    private lateinit var database: AppDatabase
    private val imageStore by lazy { NotificationImageStore(applicationContext) }

    // Merged from base.apk: OTP Regex. Matches context words near a 4-to-8 digit number.
    private val otpRegex = Regex(
        "(?i)\\b(?:code|otp|pin|password|verification)\\b.*?\\b(\\d{4,8})\\b" +
        "|\\b(\\d{4,8})\\b.*?\\b(?:code|otp|pin|password|verification)\\b"
    )

    override fun onCreate() {
        super.onCreate()
        database = AppDatabase.getDatabase(applicationContext)
        createAlertChannelIfNeeded()
    }

    override fun onNotificationPosted(sbn: StatusBarNotification) {
        val packageName = sbn.packageName
        val notification = sbn.notification

        // New feature safeguard: never process our own app's notifications
        // (including the instant alerts below) - avoids a feedback loop.
        if (packageName == applicationContext.packageName) return

        // Merged from base.apk: ignore ongoing/foreground-service notifications
        // (media playback controls, download progress, etc.) - these are noise, not "kept" content.
        if ((notification.flags and Notification.FLAG_ONGOING_EVENT) != 0) return

        // BUG FIX: the README promises that noisy group-summary updates are
        // filtered out, but nothing was actually filtering them - the flag was
        // only recorded on the row. A summary ("3 new messages") duplicates the
        // individual notifications that arrive alongside it, so it is dropped
        // here. isGroupSummary stays on the entity for rows captured before
        // this fix.
        if ((notification.flags and Notification.FLAG_GROUP_SUMMARY) != 0) return

        serviceScope.launch {
            try {
                // Feature 5 (Clone from Notisave): Quiet Hours.
                // BUG FIX: this used to `return` before storing anything, so an
                // archiver silently lost every notification of the night - the
                // opposite of what Quiet Hours means everywhere else in the app
                // ("tracked quietly, without an alert popup", per the README).
                // The capture now always happens; only the instant alert is
                // suppressed. See the counter below for the "captured quietly"
                // stat surfaced on the dashboard.
                val quietNow = isQuietHoursActive()

                // 1. Check if app is monitored
                val isMonitored = database.appPreferenceDao().isMonitored(packageName) ?: false
                if (!isMonitored) return@launch

                // New feature: per-app temporary snooze (separate from Quiet Hours, which is global)
                val snoozedUntil = database.appPreferenceDao().getSnoozedUntil(packageName)
                if (snoozedUntil != null && snoozedUntil > System.currentTimeMillis()) {
                    Log.d("NotificationListener", "$packageName is snoozed until $snoozedUntil, skipping")
                    return@launch
                }

                // 2. Extract Data
                val extras = notification.extras
                val (title, text) = extractTitleAndText(notification)

                val subText = extras.getCharSequence(Notification.EXTRA_SUB_TEXT)?.toString()
                val lastMessage = lastMessageBundle(notification)

                // A conversation notification is re-posted every time anything in the
                // chat changes, carrying the same newest message each time. Stamping the
                // row with the message's own time (rather than the re-post time) makes
                // those re-posts exact duplicates that the check below can recognise.
                val timestamp = lastMessage?.getLong(MESSAGE_KEY_TIME)?.takeIf { it > 0 }
                    ?: sbn.postTime

                // Validate essential data
                if (title.isNullOrBlank() && text.isNullOrBlank()) return@launch

                // 3. Deduplicate
                val duplicate = database.notificationDao().findDuplicate(
                    packageName, title, text, timestamp - 2000
                )
                if (duplicate != null) return@launch


                // 4. Merged from base.apk: OTP extraction + Keyword Radar
                val combinedContent = "${title.orEmpty()} ${text.orEmpty()}"

                var isOtp = false
                var extractedCode: String? = null
                val otpMatch = otpRegex.find(combinedContent)
                if (otpMatch != null) {
                    isOtp = true
                    extractedCode = otpMatch.groupValues
                        .drop(1)
                        .firstOrNull { it.isNotEmpty() && it.matches(Regex("\\d{4,8}")) }
                }

                val isPriorityFlagged = getKeywordPattern()?.matcher(combinedContent)?.find() ?: false

                // 5. Create Entity
                val entity = NotificationEntity(
                    packageName = packageName,
                    title = title,
                    content = text,
                    subText = subText,
                    timestamp = timestamp,
                    category = notification.category,
                    groupKey = sbn.groupKey,
                    isGroupSummary = (notification.flags and Notification.FLAG_GROUP_SUMMARY) != 0,
                    // BUG FIX: EXTRA_SELF_DISPLAY_NAME is the *device owner's* name
                    // (who the messaging app thinks "you" are), so every chat row was
                    // labelled with the reader instead of the sender. The real sender
                    // lives on the last MessagingStyle message; fall back to the old
                    // value only when there is no message bundle to read.
                    messagingUser = extractSender(notification)
                        ?: extras.getString(Notification.EXTRA_SELF_DISPLAY_NAME),
                    isOtp = isOtp,
                    extractedCode = extractedCode,
                    isPriorityFlagged = isPriorityFlagged
                )

                // 6. Store. The text goes in first, on its own: a picture must never
                // be able to cost us the message. Reading a photo means a binder call
                // into the sender app's provider, and that can be slow or stall.
                val rowId = database.notificationDao().insert(entity)
                NotificationEvents.emit(NotificationEvents.POSTED)
                Log.d("NotificationListener", "Saved notification from $packageName (otp=$isOtp, priority=$isPriorityFlagged)")

                // Photo vault: keep a private copy of any picture the notification
                // carries, including WhatsApp/Telegram photo messages, so it survives
                // the sender deleting it. Runs right after the insert - not later -
                // because Android revokes our read access to a message photo the
                // moment the notification is withdrawn. After the duplicate check, so
                // re-posts no longer leave an orphaned file behind each time.
                if (photoCaptureEnabled()) {
                    imageStore.capture(notification, lastMessage)?.let { path ->
                        database.notificationDao().updateImagePath(rowId, path)
                        NotificationEvents.emit(NotificationEvents.UPDATED)
                    }
                }

                // Counted here rather than at the top of the coroutine so the
                // dashboard's "captured quietly" number reflects what was
                // actually archived, not every notification the phone received
                // from apps the user isn't even monitoring.
                if (quietNow) {
                    incrementQuietHoursCapturedToday()
                }

                // New feature: refresh the home screen widget with the latest capture
                com.example.notification_keeper.widget.NotificationWidgetProvider.requestUpdate(applicationContext)

                // New feature: instant alert for captured codes / priority matches.
                // Suppressed during Quiet Hours - the capture above still happened.
                if ((isOtp || isPriorityFlagged) && !quietNow) {
                    postInstantAlert(isOtp, isPriorityFlagged, title, extractedCode, packageName)
                }
            } catch (e: Exception) {
                Log.e("NotificationListener", "Error processing notification", e)
            }
        }
    }

    override fun onNotificationRemoved(sbn: StatusBarNotification) {
        // We do not delete from archive when notification is removed.
        // (Pre-API-26 devices land here; they get no removal reason, so the
        // Recall Radar below simply never fires for them.)
    }

    /**
     * New feature A: "Recall Radar".
     *
     * The reason a notification disappears is the one signal Android gives us
     * about *why*. When the user swipes it away we get REASON_CANCEL / _CLICK;
     * when the posting app pulls it back itself we get REASON_APP_CANCEL - which
     * is exactly what a messaging app does the instant a sender deletes ("unsends")
     * a message that was already delivered. That message text is already safe in
     * our archive; all that's missing is the fact that someone tried to take it back.
     *
     * Apps also cancel their own notifications for innocent reasons (you read the
     * chat on your laptop, the app cleans up), so this is a heuristic, not proof.
     * Two guards keep the false-positive rate sane, and the UI is worded as
     * "may have been deleted" rather than stating it as fact:
     *   1. the notification must have been withdrawn within [RECALL_WINDOW_MS] of
     *      being posted - a recall is near-instant, reading a chat usually isn't;
     *   2. it must look like a conversation (message category or a known sender),
     *      because that's the only place "unsend" exists.
     */
    override fun onNotificationRemoved(
        sbn: StatusBarNotification,
        rankingMap: NotificationListenerService.RankingMap?,
        reason: Int
    ) {
        super.onNotificationRemoved(sbn, rankingMap, reason)

        if (sbn.packageName == applicationContext.packageName) return
        if (reason != RECALL_REASON_APP_CANCEL && reason != RECALL_REASON_APP_CANCEL_ALL) return

        val withdrawnAt = System.currentTimeMillis()
        if (withdrawnAt - sbn.postTime > RECALL_WINDOW_MS) return

        val notification = sbn.notification
        if ((notification.flags and Notification.FLAG_GROUP_SUMMARY) != 0) return

        serviceScope.launch {
            try {
                val (title, text) = extractTitleAndText(notification)
                if (title.isNullOrBlank() && text.isNullOrBlank()) return@launch

                val stored = database.notificationDao()
                    .findLatestMatch(sbn.packageName, title, text) ?: return@launch
                if (stored.recalledAt != null) return@launch

                // Only conversations can be "unsent" - skip transactional noise.
                val looksLikeConversation =
                    stored.category == Notification.CATEGORY_MESSAGE || stored.messagingUser != null
                if (!looksLikeConversation) return@launch

                database.notificationDao().markRecalled(stored.id, withdrawnAt)
                NotificationEvents.emit(NotificationEvents.RECALLED)
                Log.d("NotificationListener", "Recall detected for ${sbn.packageName} (id=${stored.id})")

                com.example.notification_keeper.widget.NotificationWidgetProvider
                    .requestUpdate(applicationContext)

                if (!isQuietHoursActive()) {
                    postRecallAlert(stored.messagingUser ?: title, sbn.packageName)
                }
            } catch (e: Exception) {
                Log.e("NotificationListener", "Error processing removal", e)
            }
        }
    }

    /**
     * Shared title/body extraction, used both when a notification arrives and
     * when it is withdrawn - the two must agree exactly, or the Recall Radar
     * would fail to find the row it stored moments earlier.
     *
     * Merged from base.apk: MessagingStyle notifications (WhatsApp, Telegram,
     * Signal, ...) are handled by grabbing the actual last message rather than a
     * possibly stale summary line.
     */
    private fun extractTitleAndText(notification: Notification): Pair<String?, String?> {
        val extras = notification.extras
        val title = extras.getString(Notification.EXTRA_TITLE)
        var text = extras.getCharSequence(Notification.EXTRA_TEXT)?.toString()

        lastMessageBundle(notification)?.getCharSequence("text")?.toString()?.let { msgText ->
            if (msgText.isNotBlank()) text = msgText
        }

        if (text.isNullOrBlank()) {
            text = extras.getCharSequence(Notification.EXTRA_BIG_TEXT)?.toString()
        }
        if (text.isNullOrBlank()) {
            text = extras.getString(Notification.EXTRA_SUMMARY_TEXT)
        }
        return title to text
    }

    /** The last entry of a MessagingStyle notification's message array, if any. */
    private fun lastMessageBundle(notification: Notification): Bundle? {
        val extras = notification.extras
        if (!extras.containsKey(Notification.EXTRA_MESSAGES)) return null
        val messages = extras.getParcelableArray(Notification.EXTRA_MESSAGES)
        if (messages.isNullOrEmpty()) return null
        return messages.last() as? Bundle
    }

    /**
     * The name of whoever actually sent the last message. Newer apps put a
     * [Person] under "sender_person"; older ones put a plain CharSequence under
     * "sender". A null sender means the message came from the device owner.
     */
    private fun extractSender(notification: Notification): String? {
        val bundle = lastMessageBundle(notification) ?: return null

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
            val person = bundle.getParcelable<Person>("sender_person")
            val name = person?.name?.toString()
            if (!name.isNullOrBlank()) return name
        }
        return bundle.getCharSequence("sender")?.toString()?.takeIf { it.isNotBlank() }
    }

    /**
     * Feature 5: Check if quiet hours are currently active
     */
    private fun isQuietHoursActive(): Boolean {
        val prefs = applicationContext.getSharedPreferences("notification_keeper_prefs", MODE_PRIVATE)
        val enabled = prefs.getBoolean("quiet_hours_enabled", false)
        if (!enabled) return false

        val startHour = prefs.getInt("quiet_hours_start_hour", 22)
        val startMinute = prefs.getInt("quiet_hours_start_minute", 0)
        val endHour = prefs.getInt("quiet_hours_end_hour", 7)
        val endMinute = prefs.getInt("quiet_hours_end_minute", 0)

        val now = Calendar.getInstance()
        val currentMinutes = now.get(Calendar.HOUR_OF_DAY) * 60 + now.get(Calendar.MINUTE)
        val startMinutes = startHour * 60 + startMinute
        val endMinutes = endHour * 60 + endMinute

        return if (startMinutes <= endMinutes) {
            currentMinutes in startMinutes..endMinutes
        } else {
            currentMinutes >= startMinutes || currentMinutes <= endMinutes
        }
    }

    /**
     * Merged from base.apk: "Keyword Radar". Reads the user's keyword list fresh from
     * SharedPreferences on every notification (rather than caching it in memory), so
     * changes made in Settings take effect immediately without needing to restart the
     * listener service or bind to it from Flutter.
     */
    private fun getKeywordPattern(): Pattern? {
        val prefs = applicationContext.getSharedPreferences("notification_keeper_prefs", MODE_PRIVATE)
        val keywords = prefs.getStringSet("priority_keywords", null)
        if (keywords.isNullOrEmpty()) return null

        val escaped = keywords.joinToString("|") { Pattern.quote(it) }
        return Pattern.compile("(?i)\\b($escaped)\\b")
    }

    /**
     * Merged from base.apk: feeds the "quiet hours" stat exposed via
     * MainActivity.getStats(). Stored per-calendar-day so it naturally resets at midnight
     * without needing a separate scheduled job (MainActivity does the matching
     * day check when it reads the value back).
     *
     * Since the Quiet Hours fix this counts notifications captured *quietly*
     * (stored, but with the instant alert withheld) rather than notifications
     * thrown away.
     */
    private fun incrementQuietHoursCapturedToday() {
        val prefs = applicationContext.getSharedPreferences("notification_keeper_prefs", MODE_PRIVATE)
        val today = Calendar.getInstance().get(Calendar.DAY_OF_YEAR)
        val storedDay = prefs.getInt("quiet_hours_skipped_day", -1)
        val currentCount = if (storedDay == today) prefs.getInt("quiet_hours_skipped_today", 0) else 0

        prefs.edit()
            .putInt("quiet_hours_skipped_day", today)
            .putInt("quiet_hours_skipped_today", currentCount + 1)
            .apply()
    }

    /** Photo vault switch, Settings > Photos. On by default. */
    private fun photoCaptureEnabled(): Boolean =
        applicationContext.getSharedPreferences("notification_keeper_prefs", MODE_PRIVATE)
            .getBoolean(PREF_CAPTURE_PHOTOS, true)

    private fun createAlertChannelIfNeeded() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val manager = getSystemService(NotificationManager::class.java)
            val channel = NotificationChannel(
                ALERT_CHANNEL_ID,
                getString(R.string.alert_channel_name),
                NotificationManager.IMPORTANCE_HIGH
            ).apply {
                description = getString(R.string.alert_channel_description)
            }
            manager?.createNotificationChannel(channel)
        }
    }

    /**
     * New feature: post a local notification immediately when a verification code or
     * a Keyword Radar match is captured, so the user doesn't have to open the app to
     * notice. Opt-out via Settings > Instant Alerts (defaults to on).
     */
    private fun postInstantAlert(
        isOtp: Boolean,
        isPriority: Boolean,
        title: String?,
        extractedCode: String?,
        sourcePackage: String
    ) {
        val prefs = applicationContext.getSharedPreferences("notification_keeper_prefs", MODE_PRIVATE)
        val alertsEnabled = prefs.getBoolean("instant_alerts_enabled", true)
        if (!alertsEnabled) return

        val alertTitle = getString(
            if (isOtp) R.string.alert_code_title else R.string.alert_priority_title
        )
        val alertText = when {
            isOtp && !extractedCode.isNullOrBlank() ->
                getString(R.string.alert_code_body, extractedCode)
            else -> title ?: getString(R.string.alert_fallback_body)
        }

        val launchIntent = Intent(applicationContext, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
        }
        val pendingIntent = PendingIntent.getActivity(
            applicationContext,
            0,
            launchIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val notification = NotificationCompat.Builder(applicationContext, ALERT_CHANNEL_ID)
            .setSmallIcon(R.mipmap.ic_launcher)
            .setContentTitle(alertTitle)
            .setContentText(alertText)
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setAutoCancel(true)
            .setContentIntent(pendingIntent)
            .build()

        try {
            val manager = getSystemService(NotificationManager::class.java)
            // Unique-ish ID per alert so multiple instant alerts don't overwrite each other
            manager?.notify(sourcePackage.hashCode(), notification)
        } catch (e: SecurityException) {
            // POST_NOTIFICATIONS not granted - silently skip, the notification is
            // already safely stored in the archive regardless.
            Log.w("NotificationListener", "Could not post instant alert: ${e.message}")
        }
    }

    /**
     * New feature A: tells the user that something was taken back. The content
     * itself is deliberately not repeated here - the point is to send them to
     * the archive, where the message survives.
     */
    private fun postRecallAlert(who: String?, sourcePackage: String) {
        val prefs = applicationContext.getSharedPreferences("notification_keeper_prefs", MODE_PRIVATE)
        if (!prefs.getBoolean("instant_alerts_enabled", true)) return

        val launchIntent = Intent(applicationContext, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
        }
        val pendingIntent = PendingIntent.getActivity(
            applicationContext,
            1,
            launchIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val notification = NotificationCompat.Builder(applicationContext, ALERT_CHANNEL_ID)
            .setSmallIcon(R.mipmap.ic_launcher)
            .setContentTitle(getString(R.string.recall_alert_title))
            .setContentText(
                if (who.isNullOrBlank()) getString(R.string.recall_alert_body_generic)
                else getString(R.string.recall_alert_body, who)
            )
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setAutoCancel(true)
            .setContentIntent(pendingIntent)
            .build()

        try {
            val manager = getSystemService(NotificationManager::class.java)
            manager?.notify("recall_$sourcePackage".hashCode(), notification)
        } catch (e: SecurityException) {
            Log.w("NotificationListener", "Could not post recall alert: ${e.message}")
        }
    }

    companion object {
        private const val ALERT_CHANNEL_ID = "instant_alerts"

        /** SharedPreferences key for the photo vault switch (read by MainActivity too). */
        const val PREF_CAPTURE_PHOTOS = "capture_photos_enabled"

        // Notification.MessagingStyle.Message bundle key for the message timestamp.
        private const val MESSAGE_KEY_TIME = "time"

        // NotificationListenerService.REASON_APP_CANCEL / _ALL. Spelled out as
        // literals so the Recall Radar compiles and links on the API 21+ range
        // this app supports - the constants themselves only exist from API 26,
        // which is also the first version that reports a removal reason at all.
        private const val RECALL_REASON_APP_CANCEL = 8
        private const val RECALL_REASON_APP_CANCEL_ALL = 9

        // How soon after posting a withdrawal still counts as a "recall".
        // Deleting a message you just sent happens in seconds; an app clearing a
        // notification because you read the chat elsewhere usually takes longer.
        private const val RECALL_WINDOW_MS = 60_000L
    }
}
