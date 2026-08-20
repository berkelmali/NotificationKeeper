package com.example.notification_keeper.worker

import android.content.Context
import androidx.work.CoroutineWorker
import androidx.work.WorkerParameters
import com.example.notification_keeper.data.database.AppDatabase

/**
 * New feature B: "Code Shredder" — ephemeral verification codes.
 *
 * A one-time password is the single most sensitive thing this app ever stores,
 * and it is worthless roughly a minute after it arrives. Keeping it in the
 * archive forever is all risk and no benefit: anyone who gets past the vault
 * (or reads an unencrypted export) inherits every code the phone ever received.
 *
 * So the user can pick a shred window (off / 5 min / 15 min / 1 hour / 1 day).
 * Once a captured code is older than that window, this pass destroys the digits
 * in place: `extractedCode` is nulled and every 4-8 digit run in the title and
 * body is replaced with bullets. The row itself survives, so the archive still
 * records "a verification code arrived from this app at this time" — the
 * history stays intact, only the secret is gone.
 *
 * Deliberately irreversible: it is an UPDATE over the real row, not a display
 * filter, so the code is gone from the database file, from CSV/JSON exports and
 * from any backup taken afterwards.
 */
object CodeShredder {
    const val PREF_KEY = "otp_shred_minutes"
    const val WORK_NAME = "CodeShredRoutine"

    private val digitRun = Regex("\\d{4,8}")

    /** Replaces every 4-8 digit run with the same number of bullet characters. */
    fun redact(value: String?): String? =
        value?.replace(digitRun) { match -> "•".repeat(match.value.length) }

    /**
     * Shreds every captured code older than the configured window.
     * Returns how many rows were wiped (0 when the feature is off).
     */
    suspend fun shredExpired(context: Context): Int {
        val prefs = context.getSharedPreferences("notification_keeper_prefs", Context.MODE_PRIVATE)
        // 0 = "keep codes" (shredder disabled)
        val minutes = prefs.getInt(PREF_KEY, 0)
        if (minutes <= 0) return 0

        val cutoff = System.currentTimeMillis() - minutes * 60_000L
        val dao = AppDatabase.getDatabase(context.applicationContext).notificationDao()

        var shredded = 0
        for (entity in dao.getShreddableCodes(cutoff)) {
            dao.shredCode(entity.id, redact(entity.title), redact(entity.content))
            shredded++
        }
        return shredded
    }
}

/**
 * Runs the shred pass on a schedule so codes expire even while the app is
 * closed. 15 minutes is WorkManager's minimum periodic interval; a shorter
 * user-facing window (5 minutes) therefore shreds on the next tick, or
 * immediately the next time the app is opened — MainActivity runs the same
 * pass on startup.
 */
class CodeShredWorker(appContext: Context, workerParams: WorkerParameters) :
    CoroutineWorker(appContext, workerParams) {

    override suspend fun doWork(): Result {
        return try {
            CodeShredder.shredExpired(applicationContext)
            Result.success()
        } catch (e: Exception) {
            Result.failure()
        }
    }
}
