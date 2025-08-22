import Flutter
import UIKit

public class FlutterSecureStoragePlusPlugin: NSObject, FlutterPlugin {
  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "flutter_secure_storage_plus", binaryMessenger: registrar.messenger())
    let instance = FlutterSecureStoragePlusPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    let userDefaults = UserDefaults.standard
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
      userDefaults.set(value, forKey: key)
      result(nil)
    case "read":
      guard let args = call.arguments as? [String: Any],
            let key = args["key"] as? String else {
        result(FlutterError(code: "INVALID_ARGUMENT", message: "Key is required", details: nil))
        return
      }
      let value = userDefaults.string(forKey: key)
      result(value)
    case "delete":
      guard let args = call.arguments as? [String: Any],
            let key = args["key"] as? String else {
        result(FlutterError(code: "INVALID_ARGUMENT", message: "Key is required", details: nil))
        return
      }
      userDefaults.removeObject(forKey: key)
      result(nil)
    default:
      result(FlutterMethodNotImplemented)
    }
  }
}
