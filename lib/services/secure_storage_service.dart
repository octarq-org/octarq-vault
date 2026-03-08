import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';

class SecureStorageService {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  final LocalAuthentication _auth = LocalAuthentication();

  static const String _masterKeyAlias = 'asset_vault_master_key';
  static const String _saltAlias = 'asset_vault_salt';

  Future<bool> hasStoredKey() async {
    return await _storage.containsKey(key: _masterKeyAlias);
  }

  Future<void> storeMasterKey(Uint8List key, String saltBase64) async {
    final keyBase64 = base64.encode(key);
    await _storage.write(key: _masterKeyAlias, value: keyBase64);
    await _storage.write(key: _saltAlias, value: saltBase64);
  }

  Future<String?> getSalt() async {
    return await _storage.read(key: _saltAlias);
  }

  Future<Uint8List?> getMasterKeyWithBiometrics(String reason) async {
    final canAuthenticateWithBiometrics = await _auth.canCheckBiometrics;
    final canAuthenticate = canAuthenticateWithBiometrics || await _auth.isDeviceSupported();

    if (canAuthenticate) {
      final didAuthenticate = await _auth.authenticate(
        localizedReason: reason,
        persistAcrossBackgrounding: true,
        biometricOnly: false,
      );

      if (didAuthenticate) {
        final keyBase64 = await _storage.read(key: _masterKeyAlias);
        if (keyBase64 != null) {
          return base64.decode(keyBase64);
        }
      }
    }
    return null;
  }

  Future<void> clearAll() async {
    await _storage.deleteAll();
  }
}
