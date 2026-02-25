package com.dhiabechattaoui.flutter_secure_storage_plus

import android.content.Context
import androidx.biometric.BiometricManager

object BiometricAuthHelper {

    data class AuthResult(
        val authenticators: Int,
        val reason: String
    )

    fun resolveAuthenticators(context: Context): AuthResult {

        val manager = BiometricManager.from(context)

        // 1️⃣ 优先 STRONG
        val strong = manager.canAuthenticate(
            BiometricManager.Authenticators.BIOMETRIC_STRONG
        )

        if (strong == BiometricManager.BIOMETRIC_SUCCESS) {
            return AuthResult(
                BiometricManager.Authenticators.BIOMETRIC_STRONG
                        or BiometricManager.Authenticators.DEVICE_CREDENTIAL,
                "Using STRONG biometric"
            )
        }


        // 3️⃣ 最后 PIN
        return AuthResult(
            BiometricManager.Authenticators.DEVICE_CREDENTIAL,
            "Using device credential only"
        )
    }
}
