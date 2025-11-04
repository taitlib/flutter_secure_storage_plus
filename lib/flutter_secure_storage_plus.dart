/// A Flutter plugin for secure storage with biometric authentication and key rotation.
///
/// This package provides a cross-platform secure storage solution with support for:
/// - Biometric-gated read/write operations (Face ID/Touch ID, Android Biometrics)
/// - Transparent key rotation helpers
/// - Secure storage using platform best practices (Keychain/Keystore/Credential Storage)
/// - Web fallback with WASM-friendly APIs
///
/// ## Usage
///
/// ```dart
/// import 'package:flutter_secure_storage_plus/flutter_secure_storage_plus.dart';
///
/// final storage = FlutterSecureStoragePlus();
///
/// // Write with biometric protection
/// await storage.write(
///   key: 'token',
///   value: 'abc',
///   requireBiometrics: true,
/// );
///
/// // Read with biometric authentication
/// final token = await storage.read(
///   key: 'token',
///   requireBiometrics: true,
/// );
///
/// // Rotate encryption keys
/// final rotatedCount = await storage.rotateKeys();
/// ```
// ignore: unnecessary_library_name
library flutter_secure_storage_plus;

import 'flutter_secure_storage_plus_platform_interface.dart';

/// Primary entry point for interacting with secure storage across platforms.
///
/// This class delegates to the current platform implementation registered via
/// [FlutterSecureStoragePlusPlatform]. On mobile and desktop it uses a method
/// channel implementation, and on web it uses a web implementation.
class FlutterSecureStoragePlus {
  /// Creates a new instance of [FlutterSecureStoragePlus].
  FlutterSecureStoragePlus();

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

  /// Rotates encryption keys by re-encrypting all stored values with new keys.
  /// This is a transparent operation that migrates existing data to new encryption keys.
  /// Returns the number of keys that were rotated.
  Future<int> rotateKeys() {
    return FlutterSecureStoragePlusPlatform.instance.rotateKeys();
  }
}
