package com.example.notification_keeper.widget

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.widget.RemoteViews
import com.example.notification_keeper.app.MainActivity
import com.example.notification_keeper.app.R
import com.example.notification_keeper.data.database.AppDatabase
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch

/**
 * New feature: home screen widget. Shows up to 4 of the most recently captured
 * notifications so the user can glance at them without opening the app.
 *
 * RemoteViews (what widgets are built from) is deliberately limited - this uses
 * a handful of static TextView rows rather than a scrollable list, which would
 * need a full RemoteViewsService/Factory. Good enough for a "recent activity"
 * glance; a scrollable version is a reasonable future enhancement.
 */
class NotificationWidgetProvider : AppWidgetProvider() {

    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray) {
        for (widgetId in appWidgetIds) {
            updateWidget(context, appWidgetManager, widgetId)
        }
    }

    private fun updateWidget(context: Context, appWidgetManager: AppWidgetManager, widgetId: Int) {
        val views = RemoteViews(context.packageName, R.layout.widget_notification_keeper)

        // Tapping the widget opens the app
        val launchIntent = Intent(context, MainActivity::class.java)
        val pendingIntent = PendingIntent.getActivity(
            context, 0, launchIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        views.setOnClickPendingIntent(R.id.widget_title, pendingIntent)

        // Show a lightweight loading state immediately, then fill in real data async
        // (AppWidgetProvider callbacks run on the main thread and must return quickly,
        // so the DB read happens off-thread and pushes a second update when ready).
        appWidgetManager.updateAppWidget(widgetId, views)

        CoroutineScope(Dispatchers.IO).launch {
            try {
                val db = AppDatabase.getDatabase(context.applicationContext)
                val recent = db.notificationDao().getAll().take(4)

                val freshViews = RemoteViews(context.packageName, R.layout.widget_notification_keeper)
                freshViews.setOnClickPendingIntent(R.id.widget_title, pendingIntent)

                val rowIds = intArrayOf(R.id.widget_row_1, R.id.widget_row_2, R.id.widget_row_3, R.id.widget_row_4)

                if (recent.isEmpty()) {
                    freshViews.setViewVisibility(R.id.widget_empty_state, android.view.View.VISIBLE)
                    for (id in rowIds) {
                        freshViews.setViewVisibility(id, android.view.View.GONE)
                    }
                } else {
                    freshViews.setViewVisibility(R.id.widget_empty_state, android.view.View.GONE)
                    for (i in rowIds.indices) {
                        if (i < recent.size) {
                            val n = recent[i]
                            val snippet = (n.title ?: "").let { t ->
                                if (t.isNotBlank()) "$t: ${n.content ?: ""}" else (n.content ?: "")
                            }
                            freshViews.setViewVisibility(rowIds[i], android.view.View.VISIBLE)
                            freshViews.setTextViewText(rowIds[i], snippet.take(60))
                        } else {
                            freshViews.setViewVisibility(rowIds[i], android.view.View.GONE)
                        }
                    }
                }

                appWidgetManager.updateAppWidget(widgetId, freshViews)
            } catch (e: Exception) {
                // Leave the widget showing its last-known state rather than crashing it
            }
        }
    }

    companion object {
        /**
         * Called from NotificationListener.kt right after a new notification is
         * stored, so the widget refreshes promptly instead of waiting for the next
         * ~30-minute system-driven update.
         */
        fun requestUpdate(context: Context) {
            val manager = AppWidgetManager.getInstance(context)
            val ids = manager.getAppWidgetIds(
                ComponentName(context, NotificationWidgetProvider::class.java)
            )
            if (ids.isNotEmpty()) {
                val intent = Intent(context, NotificationWidgetProvider::class.java).apply {
                    action = AppWidgetManager.ACTION_APPWIDGET_UPDATE
                    putExtra(AppWidgetManager.EXTRA_APPWIDGET_IDS, ids)
                }
                context.sendBroadcast(intent)
            }
        }
    }
}
