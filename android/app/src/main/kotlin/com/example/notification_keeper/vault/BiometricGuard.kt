package com.example.notification_keeper.vault

import android.app.Activity
import android.content.Context
import android.content.Intent
import android.os.Build
import android.provider.Settings
import android.security.keystore.KeyGenParameterSpec
import android.security.keystore.KeyPermanentlyInvalidatedException
import android.security.keystore.KeyProperties
import android.util.Log
import androidx.biometric.BiometricManager
import androidx.biometric.BiometricManager.Authenticators.BIOMETRIC_STRONG
import androidx.biometric.BiometricPrompt
import androidx.core.content.ContextCompat
import androidx.fragment.app.FragmentActivity
import java.security.KeyStore
import javax.crypto.Cipher
import javax.crypto.KeyGenerator
import javax.crypto.SecretKey

/**
 * Fingerprint unlock for the vault, tied to a Keystore key.
 *
 * Every fingerprint enrolled in Android unlocks the vault - apps cannot keep a
 * list of their own, or tell fingers apart. That is what makes "more than one
 * fingerprint" work, and it is also the risk: whoever adds their finger to an
 * unlocked phone could open the vault with it.
 *
 * So switching fingerprint unlock on creates a Keystore key that only a strong
 * biometric can unlock, and that Android destroys for good as soon as another
 * one is enrolled. Unlocking asks for the fingerprint *through that key* and
 * then uses the key, so a match only counts if it came from a fingerprint that
 * was already on the phone when fingerprint unlock was switched on. Once the
 * key is gone, fingerprints are refused until the vault PIN is entered - the
 * same thing banking apps do.
 *
 * Weak (class 2) biometrics, such as many phones' face unlock, can never
 * unlock the key, so they never open the vault either.
 */
object BiometricGuard {
    private const val TAG = "BiometricGuard"
    private const val KEYSTORE = "AndroidKeyStore"
    private const val ALIAS = "notification_keeper_biometric_guard"
    private const val TRANSFORMATION = "AES/GCM/NoPadding"
    private val CHALLENGE = "notification-keeper-vault".toByteArray()

    const val STATUS_READY = "ready"
    const val STATUS_NONE_ENROLLED = "none_enrolled"
    const val STATUS_UNSUPPORTED = "unsupported"

    const val RESULT_OK = "ok"
    const val RESULT_CANCELLED = "cancelled"
    const val RESULT_INVALIDATED = "invalidated"
    const val RESULT_LOCKOUT = "lockout"
    const val RESULT_UNAVAILABLE = "unavailable"
    const val RESULT_ERROR = "error"

    /** Whether this phone can unlock with a strong biometric, and has one enrolled yet. */
    fun status(context: Context): String =
        when (BiometricManager.from(context).canAuthenticate(BIOMETRIC_STRONG)) {
            BiometricManager.BIOMETRIC_SUCCESS -> STATUS_READY
            BiometricManager.BIOMETRIC_ERROR_NONE_ENROLLED -> STATUS_NONE_ENROLLED
            else -> STATUS_UNSUPPORTED
        }

