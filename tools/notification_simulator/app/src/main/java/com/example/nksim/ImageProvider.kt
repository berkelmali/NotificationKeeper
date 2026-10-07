package com.example.nksim

import android.content.ContentProvider
import android.content.ContentValues
import android.database.Cursor
import android.net.Uri
import android.os.ParcelFileDescriptor
import java.io.File
import java.io.FileNotFoundException

/**
 * A deliberately minimal stand-in for a messaging app's FileProvider.
 *
 * It is not exported, so the only way another app can read a photo is through
 * the temporary URI grant Android issues while a notification that references
 * the URI is showing - which is exactly the situation Notification Keeper is
 * in when WhatsApp or Telegram posts a photo message.
 */
class ImageProvider : ContentProvider() {

    override fun onCreate(): Boolean = true

    override fun openFile(uri: Uri, mode: String): ParcelFileDescriptor {
        android.util.Log.i("NKSimulator", "openFile $uri mode=$mode by uid=${android.os.Binder.getCallingUid()}")
        val name = uri.lastPathSegment ?: throw FileNotFoundException("no file name in $uri")
        // Reject anything that tries to climb out of the shared directory.
        if (name.contains('/') || name.contains("..")) throw FileNotFoundException(name)
        val file = File(sharedDir(context!!), name)
        if (!file.exists()) throw FileNotFoundException(file.path)
        return ParcelFileDescriptor.open(file, ParcelFileDescriptor.MODE_READ_ONLY)
    }

    override fun getType(uri: Uri): String = "image/png"

    override fun query(
        uri: Uri,
        projection: Array<out String>?,
        selection: String?,
        selectionArgs: Array<out String>?,
        sortOrder: String?
    ): Cursor? = null

    override fun insert(uri: Uri, values: ContentValues?): Uri? = null

    override fun delete(uri: Uri, selection: String?, selectionArgs: Array<out String>?): Int = 0

    override fun update(
        uri: Uri,
        values: ContentValues?,
        selection: String?,
        selectionArgs: Array<out String>?
    ): Int = 0

    companion object {
        const val AUTHORITY = "com.example.nksim.images"

        fun sharedDir(context: android.content.Context): File =
            File(context.cacheDir, "shared").apply { mkdirs() }

        fun uriFor(name: String): Uri = Uri.parse("content://$AUTHORITY/$name")
    }
}
