package com.dhiabechattaoui.flutter_secure_storage_plus

import android.content.Context
import android.content.SharedPreferences
import android.util.Base64
import androidx.biometric.BiometricPrompt
import androidx.core.content.ContextCompat
import androidx.fragment.app.FragmentActivity
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.nio.charset.Charset
import java.util.concurrent.Executor
import javax.crypto.Cipher
import javax.crypto.spec.GCMParameterSpec

class FlutterSecureStoragePlusPlugin :
    FlutterPlugin,
    MethodChannel.MethodCallHandler,
    ActivityAware {

    private lateinit var channel: MethodChannel
    private lateinit var context: Context
    private lateinit var prefs: SharedPreferences

    private var activity: FragmentActivity? = null
    private lateinit var executor: Executor

    private val PREF_NAME = "flutter_secure_storage_plus_keystore"
    private val KEY_ALIAS = "secure_storage_plus_biometric_key"

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {

        context = binding.applicationContext
        prefs = context.getSharedPreferences(PREF_NAME, Context.MODE_PRIVATE)

        executor = ContextCompat.getMainExecutor(context)

        channel =
            MethodChannel(
                binding.binaryMessenger,
                "flutter_secure_storage_plus"
            )

        channel.setMethodCallHandler(this)
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activity = binding.activity as FragmentActivity
    }

    override fun onDetachedFromActivityForConfigChanges() {
        activity = null
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        activity = binding.activity as FragmentActivity
    }

    override fun onDetachedFromActivity() {
        activity = null
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }

    // =============================
    // Cipher Builders
    // =============================

    private fun buildEncryptCipher(): Cipher {

        val key =
            BiometricKeyStore.getOrCreateKey(
                context,
                KEY_ALIAS
            )

        val cipher =
            Cipher.getInstance("AES/GCM/NoPadding")

        cipher.init(
            Cipher.ENCRYPT_MODE,
            key
        )

        return cipher
    }

    private fun buildDecryptCipher(
        data: ByteArray
    ): Pair<Cipher, ByteArray> {

        val key =
            BiometricKeyStore.getOrCreateKey(
                context,
                KEY_ALIAS
            )

        val iv =
            data.copyOfRange(0, 12)

        val encrypted =
            data.copyOfRange(12, data.size)

        val cipher =
            Cipher.getInstance("AES/GCM/NoPadding")

        cipher.init(
            Cipher.DECRYPT_MODE,
            key,
            GCMParameterSpec(128, iv)
        )

        return Pair(cipher, encrypted)
    }

    // =============================
    // Biometric Crypto Auth
    // =============================

    private fun authenticateAndEncrypt(
        value: String,
        prefKey: String,
        result: MethodChannel.Result
    ) {

        val act = activity ?: run {
            result.error("NO_ACTIVITY", "No FragmentActivity", null)
            return
        }

        val cipher =
            buildEncryptCipher()

        val prompt =
            BiometricPrompt(
                act,
                executor,
                object :
                    BiometricPrompt.AuthenticationCallback() {

                    override fun onAuthenticationSucceeded(
                        authResult: BiometricPrompt.AuthenticationResult
                    ) {

                        try {

                            val cryptoCipher =
                                authResult.cryptoObject!!.cipher!!

                            val encrypted =
                                cryptoCipher.doFinal(
                                    value.toByteArray(
                                        Charset.forName("UTF-8")
                                    )
                                )

                            val combined =
                                cryptoCipher.iv + encrypted

                            val encoded =
                                Base64.encodeToString(
                                    combined,
                                    Base64.NO_WRAP
                                )

                            prefs.edit()
                                .putString(prefKey, encoded)
                                .apply()

                            result.success(null)

                        } catch (e: Exception) {
                            result.error(
                                "ENCRYPT_ERROR",
                                e.message,
                                null
                            )
                        }
                    }

                    override fun onAuthenticationError(
                        errorCode: Int,
                        errString: CharSequence
                    ) {
                        result.error(
                            "AUTH_ERROR",
                            errString.toString(),
                            null
                        )
                    }
                }
            )

        val auth = BiometricAuthHelper.resolveAuthenticators(context)

        val promptInfo =
            BiometricPrompt.PromptInfo.Builder()
                .setTitle("Secure Storage")
                .setSubtitle("Authenticate to encrypt")
                .setAllowedAuthenticators(auth.authenticators)
                .build()

        prompt.authenticate(
            promptInfo,
            BiometricPrompt.CryptoObject(cipher)
        )
    }

    private fun authenticateAndDecrypt(
        stored: String,
        result: MethodChannel.Result
    ) {

        val act = activity ?: run {
            result.error("NO_ACTIVITY", "No FragmentActivity", null)
            return
        }

        val decoded =
            Base64.decode(stored, Base64.NO_WRAP)

        val (cipher, encrypted) =
            buildDecryptCipher(decoded)

        val prompt =
            BiometricPrompt(
                act,
                executor,
                object :
                    BiometricPrompt.AuthenticationCallback() {

                    override fun onAuthenticationSucceeded(
                        authResult: BiometricPrompt.AuthenticationResult
                    ) {

                        try {

                            val cryptoCipher =
                                authResult.cryptoObject!!.cipher!!

                            val decrypted =
                                cryptoCipher.doFinal(encrypted)

                            result.success(
                                String(
                                    decrypted,
                                    Charset.forName("UTF-8")
                                )
                            )

                        } catch (e: Exception) {
                            result.error(
                                "DECRYPT_ERROR",
                                e.message,
                                null
                            )
                        }
                    }

                    override fun onAuthenticationError(
                        errorCode: Int,
                        errString: CharSequence
                    ) {
                        result.error(
                            "AUTH_ERROR",
                            errString.toString(),
                            null
                        )
                    }
                }
            )

        val auth = BiometricAuthHelper.resolveAuthenticators(context)

        val promptInfo =
            BiometricPrompt.PromptInfo.Builder()
                .setTitle("Secure Storage")
                .setSubtitle("Authenticate to decrypt")
                .setAllowedAuthenticators(auth.authenticators)
                .build()

        prompt.authenticate(
            promptInfo,
            BiometricPrompt.CryptoObject(cipher)
        )
    }

    // =============================
    // MethodChannel
    // =============================

    override fun onMethodCall(
        call: MethodCall,
        result: MethodChannel.Result
    ) {

        when (call.method) {

            "write" -> {

                val key =
                    call.argument<String>("key")

                val value =
                    call.argument<String>("value")

                if (key == null || value == null) {
                    result.error(
                        "INVALID_ARGUMENT",
                        "Key and value required",
                        null
                    )
                    return
                }

                authenticateAndEncrypt(
                    value,
                    key,
                    result
                )
            }

            "read" -> {

                val key =
                    call.argument<String>("key")

                if (key == null) {
                    result.error(
                        "INVALID_ARGUMENT",
                        "Key required",
                        null
                    )
                    return
                }

                val stored =
                    prefs.getString(key, null)

                if (stored == null) {
                    result.success(null)
                    return
                }

                authenticateAndDecrypt(
                    stored,
                    result
                )
            }

            "delete" -> {

                val key =
                    call.argument<String>("key")

                if (key == null) {
                    result.error(
                        "INVALID_ARGUMENT",
                        "Key required",
                        null
                    )
                    return
                }

                prefs.edit().remove(key).apply()
                result.success(null)
            }

            "getPlatformVersion" -> {
                result.success("Android")
            }

            else -> result.notImplemented()
        }
    }
}
