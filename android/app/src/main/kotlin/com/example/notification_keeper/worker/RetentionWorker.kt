package com.example.notification_keeper.worker

import android.content.Context
import androidx.work.CoroutineWorker
import androidx.work.WorkerParameters
import com.example.notification_keeper.data.database.AppDatabase
import java.io.File
import java.util.concurrent.TimeUnit

/**
 * Merged from base.apk (com.example.fluter): "BurnerWorker" / "Data Hygiene" feature.
 *
 * Runs roughly once every 24 hours (see MainActivity's WorkManager scheduling) and
 * automatically deletes notifications older than the user's configured retention window,
 * so the local archive doesn't grow unbounded. Unlike base.apk's raw-SQL version, this
 * reuses the existing Room DAO so it stays in sync with the rest of the app's data layer.
 */
class RetentionWorker(appContext: Context, workerParams: WorkerParameters) :
    CoroutineWorker(appContext, workerParams) {

    override suspend fun doWork(): Result {
        return try {
            val prefs = applicationContext.getSharedPreferences("notification_keeper_prefs", Context.MODE_PRIVATE)
            // 0 = "keep forever" (retention disabled)
            val retentionDays = prefs.getInt("retention_days", 0)
            if (retentionDays <= 0) {
                return Result.success()
            }

            val cutoffTimestamp = System.currentTimeMillis() - TimeUnit.DAYS.toMillis(retentionDays.toLong())
            val db = AppDatabase.getDatabase(applicationContext)

            // New feature: delete orphaned image files for rows we're about to remove,
            // so saved attachment images (see imagePath) don't pile up forever.
            val withImages = db.notificationDao().getOlderThanWithImages(cutoffTimestamp)
            withImages.forEach { entity ->
                entity.imagePath?.let { path ->
                    try {
                        File(path).delete()
                    } catch (e: Exception) {
                        // Non-fatal - the DB row will still be cleaned up below
                    }
                }
            }

            db.notificationDao().deleteOlderThan(cutoffTimestamp)

            Result.success()
        } catch (e: Exception) {
            Result.failure()
        }
    }

    companion object {
        const val WORK_NAME = "RetentionRoutine"
    }
}
