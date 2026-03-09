import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SecureStorageService {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  final LocalAuthentication _auth = LocalAuthentication();

  static const String _masterKeyAlias = 'asset_vault_master_key';
  static const String _saltAlias = 'asset_vault_salt';

  /// On macOS desktop, Keychain is unreliable without code signing.
  /// Use SharedPreferences as the primary storage on macOS.
  bool get _useFallback {
    if (kIsWeb) return true;
    try {
      return Platform.isMacOS;
    } catch (_) {
      return false;
    }
  }

  Future<bool> hasStoredKey() async {
    if (_useFallback) {
      final prefs = await SharedPreferences.getInstance();
      return prefs.containsKey(_masterKeyAlias);
    }
    try {
      if (await _storage.containsKey(key: _masterKeyAlias)) return true;
    } on PlatformException catch (_) {
      final prefs = await SharedPreferences.getInstance();
      return prefs.containsKey(_masterKeyAlias);
    }
    return false;
  }

  Future<void> storeMasterKey(Uint8List key, String saltBase64) async {
    final keyBase64 = base64.encode(key);
    if (_useFallback) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_masterKeyAlias, keyBase64);
      await prefs.setString(_saltAlias, saltBase64);
      return;
    }
    try {
      await _storage.write(key: _masterKeyAlias, value: keyBase64);
      await _storage.write(key: _saltAlias, value: saltBase64);
    } on PlatformException catch (_) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_masterKeyAlias, keyBase64);
      await prefs.setString(_saltAlias, saltBase64);
    }
  }

  Future<String?> getSalt() async {
    if (_useFallback) {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_saltAlias);
    }
    try {
      return await _storage.read(key: _saltAlias);
    } on PlatformException catch (_) {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_saltAlias);
    }
  }

  Future<Uint8List?> getMasterKeyWithBiometrics(String reason) async {
    final canAuthenticateWithBiometrics = await _auth.canCheckBiometrics;
    final canAuthenticate =
        canAuthenticateWithBiometrics || await _auth.isDeviceSupported();

    if (canAuthenticate) {
      final didAuthenticate = await _auth.authenticate(
        localizedReason: reason,
        biometricOnly: false,
        persistAcrossBackgrounding: true,
      );

      if (didAuthenticate) {
        String? keyBase64;
        if (_useFallback) {
          final prefs = await SharedPreferences.getInstance();
          keyBase64 = prefs.getString(_masterKeyAlias);
        } else {
          try {
            keyBase64 = await _storage.read(key: _masterKeyAlias);
          } on PlatformException catch (_) {
            final prefs = await SharedPreferences.getInstance();
            keyBase64 = prefs.getString(_masterKeyAlias);
          }
        }
        if (keyBase64 != null) {
          return base64.decode(keyBase64);
        }
      }
    }
    return null;
  }

  Future<void> clearAll() async {
    if (_useFallback) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_masterKeyAlias);
      await prefs.remove(_saltAlias);
      return;
    }
    try {
      await _storage.deleteAll();
    } on PlatformException catch (_) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_masterKeyAlias);
      await prefs.remove(_saltAlias);
    }
  }
}
