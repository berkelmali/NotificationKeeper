package com.example.notification_keeper.data.dao

import androidx.room.Dao
import androidx.room.Insert
import androidx.room.OnConflictStrategy
import androidx.room.Query
import com.example.notification_keeper.data.entity.AppPreferenceEntity

@Dao
interface AppPreferenceDao {
    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insert(preference: AppPreferenceEntity)

    @Query("SELECT * FROM app_preferences")
    suspend fun getAll(): List<AppPreferenceEntity>
    
    @Query("SELECT isMonitored FROM app_preferences WHERE packageName = :packageName")
    suspend fun isMonitored(packageName: String): Boolean?

    @Query("DELETE FROM app_preferences WHERE packageName = :packageName")
    suspend fun delete(packageName: String)

    // New feature: per-app temporary snooze
    @Query("SELECT snoozedUntil FROM app_preferences WHERE packageName = :packageName")
    suspend fun getSnoozedUntil(packageName: String): Long?

    @Query("UPDATE app_preferences SET snoozedUntil = :until WHERE packageName = :packageName")
    suspend fun setSnoozedUntil(packageName: String, until: Long?)
}
