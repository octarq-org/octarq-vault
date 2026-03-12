import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
          final dbPath = await getVaultDatabasePath();
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
            final salt = await storage.getSalt();
            if (salt == null || salt.isEmpty) {
              // No salt: cannot unlock (e.g. after bundle ID change). Wipe orphan DB → setup.
              if (kDebugMode) {
                print(
                  'AuthNotifier._init: DB exists but no salt; wiping orphan DB.',
                );
              }
              await deleteDatabase(dbPath);
              if (await fileExists(dbPath)) forceDeleteFile(dbPath);
            } else {
              if (kDebugMode) {
                print('AuthNotifier._init: DB exists but no key in storage.');
              }
              state = AuthState.locked;
              return;
            }
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
          final dbPath = await getVaultDatabasePath();
          if (await fileExists(dbPath)) {
            if (kDebugMode) {
              print('setupMasterPassword: deleting stale DB at $dbPath');
            }
            await deleteDatabase(dbPath);
            if (await fileExists(dbPath)) forceDeleteFile(dbPath);
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
      if (await _handleDbOpenFailure(e)) return false;
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
            'Not a valid vault backup. Use the .enc file from OctarqVault (Export/Google Drive), not the internal database.';
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
        final dbPath = await getVaultDatabasePath();
        if (await fileExists(dbPath)) {
          await deleteDatabase(dbPath);
          if (await fileExists(dbPath)) forceDeleteFile(dbPath);
        }
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
      final key = await storage.getMasterKeyWithBiometrics(
        'Unlock OctarqVault',
      );

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
      if (await _handleDbOpenFailure(e)) return false;
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

  Future<void> _wipeDbAndStorage() async {
    await ref.read(secureStorageServiceProvider).clearAll();
    if (!kIsWeb) {
      try {
        final dbPath = await getVaultDatabasePath();
        if (await fileExists(dbPath)) {
          await deleteDatabase(dbPath);
          if (await fileExists(dbPath)) forceDeleteFile(dbPath);
        }
      } catch (_) {}
    }
  }

  static bool _isCorruptDbError(Object e) {
    final msg = e.toString().toLowerCase();
    return msg.contains('file is not a database') ||
        msg.contains('open_failed') ||
        msg.contains('databaseexception') ||
        msg.contains('out of memory') ||
        msg.contains('code=7') ||
        msg.contains('during open');
  }

  /// On DB open failure (corrupt/wrong key), close db then wipe and go to setup.
  Future<bool> _handleDbOpenFailure(Object e) async {
    if (!_isCorruptDbError(e)) return false;
    _lastError = 'Vault file was corrupted or invalid. Creating a new vault.';
    await ref.read(databaseServiceProvider).close();
    await _wipeDbAndStorage();
    state = AuthState.unsetup;
    return true; // caller should treat as "handled", not retry
  }
}

final authProvider = NotifierProvider<AuthNotifier, AuthState>(() {
  return AuthNotifier();
});
