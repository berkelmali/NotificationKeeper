package com.example.notification_keeper.app

import android.content.Intent
import android.content.SharedPreferences
import android.os.Bundle
import android.provider.Settings
import androidx.core.app.NotificationManagerCompat
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import com.example.notification_keeper.data.database.AppDatabase
import com.example.notification_keeper.data.entity.AppPreferenceEntity
import com.example.notification_keeper.data.entity.NotificationEntity
import com.example.notification_keeper.worker.RetentionWorker
import androidx.work.Constraints
import androidx.work.ExistingPeriodicWorkPolicy
import androidx.work.PeriodicWorkRequestBuilder
import androidx.work.WorkManager
import com.google.gson.Gson
import java.io.File
import java.util.Calendar
import java.util.concurrent.TimeUnit

// BUG FIX: local_auth's BiometricPrompt requires a FragmentActivity host.
// FlutterActivity does not extend FragmentActivity, so the biometric
// prompt would silently fail to appear at all under the old base class.
class MainActivity: FlutterFragmentActivity() {
    private val CHANNEL = "com.example.notification_keeper/notifications"
    private val scope = CoroutineScope(Dispatchers.Main)

    // Merged from base.apk: schedule the automatic retention/cleanup routine once per app start.
    // ExistingPeriodicWorkPolicy.KEEP means this is a no-op if it's already scheduled.
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        val retentionRequest = PeriodicWorkRequestBuilder<RetentionWorker>(24, TimeUnit.HOURS)
            .setConstraints(
                Constraints.Builder()
                    .setRequiresBatteryNotLow(true)
                    .build()
            )
            .build()

