package com.example.notification_keeper.apps

import android.content.Context
import android.content.Intent
import android.content.pm.ApplicationInfo
import android.content.pm.PackageManager
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.drawable.Drawable
import java.io.ByteArrayOutputStream

/**
 * App detection: what an app is really called and what its icon looks like,
 * straight from Android rather than guessed from the package name.
 *
 * The Flutter side used to derive names from the last package segment, which
 * named Telegram "Messenger" (org.telegram.messenger) and Instagram "Android"
 * (com.instagram.android), and drew a coloured letter instead of the icon.
 */
class AppCatalog(context: Context) {

    private val pm: PackageManager = context.packageManager
    private val ownPackage: String = context.packageName

    /**
     * Packages with a launcher entry - the apps a person thinks of as "apps".
     * The full installed list on a stock Android 16 image is ~250 packages, led
     * by things like "2 Button Navigation Bar" overlays that can never post a
     * notification; this is what the Apps screen should show by default.
     */
    fun launchablePackages(): Set<String> {
        val intent = Intent(Intent.ACTION_MAIN).addCategory(Intent.CATEGORY_LAUNCHER)
        @Suppress("DEPRECATION")
        return pm.queryIntentActivities(intent, 0).mapTo(HashSet()) { it.activityInfo.packageName }
    }

    fun installedApplications(): List<ApplicationInfo> {
        @Suppress("DEPRECATION")
        return pm.getInstalledApplications(0).filter { it.packageName != ownPackage }
    }

    fun label(info: ApplicationInfo): String = pm.getApplicationLabel(info).toString()

    fun isSystem(info: ApplicationInfo): Boolean =
        (info.flags and ApplicationInfo.FLAG_SYSTEM) != 0 &&
            (info.flags and ApplicationInfo.FLAG_UPDATED_SYSTEM_APP) == 0

    /**
     * Label and icon for one package, as a channel-ready map. An app that is no
     * longer installed (uninstalled since its notifications were archived, or a
     * backup restored from another phone) comes back with installed=false and
     * no label, and the Flutter side falls back to its verified known-app table.
     */
    fun identity(packageName: String, iconSizePx: Int): Map<String, Any?> {
        return try {
            @Suppress("DEPRECATION")
            val info = pm.getApplicationInfo(packageName, 0)
            mapOf(
                "packageName" to packageName,
                "label" to label(info),
                "icon" to iconPng(pm.getApplicationIcon(info), iconSizePx),
                "installed" to true,
                "isSystem" to isSystem(info),
            )
        } catch (e: PackageManager.NameNotFoundException) {
            mapOf(
                "packageName" to packageName,
                "label" to null,
                "icon" to null,
                "installed" to false,
                "isSystem" to false,
            )
        }
    }

    /** Renders any icon - adaptive icons included, with the device's mask shape - to PNG. */
    private fun iconPng(drawable: Drawable, size: Int): ByteArray? {
        return try {
            val bitmap = Bitmap.createBitmap(size, size, Bitmap.Config.ARGB_8888)
            drawable.setBounds(0, 0, size, size)
            drawable.draw(Canvas(bitmap))
            ByteArrayOutputStream().use { out ->
                bitmap.compress(Bitmap.CompressFormat.PNG, 100, out)
                out.toByteArray()
            }
        } catch (e: Exception) {
            null
        }
    }
}
