package com.example.notification_keeper.service

import android.app.Notification
import android.content.Context
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.Canvas
import android.graphics.ImageDecoder
import android.graphics.drawable.BitmapDrawable
import android.graphics.drawable.Drawable
import android.graphics.drawable.Icon
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.util.Log
import java.io.File
import java.io.FileOutputStream
import java.util.UUID
import kotlin.math.max
import kotlin.math.roundToInt

/**
 * Photo vault: keeps a private copy of the picture a notification carries, so it
 * stays viewable in the archive after the sender deletes the message.
 *
 * Apps put pictures in one of three places, and this reads all of them:
 *
 *  1. **Messaging data URI** - WhatsApp, Telegram, Signal and most chat apps
 *     attach a photo to the newest MessagingStyle message as `type` + `uri`,
 *     where the URI points into the sender app's own (non-exported) provider.
 *     Android grants notification listeners temporary read access to such URIs
 *     while the notification is showing, and revokes it the moment the
 *     notification is withdrawn - which is exactly what "delete for everyone"
 *     does. The copy therefore has to happen at post time; there is no later.
 *  2. **`EXTRA_PICTURE_ICON`** - BigPictureStyle as most apps build it on
 *     Android 12+, where the picture is an [Icon] rather than a [Bitmap].
 *  3. **`EXTRA_PICTURE`** - BigPictureStyle with a plain bitmap (older apps).
 *
 * Every picture is decoded and re-encoded rather than copied byte for byte. That
 * bounds storage (long edge capped at [MAX_DIMENSION]), applies the photo's
 * rotation, and drops embedded metadata such as GPS coordinates - a stored copy
 * of someone else's photo should not also keep where it was taken.
 */
class NotificationImageStore(private val context: Context) {

    private val dir: File
        get() = File(context.filesDir, DIR_NAME).apply { if (!exists()) mkdirs() }

    /** Returns the absolute path of the stored copy, or null if there was no picture. */
    fun capture(notification: Notification, lastMessage: Bundle?): String? {
        fromMessageData(lastMessage)?.let { return it }

        val extras = notification.extras
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            @Suppress("DEPRECATION")
            val icon = extras.getParcelable<Icon>(Notification.EXTRA_PICTURE_ICON)
            icon?.loadDrawable(context)?.let(::drawableToBitmap)?.let { return save(it) }
        }

        @Suppress("DEPRECATION")
        (extras.get(Notification.EXTRA_PICTURE) as? Bitmap)?.let { return save(it) }

