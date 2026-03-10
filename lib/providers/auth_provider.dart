import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import '../utils/platform_utils.dart';
import 'service_providers.dart';
import '../services/e2ee_sync_service.dart';

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
      bool hasKey = await storage.hasStoredKey();

      // Check if we're still alive after the async call
      if (!ref.mounted) return;

      if (kDebugMode) {
        print('AuthNotifier._init: hasStoredKey=$hasKey');
      }

      if (!kIsWeb) {
        try {
          final dbPath = p.join(await getDatabasesPath(), 'asset_vault_enc.db');
          final dbExists = await fileExists(dbPath);

          if (!ref.mounted) return;

          if (hasKey && !dbExists) {
            if (kDebugMode) {
              print(
                'AuthNotifier._init: Orphaned key detected (DB missing). Wiping key.',
              );
            }
            await storage.clearAll();
            hasKey = false;
          } else if (!hasKey && dbExists) {
            if (kDebugMode) {
              print('AuthNotifier._init: DB exists but no key in storage.');
            }
            state = AuthState.locked;
            return;
          }
        } catch (_) {
          // getDatabasesPath or File ops may fail in test env, ignore
        }
      }

      if (hasKey) {
        state = AuthState.locked;
        return;
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
          if (await fileExists(dbPath)) {
            if (kDebugMode) {
              print('setupMasterPassword: deleting stale DB at $dbPath');
            }
            // Cannot use File in web, sqflite exposes deleteDatabase
            await deleteDatabase(dbPath);
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

  Future<bool> unlockWithExternalPayload(
    String password,
    Uint8List payload,
  ) async {
    _lastError = null;
    try {
      final encryption = ref.read(encryptionServiceProvider);
      final storage = ref.read(secureStorageServiceProvider);
      final syncService = ref.read(e2eeSyncServiceProvider);

      final saltBase64 = E2EESyncService.extractSaltFromPayload(payload);
      if (saltBase64 == null) {
        _lastError =
            'Not a valid vault backup. Use the .enc file from Asset Vault (Export/Google Drive), not the internal database.';
        return false;
      }

      await encryption.deriveKey(password, saltBase64);
      final key = encryption.masterKey;

      // Try decrypting to verify password is correct
      try {
        syncService.unpackCiphertextToSnapshot(payload);
      } catch (e) {
        _lastError = 'Incorrect password or corrupted file.';
        encryption.wipeKey();
        return false;
      }

      // If successful, persist the salt and key
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
        print('External unlock failed: $e\n$st');
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

        final saltBase64 = await storage.getSalt();
        if (saltBase64 != null) {
          encryption.setSalt(saltBase64);
        }

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
