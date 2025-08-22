import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'flutter_secure_storage_plus_platform_interface.dart';

/// Method-channel based implementation of [FlutterSecureStoragePlusPlatform].
class MethodChannelFlutterSecureStoragePlus
    extends FlutterSecureStoragePlusPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('flutter_secure_storage_plus');

  @override
  /// Returns the platform version string from the native side.
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>(
      'getPlatformVersion',
    );
    return version;
  }

  @override
  Future<void> write({
    required String key,
    required String value,
    bool? requireBiometrics,
  }) async {
    await methodChannel.invokeMethod('write', {
      'key': key,
      'value': value,
      if (requireBiometrics != null) 'requireBiometrics': requireBiometrics,
    });
  }

  @override
  Future<String?> read({required String key, bool? requireBiometrics}) async {
    final result = await methodChannel.invokeMethod<String>('read', {
      'key': key,
      if (requireBiometrics != null) 'requireBiometrics': requireBiometrics,
    });
    return result;
  }

  @override
  Future<void> delete({required String key}) async {
    await methodChannel.invokeMethod('delete', {'key': key});
  }
}