        return null
    }

    private fun fromMessageData(message: Bundle?): String? {
        if (message == null) return null
        val type = message.getString(KEY_DATA_TYPE) ?: return null
        if (!type.startsWith("image/")) return null
        @Suppress("DEPRECATION")
        val uri = message.getParcelable<Uri>(KEY_DATA_URI) ?: return null

        Log.d(TAG, "Reading message photo $uri ($type)")
        return try {
            decodeUri(uri)?.let(::save)?.also { Log.d(TAG, "Kept message photo as $it") }
        } catch (e: SecurityException) {
            // The platform did not grant us this URI (or already revoked it).
            Log.w(TAG, "No read grant for message photo $uri: ${e.message}")
            null
        } catch (e: Exception) {
            Log.w(TAG, "Could not read message photo $uri", e)
            null
        }
    }

    private fun decodeUri(uri: Uri): Bitmap? {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
            // ImageDecoder applies EXIF orientation and decodes HEIF/WebP too.
            val source = ImageDecoder.createSource(context.contentResolver, uri)
            return ImageDecoder.decodeBitmap(source) { decoder, info, _ ->
                val (w, h) = info.size.width to info.size.height
                val scale = MAX_DIMENSION.toFloat() / max(w, h)
                if (scale < 1f) decoder.setTargetSize((w * scale).roundToInt(), (h * scale).roundToInt())
                decoder.allocator = ImageDecoder.ALLOCATOR_SOFTWARE
            }
        }

        val resolver = context.contentResolver
        val bounds = BitmapFactory.Options().apply { inJustDecodeBounds = true }
        resolver.openInputStream(uri)?.use { BitmapFactory.decodeStream(it, null, bounds) } ?: return null
        if (bounds.outWidth <= 0 || bounds.outHeight <= 0) return null
        val options = BitmapFactory.Options().apply {
            inSampleSize = sampleSizeFor(bounds.outWidth, bounds.outHeight)
        }
        return resolver.openInputStream(uri)?.use { BitmapFactory.decodeStream(it, null, options) }
    }

    private fun drawableToBitmap(drawable: Drawable): Bitmap? {
        if (drawable is BitmapDrawable) drawable.bitmap?.let { return it }
        val w = drawable.intrinsicWidth
        val h = drawable.intrinsicHeight
        if (w <= 0 || h <= 0) return null
        val scale = minOf(1f, MAX_DIMENSION.toFloat() / max(w, h))
        val bitmap = Bitmap.createBitmap(
            (w * scale).roundToInt().coerceAtLeast(1),
            (h * scale).roundToInt().coerceAtLeast(1),
            Bitmap.Config.ARGB_8888
        )
        drawable.setBounds(0, 0, bitmap.width, bitmap.height)
        drawable.draw(Canvas(bitmap))
        return bitmap
    }

    private fun save(source: Bitmap): String? {
        return try {
            val bitmap = downscale(source)
            // Keep transparency when the picture has it (stickers, screenshots
            // of UI); everything else is a photo and JPEG is the right trade-off.
            val png = bitmap.hasAlpha()
            val file = File(dir, "${UUID.randomUUID()}.${if (png) "png" else "jpg"}")
            FileOutputStream(file).use { out ->
                bitmap.compress(
                    if (png) Bitmap.CompressFormat.PNG else Bitmap.CompressFormat.JPEG,
                    if (png) 100 else JPEG_QUALITY,
                    out
                )
            }
            file.absolutePath
        } catch (e: Exception) {
            Log.e(TAG, "Failed to save notification image", e)
            null
        }
    }

    private fun downscale(bitmap: Bitmap): Bitmap {
        val longEdge = max(bitmap.width, bitmap.height)
        if (longEdge <= MAX_DIMENSION) return bitmap
        val scale = MAX_DIMENSION.toFloat() / longEdge
        return Bitmap.createScaledBitmap(
            bitmap,
            (bitmap.width * scale).roundToInt().coerceAtLeast(1),
            (bitmap.height * scale).roundToInt().coerceAtLeast(1),
            true
        )
    }

    /** Count and total size of stored photos, for the storage line in Settings. */
    fun stats(): Pair<Int, Long> {
        val files = dir.listFiles()?.filter { it.isFile } ?: emptyList()
        return files.size to files.sumOf { it.length() }
    }

    /** Deletes every stored photo file. Callers clear the imagePath columns. */
    fun deleteAll() {
        dir.listFiles()?.forEach { runCatching { it.delete() } }
    }

    companion object {
        private const val TAG = "NotificationImageStore"
        const val DIR_NAME = "notification_images"

        /** Long edge of a stored photo. Sharp on a phone screen, ~200-500 KB as JPEG. */
        const val MAX_DIMENSION = 1600
        private const val JPEG_QUALITY = 85

        // Notification.MessagingStyle.Message bundle keys (KEY_DATA_MIME_TYPE / KEY_DATA_URI).
        private const val KEY_DATA_TYPE = "type"
        private const val KEY_DATA_URI = "uri"

        fun sampleSizeFor(width: Int, height: Int, maxDimension: Int = MAX_DIMENSION): Int {
            var sample = 1
            while (max(width, height) / (sample * 2) >= maxDimension) sample *= 2
            return sample
        }
    }
}
