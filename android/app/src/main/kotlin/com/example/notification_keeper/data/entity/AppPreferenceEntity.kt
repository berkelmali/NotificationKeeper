package com.example.notification_keeper.data.entity

import androidx.room.Entity
import androidx.room.PrimaryKey

@Entity(tableName = "app_preferences")
data class AppPreferenceEntity(
    @PrimaryKey val packageName: String,
    val isMonitored: Boolean,
    // New feature: temporary per-app snooze (epoch millis; null/past = not snoozed).
    // Distinct from the global Quiet Hours (base.apk) and the permanent isMonitored
    // toggle - lets the user pause just one noisy app for a few hours without
    // turning off monitoring for it entirely.
    val snoozedUntil: Long? = null
)
