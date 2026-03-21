import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../utils/platform_utils.dart';
import 'relation_providers.dart';
import 'service_providers.dart';
import '../services/e2ee_sync_service.dart';

enum AuthState { initializing, unsetup, locked, unlocked }

/// Fixed plaintext used to create the verification blob.
const _kVerifyPlaintext = 'OCTARQ_VAULT_VERIFY_V1';

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

      // Migrate legacy storage keys (asset_vault_* → octarq_vault_*).
      await storage.migrateKeysIfNeeded();

      bool hasKey = await storage.hasStoredKey();

      // Check if we're still alive after the async call
      if (!ref.mounted) return;

      if (kDebugMode) {
        debugPrint('AuthNotifier._init: hasStoredKey=$hasKey');
      }

      if (!kIsWeb) {
        try {
          // Migrate legacy DB file (asset_vault_enc.db → octarq_vault.db).
          await migrateDbFileIfNeeded();

          final dbPath = await getVaultDatabasePath();
          final dbExists = await fileExists(dbPath);

          if (!ref.mounted) return;

          if (hasKey && !dbExists) {
            if (kDebugMode) {
              debugPrint(
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
                debugPrint(
                  'AuthNotifier._init: DB exists but no salt; wiping orphan DB.',
                );
              }
              await deleteDatabase(dbPath);
              if (await fileExists(dbPath)) forceDeleteFile(dbPath);
            } else {
              if (kDebugMode) {
                debugPrint(
                  'AuthNotifier._init: DB exists but no key in storage.',
                );
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
        debugPrint('AuthNotifier._init error: $e');
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
              debugPrint('setupMasterPassword: deleting stale DB at $dbPath');
            }
            await deleteDatabase(dbPath);
            if (await fileExists(dbPath)) forceDeleteFile(dbPath);
          }
        } catch (_) {}
      }

      final saltBase64 = encryption.generateSaltBase64();
      await encryption.deriveKey(password, saltBase64);
      final key = encryption.masterKey;

      // Store a verification blob so future unlocks can distinguish a wrong
      // password from actual DB corruption without wiping the vault.
      final verifyBytes = encryption.encryptBytes(
        utf8.encode(_kVerifyPlaintext),
      );
      await storage.storeVerifyBlob(base64.encode(verifyBytes));

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
        debugPrint('Vault creation failed: $e\n$st');
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

      // Verify password using the stored verification blob BEFORE opening the
      // database. This cleanly separates "wrong password" (decryption failure)
      // from "corrupted database" (SQLCipher error after correct key).
      final verifyBlobBase64 = await storage.getVerifyBlob();
      if (verifyBlobBase64 != null) {
        try {
          final plain = utf8.decode(
            encryption.decryptBytes(base64.decode(verifyBlobBase64)),
          );
          if (plain != _kVerifyPlaintext) {
            _lastError = 'Incorrect password.';
            encryption.wipeKey();
            return false;
          }
        } catch (_) {
          _lastError = 'Incorrect password.';
          encryption.wipeKey();
          return false;
        }
      }

      final key = encryption.masterKey;
      final db = ref.read(databaseServiceProvider);
      if (!kIsWeb) {
        await db.init(key);
      }

      // If this is an old vault (no verify blob), generate one now so future
      // unlocks benefit from the fast wrong-password detection.
      if (verifyBlobBase64 == null) {
        try {
          final verifyBytes = encryption.encryptBytes(
            utf8.encode(_kVerifyPlaintext),
          );
          await storage.storeVerifyBlob(base64.encode(verifyBytes));
        } catch (_) {} // Non-critical — don't fail the unlock.
      }

      state = AuthState.unlocked;
      return true;
    } catch (e, st) {
      if (await _handleDbOpenFailure(e)) return false;
      _lastError = e.toString();
      if (kDebugMode) {
        debugPrint('Unlock failed: $e\n$st');
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
      final verifyBytes = encryption.encryptBytes(
        utf8.encode(_kVerifyPlaintext),
      );
      await storage.storeVerifyBlob(base64.encode(verifyBytes));
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
        debugPrint('External unlock failed: $e\n$st');
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
        debugPrint('Biometric unlock failed: $e\n$st');
      }
      return false;
    }
  }

  Future<void> lock() async {
    ref.read(encryptionServiceProvider).wipeKey();
    if (!kIsWeb) {
      await ref.read(databaseServiceProvider).close();
    }
    // Do not ref.invalidate(assetsProvider): AssetsNotifier listens to authProvider
    // and clears state on locked — invalidating here creates a circular dependency
    // (assetsProvider → authProvider) while lock() is updating auth.
    ref.read(webVaultRelationsProvider.notifier).replace([]);
    ref.invalidate(assetRelationsProvider);
    state = AuthState.locked;
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

  /// On DB open failure (corrupt/wrong key), inform the user.
  /// Do NOT automatically wipe the database, as SQLCipher often returns
  /// "file is not a database" for an incorrect password.
  Future<bool> _handleDbOpenFailure(Object e) async {
    if (!_isCorruptDbError(e)) return false;
    _lastError =
        'Could not open vault. Incorrect password or corrupted file. If you have a backup, you can restore it from the setup screen.';
    await ref.read(databaseServiceProvider).close();
    // We stay in locked state so the user can try again.
    return true; // caller treats as handled error
  }
}

final authProvider = NotifierProvider<AuthNotifier, AuthState>(() {
  return AuthNotifier();
});
