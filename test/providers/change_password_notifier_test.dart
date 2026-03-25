import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// RED: change_password_provider.dart does not exist yet.
// This file will fail to compile until task-015 implements ChangePasswordNotifier.
import 'package:octarq_vault/providers/change_password_provider.dart';
import 'package:octarq_vault/providers/service_providers.dart';
import 'package:octarq_vault/services/database_service.dart';
import 'package:octarq_vault/services/encryption_service.dart';
import 'package:octarq_vault/services/secure_storage_service.dart';

// ---------------------------------------------------------------------------
// Mocks
// ---------------------------------------------------------------------------

class _MockDatabaseService extends DatabaseService {
  bool reKeyDatabaseCalled = false;
  bool reEncryptAllFieldsCalled = false;
  Exception? reKeyError;
  Exception? reEncryptError;

  @override
  bool get isOpen => true;

  @override
  Future<void> rekeyDatabase(Uint8List newKey) async {
    if (reKeyError != null) throw reKeyError!;
    reKeyDatabaseCalled = true;
  }

  @override
  Future<void> reEncryptAllFields(
    EncryptionService oldEnc,
    EncryptionService newEnc,
  ) async {
    if (reEncryptError != null) throw reEncryptError!;
    reEncryptAllFieldsCalled = true;
  }
}

class _MockEncryptionService extends EncryptionService {
  final String? rejectOnDerivePassword;

  _MockEncryptionService({this.rejectOnDerivePassword});

  @override
  Uint8List get masterKey => Uint8List(32);

  @override
  String get currentSaltBase64 => 'dGVzdHNhbHQ=';

  @override
  Future<void> deriveKey(String password, String saltBase64) async {
    if (rejectOnDerivePassword != null && password == rejectOnDerivePassword) {
      throw Exception('Incorrect current password');
    }
    // no-op: skip Argon2 in tests — caller gets zeroed key
  }

  @override
  Uint8List decryptBytes(Uint8List payloadToDecrypt) {
    // Simulate successful verify blob decryption → returns the plaintext
    return Uint8List.fromList(utf8.encode('OCTARQ_VAULT_VERIFY_V1'));
  }

  @override
  Uint8List encryptBytes(Uint8List plaintextBytes) {
    // Return a minimal valid-looking payload (IV 12 bytes + dummy ciphertext)
    return Uint8List(28);
  }
}

class _MockSecureStorageService extends SecureStorageService {
  bool storeMasterKeyCalled = false;
  bool storeVerifyBlobCalled = false;
  Uint8List? storedKey;
  String? storedSalt;
  String? storedBlob;

  @override
  Future<String?> getVerifyBlob() async {
    // Return a base64-encoded dummy blob; the mock decryptBytes handles it.
    return base64.encode(Uint8List(28));
  }

  @override
  Future<String?> getSalt() async => 'dGVzdHNhbHQ=';

  @override
  Future<void> storeMasterKey(Uint8List key, String saltBase64) async {
    storeMasterKeyCalled = true;
    storedKey = key;
    storedSalt = saltBase64;
  }

  @override
  Future<void> storeVerifyBlob(String base64Blob) async {
    storeVerifyBlobCalled = true;
    storedBlob = base64Blob;
  }
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

ProviderContainer _container({
  required _MockDatabaseService db,
  required _MockEncryptionService enc,
  required _MockSecureStorageService storage,
}) {
  return ProviderContainer(
    overrides: [
      databaseServiceProvider.overrideWithValue(db),
      encryptionServiceProvider.overrideWithValue(enc),
      secureStorageServiceProvider.overrideWithValue(storage),
    ],
  );
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('ChangePasswordNotifier', () {
    test('successful change calls rekeyDatabase, reEncryptAllFields, '
        'storeMasterKey, storeVerifyBlob', () async {
      final db = _MockDatabaseService();
      final enc = _MockEncryptionService();
      final storage = _MockSecureStorageService();
      final container = _container(db: db, enc: enc, storage: storage);
      addTearDown(container.dispose);

      await container
          .read(changePasswordProvider.notifier)
          .changePassword('OldPass123!', 'NewPass456!');

      expect(db.reKeyDatabaseCalled, isTrue);
      expect(db.reEncryptAllFieldsCalled, isTrue);
      expect(storage.storeMasterKeyCalled, isTrue);
      expect(storage.storeVerifyBlobCalled, isTrue);

      final state = container.read(changePasswordProvider);
      expect(state.isSuccess, isTrue);
    });

    test('wrong current password — rekeyDatabase never called', () async {
      final db = _MockDatabaseService();
      final enc = _MockEncryptionService(rejectOnDerivePassword: 'WrongPass!');
      final storage = _MockSecureStorageService();
      final container = _container(db: db, enc: enc, storage: storage);
      addTearDown(container.dispose);

      await container
          .read(changePasswordProvider.notifier)
          .changePassword('WrongPass!', 'NewPass456!');

      expect(db.reKeyDatabaseCalled, isFalse);
      expect(storage.storeMasterKeyCalled, isFalse);

      final state = container.read(changePasswordProvider);
      expect(state.hasError, isTrue);
      expect(state.errorMessage, contains('Incorrect'));
    });

    test('PRAGMA rekey throws — reEncryptAllFields never called, '
        'storage not updated', () async {
      final db = _MockDatabaseService()..reKeyError = Exception('IO error');
      final enc = _MockEncryptionService();
      final storage = _MockSecureStorageService();
      final container = _container(db: db, enc: enc, storage: storage);
      addTearDown(container.dispose);

      await container
          .read(changePasswordProvider.notifier)
          .changePassword('OldPass123!', 'NewPass456!');

      expect(db.reEncryptAllFieldsCalled, isFalse);
      expect(storage.storeMasterKeyCalled, isFalse);

      final state = container.read(changePasswordProvider);
      expect(state.hasError, isTrue);
    });

    test('reEncryptAllFields throws — storage not updated', () async {
      final db = _MockDatabaseService()
        ..reEncryptError = Exception('unexpected error');
      final enc = _MockEncryptionService();
      final storage = _MockSecureStorageService();
      final container = _container(db: db, enc: enc, storage: storage);
      addTearDown(container.dispose);

      await container
          .read(changePasswordProvider.notifier)
          .changePassword('OldPass123!', 'NewPass456!');

      expect(storage.storeMasterKeyCalled, isFalse);

      final state = container.read(changePasswordProvider);
      expect(state.hasError, isTrue);
    });
  });
}
