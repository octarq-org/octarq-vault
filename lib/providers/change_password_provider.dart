import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/encryption_service.dart';
import 'service_providers.dart';

const _kVerifyPlaintext = 'OCTARQ_VAULT_VERIFY_V1';

// ---------------------------------------------------------------------------
// State
// ---------------------------------------------------------------------------

class ChangePasswordState {
  final bool isLoading;
  final bool isSuccess;
  final String? errorMessage;

  bool get hasError => errorMessage != null;

  const ChangePasswordState({
    this.isLoading = false,
    this.isSuccess = false,
    this.errorMessage,
  });
}

// ---------------------------------------------------------------------------
// Notifier
// ---------------------------------------------------------------------------

class ChangePasswordNotifier extends Notifier<ChangePasswordState> {
  @override
  ChangePasswordState build() => const ChangePasswordState();

  /// Verifies [current] password, re-keys the database, re-encrypts all field
  /// values, and updates secure storage — atomically from the caller's view.
  ///
  /// On success: [state.isSuccess] == true.
  /// On failure: [state.hasError] == true, [state.errorMessage] is set.
  Future<void> changePassword(String current, String newPwd) async {
    state = const ChangePasswordState(isLoading: true);

    final enc = ref.read(encryptionServiceProvider);
    final db = ref.read(databaseServiceProvider);
    final storage = ref.read(secureStorageServiceProvider);

    // ── Step 1: Verify current password via verify blob ──────────────────────
    try {
      final oldSaltBase64 = await storage.getSalt();
      if (oldSaltBase64 == null || oldSaltBase64.isEmpty) {
        state = const ChangePasswordState(
          errorMessage: 'Incorrect current password',
        );
        return;
      }
      final blobBase64 = await storage.getVerifyBlob();
      if (blobBase64 != null) {
        final originalKeyBytes = Uint8List.fromList(enc.masterKey);
        final originalSaltBase64 = (() {
          try {
            return enc.currentSaltBase64;
          } catch (_) {
            return null;
          }
        })();
        try {
          await enc.deriveKey(current, oldSaltBase64);
          final decrypted = enc.decryptBytes(base64.decode(blobBase64));
          final plaintext = utf8.decode(decrypted);
          if (!plaintext.startsWith(_kVerifyPlaintext)) {
            state = const ChangePasswordState(
              errorMessage: 'Incorrect current password',
            );
            return;
          }
        } finally {
          enc.setMasterKey(originalKeyBytes);
          if (originalSaltBase64 != null) {
            enc.setSalt(originalSaltBase64);
          }
        }
      }
    } catch (_) {
      state = const ChangePasswordState(
        errorMessage: 'Incorrect current password',
      );
      return;
    }

    // ── Step 2: Derive new key in-place (updates enc singleton) ──────────────
    // Save old key so we can construct the old-enc reference for re-encryption.
    final oldKeyBytes = Uint8List.fromList(enc.masterKey);
    final oldSaltBase64 = (() {
      try {
        return enc.currentSaltBase64;
      } catch (_) {
        // Some test mocks / edge states may not have salt initialized.
        return null;
      }
    })();
    final newSalt = _generateSalt();
    await enc.deriveKey(newPwd, base64.encode(newSalt));

    // Reconstruct oldEnc with the saved key for reEncryptAllFields.
    final oldEnc = EncryptionService();
    oldEnc.setMasterKey(oldKeyBytes);

    // ── Step 3: PRAGMA rekey ──────────────────────────────────────────────────
    try {
      await db.rekeyDatabase(enc.masterKey);
    } catch (e) {
      // DB is still under the old key — restore enc singleton and surface error.
      enc.setMasterKey(oldKeyBytes);
      if (oldSaltBase64 != null) {
        enc.setSalt(oldSaltBase64);
      }
      state = ChangePasswordState(errorMessage: e.toString());
      return;
    }

    // ── Step 4: Re-encrypt all asset_fields rows ──────────────────────────────
    try {
      await db.reEncryptAllFields(oldEnc, enc);
    } catch (e) {
      // Atomicity: `rekeyDatabase()` already switched SQLCipher key. The
      // transaction inside `reEncryptAllFields()` rolls back row updates, but
      // PRAGMA rekey is not transactional. Rekey back to the old SQLCipher
      // key so the vault remains openable with `[current]` password.
      try {
        await db.rekeyDatabase(oldKeyBytes);
        enc.setMasterKey(oldKeyBytes);
        if (oldSaltBase64 != null) {
          enc.setSalt(oldSaltBase64);
        }
      } catch (_) {
        // Best-effort rollback failed; surface the original re-encryption error
        // below.
      }
      state = ChangePasswordState(errorMessage: e.toString());
      return;
    }

    // ── Step 5: Persist new key + verify blob ────────────────────────────────
    final newVerifyBlob = enc.encryptBytes(
      Uint8List.fromList(utf8.encode(_kVerifyPlaintext)),
    );
    await storage.storeMasterKey(enc.masterKey, enc.currentSaltBase64);
    await storage.storeVerifyBlob(base64.encode(newVerifyBlob));

    state = const ChangePasswordState(isSuccess: true);
  }

  static Uint8List _generateSalt() {
    final rng = Random.secure();
    return Uint8List.fromList(List.generate(32, (_) => rng.nextInt(256)));
  }
}

// ---------------------------------------------------------------------------
// Provider
// ---------------------------------------------------------------------------

final changePasswordProvider =
    NotifierProvider<ChangePasswordNotifier, ChangePasswordState>(
      ChangePasswordNotifier.new,
    );
