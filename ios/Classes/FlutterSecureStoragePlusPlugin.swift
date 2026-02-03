import Flutter
import UIKit
import Security
import LocalAuthentication

public class FlutterSecureStoragePlusPlugin: NSObject, FlutterPlugin {

  private let service = "com.dhiabechattaoui.flutter_secure_storage_plus"

  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(
      name: "flutter_secure_storage_plus",
      binaryMessenger: registrar.messenger()
    )
    registrar.addMethodCallDelegate(
      FlutterSecureStoragePlusPlugin(),
      channel: channel
    )
  }

  // MARK: - Base Query

  private func baseQuery(forKey key: String) -> [String: Any] {
    [
      kSecClass as String: kSecClassGenericPassword,
      kSecAttrService as String: service,
      kSecAttrAccount as String: key
    ]
  }

  // MARK: - Write (系统自动认证)

  private func write(
    key: String,
    value: String,
    requireAuthentication: Bool
  ) -> OSStatus {

    let data = value.data(using: .utf8)!
    var query = baseQuery(forKey: key)

    SecItemDelete(query as CFDictionary)

    if requireAuthentication {
      let accessControl = SecAccessControlCreateWithFlags(
        kCFAllocatorDefault,
        kSecAttrAccessibleWhenUnlockedThisDeviceOnly,
        [.userPresence], // FaceID / TouchID / PIN
        nil
      )!

      query[kSecAttrAccessControl as String] = accessControl
    } else {
      query[kSecAttrAccessible as String] =
        kSecAttrAccessibleWhenUnlockedThisDeviceOnly
    }

    query[kSecValueData as String] = data

    return SecItemAdd(query as CFDictionary, nil)
  }

  // MARK: - Read (系统自动认证)

  private func read(
    key: String
  ) -> String? {

    var query = baseQuery(forKey: key)
    query[kSecReturnData as String] = true
    query[kSecMatchLimit as String] = kSecMatchLimitOne

    var result: AnyObject?
    let status = SecItemCopyMatching(
      query as CFDictionary,
      &result
    )

    guard status == errSecSuccess,
          let data = result as? Data
    else { return nil }

    return String(data: data, encoding: .utf8)
  }

  // MARK: - Delete (不弹认证，系统限制)

  private func delete(key: String) -> OSStatus {
    let query = baseQuery(forKey: key)
    return SecItemDelete(query as CFDictionary)
  }

  // MARK: - Flutter Channel

  public func handle(
    _ call: FlutterMethodCall,
    result: @escaping FlutterResult
  ) {

    switch call.method {

    case "write":
      let args = call.arguments as! [String: Any]
      let key = args["key"] as! String
      let value = args["value"] as! String
      let requireAuth = args["requireBiometrics"] as? Bool ?? false

      let status = write(
        key: key,
        value: value,
        requireAuthentication: requireAuth
      )

      status == errSecSuccess
        ? result(nil)
        : result(FlutterError(
            code: "WRITE_FAILED",
            message: "Keychain error: \(status)",
            details: nil
          ))

    case "read":
      let args = call.arguments as! [String: Any]
      let key = args["key"] as! String

      result(read(key: key))

    case "delete":
      let args = call.arguments as! [String: Any]
      let key = args["key"] as! String
      _ = delete(key: key)
      result(nil)

    default:
      result(FlutterMethodNotImplemented)
    }
  }
}
