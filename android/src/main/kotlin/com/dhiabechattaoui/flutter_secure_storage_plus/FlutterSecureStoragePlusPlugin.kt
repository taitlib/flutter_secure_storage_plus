package com.dhiabechattaoui.flutter_secure_storage_plus


import android.content.Context
import android.os.Handler
import android.os.Looper
import androidx.biometric.BiometricManager
import androidx.biometric.BiometricPrompt
import androidx.core.content.ContextCompat
import androidx.fragment.app.FragmentActivity
import androidx.security.crypto.EncryptedSharedPreferences
import androidx.security.crypto.MasterKey
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import java.io.IOException
import java.security.GeneralSecurityException
import java.util.concurrent.Executor

/** FlutterSecureStoragePlusPlugin */
class FlutterSecureStoragePlusPlugin: FlutterPlugin, MethodCallHandler, ActivityAware {
  private lateinit var channel : MethodChannel
  private lateinit var context: Context
  private var activityBinding: ActivityPluginBinding? = null
  private val prefsName = "flutter_secure_storage_plus"
  private val biometricPrefsName = "flutter_secure_storage_plus_biometric"

  override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
    channel = MethodChannel(flutterPluginBinding.binaryMessenger, "flutter_secure_storage_plus")
    channel.setMethodCallHandler(this)
    context = flutterPluginBinding.applicationContext
  }
  
  override fun onAttachedToActivity(binding: ActivityPluginBinding) {
    activityBinding = binding
  }
  
  override fun onDetachedFromActivityForConfigChanges() {
    activityBinding = null
  }
  
  override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
    activityBinding = binding
  }
  
  override fun onDetachedFromActivity() {
    activityBinding = null
  }
  
  private fun getFragmentActivity(): FragmentActivity? {
    val binding = activityBinding ?: return null
    val activity = binding.activity
    // Try to cast to FragmentActivity
    return activity as? FragmentActivity
  }

  private fun getEncryptedPrefs(requireBiometrics: Boolean = false): android.content.SharedPreferences? {
    return try {
      val masterKey = if (requireBiometrics) {
        MasterKey.Builder(context, MasterKey.DEFAULT_MASTER_KEY_ALIAS)
          .setKeyScheme(MasterKey.KeyScheme.AES256_GCM)
          .setUserAuthenticationRequired(true)
          .build()
      } else {
        MasterKey.Builder(context)
          .setKeyScheme(MasterKey.KeyScheme.AES256_GCM)
          .build()
      }

      val prefsNameToUse = if (requireBiometrics) biometricPrefsName else prefsName
      
      EncryptedSharedPreferences.create(
        context,
        prefsNameToUse,
        masterKey,
        EncryptedSharedPreferences.PrefKeyEncryptionScheme.AES256_SIV,
        EncryptedSharedPreferences.PrefValueEncryptionScheme.AES256_GCM
      )
    } catch (e: GeneralSecurityException) {
      null
    } catch (e: IOException) {
      null
    }
  }
  
  private fun authenticateWithBiometrics(
    reason: String,
    onSuccess: () -> Unit,
    onError: (String) -> Unit
  ) {
    // Check if biometrics are available first
    val biometricManager = BiometricManager.from(context)
    when (biometricManager.canAuthenticate(BiometricManager.Authenticators.BIOMETRIC_STRONG or BiometricManager.Authenticators.DEVICE_CREDENTIAL)) {
      BiometricManager.BIOMETRIC_ERROR_NO_HARDWARE -> {
        onError("No biometric hardware available")
        return
      }
      BiometricManager.BIOMETRIC_ERROR_HW_UNAVAILABLE -> {
        onError("Biometric hardware unavailable")
        return
      }
      BiometricManager.BIOMETRIC_ERROR_NONE_ENROLLED -> {
        onError("No biometrics enrolled")
        return
      }
      else -> {
        // Continue with authentication
      }
    }
    
    // Get the current activity from binding
    val currentActivity = getFragmentActivity()
    if (currentActivity == null) {
      // Fallback: try to get activity from binding directly
      val binding = activityBinding
      if (binding == null) {
        onError("Activity context required for biometric authentication. Please ensure the app is running.")
        return
      }
      // If we can't get FragmentActivity, we'll need to use a workaround
      // For now, let's try to create a FragmentActivity wrapper or use a different approach
      onError("Biometric authentication requires FragmentActivity. Current activity: ${binding.activity.javaClass.simpleName}")
      return
    }
    
    val executor = ContextCompat.getMainExecutor(context)
    val biometricPrompt = BiometricPrompt(
      currentActivity,
      executor,
      object : BiometricPrompt.AuthenticationCallback() {
        override fun onAuthenticationSucceeded(result: BiometricPrompt.AuthenticationResult) {
          Handler(Looper.getMainLooper()).post {
            onSuccess()
          }
        }

        override fun onAuthenticationError(errorCode: Int, errString: CharSequence) {
          Handler(Looper.getMainLooper()).post {
            onError("Biometric authentication error: $errString")
          }
        }

        override fun onAuthenticationFailed() {
          Handler(Looper.getMainLooper()).post {
            onError("Biometric authentication failed")
          }
        }
      }
    )

    val promptInfo = BiometricPrompt.PromptInfo.Builder()
      .setTitle("Biometric Authentication")
      .setSubtitle(reason)
      .setNegativeButtonText("Cancel")
      .build()

    try {
      biometricPrompt.authenticate(promptInfo)
    } catch (e: Exception) {
      onError("Failed to show biometric prompt: ${e.message}")
    }
  }

  override fun onMethodCall(call: MethodCall, result: Result) {
    when (call.method) {
      "getPlatformVersion" -> {
        result.success("Android ${android.os.Build.VERSION.RELEASE}")
      }
      "write" -> {
        val key = call.argument<String>("key")
        val value = call.argument<String>("value")
        val requireBiometrics = call.argument<Boolean>("requireBiometrics") ?: false
        
        if (key == null || value == null) {
          result.error("INVALID_ARGUMENT", "Key and value are required", null)
          return
        }
        
        if (requireBiometrics) {
          authenticateWithBiometrics(
            reason = "Authenticate to save secure data",
            onSuccess = {
              val prefs = getEncryptedPrefs(requireBiometrics = true)
              if (prefs == null) {
                result.error("STORAGE_ERROR", "Failed to initialize secure storage", null)
                return@authenticateWithBiometrics
              }
              prefs.edit().putString(key, value).apply()
              result.success(null)
            },
            onError = { errorMessage ->
              result.error("AUTH_ERROR", errorMessage, null)
            }
          )
        } else {
          val prefs = getEncryptedPrefs(requireBiometrics = false)
          if (prefs == null) {
            result.error("STORAGE_ERROR", "Failed to initialize secure storage", null)
            return
          }
          prefs.edit().putString(key, value).apply()
          result.success(null)
        }
      }
      "read" -> {
        val key = call.argument<String>("key")
        val requireBiometrics = call.argument<Boolean>("requireBiometrics") ?: false
        
        if (key == null) {
          result.error("INVALID_ARGUMENT", "Key is required", null)
          return
        }
        
        if (requireBiometrics) {
          authenticateWithBiometrics(
            reason = "Authenticate to access secure data",
            onSuccess = {
              val prefs = getEncryptedPrefs(requireBiometrics = true)
              if (prefs == null) {
                result.error("STORAGE_ERROR", "Failed to initialize secure storage", null)
                return@authenticateWithBiometrics
              }
              val value = prefs.getString(key, null)
              result.success(value)
            },
            onError = { errorMessage ->
              result.error("AUTH_ERROR", errorMessage, null)
            }
          )
        } else {
          val prefs = getEncryptedPrefs(requireBiometrics = false)
          if (prefs == null) {
            result.error("STORAGE_ERROR", "Failed to initialize secure storage", null)
            return
          }
          val value = prefs.getString(key, null)
          result.success(value)
        }
      }
      "delete" -> {
        val key = call.argument<String>("key")
        if (key == null) {
          result.error("INVALID_ARGUMENT", "Key is required", null)
          return
        }
        // Try both regular and biometric prefs
        val prefs = getEncryptedPrefs(requireBiometrics = false)
        val biometricPrefs = getEncryptedPrefs(requireBiometrics = true)
        prefs?.edit()?.remove(key)?.apply()
        biometricPrefs?.edit()?.remove(key)?.apply()
        result.success(null)
      }
      "rotateKeys" -> {
        try {
          var rotatedCount = 0
          
          // Rotate regular keys
          val oldPrefs = getEncryptedPrefs(requireBiometrics = false)
          if (oldPrefs != null) {
            val allKeys = oldPrefs.all.keys
            val keyValuePairs = mutableMapOf<String, String?>()
            
            // Read all values
            for (key in allKeys) {
              keyValuePairs[key] = oldPrefs.getString(key, null)
            }
            
            // Clear old preferences
            oldPrefs.edit().clear().apply()
            
            // Create new MasterKey and re-encrypt
            val newMasterKey = MasterKey.Builder(context)
              .setKeyScheme(MasterKey.KeyScheme.AES256_GCM)
              .build()
            
            val newPrefs = EncryptedSharedPreferences.create(
              context,
              prefsName,
              newMasterKey,
              EncryptedSharedPreferences.PrefKeyEncryptionScheme.AES256_SIV,
              EncryptedSharedPreferences.PrefValueEncryptionScheme.AES256_GCM
            )
            
            // Write all values back with new key
            val editor = newPrefs.edit()
            for ((key, value) in keyValuePairs) {
              if (value != null) {
                editor.putString(key, value)
                rotatedCount++
              }
            }
            editor.apply()
          }
          
          // Rotate biometric keys
          val oldBiometricPrefs = getEncryptedPrefs(requireBiometrics = true)
          if (oldBiometricPrefs != null) {
            val allKeys = oldBiometricPrefs.all.keys
            val keyValuePairs = mutableMapOf<String, String?>()
            
            // Read all values
            for (key in allKeys) {
              keyValuePairs[key] = oldBiometricPrefs.getString(key, null)
            }
            
            // Clear old preferences
            oldBiometricPrefs.edit().clear().apply()
            
            // Create new MasterKey with biometric requirement and re-encrypt
            val newBiometricMasterKey = MasterKey.Builder(context, MasterKey.DEFAULT_MASTER_KEY_ALIAS)
              .setKeyScheme(MasterKey.KeyScheme.AES256_GCM)
              .setUserAuthenticationRequired(true)
              .build()
            
            val newBiometricPrefs = EncryptedSharedPreferences.create(
              context,
              biometricPrefsName,
              newBiometricMasterKey,
              EncryptedSharedPreferences.PrefKeyEncryptionScheme.AES256_SIV,
              EncryptedSharedPreferences.PrefValueEncryptionScheme.AES256_GCM
            )
            
            // Write all values back with new key
            val editor = newBiometricPrefs.edit()
            for ((key, value) in keyValuePairs) {
              if (value != null) {
                editor.putString(key, value)
                rotatedCount++
              }
            }
            editor.apply()
          }
          
          result.success(rotatedCount)
        } catch (e: Exception) {
          result.error("ROTATION_ERROR", "Failed to rotate keys: ${e.message}", null)
        }
      }
      else -> {
        result.notImplemented()
      }
    }
  }

  override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
    channel.setMethodCallHandler(null)
  }
}
