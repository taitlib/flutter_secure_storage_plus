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

        if (existingKey != null) {
            return existingKey
        }

        // 必须有安全锁屏
        val keyguardManager =
            context.getSystemService(Context.KEYGUARD_SERVICE)
                    as KeyguardManager

        if (!keyguardManager.isDeviceSecure) {
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
                // AES-256
                .setKeySize(256)

                // GCM 模式
                .setBlockModes(KeyProperties.BLOCK_MODE_GCM)
                .setEncryptionPaddings(
                    KeyProperties.ENCRYPTION_PADDING_NONE
                )

                // 每次随机 IV
                .setRandomizedEncryptionRequired(true)

                // 不强制认证
                .setUserAuthenticationRequired(false)

                // 生物变更不失效
                .setInvalidatedByBiometricEnrollment(false)

                // 锁屏状态不可用
               .setUnlockedDeviceRequired(true)


        // =============================
        // 统一使用 0 秒（每次都认证）
        // =============================
        try {

            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {

                // Android 11+
                builder.setUserAuthenticationParameters(
                    0, // 每次都必须认证
                    KeyProperties.AUTH_BIOMETRIC_STRONG
                            or KeyProperties.AUTH_DEVICE_CREDENTIAL
                )

            } else {

                // Android 6 ~ 10
                // ⭐⭐⭐ Samsung Android10 必须 -1
                builder.setUserAuthenticationValidityDurationSeconds(-1)
            }

        } catch (e: NoSuchMethodError) {

            // 🔥 国产ROM兼容
            builder.setUserAuthenticationValidityDurationSeconds(-1)
        }

        // =============================
        // StrongBox（如果支持）
        // =============================

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P &&
            context.packageManager.hasSystemFeature(
                "android.hardware.strongbox_keystore"
            )
        ) {
            try {
                builder.setIsStrongBoxBacked(true)
                Log.d("BiometricKeyStore", "StrongBox enabled")
            } catch (_: Exception) {
                Log.d("BiometricKeyStore", "StrongBox not available")
            }
        }

        keyGenerator.init(builder.build())

        Log.d("BiometricKeyStore", "Auth-bound AES key created")

        return keyGenerator.generateKey()
    }
}