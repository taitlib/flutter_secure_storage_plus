package com.dhiabechattaoui.flutter_secure_storage_plus

import android.content.Context
import android.content.SharedPreferences
import android.util.Base64
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import java.nio.charset.Charset
import javax.crypto.Cipher
import javax.crypto.spec.GCMParameterSpec

class FlutterSecureStoragePlusPlugin :
    FlutterPlugin,
    MethodCallHandler,
    ActivityAware {

    private lateinit var channel: MethodChannel
    private lateinit var context: Context
    private lateinit var prefs: SharedPreferences

    private val PREF_NAME = "flutter_secure_storage_plus_keystore"
    private val KEY_ALIAS = "secure_storage_plus_biometric_key"

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        context = binding.applicationContext
        prefs = context.getSharedPreferences(PREF_NAME, Context.MODE_PRIVATE)

        channel = MethodChannel(binding.binaryMessenger, "flutter_secure_storage_plus")
        channel.setMethodCallHandler(this)
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {}
    override fun onDetachedFromActivityForConfigChanges() {}
    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {}
    override fun onDetachedFromActivity() {}

    // ---------------- AES-GCM ----------------

    private fun encrypt(data: String): String {

        val key = BiometricKeyStore.getOrCreateKey(context, KEY_ALIAS)

        val cipher = Cipher.getInstance("AES/GCM/NoPadding")
        cipher.init(Cipher.ENCRYPT_MODE, key)

        val iv = cipher.iv
        val encrypted = cipher.doFinal(data.toByteArray(Charset.forName("UTF-8")))

        val combined = iv + encrypted

        return Base64.encodeToString(combined, Base64.NO_WRAP)
    }

    private fun decrypt(data: String): String? {

        val key = BiometricKeyStore.getOrCreateKey(context, KEY_ALIAS)

        val combined = Base64.decode(data, Base64.NO_WRAP)

        val iv = combined.copyOfRange(0, 12)
        val encrypted = combined.copyOfRange(12, combined.size)

        val cipher = Cipher.getInstance("AES/GCM/NoPadding")

        val spec = GCMParameterSpec(128, iv)

        // ⭐⭐⭐ 这里会自动触发生物识别 ⭐⭐⭐
        cipher.init(Cipher.DECRYPT_MODE, key, spec)

        val decrypted = cipher.doFinal(encrypted)

        return String(decrypted, Charset.forName("UTF-8"))
    }

    // ---------------- MethodChannel ----------------

    override fun onMethodCall(call: MethodCall, result: Result) {

        when (call.method) {

            "getPlatformVersion" -> {
                result.success("Android ${android.os.Build.VERSION.RELEASE}")
            }

            "write" -> {

                val key = call.argument<String>("key")
                val value = call.argument<String>("value")

                if (key == null || value == null) {
                    result.error("INVALID_ARGUMENT", "Key and value required", null)
                    return
                }

                try {
                    val encrypted = encrypt(value)
                    prefs.edit().putString(key, encrypted).apply()
                    result.success(null)
                } catch (e: Exception) {
                    result.error("WRITE_ERROR", e.javaClass.name + ":" + e.toString(), e.message)
                }
            }

            "read" -> {

                val key = call.argument<String>("key")

                if (key == null) {
                    result.error("INVALID_ARGUMENT", "Key required", null)
                    return
                }

                try {
                    val stored = prefs.getString(key, null)

                    if (stored == null) {
                        result.success(null)
                        return
                    }

                    val decrypted = decrypt(stored)
                    result.success(decrypted)

                } catch (e: Exception) {
                    result.error("READ_ERROR", e.message, null)
                }
            }

            "delete" -> {
                val key = call.argument<String>("key")
                if (key == null) {
                    result.error("INVALID_ARGUMENT", "Key required", null)
                    return
                }
                prefs.edit().remove(key).apply()
                result.success(null)
            }

            else -> result.notImplemented()
        }
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }
}
