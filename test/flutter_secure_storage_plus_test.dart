import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage_plus/flutter_secure_storage_plus.dart';
import 'package:flutter_secure_storage_plus/flutter_secure_storage_plus_platform_interface.dart';
import 'package:flutter_secure_storage_plus/flutter_secure_storage_plus_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockFlutterSecureStoragePlusPlatform
    with MockPlatformInterfaceMixin
    implements FlutterSecureStoragePlusPlatform {
  String? _value;

  @override
  Future<String?> getPlatformVersion() => Future.value('42');

  @override
  Future<void> write({
    required String key,
    required String value,
    bool? requireBiometrics,
  }) async {
    _value = value;
  }

  @override
  Future<String?> read({required String key, bool? requireBiometrics}) async {
    return _value;
  }

  @override
  Future<void> delete({required String key}) async {
    _value = null;
  }

  @override
  Future<int> rotateKeys() async {
    // Mock implementation - just return 0 for testing
    return 0;
  }
}

void main() {
  final FlutterSecureStoragePlusPlatform initialPlatform =
      FlutterSecureStoragePlusPlatform.instance;

  test('$MethodChannelFlutterSecureStoragePlus is the default instance', () {
    expect(
      initialPlatform,
      isInstanceOf<MethodChannelFlutterSecureStoragePlus>(),
    );
  });

  test('getPlatformVersion', () async {
    FlutterSecureStoragePlus flutterSecureStoragePlusPlugin =
        FlutterSecureStoragePlus();
    MockFlutterSecureStoragePlusPlatform fakePlatform =
        MockFlutterSecureStoragePlusPlatform();
    FlutterSecureStoragePlusPlatform.instance = fakePlatform;

    expect(await flutterSecureStoragePlusPlugin.getPlatformVersion(), '42');
  });
}
