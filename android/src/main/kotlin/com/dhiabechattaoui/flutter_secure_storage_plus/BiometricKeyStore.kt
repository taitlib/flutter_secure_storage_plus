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

        val keyStore = KeyStore.getInstance(ANDROID_KEYSTORE)
        keyStore.load(null)

        val existingKey =
            keyStore.getKey(alias, null) as? SecretKey

        if (existingKey != null) return existingKey

        val km =
            context.getSystemService(Context.KEYGUARD_SERVICE)
                    as KeyguardManager

        if (!km.isDeviceSecure) {
            throw IllegalStateException("Secure lock screen required")
        }

        val keyGenerator =
            KeyGenerator.getInstance(
                KeyProperties.KEY_ALGORITHM_AES,
                ANDROID_KEYSTORE
            )

        val builder = KeyGenParameterSpec.Builder(
            alias,
            KeyProperties.PURPOSE_ENCRYPT or
                    KeyProperties.PURPOSE_DECRYPT
        )
            .setBlockModes(KeyProperties.BLOCK_MODE_GCM)
            .setEncryptionPaddings(
                KeyProperties.ENCRYPTION_PADDING_NONE
            )
            // ⭐⭐⭐ 模拟器也必须开启 ⭐⭐⭐
            .setUserAuthenticationRequired(true)

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {

            builder.setUserAuthenticationParameters(
                0,
                KeyProperties.AUTH_BIOMETRIC_STRONG
                        or KeyProperties.AUTH_DEVICE_CREDENTIAL
            )

        } else {

            // Android10 Samsung 兼容
            builder.setUserAuthenticationValidityDurationSeconds(0)
        }

        builder.setInvalidatedByBiometricEnrollment(true)

        keyGenerator.init(builder.build())

        Log.e("BiometricKeyStore", "AuthBoundKey Created")

        return keyGenerator.generateKey()
    }
}
