package com.example.notification_keeper.data.dao

import androidx.room.Dao
import androidx.room.Insert
import androidx.room.Query
import com.example.notification_keeper.data.entity.NotificationEntity

@Dao
interface NotificationDao {
    @Insert
    suspend fun insert(notification: NotificationEntity)

    // New feature: bulk insert, used when restoring from a backup file
    @Insert
    suspend fun insertAll(notifications: List<NotificationEntity>)

    @Query("SELECT * FROM notifications ORDER BY timestamp DESC")
    suspend fun getAll(): List<NotificationEntity>

    @Query("SELECT * FROM notifications WHERE packageName = :packageName ORDER BY timestamp DESC")
    suspend fun getByApp(packageName: String): List<NotificationEntity>

    // Check if a similar notification exists within the given time range
    @Query("SELECT * FROM notifications WHERE packageName = :packageName AND title = :title AND content = :content AND timestamp > :timestampLimit LIMIT 1")
    suspend fun findDuplicate(packageName: String, title: String?, content: String?, timestampLimit: Long): NotificationEntity?

    @Query("SELECT COUNT(*) FROM notifications")
    suspend fun getCount(): Int

    @Query("SELECT COUNT(*) FROM notifications WHERE timestamp >= :startOfDay")
    suspend fun getTodayCount(startOfDay: Long): Int

    @Query("SELECT COUNT(*) FROM notifications WHERE timestamp >= :startOfWeek")
    suspend fun getWeekCount(startOfWeek: Long): Int

    @Query("SELECT packageName, COUNT(*) as count FROM notifications GROUP BY packageName ORDER BY count DESC")
    suspend fun getCountByApp(): List<AppNotificationCount>

    @Query("SELECT * FROM notifications WHERE timestamp BETWEEN :start AND :end ORDER BY timestamp DESC")
    suspend fun getBetween(start: Long, end: Long): List<NotificationEntity>

    @Query("DELETE FROM notifications WHERE id = :id")
    suspend fun deleteById(id: Long)

    @Query("DELETE FROM notifications WHERE timestamp < :timestamp")
    suspend fun deleteOlderThan(timestamp: Long)

    // New feature: needed so RetentionWorker can delete orphaned image files
    // for notifications it's about to remove (see imagePath on NotificationEntity)
    @Query("SELECT * FROM notifications WHERE timestamp < :timestamp AND imagePath IS NOT NULL")
    suspend fun getOlderThanWithImages(timestamp: Long): List<NotificationEntity>

    @Query("DELETE FROM notifications")
    suspend fun deleteAll()

    @Query("UPDATE notifications SET isStarred = :isStarred WHERE id = :id")
    suspend fun updateStarred(id: Long, isStarred: Boolean)

    @Query("UPDATE notifications SET isRead = :isRead WHERE id = :id")
    suspend fun updateRead(id: Long, isRead: Boolean)

    // Feature 3: Update tags
    @Query("UPDATE notifications SET tags = :tags WHERE id = :id")
    suspend fun updateTags(id: Long, tags: String?)

    // Feature 2: Get hourly distribution for today
    @Query("SELECT * FROM notifications WHERE timestamp >= :startOfDay ORDER BY timestamp ASC")
    suspend fun getTodayNotifications(startOfDay: Long): List<NotificationEntity>

    // --- Merged from base.apk (com.example.fluter) ---

    // Recent Codes widget: most recent notifications with a detected OTP/verification code
    @Query("SELECT * FROM notifications WHERE isOtp = 1 ORDER BY timestamp DESC LIMIT :limit")
    suspend fun getRecentOtpCodes(limit: Int = 20): List<NotificationEntity>

    // Keyword Radar: notifications flagged as priority by the user's keyword list
    @Query("SELECT * FROM notifications WHERE isPriorityFlagged = 1 ORDER BY timestamp DESC")
    suspend fun getPriorityFlagged(): List<NotificationEntity>

    // Date-range search (new feature, see feature #1 in the merge changelog)
    @Query(
        "SELECT * FROM notifications WHERE timestamp BETWEEN :start AND :end " +
        "AND (title LIKE '%' || :query || '%' OR content LIKE '%' || :query || '%' OR tags LIKE '%' || :query || '%') " +
        "ORDER BY timestamp DESC"
    )
    suspend fun searchWithDateRange(query: String, start: Long, end: Long): List<NotificationEntity>
}

data class AppNotificationCount(
    val packageName: String,
    val count: Int
)
