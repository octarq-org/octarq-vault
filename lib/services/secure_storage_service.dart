import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/platform_utils.dart';

class SecureStorageService {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  LocalAuthentication? _auth;

  static const String _masterKeyAlias = 'asset_vault_master_key';
  static const String _saltAlias = 'asset_vault_salt';

  /// On the web platform there is no hardware-backed secure store, so the
  /// master key is kept in SharedPreferences (browser localStorage).  Users
  /// are warned about this limitation via the in-app Web Security Notice.
  /// On all native platforms (including macOS) we always attempt the
  /// platform Keychain / Keystore first and only fall back to SharedPreferences
  /// when a PlatformException is thrown (e.g. macOS without code signing in
  /// debug mode).  In that case a SecurityException is re-thrown so the caller
  /// can inform the user rather than silently accepting insecure storage.
  bool get _useFallback => kIsWeb;

  Future<bool> hasStoredKey() async {
    if (_useFallback) {
      final prefs = await SharedPreferences.getInstance();
      return prefs.containsKey(_masterKeyAlias);
    }
    try {
      if (await _storage.containsKey(key: _masterKeyAlias)) return true;
    } on PlatformException catch (e) {
      throw Exception(
        'Keychain unavailable: ${e.message}. '
        'On macOS, code-signing is required for secure Keychain access. '
        'Please build a signed release or use a signed debug profile.',
      );
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
    } on PlatformException catch (e) {
      throw Exception(
        'Keychain unavailable: ${e.message}. '
        'On macOS, code-signing is required for secure Keychain access.',
      );
    }
  }

  Future<String?> getSalt() async {
    if (_useFallback) {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_saltAlias);
    }
    try {
      return await _storage.read(key: _saltAlias);
    } on PlatformException catch (e) {
      throw Exception(
        'Keychain unavailable: ${e.message}. '
        'On macOS, code-signing is required for secure Keychain access.',
      );
    }
  }

  Future<Uint8List?> getMasterKeyWithBiometrics(String reason) async {
    if (kIsWeb) return null;

    _auth ??= LocalAuthentication();
    final auth = _auth!;

    final canAuthenticateWithBiometrics = await auth.canCheckBiometrics;
    final canAuthenticate =
        canAuthenticateWithBiometrics || await auth.isDeviceSupported();

    if (canAuthenticate) {
      final didAuthenticate = await auth.authenticate(
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
          keyBase64 = await _storage.read(key: _masterKeyAlias);
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
    await _storage.deleteAll();
  }
}
