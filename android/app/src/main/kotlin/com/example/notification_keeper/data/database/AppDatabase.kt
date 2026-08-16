package com.example.notification_keeper.data.database

import android.content.Context
import androidx.room.Database
import androidx.room.Room
import androidx.room.RoomDatabase
import androidx.room.migration.Migration
import androidx.sqlite.db.SupportSQLiteDatabase
import com.example.notification_keeper.data.dao.AppPreferenceDao
import com.example.notification_keeper.data.dao.NotificationDao
import com.example.notification_keeper.data.entity.AppPreferenceEntity
import com.example.notification_keeper.data.entity.NotificationEntity

@Database(entities = [NotificationEntity::class, AppPreferenceEntity::class], version = 6, exportSchema = false)
abstract class AppDatabase : RoomDatabase() {
    abstract fun notificationDao(): NotificationDao
    abstract fun appPreferenceDao(): AppPreferenceDao

    companion object {
        @Volatile
        private var INSTANCE: AppDatabase? = null

        private val MIGRATION_1_2 = object : Migration(1, 2) {
            override fun migrate(db: SupportSQLiteDatabase) {
                db.execSQL("ALTER TABLE notifications ADD COLUMN isRead INTEGER NOT NULL DEFAULT 0")
                db.execSQL("ALTER TABLE notifications ADD COLUMN isStarred INTEGER NOT NULL DEFAULT 0")
            }
        }

        private val MIGRATION_2_3 = object : Migration(2, 3) {
            override fun migrate(db: SupportSQLiteDatabase) {
                // Feature 3: Add tags column for notification tagging
                db.execSQL("ALTER TABLE notifications ADD COLUMN tags TEXT DEFAULT NULL")
            }
        }

        // Merged from base.apk (com.example.fluter): OTP detection + Keyword Radar columns
        private val MIGRATION_3_4 = object : Migration(3, 4) {
            override fun migrate(db: SupportSQLiteDatabase) {
                db.execSQL("ALTER TABLE notifications ADD COLUMN isOtp INTEGER NOT NULL DEFAULT 0")
                db.execSQL("ALTER TABLE notifications ADD COLUMN extractedCode TEXT DEFAULT NULL")
                db.execSQL("ALTER TABLE notifications ADD COLUMN isPriorityFlagged INTEGER NOT NULL DEFAULT 0")

                db.execSQL("CREATE INDEX IF NOT EXISTS idx_notifications_otp ON notifications(timestamp DESC) WHERE isOtp = 1")
                db.execSQL("CREATE INDEX IF NOT EXISTS idx_notifications_priority ON notifications(timestamp DESC) WHERE isPriorityFlagged = 1")
            }
        }

        // New feature: per-app temporary snooze
        private val MIGRATION_4_5 = object : Migration(4, 5) {
            override fun migrate(db: SupportSQLiteDatabase) {
                db.execSQL("ALTER TABLE app_preferences ADD COLUMN snoozedUntil INTEGER DEFAULT NULL")
            }
        }

        // New feature: image attachment preview
        private val MIGRATION_5_6 = object : Migration(5, 6) {
            override fun migrate(db: SupportSQLiteDatabase) {
                db.execSQL("ALTER TABLE notifications ADD COLUMN imagePath TEXT DEFAULT NULL")
            }
        }

        fun getDatabase(context: Context): AppDatabase {
            return INSTANCE ?: synchronized(this) {
                val instance = Room.databaseBuilder(
                    context.applicationContext,
                    AppDatabase::class.java,
                    "notification_keeper_database"
                )
                .addMigrations(MIGRATION_1_2, MIGRATION_2_3, MIGRATION_3_4, MIGRATION_4_5, MIGRATION_5_6)
                .fallbackToDestructiveMigration() // For development simplicity
                .build()
                INSTANCE = instance
                instance
            }
        }
    }
}
