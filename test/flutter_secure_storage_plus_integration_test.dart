import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage_plus/flutter_secure_storage_plus.dart';
import 'package:flutter_secure_storage_plus/flutter_secure_storage_plus_platform_interface.dart';
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
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  group('FlutterSecureStoragePlus integration', () {
    final storage = FlutterSecureStoragePlus();
    const testKey = 'test_key';
    const testValue = 'test_value';

    setUp(() async {
      FlutterSecureStoragePlusPlatform.instance =
          MockFlutterSecureStoragePlusPlatform();
      await storage.delete(key: testKey);
    });

    test('write and read value', () async {
      await storage.write(key: testKey, value: testValue);
      final value = await storage.read(key: testKey);
      expect(value, testValue);
    });

    test('delete value', () async {
      await storage.write(key: testKey, value: testValue);
      await storage.delete(key: testKey);
      final value = await storage.read(key: testKey);
      expect(value, isNull);
    });
  });
}
