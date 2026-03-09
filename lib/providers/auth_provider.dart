import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite_sqlcipher/sqflite.dart';
import 'package:path/path.dart' as p;
import 'dart:io';

import 'service_providers.dart';

enum AuthState { initializing, unsetup, locked, unlocked }

class AuthNotifier extends Notifier<AuthState> {
  String? _lastError;
  String? get lastError => _lastError;

  @override
  AuthState build() {
    _init();
    return AuthState.initializing;
  }

  Future<void> _init() async {
    try {
      final storage = ref.read(secureStorageServiceProvider);
      final hasKey = await storage.hasStoredKey();

      // Check if we're still alive after the async call
      if (!ref.mounted) return;

      if (kDebugMode) {
        print('AuthNotifier._init: hasStoredKey=$hasKey');
      }

      if (hasKey) {
        state = AuthState.locked;
        return;
      }

      // Fallback: check if DB file exists even if Keychain lost the key
      if (!kIsWeb) {
        try {
          final dbPath = p.join(await getDatabasesPath(), 'asset_vault_enc.db');
          if (!ref.mounted) return;
          final dbFile = File(dbPath);
          if (await dbFile.exists()) {
            if (!ref.mounted) return;
            if (kDebugMode) {
              print(
                'AuthNotifier._init: DB file exists but no key in storage — vault exists',
              );
            }
            state = AuthState.locked;
            return;
          }
        } catch (_) {
          // getDatabasesPath or File ops may fail in test env, ignore
        }
      }

      if (!ref.mounted) return;
      state = AuthState.unsetup;
    } catch (e) {
      if (kDebugMode) {
        print('AuthNotifier._init error: $e');
      }
      if (ref.mounted) {
        state = AuthState.unsetup;
      }
    }
  }

  Future<bool> setupMasterPassword(String password) async {
    _lastError = null;
    try {
      final encryption = ref.read(encryptionServiceProvider);
      final storage = ref.read(secureStorageServiceProvider);

      // Delete any existing DB file to avoid "file is not a database" error
      // when re-creating a vault with a new key
      if (!kIsWeb) {
        try {
          final dbPath = p.join(await getDatabasesPath(), 'asset_vault_enc.db');
          final dbFile = File(dbPath);
          if (await dbFile.exists()) {
            if (kDebugMode) {
              print('setupMasterPassword: deleting stale DB at $dbPath');
            }
            await dbFile.delete();
          }
        } catch (_) {}
      }

      final saltBase64 = encryption.generateSaltBase64();
      await encryption.deriveKey(password, saltBase64);
      final key = encryption.masterKey;

      await storage.storeMasterKey(key, saltBase64);

      final db = ref.read(databaseServiceProvider);
      if (!kIsWeb) {
        await db.init(key);
      }

      state = AuthState.unlocked;
      return true;
    } catch (e, st) {
      _lastError = e.toString();
      if (kDebugMode) {
        print('Vault creation failed: $e\n$st');
      }
      return false;
    }
  }

  Future<bool> unlockWithPassword(String password) async {
    _lastError = null;
    try {
      final encryption = ref.read(encryptionServiceProvider);
      final storage = ref.read(secureStorageServiceProvider);

      final saltBase64 = await storage.getSalt();
      if (saltBase64 == null) {
        _lastError = 'No salt found. Vault may be corrupted.';
        return false;
      }

      await encryption.deriveKey(password, saltBase64);
      final key = encryption.masterKey;

      final db = ref.read(databaseServiceProvider);
      if (!kIsWeb) {
        await db.init(key);
      }

      state = AuthState.unlocked;
      return true;
    } catch (e, st) {
      _lastError = e.toString();
      if (kDebugMode) {
        print('Unlock failed: $e\n$st');
      }
      return false;
    }
  }

  Future<bool> unlockWithBiometrics() async {
    _lastError = null;
    try {
      final storage = ref.read(secureStorageServiceProvider);
      final key = await storage.getMasterKeyWithBiometrics('Unlock AssetVault');

      if (key != null) {
        final encryption = ref.read(encryptionServiceProvider);
        encryption.setMasterKey(key);

        final db = ref.read(databaseServiceProvider);
        if (!kIsWeb) {
          await db.init(key);
        }

        state = AuthState.unlocked;
        return true;
      }
      return false;
    } catch (e, st) {
      _lastError = e.toString();
      if (kDebugMode) {
        print('Biometric unlock failed: $e\n$st');
      }
      return false;
    }
  }

  Future<void> lock() async {
    ref.read(encryptionServiceProvider).wipeKey();
    if (!kIsWeb) {
      await ref.read(databaseServiceProvider).close();
    }
    state = AuthState.locked;
  }
}

final authProvider = NotifierProvider<AuthNotifier, AuthState>(() {
  return AuthNotifier();
});
