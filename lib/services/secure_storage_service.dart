import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'platform_secure_storage.dart';

class SecureStorageService {
  final FlutterSecureStorage _storage = platformFlutterSecureStorage();
  LocalAuthentication? _auth;

  // Current key aliases (octarq_vault_* naming scheme)
  static const String _masterKeyAlias = 'octarq_vault_master_key';
  static const String _saltAlias = 'octarq_vault_salt';
  static const String _verifyAlias = 'octarq_vault_verify';
  static const String _webPasskeyEnabledAlias = 'octarq_vault_web_passkey';
  static const String _webPasskeyCredentialIdAlias =
      'octarq_vault_web_passkey_credential_id';

  // Legacy aliases used before the rename — kept for migration only
  static const String _legacyMasterKeyAlias = 'asset_vault_master_key';
  static const String _legacySaltAlias = 'asset_vault_salt';

  /// On the web platform there is no hardware-backed secure store, so the
  /// master key is kept in SharedPreferences (browser localStorage).  Users
  /// are warned about this limitation via the in-app Web Security Notice.
  /// On all native platforms (including macOS) we always attempt the
  /// platform Keychain / Keystore first.  On macOS without code-signing the
  /// Keychain throws a PlatformException which is re-thrown so the caller can
  /// inform the user rather than silently accepting insecure storage.
  bool get _useFallback => kIsWeb;

  /// Migrates legacy `asset_vault_*` storage keys to `octarq_vault_*`.
  /// Idempotent — safe to call on every app start.
  Future<void> migrateKeysIfNeeded() async {
    try {
      if (_useFallback) {
        final prefs = await SharedPreferences.getInstance();
        if (!prefs.containsKey(_masterKeyAlias) &&
            prefs.containsKey(_legacyMasterKeyAlias)) {
          final key = prefs.getString(_legacyMasterKeyAlias);
          final salt = prefs.getString(_legacySaltAlias);
          if (key != null) await prefs.setString(_masterKeyAlias, key);
          if (salt != null) await prefs.setString(_saltAlias, salt);
          await prefs.remove(_legacyMasterKeyAlias);
          await prefs.remove(_legacySaltAlias);
        }
      } else {
        final hasNew = await _storage.containsKey(key: _masterKeyAlias);
        final hasLegacy = await _storage.containsKey(
          key: _legacyMasterKeyAlias,
        );
        if (!hasNew && hasLegacy) {
          final key = await _storage.read(key: _legacyMasterKeyAlias);
          final salt = await _storage.read(key: _legacySaltAlias);
          if (key != null) {
            await _storage.write(key: _masterKeyAlias, value: key);
          }
          if (salt != null) {
            await _storage.write(key: _saltAlias, value: salt);
          }
          await _storage.delete(key: _legacyMasterKeyAlias);
          await _storage.delete(key: _legacySaltAlias);
        }
      }
    } catch (_) {
      // Migration is best-effort; failures should not block startup.
    }
  }

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

  /// Stores a base64-encoded verification blob used to confirm password
  /// correctness without opening the database.
  Future<void> storeVerifyBlob(String base64Blob) async {
    if (_useFallback) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_verifyAlias, base64Blob);
      return;
    }
    try {
      await _storage.write(key: _verifyAlias, value: base64Blob);
    } on PlatformException catch (e) {
      throw Exception(
        'Keychain unavailable: ${e.message}. '
        'On macOS, code-signing is required for secure Keychain access.',
      );
    }
  }

  /// Returns the stored verification blob, or null if not yet created
  /// (legacy vault created before this feature was added).
  Future<String?> getVerifyBlob() async {
    if (_useFallback) {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_verifyAlias);
    }
    try {
      return await _storage.read(key: _verifyAlias);
    } on PlatformException catch (e) {
      throw Exception(
        'Keychain unavailable: ${e.message}. '
        'On macOS, code-signing is required for secure Keychain access.',
      );
    }
  }

  Future<Uint8List?> getStoredMasterKey() async {
    String? keyBase64;
    if (_useFallback) {
      final prefs = await SharedPreferences.getInstance();
      keyBase64 = prefs.getString(_masterKeyAlias);
    } else {
      try {
        keyBase64 = await _storage.read(key: _masterKeyAlias);
      } on PlatformException catch (e) {
        throw Exception(
          'Keychain unavailable: ${e.message}. '
          'On macOS, code-signing is required for secure Keychain access.',
        );
      }
    }
    if (keyBase64 == null || keyBase64.isEmpty) return null;
    return base64.decode(keyBase64);
  }

  Future<bool> isWebPasskeyEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_webPasskeyEnabledAlias) ?? false;
  }

  Future<void> setWebPasskeyEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_webPasskeyEnabledAlias, enabled);
  }

  Future<void> storeWebPasskeyCredentialId(String credentialId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_webPasskeyCredentialIdAlias, credentialId);
  }

  Future<String?> getWebPasskeyCredentialId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_webPasskeyCredentialIdAlias);
  }

  Future<void> clearWebPasskey() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_webPasskeyEnabledAlias);
    await prefs.remove(_webPasskeyCredentialIdAlias);
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
      await prefs.remove(_verifyAlias);
      await prefs.remove(_webPasskeyEnabledAlias);
      await prefs.remove(_webPasskeyCredentialIdAlias);
      return;
    }
    await _storage.deleteAll();
  }
}
