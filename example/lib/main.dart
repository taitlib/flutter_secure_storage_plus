import 'package:flutter/material.dart';
import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_secure_storage_plus/flutter_secure_storage_plus.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String _platformVersion = 'Unknown';
  String? _storedValue;
  String? _status;
  bool _useBiometrics = false;
  bool _isLoading = false;
  final _storage = FlutterSecureStoragePlus();
  final _keyController = TextEditingController(text: 'token');
  final _valueController = TextEditingController(text: 'abc');

  @override
  void initState() {
    super.initState();
    initPlatformState();
  }

  Future<void> initPlatformState() async {
    String platformVersion;
    try {
      platformVersion =
          await _storage.getPlatformVersion() ?? 'Unknown platform version';
    } on PlatformException {
      platformVersion = 'Failed to get platform version.';
    }
    if (!mounted) return;
    setState(() {
      _platformVersion = platformVersion;
    });
  }

  Future<void> _write({bool requireBiometrics = false}) async {
    setState(() {
      _isLoading = true;
      _status = null;
    });
    try {
      await _storage.write(
        key: _keyController.text,
        value: _valueController.text,
        requireBiometrics: requireBiometrics,
      );
      setState(() {
        _status = requireBiometrics
            ? '✓ Value written with biometric protection!'
            : '✓ Value written!';
      });
    } catch (e) {
      setState(() {
        _status = '✗ Write failed: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _read({bool requireBiometrics = false}) async {
    setState(() {
      _isLoading = true;
      _status = null;
    });
    try {
      final value = await _storage.read(
        key: _keyController.text,
        requireBiometrics: requireBiometrics,
      );
      setState(() {
        _storedValue = value;
        if (value != null) {
          _status = requireBiometrics
              ? '✓ Value read with biometric authentication: $value'
              : '✓ Value read: $value';
        } else {
          _status = 'ℹ No value found.';
        }
      });
    } catch (e) {
      setState(() {
        _status = '✗ Read failed: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _delete() async {
    setState(() {
      _isLoading = true;
      _status = null;
    });
    try {
      await _storage.delete(key: _keyController.text);
      setState(() {
        _storedValue = null;
        _status = '✓ Value deleted!';
      });
    } catch (e) {
      setState(() {
        _status = '✗ Delete failed: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _rotateKeys() async {
    setState(() {
      _isLoading = true;
      _status = null;
    });
    try {
      final rotatedCount = await _storage.rotateKeys();
      setState(() {
        _status = '✓ Keys rotated successfully! ($rotatedCount items)';
      });
    } catch (e) {
      setState(() {
        _status = '✗ Key rotation failed: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Secure Storage Plus'),
          backgroundColor: Colors.blue.shade700,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Platform info
              Card(
                color: Colors.blue.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Platform Info',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text('Running on: $_platformVersion'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Input fields
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Key-Value Storage',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _keyController,
                        decoration: const InputDecoration(
                          labelText: 'Key',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _valueController,
                        decoration: const InputDecoration(
                          labelText: 'Value',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      CheckboxListTile(
                        title: const Text('Use Biometric Authentication'),
                        subtitle: const Text(
                          'Protect with Face ID/Touch ID/Fingerprint',
                        ),
                        value: _useBiometrics,
                        onChanged: (value) {
                          setState(() {
                            _useBiometrics = value ?? false;
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Basic operations
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Basic Operations',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          ElevatedButton.icon(
                            onPressed: _isLoading
                                ? null
                                : () =>
                                      _write(requireBiometrics: _useBiometrics),
                            icon: const Icon(Icons.save),
                            label: const Text('Write'),
                          ),
                          ElevatedButton.icon(
                            onPressed: _isLoading
                                ? null
                                : () =>
                                      _read(requireBiometrics: _useBiometrics),
                            icon: const Icon(Icons.read_more),
                            label: const Text('Read'),
                          ),
                          ElevatedButton.icon(
                            onPressed: _isLoading ? null : _delete,
                            icon: const Icon(Icons.delete),
                            label: const Text('Delete'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red.shade400,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Biometric-only section
              Card(
                color: Colors.amber.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.fingerprint, color: Colors.amber.shade700),
                          const SizedBox(width: 8),
                          const Text(
                            'Biometric Protected Operations',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'These operations require biometric authentication',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          ElevatedButton.icon(
                            onPressed: _isLoading
                                ? null
                                : () => _write(requireBiometrics: true),
                            icon: const Icon(Icons.fingerprint),
                            label: const Text('Write (Biometric)'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.amber.shade700,
                              foregroundColor: Colors.white,
                            ),
                          ),
                          ElevatedButton.icon(
                            onPressed: _isLoading
                                ? null
                                : () => _read(requireBiometrics: true),
                            icon: const Icon(Icons.fingerprint),
                            label: const Text('Read (Biometric)'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.amber.shade700,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Key rotation section
              Card(
                color: Colors.green.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.vpn_key, color: Colors.green.shade700),
                          const SizedBox(width: 8),
                          const Text(
                            'Key Rotation',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Re-encrypt all stored values with new encryption keys',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _isLoading ? null : _rotateKeys,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Rotate Keys'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green.shade700,
                          foregroundColor: Colors.white,
                          minimumSize: const Size(double.infinity, 48),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Status display
              if (_status != null)
                Card(
                  color: _status!.startsWith('✓')
                      ? Colors.green.shade50
                      : _status!.startsWith('✗')
                      ? Colors.red.shade50
                      : Colors.blue.shade50,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        if (_isLoading)
                          const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        else if (_status!.startsWith('✓'))
                          Icon(Icons.check_circle, color: Colors.green.shade700)
                        else if (_status!.startsWith('✗'))
                          Icon(Icons.error, color: Colors.red.shade700)
                        else
                          Icon(Icons.info, color: Colors.blue.shade700),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _status!,
                            style: TextStyle(
                              color: _status!.startsWith('✓')
                                  ? Colors.green.shade900
                                  : _status!.startsWith('✗')
                                  ? Colors.red.shade900
                                  : Colors.blue.shade900,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              if (_storedValue != null) ...[
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Current Value',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        SelectableText(
                          _storedValue!,
                          style: const TextStyle(fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _keyController.dispose();
    _valueController.dispose();
    super.dispose();
  }
}