        WorkManager.getInstance(this).enqueueUniquePeriodicWork(
            RetentionWorker.WORK_NAME,
            ExistingPeriodicWorkPolicy.KEEP,
            retentionRequest
        )
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "getAllNotifications" -> {
                    scope.launch(Dispatchers.IO) {
                        try {
                            val db = AppDatabase.getDatabase(applicationContext)
                            val notifications = db.notificationDao().getAll()
                            val list = notifications.map { it.toMap() }
                            withContext(Dispatchers.Main) {
                                result.success(list)
                            }
                        } catch (e: Exception) {
                            withContext(Dispatchers.Main) {
                                result.error("DB_ERROR", e.message, null)
                            }
                        }
                    }
                }
                "getNotificationsByApp" -> {
                    val packageName = call.argument<String>("packageName")
                    if (packageName != null) {
                        scope.launch(Dispatchers.IO) {
                            try {
                                val db = AppDatabase.getDatabase(applicationContext)
                                val notifications = db.notificationDao().getByApp(packageName)
                                val list = notifications.map { it.toMap() }
                                withContext(Dispatchers.Main) {
                                    result.success(list)
                                }
                            } catch (e: Exception) {
                                withContext(Dispatchers.Main) {
                                    result.error("DB_ERROR", e.message, null)
                                }
                            }
                        }
                    } else {
                        result.error("INVALID_ARGUMENT", "packageName is null", null)
                    }
                }
                "getStats" -> {
                    scope.launch(Dispatchers.IO) {
                        try {
                            val db = AppDatabase.getDatabase(applicationContext)
                            val dao = db.notificationDao()
                            
                            val totalCount = dao.getCount()
                            
                            val todayCal = Calendar.getInstance().apply {
                                set(Calendar.HOUR_OF_DAY, 0)
                                set(Calendar.MINUTE, 0)
                                set(Calendar.SECOND, 0)
                                set(Calendar.MILLISECOND, 0)
                            }
                            val todayCount = dao.getTodayCount(todayCal.timeInMillis)
                            
                            val weekCal = Calendar.getInstance().apply {
                                add(Calendar.DAY_OF_YEAR, -7)
                                set(Calendar.HOUR_OF_DAY, 0)
                                set(Calendar.MINUTE, 0)
                                set(Calendar.SECOND, 0)
                                set(Calendar.MILLISECOND, 0)
                            }
                            val weekCount = dao.getWeekCount(weekCal.timeInMillis)
                            
                            val appCounts = dao.getCountByApp()
                            val appCountMap = appCounts.associate { it.packageName to it.count }
                            
                            val dailyCounts = mutableListOf<Map<String, Any>>()
                            for (i in 6 downTo 0) {
                                val dayStart = Calendar.getInstance().apply {
                                    add(Calendar.DAY_OF_YEAR, -i)
                                    set(Calendar.HOUR_OF_DAY, 0)
                                    set(Calendar.MINUTE, 0)
                                    set(Calendar.SECOND, 0)
                                    set(Calendar.MILLISECOND, 0)
                                }
                                val dayEnd = Calendar.getInstance().apply {
                                    add(Calendar.DAY_OF_YEAR, -i)
                                    set(Calendar.HOUR_OF_DAY, 23)
                                    set(Calendar.MINUTE, 59)
                                    set(Calendar.SECOND, 59)
                                    set(Calendar.MILLISECOND, 999)
                                }
                                val count = dao.getBetween(dayStart.timeInMillis, dayEnd.timeInMillis).size
                                dailyCounts.add(mapOf(
                                    "date" to dayStart.timeInMillis,
                                    "count" to count
                                ))
                            }

                            val todayNotifications = dao.getTodayNotifications(todayCal.timeInMillis)
                            val hourlyCounts = mutableMapOf<Int, Int>()
                            for (hour in 0..23) {
                                hourlyCounts[hour] = 0
                            }
                            for (notif in todayNotifications) {
                                val cal = Calendar.getInstance().apply {
                                    timeInMillis = notif.timestamp
                                }
                                val hour = cal.get(Calendar.HOUR_OF_DAY)
                                hourlyCounts[hour] = (hourlyCounts[hour] ?: 0) + 1
                            }

                            // Merged from base.apk: surface OTP + priority counts in the stats payload
                            // (feeds the expanded stats dashboard - see merge changelog, feature #9)
                            val otpCount = todayNotifications.count { it.isOtp }
                            val priorityCount = todayNotifications.count { it.isPriorityFlagged }
                            val quietHoursSkippedToday = getSharedPreferences("notification_keeper_prefs", MODE_PRIVATE)
                                .getInt("quiet_hours_skipped_today", 0)
                            
                            val statsMap = mapOf(
                                "totalCount" to totalCount,
                                "todayCount" to todayCount,
                                "weekCount" to weekCount,
                                "appCounts" to appCountMap,
                                "dailyCounts" to dailyCounts,
                                "hourlyCounts" to hourlyCounts,
                                "otpCountToday" to otpCount,
                                "priorityCountToday" to priorityCount,
                                "quietHoursSkippedToday" to quietHoursSkippedToday
                            )
                            
                            withContext(Dispatchers.Main) {
                                result.success(statsMap)
                            }
                        } catch (e: Exception) {
                            withContext(Dispatchers.Main) {
                                result.error("DB_ERROR", e.message, null)
                            }
                        }
                    }
                }
                "deleteNotification" -> {
                    val id = call.argument<Number>("id")?.toLong()
                    if (id != null) {
                        scope.launch(Dispatchers.IO) {
                            try {
                                val db = AppDatabase.getDatabase(applicationContext)
                                db.notificationDao().deleteById(id)
                                withContext(Dispatchers.Main) {
                                    result.success(true)
                                }
                            } catch (e: Exception) {
                                withContext(Dispatchers.Main) {
                                    result.error("DB_ERROR", e.message, null)
                                }
                            }
                        }
                    } else {
                        result.error("INVALID_ARGUMENT", "id is null", null)
                    }
                }
                "deleteOlderThan" -> {
                    val days = call.argument<Number>("days")?.toInt()
                    if (days != null) {
                        scope.launch(Dispatchers.IO) {
                            try {
                                val db = AppDatabase.getDatabase(applicationContext)
                                val cal = Calendar.getInstance().apply {
                                    add(Calendar.DAY_OF_YEAR, -days)
                                }
                                // New feature: clean up orphaned image files too (see imagePath)
                                val withImages = db.notificationDao().getOlderThanWithImages(cal.timeInMillis)
                                withImages.forEach { entity ->
                                    entity.imagePath?.let { path -> try { File(path).delete() } catch (e: Exception) {} }
                                }
                                db.notificationDao().deleteOlderThan(cal.timeInMillis)
                                com.example.notification_keeper.widget.NotificationWidgetProvider.requestUpdate(applicationContext)
                                withContext(Dispatchers.Main) {
                                    result.success(true)
                                }
                            } catch (e: Exception) {
                                withContext(Dispatchers.Main) {
                                    result.error("DB_ERROR", e.message, null)
                                }
                            }
                        }
                    } else {
                        result.error("INVALID_ARGUMENT", "days is null", null)
                    }
                }
                "deleteAllNotifications" -> {
                    scope.launch(Dispatchers.IO) {
                        try {
                            val db = AppDatabase.getDatabase(applicationContext)
                            db.notificationDao().deleteAll()
                            // New feature: also clear the saved images folder
                            try {
                                File(applicationContext.filesDir, "notification_images").deleteRecursively()
                            } catch (e: Exception) { /* non-fatal */ }
                            com.example.notification_keeper.widget.NotificationWidgetProvider.requestUpdate(applicationContext)
                            withContext(Dispatchers.Main) {
                                result.success(true)
                            }
                        } catch (e: Exception) {
                            withContext(Dispatchers.Main) {
                                result.error("DB_ERROR", e.message, null)
                            }
                        }
                    }
                }
                "toggleStar" -> {
                    val id = call.argument<Number>("id")?.toLong()
                    val isStarred = call.argument<Boolean>("isStarred")
                    if (id != null && isStarred != null) {
                        scope.launch(Dispatchers.IO) {
                            try {
                                val db = AppDatabase.getDatabase(applicationContext)
                                db.notificationDao().updateStarred(id, isStarred)
                                withContext(Dispatchers.Main) {
                                    result.success(true)
                                }
                            } catch (e: Exception) {
                                withContext(Dispatchers.Main) {
                                    result.error("DB_ERROR", e.message, null)
                                }
                            }
                        }
                    } else {
                        result.error("INVALID_ARGUMENT", "id or isStarred is null", null)
                    }
                }
                "markAsRead" -> {
                    val id = call.argument<Number>("id")?.toLong()
                    if (id != null) {
                        scope.launch(Dispatchers.IO) {
                            try {
                                val db = AppDatabase.getDatabase(applicationContext)
                                db.notificationDao().updateRead(id, true)
                                withContext(Dispatchers.Main) {
                                    result.success(true)
                                }
                            } catch (e: Exception) {
                                withContext(Dispatchers.Main) {
                                    result.error("DB_ERROR", e.message, null)
                                }
                            }
                        }
                    } else {
                        result.error("INVALID_ARGUMENT", "id is null", null)
                    }
                }
                "updateTags" -> {
                    val id = call.argument<Number>("id")?.toLong()
                    val tags = call.argument<String>("tags")
                    if (id != null) {
                        scope.launch(Dispatchers.IO) {
                            try {
                                val db = AppDatabase.getDatabase(applicationContext)
                                db.notificationDao().updateTags(id, tags)
                                withContext(Dispatchers.Main) {
                                    result.success(true)
                                }
                            } catch (e: Exception) {
                                withContext(Dispatchers.Main) {
                                    result.error("DB_ERROR", e.message, null)
                                }
                            }
                        }
                    } else {
                        result.error("INVALID_ARGUMENT", "id is null", null)
                    }
                }
                "setQuietHours" -> {
                    val enabled = call.argument<Boolean>("enabled") ?: false
                    val startHour = call.argument<Number>("startHour")?.toInt() ?: 22
                    val startMinute = call.argument<Number>("startMinute")?.toInt() ?: 0
                    val endHour = call.argument<Number>("endHour")?.toInt() ?: 7
                    val endMinute = call.argument<Number>("endMinute")?.toInt() ?: 0

                    val prefs: SharedPreferences = getSharedPreferences("notification_keeper_prefs", MODE_PRIVATE)
                    prefs.edit()
                        .putBoolean("quiet_hours_enabled", enabled)
                        .putInt("quiet_hours_start_hour", startHour)
                        .putInt("quiet_hours_start_minute", startMinute)
                        .putInt("quiet_hours_end_hour", endHour)
                        .putInt("quiet_hours_end_minute", endMinute)
                        .apply()
                    
                    result.success(true)
                }
                "exportNotifications" -> {
                    // format: "json" (default) or "csv" - see merge changelog, feature #4
                    val format = call.argument<String>("format") ?: "json"
                    scope.launch(Dispatchers.IO) {
                        try {
                            val db = AppDatabase.getDatabase(applicationContext)
                            val notifications = db.notificationDao().getAll()

                            val file: File
                            if (format == "csv") {
                                file = File(applicationContext.cacheDir, "notifications_export.csv")
                                file.bufferedWriter().use { writer ->
                                    writer.write("id,packageName,title,content,subText,timestamp,category,isOtp,extractedCode,isPriorityFlagged,tags\n")
                                    notifications.forEach { n ->
                                        writer.write(listOf(
                                            n.id, csvEscape(n.packageName), csvEscape(n.title), csvEscape(n.content),
                                            csvEscape(n.subText), n.timestamp, csvEscape(n.category),
                                            n.isOtp, csvEscape(n.extractedCode), n.isPriorityFlagged, csvEscape(n.tags)
                                        ).joinToString(",") + "\n")
                                    }
                                }
                            } else {
                                val list = notifications.map { it.toMap() }
                                val json = Gson().toJson(list)
                                file = File(applicationContext.cacheDir, "notifications_export.json")
                                file.writeText(json)
                            }

                            withContext(Dispatchers.Main) {
                                result.success(file.absolutePath)
                            }
                        } catch (e: Exception) {
                            withContext(Dispatchers.Main) {
                                result.error("EXPORT_ERROR", e.message, null)
                            }
                        }
                    }
                }
                "getMonitoredApps" -> {
                    scope.launch(Dispatchers.IO) {
                        try {
                            val db = AppDatabase.getDatabase(applicationContext)
                            val pm = packageManager
                            val installed = pm.getInstalledPackages(0)
                            
                            val notifCounts = db.notificationDao().getCountByApp()
                            val countMap = notifCounts.associate { it.packageName to it.count }

                            // New feature: fetch all preferences (including snooze) in one query
                            val allPrefs = db.appPreferenceDao().getAll()
                            val prefsMap = allPrefs.associateBy { it.packageName }
                            
                            val appList = installed.map { pkg ->
                                val pref = prefsMap[pkg.packageName]
                                val isMonitored = pref?.isMonitored ?: false
                                val label = pkg.applicationInfo?.loadLabel(pm)?.toString() ?: pkg.packageName
                                mapOf(
                                    "packageName" to pkg.packageName,
                                    "appName" to label,
                                    "isMonitored" to isMonitored,
                                    "notificationCount" to (countMap[pkg.packageName] ?: 0),
                                    "snoozedUntil" to pref?.snoozedUntil
                                )
                            }.sortedBy { (it["appName"] as String).lowercase() }
                            
                            withContext(Dispatchers.Main) {
                                result.success(appList)
                            }
                        } catch (e: Exception) {
                            withContext(Dispatchers.Main) {
                                result.error("PM_ERROR", e.message, null)
                            }
                        }
                    }
                }
                "toggleAppMonitoring" -> {
                    val packageName = call.argument<String>("packageName")
                    val isMonitored = call.argument<Boolean>("isMonitored")
                    if (packageName != null && isMonitored != null) {
                        scope.launch(Dispatchers.IO) {
                            try {
                                val db = AppDatabase.getDatabase(applicationContext)
                                db.appPreferenceDao().insert(AppPreferenceEntity(packageName, isMonitored))
                                withContext(Dispatchers.Main) {
                                    result.success(true)
                                }
                            } catch (e: Exception) {
                                withContext(Dispatchers.Main) {
                                    result.error("DB_ERROR", e.message, null)
                                }
                            }
                        }
                    } else {
                        result.error("INVALID_ARGUMENT", "packageName or isMonitored is null", null)
                    }
                }
                // New feature: per-app temporary snooze (pause one app for N minutes without
                // turning off monitoring for it permanently)
                "snoozeApp" -> {
                    val packageName = call.argument<String>("packageName")
                    val minutes = call.argument<Number>("minutes")?.toLong()
                    if (packageName != null && minutes != null) {
                        scope.launch(Dispatchers.IO) {
                            try {
                                val db = AppDatabase.getDatabase(applicationContext)
                                val until = System.currentTimeMillis() + (minutes * 60_000L)
                                val existing = db.appPreferenceDao().isMonitored(packageName)
                                if (existing == null) {
                                    // No row yet for this app - create one, default to monitored=true
                                    db.appPreferenceDao().insert(
                                        AppPreferenceEntity(packageName, true, until)
                                    )
                                } else {
                                    db.appPreferenceDao().setSnoozedUntil(packageName, until)
                                }
                                withContext(Dispatchers.Main) { result.success(true) }
                            } catch (e: Exception) {
                                withContext(Dispatchers.Main) { result.error("DB_ERROR", e.message, null) }
                            }
                        }
                    } else {
                        result.error("INVALID_ARGUMENT", "packageName or minutes is null", null)
                    }
                }
                "unsnoozeApp" -> {
                    val packageName = call.argument<String>("packageName")
                    if (packageName != null) {
                        scope.launch(Dispatchers.IO) {
                            try {
                                val db = AppDatabase.getDatabase(applicationContext)
                                db.appPreferenceDao().setSnoozedUntil(packageName, null)
                                withContext(Dispatchers.Main) { result.success(true) }
                            } catch (e: Exception) {
                                withContext(Dispatchers.Main) { result.error("DB_ERROR", e.message, null) }
                            }
                        }
                    } else {
                        result.error("INVALID_ARGUMENT", "packageName is null", null)
                    }
                }
                "isServiceEnabled" -> {
                    // BUG FIX: manually parsing Settings.Secure's raw string was
                    // unreliable on some devices/Android versions (reported: shows
                    // as not-enabled even right after the user enables it).
                    // NotificationManagerCompat's helper is the officially
                    // recommended, more robust way to check this.
                    val enabledPackages = NotificationManagerCompat.getEnabledListenerPackages(applicationContext)
                    result.success(enabledPackages.contains(packageName))
                }
                "openNotificationSettings" -> {
                    startActivity(Intent(Settings.ACTION_NOTIFICATION_LISTENER_SETTINGS))
                    result.success(true)
                }
                // --- Merged from base.apk: Keyword Radar settings ---
                "updateKeywords" -> {
                    val keywords = call.argument<List<String>>("keywords") ?: emptyList()
                    val prefs = getSharedPreferences("notification_keeper_prefs", MODE_PRIVATE)
                    prefs.edit().putStringSet("priority_keywords", keywords.toSet()).apply()
                    result.success(true)
                }
                "getKeywords" -> {
                    val prefs = getSharedPreferences("notification_keeper_prefs", MODE_PRIVATE)
                    val keywords = prefs.getStringSet("priority_keywords", emptySet())?.toList() ?: emptyList()
                    result.success(keywords)
                }
                // --- Merged from base.apk: automatic retention / "Data Hygiene" settings ---
                "setRetentionDays" -> {
                    val days = call.argument<Number>("days")?.toInt() ?: 0
                    val prefs = getSharedPreferences("notification_keeper_prefs", MODE_PRIVATE)
                    prefs.edit().putInt("retention_days", days).apply()
                    result.success(true)
                }
                "getRetentionDays" -> {
                    val prefs = getSharedPreferences("notification_keeper_prefs", MODE_PRIVATE)
                    result.success(prefs.getInt("retention_days", 0))
                }
                // --- New feature #10: instant local alert on OTP/priority capture ---
                "setInstantAlertsEnabled" -> {
                    val enabled = call.argument<Boolean>("enabled") ?: true
                    val prefs = getSharedPreferences("notification_keeper_prefs", MODE_PRIVATE)
                    prefs.edit().putBoolean("instant_alerts_enabled", enabled).apply()
                    result.success(true)
                }
                "getInstantAlertsEnabled" -> {
                    val prefs = getSharedPreferences("notification_keeper_prefs", MODE_PRIVATE)
                    result.success(prefs.getBoolean("instant_alerts_enabled", true))
                }
                // --- New feature #1: date-range aware search ---
                "searchWithDateRange" -> {
                    val query = call.argument<String>("query") ?: ""
                    val startMillis = call.argument<Number>("start")?.toLong()
                    val endMillis = call.argument<Number>("end")?.toLong()
                    if (startMillis != null && endMillis != null) {
                        scope.launch(Dispatchers.IO) {
                            try {
                                val db = AppDatabase.getDatabase(applicationContext)
                                val results = db.notificationDao().searchWithDateRange(query, startMillis, endMillis)
                                withContext(Dispatchers.Main) {
                                    result.success(results.map { it.toMap() })
                                }
                            } catch (e: Exception) {
                                withContext(Dispatchers.Main) {
                                    result.error("DB_ERROR", e.message, null)
                                }
                            }
                        }
                    } else {
                        result.error("INVALID_ARGUMENT", "start or end is null", null)
                    }
                }
                // --- New feature: restore notifications from a backup file ---
                "restoreNotifications" -> {
                    @Suppress("UNCHECKED_CAST")
                    val items = call.argument<List<Map<String, Any?>>>("notifications")
                    if (items != null) {
                        scope.launch(Dispatchers.IO) {
                            try {
                                val db = AppDatabase.getDatabase(applicationContext)
                                // id is intentionally NOT read back here - letting Room
                                // auto-generate fresh primary keys avoids collisions with
                                // whatever is already in the local database.
                                val entities = items.map { m ->
                                    NotificationEntity(
                                        packageName = m["packageName"] as? String ?: "",
                                        title = m["title"] as? String,
                                        content = m["content"] as? String,
                                        subText = m["subText"] as? String,
                                        timestamp = (m["timestamp"] as? Number)?.toLong() ?: 0L,
                                        category = m["category"] as? String,
                                        groupKey = m["groupKey"] as? String,
                                        isGroupSummary = m["isGroupSummary"] as? Boolean ?: false,
                                        messagingUser = m["messagingUser"] as? String,
                                        isRead = m["isRead"] as? Boolean ?: false,
                                        isStarred = m["isStarred"] as? Boolean ?: false,
                                        tags = m["tags"] as? String,
                                        isOtp = m["isOtp"] as? Boolean ?: false,
                                        extractedCode = m["extractedCode"] as? String,
                                        isPriorityFlagged = m["isPriorityFlagged"] as? Boolean ?: false
                                        // imagePath deliberately not restored - the actual
                                        // image files aren't part of the backup (see changelog)
                                    )
                                }
                                db.notificationDao().insertAll(entities)
                                withContext(Dispatchers.Main) {
                                    result.success(entities.size)
                                }
                            } catch (e: Exception) {
                                withContext(Dispatchers.Main) {
                                    result.error("RESTORE_ERROR", e.message, null)
                                }
                            }
                        }
                    } else {
                        result.error("INVALID_ARGUMENT", "notifications is null", null)
                    }
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    private fun csvEscape(value: Any?): String {
        if (value == null) return ""
        val s = value.toString().replace("\"", "\"\"")
        return "\"$s\""
    }
    
    // Extension function for cleaner mapping
    private fun NotificationEntity.toMap(): Map<String, Any?> {
        return mapOf(
            "id" to id,
            "packageName" to packageName,
            "title" to title,
            "content" to content,
            "subText" to subText,
            "timestamp" to timestamp,
            "category" to category,
            "groupKey" to groupKey,
            "isGroupSummary" to isGroupSummary,
            "messagingUser" to messagingUser,
            "isRead" to isRead,
            "isStarred" to isStarred,
            "tags" to tags,
            "isOtp" to isOtp,
            "extractedCode" to extractedCode,
            "isPriorityFlagged" to isPriorityFlagged,
            "imagePath" to imagePath
        )
    }
}
