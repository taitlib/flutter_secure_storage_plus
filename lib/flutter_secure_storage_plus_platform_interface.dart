/// Platform interface for flutter_secure_storage_plus implementations.
///
/// This library defines the abstract interface that all platform-specific
/// implementations must extend.
///
/// Platform implementations should extend [FlutterSecureStoragePlusPlatform]
/// and register themselves using [FlutterSecureStoragePlusPlatform.instance].
// ignore: unnecessary_library_name
library flutter_secure_storage_plus_platform_interface;

import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'flutter_secure_storage_plus_method_channel.dart';

/// Platform interface that all `flutter_secure_storage_plus` implementations
/// must extend.
///
/// This enforces a common API and guards against unintended implementations
/// by requiring a private token.
abstract class FlutterSecureStoragePlusPlatform extends PlatformInterface {
  /// Constructs a [FlutterSecureStoragePlusPlatform].
  FlutterSecureStoragePlusPlatform() : super(token: _token);

  static final Object _token = Object();

  static FlutterSecureStoragePlusPlatform _instance =
      MethodChannelFlutterSecureStoragePlus();

  /// The default instance of [FlutterSecureStoragePlusPlatform] to use.
  ///
  /// Defaults to [MethodChannelFlutterSecureStoragePlus].
  static FlutterSecureStoragePlusPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own class
  /// that extends [FlutterSecureStoragePlusPlatform] when they register
  /// themselves.
  static set instance(FlutterSecureStoragePlusPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  /// Returns the platform version string.
  Future<String?> getPlatformVersion() {
    throw UnimplementedError('getPlatformVersion() has not been implemented.');
  }

  /// Writes a value to secure storage for the given key.
  Future<void> write({
    required String key,
    required String value,
    bool? requireBiometrics,
  }) {
    throw UnimplementedError('write() has not been implemented.');
  }

  /// Reads a value from secure storage for the given key.
  Future<String?> read({required String key, bool? requireBiometrics}) {
    throw UnimplementedError('read() has not been implemented.');
  }

  /// Deletes a value from secure storage for the given key.
  Future<void> delete({required String key}) {
    throw UnimplementedError('delete() has not been implemented.');
  }

  /// Rotates encryption keys by re-encrypting all stored values with new keys.
  /// This is a transparent operation that migrates existing data to new encryption keys.
  /// Returns the number of keys that were rotated.
  Future<int> rotateKeys() {
    throw UnimplementedError('rotateKeys() has not been implemented.');
  }
}
