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

  Future<void> _write() async {
    try {
      await _storage.write(
        key: _keyController.text,
        value: _valueController.text,
      );
      setState(() {
        _status = 'Value written!';
      });
    } catch (e) {
      setState(() {
        _status = 'Write failed: $e';
      });
    }
  }

  Future<void> _read() async {
    try {
      final value = await _storage.read(key: _keyController.text);
      setState(() {
        _storedValue = value;
        _status = value != null ? 'Value read: $value' : 'No value found.';
      });
    } catch (e) {
      setState(() {
        _status = 'Read failed: $e';
      });
    }
  }

  Future<void> _delete() async {
    try {
      await _storage.delete(key: _keyController.text);
      setState(() {
        _storedValue = null;
        _status = 'Value deleted!';
      });
    } catch (e) {
      setState(() {
        _status = 'Delete failed: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('Plugin example app')),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Running on: $_platformVersion\n'),
              TextField(
                controller: _keyController,
                decoration: const InputDecoration(labelText: 'Key'),
              ),
              TextField(
                controller: _valueController,
                decoration: const InputDecoration(labelText: 'Value'),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(onPressed: _write, child: const Text('Write')),
                  const SizedBox(width: 8),
                  ElevatedButton(onPressed: _read, child: const Text('Read')),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _delete,
                    child: const Text('Delete'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (_storedValue != null) Text('Stored value: $_storedValue'),
              if (_status != null)
                Text(_status!, style: const TextStyle(color: Colors.blue)),
            ],
          ),
        ),
      ),
    );
  }
}
