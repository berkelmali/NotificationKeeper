package com.example.notification_keeper.service

import android.os.Handler
import android.os.Looper
import io.flutter.plugin.common.EventChannel

/**
 * Live updates: tells the Flutter UI that the archive changed.
 *
 * The archive used to be read once when a screen opened and never again, so a
 * notification that arrived while the app was open - or while it sat in the
 * background - stayed invisible until a cold start. The listener service runs
 * in the same process as the activity, so a process-wide sink is enough: when
 * the UI is listening, every change is forwarded; when it is not, events are
 * simply dropped (the UI reloads when it comes back anyway).
 */
object NotificationEvents {
    const val CHANNEL = "com.example.notification_keeper/events"

    // A tiny event vocabulary, so the UI can decide what to reload.
    const val POSTED = "posted"
    const val UPDATED = "updated"
    const val RECALLED = "recalled"

    private val main = Handler(Looper.getMainLooper())

    @Volatile
    private var sink: EventChannel.EventSink? = null

    val streamHandler = object : EventChannel.StreamHandler {
        override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
            sink = events
        }

        override fun onCancel(arguments: Any?) {
            sink = null
        }
    }

    /** Safe from any thread; EventSink must be used on the main thread. */
    fun emit(event: String) {
        if (sink == null) return
        main.post { sink?.success(event) }
    }
}
