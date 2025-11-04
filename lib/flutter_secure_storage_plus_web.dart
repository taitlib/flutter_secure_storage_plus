// In order to *not* need this ignore, consider extracting the "web" version
// of your plugin as a separate package, instead of inlining it in the same
// package as the core of your plugin.
// ignore: avoid_web_libraries_in_flutter

import 'package:flutter_web_plugins/flutter_web_plugins.dart';
import 'package:web/web.dart' as web;

import 'flutter_secure_storage_plus_platform_interface.dart';

/// Web implementation of [FlutterSecureStoragePlusPlatform].
///
/// Note: Web storage using localStorage is not as secure as native keychain/keystore
/// implementations. Data is stored in the browser's localStorage which is accessible
/// to JavaScript on the same origin. For production applications handling sensitive
/// data, consider using additional encryption layers or server-side storage.
class FlutterSecureStoragePlusWeb extends FlutterSecureStoragePlusPlatform {
  /// Constructs a FlutterSecureStoragePlusWeb
  FlutterSecureStoragePlusWeb();

  static const String _storagePrefix = 'flutter_secure_storage_plus_';

  static void registerWith(Registrar registrar) {
    FlutterSecureStoragePlusPlatform.instance = FlutterSecureStoragePlusWeb();
  }

  /// Returns a [String] containing the version of the platform.
  @override
  Future<String?> getPlatformVersion() async {
    final version = web.window.navigator.userAgent;
    return version;
  }

  /// Gets the storage key with prefix
  String _getStorageKey(String key) {
    return '$_storagePrefix$key';
  }

  @override
  Future<void> write({
    required String key,
    required String value,
    bool? requireBiometrics,
  }) async {
    try {
      final storageKey = _getStorageKey(key);
      web.window.localStorage.setItem(storageKey, value);
    } catch (e) {
      throw Exception('Failed to write to localStorage: $e');
    }
  }

  @override
  Future<String?> read({required String key, bool? requireBiometrics}) async {
    try {
      final storageKey = _getStorageKey(key);
      return web.window.localStorage.getItem(storageKey);
    } catch (e) {
      throw Exception('Failed to read from localStorage: $e');
    }
  }

  @override
  Future<void> delete({required String key}) async {
    try {
      final storageKey = _getStorageKey(key);
      web.window.localStorage.removeItem(storageKey);
    } catch (e) {
      throw Exception('Failed to delete from localStorage: $e');
    }
  }

  @override
  Future<int> rotateKeys() async {
    // On web, there are no encryption keys to rotate since localStorage
    // doesn't use encryption. However, we can still re-write all items
    // to simulate key rotation for consistency.
    try {
      var rotatedCount = 0;
      final keys = <String>[];

      // Get all keys with our prefix
      for (var i = 0; i < web.window.localStorage.length; i++) {
        final key = web.window.localStorage.key(i);
        if (key != null && key.startsWith(_storagePrefix)) {
          keys.add(key.substring(_storagePrefix.length));
        }
      }

      // Re-write all items
      for (final key in keys) {
        final storageKey = _getStorageKey(key);
        final value = web.window.localStorage.getItem(storageKey);
        if (value != null) {
          web.window.localStorage.removeItem(storageKey);
          web.window.localStorage.setItem(storageKey, value);
          rotatedCount++;
        }
      }

      return rotatedCount;
    } catch (e) {
      throw Exception('Failed to rotate keys: $e');
    }
  }
}
