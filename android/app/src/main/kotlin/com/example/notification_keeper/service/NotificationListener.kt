package com.example.notification_keeper.service

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Intent
import android.graphics.Bitmap
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
import java.io.File
import java.io.FileOutputStream
import java.util.Calendar
import java.util.UUID
import java.util.regex.Pattern

class NotificationListener : NotificationListenerService() {
    private val serviceScope = CoroutineScope(Dispatchers.IO)
    private lateinit var database: AppDatabase

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

        serviceScope.launch {
            try {
                // Feature 5 (Clone from Notisave): Check quiet hours
                if (isQuietHoursActive()) {
                    Log.d("NotificationListener", "Quiet hours active, skipping notification from $packageName")
                    incrementQuietHoursSkippedToday()
                    return@launch
                }

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

                val title = extras.getString(Notification.EXTRA_TITLE)
                var text = extras.getCharSequence(Notification.EXTRA_TEXT)?.toString()

                // Merged from base.apk: handle MessagingStyle notifications (WhatsApp, Telegram, etc.)
                // gracefully by grabbing the actual last message instead of a possibly stale summary.
                if (extras.containsKey(Notification.EXTRA_MESSAGES)) {
                    val messages = extras.getParcelableArray(Notification.EXTRA_MESSAGES)
                    if (!messages.isNullOrEmpty()) {
                        val lastMessage = messages.last() as? Bundle
                        val msgText = lastMessage?.getCharSequence("text")?.toString()
                        if (!msgText.isNullOrBlank()) {
                            text = msgText
                        }
                    }
                }

                if (text.isNullOrBlank()) {
                    text = extras.getCharSequence(Notification.EXTRA_BIG_TEXT)?.toString()
                }
                if (text.isNullOrBlank()) {
                    text = extras.getString(Notification.EXTRA_SUMMARY_TEXT)
                }

                val subText = extras.getCharSequence(Notification.EXTRA_SUB_TEXT)?.toString()
                val timestamp = sbn.postTime

                // New feature: save any attached BigPictureStyle image (e.g. a photo shared
                // in a messaging app) so it can be previewed later in the archive. We
                // deliberately don't save the small "large icon" (usually just a contact
                // avatar) - only genuine picture attachments, to keep this meaningful.
                var imagePath: String? = null
                val picture = extras.get(Notification.EXTRA_PICTURE) as? Bitmap
                if (picture != null) {
                    imagePath = saveNotificationImage(picture)
                }

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
                    messagingUser = extras.getString(Notification.EXTRA_SELF_DISPLAY_NAME),
                    isOtp = isOtp,
                    extractedCode = extractedCode,
                    isPriorityFlagged = isPriorityFlagged,
                    imagePath = imagePath
                )

                // 6. Store
                database.notificationDao().insert(entity)
                Log.d("NotificationListener", "Saved notification from $packageName (otp=$isOtp, priority=$isPriorityFlagged)")

                // New feature: refresh the home screen widget with the latest capture
                com.example.notification_keeper.widget.NotificationWidgetProvider.requestUpdate(applicationContext)

                // New feature: instant alert for captured codes / priority matches
                if (isOtp || isPriorityFlagged) {
                    postInstantAlert(isOtp, isPriorityFlagged, title, extractedCode, packageName)
                }
            } catch (e: Exception) {
                Log.e("NotificationListener", "Error processing notification", e)
            }
        }
    }

    override fun onNotificationRemoved(sbn: StatusBarNotification) {
        // We do not delete from archive when notification is removed.
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
     * Merged from base.apk: feeds the "quietHoursSkippedToday" stat exposed via
     * MainActivity.getStats(). Stored per-calendar-day so it naturally resets at midnight
     * without needing a separate scheduled job.
     */
    private fun incrementQuietHoursSkippedToday() {
        val prefs = applicationContext.getSharedPreferences("notification_keeper_prefs", MODE_PRIVATE)
        val today = Calendar.getInstance().get(Calendar.DAY_OF_YEAR)
        val storedDay = prefs.getInt("quiet_hours_skipped_day", -1)
        val currentCount = if (storedDay == today) prefs.getInt("quiet_hours_skipped_today", 0) else 0

        prefs.edit()
            .putInt("quiet_hours_skipped_day", today)
            .putInt("quiet_hours_skipped_today", currentCount + 1)
            .apply()
    }

    /**
     * New feature: saves an attached BigPictureStyle image to this app's private
     * internal storage (not visible to other apps or the user's gallery) and
     * returns the absolute file path, or null if saving failed. A capped folder
     * size isn't implemented here - it piggybacks on the existing Data Hygiene /
     * RetentionWorker cleanup, which should also be extended to delete the image
     * file for notifications it removes (see CHANGELOG for this known gap).
     */
    private fun saveNotificationImage(bitmap: Bitmap): String? {
        return try {
            val dir = File(applicationContext.filesDir, "notification_images")
            if (!dir.exists()) dir.mkdirs()
            val file = File(dir, "${UUID.randomUUID()}.jpg")
            FileOutputStream(file).use { out ->
                bitmap.compress(Bitmap.CompressFormat.JPEG, 80, out)
            }
            file.absolutePath
        } catch (e: Exception) {
            Log.e("NotificationListener", "Failed to save notification image", e)
            null
        }
    }

    private fun createAlertChannelIfNeeded() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val manager = getSystemService(NotificationManager::class.java)
            val channel = NotificationChannel(
                ALERT_CHANNEL_ID,
                "Instant Alerts",
                NotificationManager.IMPORTANCE_HIGH
            ).apply {
                description = "Immediate alerts when a verification code or priority keyword is captured"
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

        val alertTitle = if (isOtp) "Code captured" else "Priority notification"
        val alertText = when {
            isOtp && !extractedCode.isNullOrBlank() -> "$extractedCode — tap to view"
            else -> title ?: "Tap to view in Notification Keeper"
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

    companion object {
        private const val ALERT_CHANNEL_ID = "instant_alerts"
    }
}
