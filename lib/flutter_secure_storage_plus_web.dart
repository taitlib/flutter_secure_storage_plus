// In order to *not* need this ignore, consider extracting the "web" version
// of your plugin as a separate package, instead of inlining it in the same
// package as the core of your plugin.
// ignore: avoid_web_libraries_in_flutter

import 'package:flutter_web_plugins/flutter_web_plugins.dart';
import 'package:web/web.dart' as web;

import 'flutter_secure_storage_plus_platform_interface.dart';

/// Web implementation of [FlutterSecureStoragePlusPlatform].
class FlutterSecureStoragePlusWeb extends FlutterSecureStoragePlusPlatform {
  /// Constructs a FlutterSecureStoragePlusWeb
  FlutterSecureStoragePlusWeb();

  static final Map<String, String> _memoryStore = {};

  static void registerWith(Registrar registrar) {
    FlutterSecureStoragePlusPlatform.instance = FlutterSecureStoragePlusWeb();
  }

  /// Returns a [String] containing the version of the platform.
  @override
  Future<String?> getPlatformVersion() async {
    final version = web.window.navigator.userAgent;
    return version;
  }

  @override
  Future<void> write({
    required String key,
    required String value,
    bool? requireBiometrics,
  }) async {
    _memoryStore[key] = value;
  }

  @override
  Future<String?> read({required String key, bool? requireBiometrics}) async {
    return _memoryStore[key];
  }

  @override
  Future<void> delete({required String key}) async {
    _memoryStore.remove(key);
  }
}
