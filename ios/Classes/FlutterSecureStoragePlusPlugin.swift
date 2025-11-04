import Flutter
import UIKit
import Security
import LocalAuthentication

public class FlutterSecureStoragePlusPlugin: NSObject, FlutterPlugin {
  private let service = "com.dhiabechattaoui.flutter_secure_storage_plus"
  
  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "flutter_secure_storage_plus", binaryMessenger: registrar.messenger())
    let instance = FlutterSecureStoragePlusPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  private func keychainQuery(forKey key: String, requireBiometrics: Bool = false) -> [String: Any] {
    var query: [String: Any] = [
      kSecClass as String: kSecClassGenericPassword,
      kSecAttrService as String: service,
      kSecAttrAccount as String: key
    ]
    
    if requireBiometrics {
      // When using biometrics, use SecAccessControl instead of kSecAttrAccessible
      if let accessControl = SecAccessControlCreateWithFlags(
        kCFAllocatorDefault,
        kSecAttrAccessibleWhenUnlockedThisDeviceOnly,
        [.biometryAny, .devicePasscode],
        nil
      ) {
        query[kSecAttrAccessControl as String] = accessControl
      }
    } else {
      query[kSecAttrAccessible as String] = kSecAttrAccessibleWhenUnlockedThisDeviceOnly
    }
    
    return query
  }
  
  private func authenticateWithBiometrics(reason: String, completion: @escaping (Bool, Error?) -> Void) {
    let context = LAContext()
    var error: NSError?
    
    if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
      context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) { success, authenticationError in
        DispatchQueue.main.async {
          completion(success, authenticationError)
        }
      }
    } else {
      // Fallback to device passcode if biometrics not available
      if context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) {
        context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: reason) { success, authenticationError in
          DispatchQueue.main.async {
            completion(success, authenticationError)
          }
        }
      } else {
        DispatchQueue.main.async {
          completion(false, error)
        }
      }
    }
  }

  private func writeToKeychain(key: String, value: String, requireBiometrics: Bool = false) -> OSStatus {
    let data = value.data(using: .utf8)!
    var query = keychainQuery(forKey: key, requireBiometrics: requireBiometrics)
    
    // Delete any existing item
    SecItemDelete(query as CFDictionary)
    
    // Add new item
    query[kSecValueData as String] = data
    
    // For biometric-protected items, provide authentication context
    if requireBiometrics {
      let context = LAContext()
      context.localizedFallbackTitle = ""
      query[kSecUseAuthenticationContext as String] = context
    }
    
    return SecItemAdd(query as CFDictionary, nil)
  }

  private func readFromKeychain(key: String, requireBiometrics: Bool = false) -> String? {
    var query = keychainQuery(forKey: key, requireBiometrics: requireBiometrics)
    query[kSecReturnData as String] = kCFBooleanTrue
    query[kSecMatchLimit as String] = kSecMatchLimitOne
    
    // For biometric-protected items, we need to provide an authentication context
    if requireBiometrics {
      let context = LAContext()
      context.localizedFallbackTitle = ""
      query[kSecUseAuthenticationContext as String] = context
    }
    
    var result: AnyObject?
    let status = SecItemCopyMatching(query as CFDictionary, &result)
    
    if status == errSecSuccess,
       let data = result as? Data,
       let value = String(data: data, encoding: .utf8) {
      return value
    }
    return nil
  }

  private func deleteFromKeychain(key: String) -> OSStatus {
    let query = keychainQuery(forKey: key)
    return SecItemDelete(query as CFDictionary)
  }
  
  private func getAllKeysFromKeychain() -> [String] {
    var query: [String: Any] = [
      kSecClass as String: kSecClassGenericPassword,
      kSecAttrService as String: service,
      kSecReturnAttributes as String: kCFBooleanTrue,
      kSecMatchLimit as String: kSecMatchLimitAll
    ]
    
    var result: AnyObject?
    let status = SecItemCopyMatching(query as CFDictionary, &result)
    
    if status == errSecSuccess,
       let items = result as? [[String: Any]] {
      return items.compactMap { item in
        item[kSecAttrAccount as String] as? String
      }
    }
    return []
  }
  
  private func rotateKeysInKeychain() -> Int {
    let keys = getAllKeysFromKeychain()
    var rotatedCount = 0
    
    for key in keys {
      // Read the value
      if let value = readFromKeychain(key: key, requireBiometrics: false) {
        // Delete the old item
        let _ = deleteFromKeychain(key: key)
        
        // Determine if this was a biometric-protected item by trying to read with biometrics
        // For simplicity, we'll re-encrypt without biometrics
        // In a real scenario, you might want to track which keys require biometrics
        let status = writeToKeychain(key: key, value: value, requireBiometrics: false)
        if status == errSecSuccess {
          rotatedCount += 1
        }
      }
    }
    
    return rotatedCount
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "getPlatformVersion":
      result("iOS " + UIDevice.current.systemVersion)
    case "write":
      guard let args = call.arguments as? [String: Any],
            let key = args["key"] as? String,
            let value = args["value"] as? String else {
        result(FlutterError(code: "INVALID_ARGUMENT", message: "Key and value are required", details: nil))
        return
      }
      let requireBiometrics = args["requireBiometrics"] as? Bool ?? false
      
      if requireBiometrics {
        // Authenticate before writing
        authenticateWithBiometrics(reason: "Authenticate to save secure data") { success, error in
          if success {
            let status = self.writeToKeychain(key: key, value: value, requireBiometrics: true)
            if status == errSecSuccess {
              result(nil)
            } else {
              result(FlutterError(code: "STORAGE_ERROR", message: "Failed to write to keychain: \(status)", details: nil))
            }
          } else {
            result(FlutterError(code: "AUTH_ERROR", message: "Biometric authentication failed", details: error?.localizedDescription))
          }
        }
      } else {
        let status = writeToKeychain(key: key, value: value, requireBiometrics: false)
        if status == errSecSuccess {
          result(nil)
        } else {
          result(FlutterError(code: "STORAGE_ERROR", message: "Failed to write to keychain: \(status)", details: nil))
        }
      }
    case "read":
      guard let args = call.arguments as? [String: Any],
            let key = args["key"] as? String else {
        result(FlutterError(code: "INVALID_ARGUMENT", message: "Key is required", details: nil))
        return
      }
      let requireBiometrics = args["requireBiometrics"] as? Bool ?? false
      
      if requireBiometrics {
        // Authenticate before reading
        authenticateWithBiometrics(reason: "Authenticate to access secure data") { success, error in
          if success {
            if let value = self.readFromKeychain(key: key, requireBiometrics: true) {
              result(value)
            } else {
              result(nil)
            }
          } else {
            result(FlutterError(code: "AUTH_ERROR", message: "Biometric authentication failed", details: error?.localizedDescription))
          }
        }
      } else {
        if let value = readFromKeychain(key: key, requireBiometrics: false) {
          result(value)
        } else {
          result(nil)
        }
      }
    case "delete":
      guard let args = call.arguments as? [String: Any],
            let key = args["key"] as? String else {
        result(FlutterError(code: "INVALID_ARGUMENT", message: "Key is required", details: nil))
        return
      }
      let status = deleteFromKeychain(key: key)
      if status == errSecSuccess || status == errSecItemNotFound {
        result(nil)
      } else {
        result(FlutterError(code: "STORAGE_ERROR", message: "Failed to delete from keychain: \(status)", details: nil))
      }
    case "rotateKeys":
      let rotatedCount = rotateKeysInKeychain()
      result(rotatedCount)
    default:
      result(FlutterMethodNotImplemented)
    }
  }
}
