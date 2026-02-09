package com.dhiabechattaoui.flutter_secure_storage_plus

import android.app.KeyguardManager
import android.content.Context
import android.os.Build
import android.security.keystore.KeyGenParameterSpec
import android.security.keystore.KeyProperties
import android.util.Log
import java.security.KeyStore
import javax.crypto.KeyGenerator
import javax.crypto.SecretKey

object BiometricKeyStore {

    private const val ANDROID_KEYSTORE = "AndroidKeyStore"

    fun getOrCreateKey(
        context: Context,
        alias: String
    ): SecretKey {

        val ks = KeyStore.getInstance(ANDROID_KEYSTORE)
        ks.load(null)

        val existing =
            ks.getKey(alias, null) as? SecretKey

        if (existing != null) return existing

        val km =
            context.getSystemService(Context.KEYGUARD_SERVICE)
                    as KeyguardManager

        if (!km.isDeviceSecure) {
            throw IllegalStateException(
                "Secure lock screen required"
            )
        }

        val keyGenerator =
            KeyGenerator.getInstance(
                KeyProperties.KEY_ALGORITHM_AES,
                ANDROID_KEYSTORE
            )

        val builder =
            KeyGenParameterSpec.Builder(
                alias,
                KeyProperties.PURPOSE_ENCRYPT or
                        KeyProperties.PURPOSE_DECRYPT
            )
                .setKeySize(256)
                .setBlockModes(KeyProperties.BLOCK_MODE_GCM)
                .setEncryptionPaddings(
                    KeyProperties.ENCRYPTION_PADDING_NONE
                )
                .setRandomizedEncryptionRequired(true)
                .setUserAuthenticationRequired(true)

        // =============================
        // ⭐ Tab S4 / Android10 关键兼容
        // =============================

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {

            builder.setUserAuthenticationParameters(
                0,
                KeyProperties.AUTH_BIOMETRIC_STRONG
                        or KeyProperties.AUTH_DEVICE_CREDENTIAL
            )

        } else {

            // ⭐⭐⭐ Samsung Android10 必须 ≥1
            builder.setUserAuthenticationValidityDurationSeconds(1)
        }

        builder.setInvalidatedByBiometricEnrollment(true)

        // =============================
        // StrongBox 只在支持设备启用
        // =============================

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P
            && context.packageManager.hasSystemFeature(
                "android.hardware.strongbox_keystore"
            )
        ) {
            try {
                builder.setIsStrongBoxBacked(true)
                Log.e("BiometricKeyStore", "StrongBox Enabled")
            } catch (_: Exception) {}
        }

        keyGenerator.init(builder.build())

        Log.e("BiometricKeyStore", "AuthBoundKey Created")

        return keyGenerator.generateKey()
    }
}
