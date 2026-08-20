package com.example.notification_keeper.data.entity

import androidx.room.Entity
import androidx.room.PrimaryKey

@Entity(tableName = "notifications")
data class NotificationEntity(
    @PrimaryKey(autoGenerate = true) val id: Long = 0,
    val packageName: String,
    val title: String?,
    val content: String?,
    val subText: String?,
    val timestamp: Long,
    val category: String?,
    val groupKey: String?,
    val isGroupSummary: Boolean,
    val messagingUser: String?,
    val isRead: Boolean = false,
    val isStarred: Boolean = false,
    val tags: String? = null, // Feature 3: comma-separated tags
    // --- Merged from base.apk (com.example.fluter) ---
    val isOtp: Boolean = false, // true if a verification/OTP code was detected in this notification
    val extractedCode: String? = null, // the extracted 4-8 digit code, if isOtp is true
    val isPriorityFlagged: Boolean = false, // true if content matched a user-defined "Keyword Radar" term
    // New feature: path to a saved copy of an image attached to the notification
    // (BigPictureStyle images or large icons), if any. Null if there was no image
    // or it couldn't be saved.
    val imagePath: String? = null,
    // --- New feature A: Recall Radar ---
    // Epoch millis of the moment the source app withdrew this notification
    // shortly after posting it (the fingerprint of a deleted/unsent message).
    // Null means it was never withdrawn, or it was dismissed normally by the user.
    val recalledAt: Long? = null,
    // --- New feature B: Code Shredder ---
    // true once the auto-shred pass has wiped the verification code out of this
    // row (extractedCode nulled, digits in title/content replaced with bullets).
    val codeShredded: Boolean = false
)
