package com.example.nksim

import android.app.Activity
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.Person
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.LinearGradient
import android.graphics.Paint
import android.graphics.Shader
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.util.Log
import java.io.File
import java.io.FileOutputStream

/**
 * Headless driver for end-to-end tests of Notification Keeper. It behaves like a
 * messaging app: it posts MessagingStyle conversation notifications - including
 * photo messages whose image travels as message data behind a content URI, the
 * way WhatsApp and Telegram send them - and it can withdraw a notification the
 * way an "unsend / delete for everyone" does (an app-side cancel).
 *
 *   adb shell am start -n com.example.nksim/.MainActivity --es action photo
 *   adb shell am start -n com.example.nksim/.MainActivity --es action text --es text "Merhaba"
 *   adb shell am start -n com.example.nksim/.MainActivity --es action unsend
 *   adb shell am start -n com.example.nksim/.MainActivity --es action photo_unsend --ei delay_ms 3000
 *
 * Optional extras: --es sender "Ayşe" (default), --ei id 42 (notification id).
 */
class MainActivity : Activity() {

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        ensureChannel()

        val action = intent.getStringExtra("action") ?: "photo"
        val sender = intent.getStringExtra("sender") ?: "Ayşe"
        val id = intent.getIntExtra("id", 42)
        val delayMs = intent.getIntExtra("delay_ms", 3000).toLong()

        when (action) {
            "photo" -> { postPhoto(id, sender); finish() }
            "text" -> { postText(id, sender, intent.getStringExtra("text") ?: "Merhaba!"); finish() }
            "unsend" -> { unsend(id); finish() }
            "photo_unsend" -> {
                postPhoto(id, sender)
                // Stay alive (invisibly) long enough to withdraw it, like a sender
                // hitting "delete for everyone" a few seconds after sending.
                Handler(Looper.getMainLooper()).postDelayed({ unsend(id); finish() }, delayMs)
            }
            else -> { Log.w(TAG, "unknown action '$action'"); finish() }
        }
    }

    private fun ensureChannel() {
        val nm = getSystemService(NotificationManager::class.java)
        nm.createNotificationChannel(
            NotificationChannel(CHANNEL_ID, "Chats", NotificationManager.IMPORTANCE_HIGH)
        )
    }

    private fun me() = Person.Builder().setName("Ben").build()

    private fun person(name: String) = Person.Builder().setName(name).setKey(name).build()

    private fun postPhoto(id: Int, sender: String) {
        val name = "photo_${System.currentTimeMillis()}.png"
        writeTestPhoto(File(ImageProvider.sharedDir(this), name))
        val uri = ImageProvider.uriFor(name)

        val message = Notification.MessagingStyle.Message("📷 Fotoğraf", System.currentTimeMillis(), person(sender))
            .setData("image/png", uri)

        post(id, sender, Notification.MessagingStyle(me()).addMessage(message))
        Log.i(TAG, "posted photo message id=$id uri=$uri")
    }

    private fun postText(id: Int, sender: String, text: String) {
        val message = Notification.MessagingStyle.Message(text, System.currentTimeMillis(), person(sender))
        post(id, sender, Notification.MessagingStyle(me()).addMessage(message))
        Log.i(TAG, "posted text message id=$id")
    }

    private fun post(id: Int, sender: String, style: Notification.MessagingStyle) {
        val notification = Notification.Builder(this, CHANNEL_ID)
            .setSmallIcon(android.R.drawable.sym_action_chat)
            .setContentTitle(sender)
            .setCategory(Notification.CATEGORY_MESSAGE)
            .setStyle(style)
            .build()
        getSystemService(NotificationManager::class.java).notify(id, notification)
    }

    private fun unsend(id: Int) {
        // An app cancelling its own notification arrives at listeners as
        // REASON_APP_CANCEL - the signal Notification Keeper's Recall Radar keys on.
        getSystemService(NotificationManager::class.java).cancel(id)
        Log.i(TAG, "withdrew notification id=$id")
    }

    /** A recognisable test image: teal-to-indigo gradient with a white "NK" mark. */
    private fun writeTestPhoto(file: File) {
        val w = 640
        val h = 480
        val bitmap = Bitmap.createBitmap(w, h, Bitmap.Config.ARGB_8888)
        val canvas = Canvas(bitmap)
        val bg = Paint().apply {
            shader = LinearGradient(0f, 0f, w.toFloat(), h.toFloat(),
                Color.rgb(20, 184, 166), Color.rgb(79, 70, 229), Shader.TileMode.CLAMP)
        }
        canvas.drawRect(0f, 0f, w.toFloat(), h.toFloat(), bg)
        val text = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            color = Color.WHITE
            textSize = 180f
            isFakeBoldText = true
            textAlign = Paint.Align.CENTER
        }
        canvas.drawText("NK", w / 2f, h / 2f + 60f, text)
        FileOutputStream(file).use { bitmap.compress(Bitmap.CompressFormat.PNG, 100, it) }
    }

    companion object {
        private const val TAG = "NKSimulator"
        private const val CHANNEL_ID = "chats"
    }
}
