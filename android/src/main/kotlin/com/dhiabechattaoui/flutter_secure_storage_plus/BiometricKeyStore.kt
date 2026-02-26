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

        // 已存在直接返回
        val existingKey = keyStore.getKey(alias, null) as? SecretKey
        if (existingKey != null) {
            return existingKey
        }

        // 必须设置安全锁屏
        val keyguardManager =
            context.getSystemService(Context.KEYGUARD_SERVICE)
                    as KeyguardManager

        if (!keyguardManager.isDeviceSecure) {
            throw IllegalStateException("Secure lock screen required")
        }

        val keyGenerator = KeyGenerator.getInstance(
            KeyProperties.KEY_ALGORITHM_AES,
            ANDROID_KEYSTORE
        )

        val builder = KeyGenParameterSpec.Builder(
            alias,
            KeyProperties.PURPOSE_ENCRYPT or
                    KeyProperties.PURPOSE_DECRYPT
        )
            .setKeySize(256)
            .setBlockModes(KeyProperties.BLOCK_MODE_GCM)
            .setEncryptionPaddings(KeyProperties.ENCRYPTION_PADDING_NONE)
            .setRandomizedEncryptionRequired(true)

            // 🔐 强制认证
            .setUserAuthenticationRequired(true)

            // 不因新增指纹失效
            .setInvalidatedByBiometricEnrollment(false)

        // ===============================
        // 🔥 关键分版本处理
        // ===============================
        try {

            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {

                // ✅ Android 11+
                builder.setUserAuthenticationParameters(
                    0, // 每次必须认证
                    KeyProperties.AUTH_BIOMETRIC_STRONG
                            or KeyProperties.AUTH_DEVICE_CREDENTIAL
                )

            } else {

                // ✅ Android 6 ~ 10
                // ⚠ 不能指定类型
                // ⚠ 不能用 0
                // ⚠ Samsung Android10 必须 -1

                builder.setUserAuthenticationValidityDurationSeconds(-1)
            }

        } catch (e: Exception) {

            // 国产 ROM 兜底
            builder.setUserAuthenticationValidityDurationSeconds(-1)
        }

        // ===============================
        // 🔒 StrongBox（自动降级）
        // ===============================
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