    /** Creates (or replaces) the key. False when the phone cannot hold one yet. */
    fun create(): Boolean {
        return try {
            delete()
            val builder = KeyGenParameterSpec.Builder(
                ALIAS,
                KeyProperties.PURPOSE_ENCRYPT or KeyProperties.PURPOSE_DECRYPT
            )
                .setBlockModes(KeyProperties.BLOCK_MODE_GCM)
                .setEncryptionPaddings(KeyProperties.ENCRYPTION_PADDING_NONE)
                .setUserAuthenticationRequired(true)
                .setInvalidatedByBiometricEnrollment(true)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
                builder.setUserAuthenticationParameters(0, KeyProperties.AUTH_BIOMETRIC_STRONG)
            }
            KeyGenerator.getInstance(KeyProperties.KEY_ALGORITHM_AES, KEYSTORE).run {
                init(builder.build())
                generateKey()
            }
            true
        } catch (e: Exception) {
            // Typically: no secure lock screen, or no fingerprint enrolled yet.
            Log.w(TAG, "Could not create the biometric key: ${e.message}")
            false
        }
    }

    fun delete() {
        try {
            KeyStore.getInstance(KEYSTORE).apply { load(null) }.deleteEntry(ALIAS)
        } catch (e: Exception) {
            // Nothing to delete.
        }
    }

    /**
     * Asks for a fingerprint through the key and reports one of the RESULT_
     * values, exactly once. A key Android has invalidated is reported before
     * any prompt appears.
     */
    fun unlock(
        activity: FragmentActivity,
        title: String,
        subtitle: String?,
        cancel: String,
        onResult: (String) -> Unit,
    ) {
        val cipher = try {
            val key = KeyStore.getInstance(KEYSTORE).apply { load(null) }
                .getKey(ALIAS, null) as? SecretKey
                // Gone entirely - e.g. the phone's screen lock was removed,
                // which deletes every key like this one. Same remedy: the PIN.
                ?: return onResult(RESULT_INVALIDATED)
            Cipher.getInstance(TRANSFORMATION).apply { init(Cipher.ENCRYPT_MODE, key) }
        } catch (e: KeyPermanentlyInvalidatedException) {
            return onResult(RESULT_INVALIDATED)
        } catch (e: Exception) {
            Log.w(TAG, "Could not prepare the biometric key: ${e.message}")
            return onResult(RESULT_ERROR)
        }

        var answered = false
        fun answer(result: String) {
            if (answered) return
            answered = true
            onResult(result)
        }

        val callback = object : BiometricPrompt.AuthenticationCallback() {
            override fun onAuthenticationSucceeded(result: BiometricPrompt.AuthenticationResult) {
                // Use the key: success means it really was unlocked, not just
                // that a callback said so.
                val used = try {
                    result.cryptoObject?.cipher?.doFinal(CHALLENGE) != null
                } catch (e: Exception) {
                    false
                }
                answer(if (used) RESULT_OK else RESULT_ERROR)
            }

            override fun onAuthenticationError(errorCode: Int, errString: CharSequence) {
                answer(
                    when (errorCode) {
                        BiometricPrompt.ERROR_NEGATIVE_BUTTON,
                        BiometricPrompt.ERROR_USER_CANCELED,
                        BiometricPrompt.ERROR_CANCELED,
                        BiometricPrompt.ERROR_TIMEOUT -> RESULT_CANCELLED
                        BiometricPrompt.ERROR_LOCKOUT,
                        BiometricPrompt.ERROR_LOCKOUT_PERMANENT -> RESULT_LOCKOUT
                        BiometricPrompt.ERROR_NO_BIOMETRICS,
                        BiometricPrompt.ERROR_HW_NOT_PRESENT,
                        BiometricPrompt.ERROR_HW_UNAVAILABLE -> RESULT_UNAVAILABLE
                        else -> RESULT_ERROR
                    }
                )
            }

            // onAuthenticationFailed: a finger that did not match. The prompt
            // stays up and says so itself; there is nothing to report yet.
        }

        val info = BiometricPrompt.PromptInfo.Builder()
            .setTitle(title)
            .apply { if (!subtitle.isNullOrEmpty()) setSubtitle(subtitle) }
            .setNegativeButtonText(cancel)
            .setAllowedAuthenticators(BIOMETRIC_STRONG)
            .setConfirmationRequired(false)
            .build()

        try {
            BiometricPrompt(activity, ContextCompat.getMainExecutor(activity), callback)
                .authenticate(info, BiometricPrompt.CryptoObject(cipher))
        } catch (e: Exception) {
            Log.w(TAG, "Could not show the biometric prompt: ${e.message}")
            answer(RESULT_ERROR)
        }
    }

    /**
     * Opens the system screen where fingerprints are added - the only place an
     * Android app can send someone to enrol one.
     *
     * Android's direct "enrol a biometric" screen closes straight away once a
     * strong biometric is enrolled, so with a finger already saved this goes
     * to the fingerprint list instead, where more are added or removed. Then
     * older entry points, then Security settings.
     */
    fun openEnrollment(activity: Activity): Boolean {
        val candidates = mutableListOf<Intent>()
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R && status(activity) == STATUS_NONE_ENROLLED) {
            candidates += Intent(Settings.ACTION_BIOMETRIC_ENROLL).putExtra(
                Settings.EXTRA_BIOMETRIC_AUTHENTICATORS_ALLOWED,
                BIOMETRIC_STRONG
            )
        }
        candidates += Intent(ACTION_FINGERPRINT_SETTINGS)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
            @Suppress("DEPRECATION")
            candidates += Intent(Settings.ACTION_FINGERPRINT_ENROLL)
        }
        candidates += Intent(Settings.ACTION_SECURITY_SETTINGS)

        for (intent in candidates) {
            if (intent.resolveActivity(activity.packageManager) != null) {
                activity.startActivity(intent)
                return true
            }
        }
        return false
    }

    /** The fingerprint list in Android's settings. Not in the SDK, but long-standing in AOSP. */
    private const val ACTION_FINGERPRINT_SETTINGS = "android.settings.FINGERPRINT_SETTINGS"
}
