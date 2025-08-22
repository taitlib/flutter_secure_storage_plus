import 'flutter_secure_storage_plus_platform_interface.dart';

/// Primary entry point for interacting with secure storage across platforms.
///
/// This class delegates to the current platform implementation registered via
/// [FlutterSecureStoragePlusPlatform]. On mobile and desktop it uses a method
/// channel implementation, and on web it uses a web implementation.
class FlutterSecureStoragePlus {
  /// Returns the underlying platform's version string, primarily for demos
  /// and diagnostics. The exact format varies by platform.
  Future<String?> getPlatformVersion() {
    return FlutterSecureStoragePlusPlatform.instance.getPlatformVersion();
  }

  /// Writes a value to secure storage for the given key.
  Future<void> write({
    required String key,
    required String value,
    bool? requireBiometrics,
  }) {
    return FlutterSecureStoragePlusPlatform.instance.write(
      key: key,
      value: value,
      requireBiometrics: requireBiometrics,
    );
  }

  /// Reads a value from secure storage for the given key.
  Future<String?> read({required String key, bool? requireBiometrics}) {
    return FlutterSecureStoragePlusPlatform.instance.read(
      key: key,
      requireBiometrics: requireBiometrics,
    );
  }

  /// Deletes a value from secure storage for the given key.
  Future<void> delete({required String key}) {
    return FlutterSecureStoragePlusPlatform.instance.delete(key: key);
  }
}
