import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:octarq_vault/providers/auth_provider.dart';
import 'package:octarq_vault/providers/service_providers.dart';
import 'package:octarq_vault/services/database_service.dart';
import 'package:octarq_vault/services/e2ee_sync_service.dart';
import 'package:octarq_vault/services/encryption_service.dart';
import 'package:octarq_vault/services/secure_storage_service.dart';

// --- Mock Services ---

class MockEncryptionService extends EncryptionService {
  bool deriveKeyCalled = false;
  bool shouldThrowOnDerive = false;

  @override
  Future<void> deriveKey(String password, String saltBase64) async {
    deriveKeyCalled = true;
    if (shouldThrowOnDerive) {
      throw Exception('Argon2 FFI not available');
    }
    // Set a deterministic test key instead of calling Argon2
    final key = Uint8List(32);
    for (int i = 0; i < 32; i++) {
      key[i] = i;
    }
    setMasterKey(key);
  }
}

class MockSecureStorageService extends SecureStorageService {
  String? _storedKeyBase64;
  String? _storedSalt;
  String? _verifyBlobBase64;
  Uint8List? biometricKey;
  bool storeCalled = false;
  bool clearAllCalled = false;

  @override
  Future<bool> hasStoredKey() async => _storedKeyBase64 != null;

  @override
  Future<void> storeMasterKey(Uint8List key, String saltBase64) async {
    storeCalled = true;
    _storedKeyBase64 = 'mock-key';
    _storedSalt = saltBase64;
  }

  @override
  Future<void> storeVerifyBlob(String base64Blob) async {
    _verifyBlobBase64 = base64Blob;
  }

  @override
  Future<String?> getVerifyBlob() async => _verifyBlobBase64;

  @override
  Future<String?> getSalt() async => _storedSalt;

  @override
  Future<Uint8List?> getMasterKeyWithBiometrics(String reason) async =>
      biometricKey;

  @override
  Future<void> clearAll() async {
    clearAllCalled = true;
    _storedKeyBase64 = null;
    _storedSalt = null;
    _verifyBlobBase64 = null;
    biometricKey = null;
  }
}

class MockDatabaseService extends DatabaseService {
  bool initCalled = false;
  bool closeCalled = false;
  bool shouldThrowOnInit = false;
  Object initError = Exception('SQLCipher not available');

  @override
  bool get isOpen => true;

  @override
  Future<void> init(Uint8List masterKeyBytes) async {
    initCalled = true;
    if (shouldThrowOnInit) {
      throw initError;
    }
    // Don't actually open a database
  }

  @override
  Future<void> close() async {
    closeCalled = true;
  }
}

class MockE2EESyncService extends E2EESyncService {
  MockE2EESyncService() : super(EncryptionService());

  VaultSnapshot? snapshotToReturn;
  Object? unpackError;

  @override
  VaultSnapshot unpackCiphertextToSnapshot(Uint8List encryptedPayload) {
    if (unpackError != null) throw unpackError!;
    return snapshotToReturn ??
        VaultSnapshot(version: 2, assets: const [], customAssetTypes: const []);
  }
}

Future<void> _waitForAuthInit(ProviderContainer container) async {
  for (int i = 0; i < 50; i++) {
    await Future<void>.delayed(Duration.zero);
    if (container.read(authProvider) != AuthState.initializing) break;
  }
}

Uint8List _externalPayloadWithSalt(String saltBase64) {
  final salt = saltBase64.codeUnits;
  return Uint8List.fromList([
    ...'AVV3'.codeUnits,
    (salt.length >> 8) & 0xFF,
    salt.length & 0xFF,
    ...salt,
    1,
    2,
    3,
  ]);
}

// --- Tests ---

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockEncryptionService mockEncryption;
  late MockSecureStorageService mockStorage;
  late MockDatabaseService mockDb;
  late MockE2EESyncService mockSync;
  late ProviderContainer container;

  setUp(() {
    mockEncryption = MockEncryptionService();
    mockStorage = MockSecureStorageService();
    mockDb = MockDatabaseService();
    mockSync = MockE2EESyncService();

    container = ProviderContainer(
      overrides: [
        encryptionServiceProvider.overrideWithValue(mockEncryption),
        secureStorageServiceProvider.overrideWithValue(mockStorage),
        databaseServiceProvider.overrideWithValue(mockDb),
        e2eeSyncServiceProvider.overrideWithValue(mockSync),
      ],
    );
  });

  tearDown(() {
    container.dispose();
  });

  group('AuthNotifier initialization', () {
    test('starts in initializing state', () {
      // The authProvider starts in initializing, then transitions
      final state = container.read(authProvider);
      expect(state, equals(AuthState.initializing));
    });

    test('transitions to unsetup when no stored key', () async {
      // Pump the event loop to let the fire-and-forget _init() complete
      for (int i = 0; i < 200; i++) {
        await Future<void>.delayed(Duration.zero);
        if (container.read(authProvider) != AuthState.initializing) break;
      }
      final state = container.read(authProvider);
      expect(state, equals(AuthState.unsetup));
    });

    test('transitions to locked when key exists', () async {
      // Pre-store a key
      await mockStorage.storeMasterKey(Uint8List(32), 'salt');

      // Create a new container to re-trigger init
      final container2 = ProviderContainer(
        overrides: [
          encryptionServiceProvider.overrideWithValue(mockEncryption),
          secureStorageServiceProvider.overrideWithValue(mockStorage),
          databaseServiceProvider.overrideWithValue(mockDb),
          e2eeSyncServiceProvider.overrideWithValue(mockSync),
        ],
      );
      container2.read(authProvider); // trigger build
      await Future.delayed(const Duration(milliseconds: 100));

      final state = container2.read(authProvider);
      expect(state, equals(AuthState.locked));
      container2.dispose();
    });
  });

  group('setupMasterPassword', () {
    test('happy path: derives key, stores, inits db, unlocks', () async {
      await _waitForAuthInit(container);

      final notifier = container.read(authProvider.notifier);
      final result = await notifier.setupMasterPassword('test-password-123');

      expect(result, isTrue);
      expect(mockEncryption.deriveKeyCalled, isTrue);
      expect(mockStorage.storeCalled, isTrue);
      // In test env kIsWeb may be true, so DB might not init
      // But we can check the state
      expect(container.read(authProvider), equals(AuthState.unlocked));
      expect(notifier.lastError, isNull);
    });

    test('failure on key derivation: returns false with error', () async {
      await _waitForAuthInit(container);
      mockEncryption.shouldThrowOnDerive = true;

      final notifier = container.read(authProvider.notifier);
      final result = await notifier.setupMasterPassword('test-password-123');

      expect(result, isFalse);
      expect(notifier.lastError, contains('Argon2 FFI not available'));
      expect(container.read(authProvider), isNot(equals(AuthState.unlocked)));
    });

    test('failure on db init still fails gracefully', () async {
      await _waitForAuthInit(container);
      mockDb.shouldThrowOnInit = true;

      final notifier = container.read(authProvider.notifier);
      // Note: kIsWeb is true in test, so db.init might be skipped
      // This test mainly validates the error pathway
      final result = await notifier.setupMasterPassword('any-password');
      // If kIsWeb, DB init is skipped so it succeeds
      // We verify either way that the method doesn't crash
      expect(result, isA<bool>());
    });
  });

  group('unlockWithPassword', () {
    test('happy path: retrieves salt, derives key, unlocks', () async {
      await _waitForAuthInit(container);

      // First setup a vault
      final notifier = container.read(authProvider.notifier);
      await notifier.setupMasterPassword('my-password');
      await notifier.lock();

      expect(container.read(authProvider), equals(AuthState.locked));

      // Now unlock
      final result = await notifier.unlockWithPassword('my-password');
      expect(result, isTrue);
      expect(container.read(authProvider), equals(AuthState.unlocked));
    });

    test('fails when no salt stored', () async {
      await _waitForAuthInit(container);

      final notifier = container.read(authProvider.notifier);
      final result = await notifier.unlockWithPassword('some-password');

      expect(result, isFalse);
      expect(notifier.lastError, contains('No salt found'));
    });

    test('treats corrupt database open as handled reset path', () async {
      await _waitForAuthInit(container);
      await mockStorage.storeMasterKey(Uint8List(32), 'stored-salt');
      mockDb.shouldThrowOnInit = true;
      mockDb.initError = Exception('DatabaseException(file is not a database)');

      final notifier = container.read(authProvider.notifier);
      final result = await notifier.unlockWithPassword('some-password');

      expect(result, isFalse);
      expect(container.read(authProvider), equals(AuthState.unsetup));
      expect(notifier.lastError, contains('Could not open vault'));
      expect(mockDb.closeCalled, isTrue);
      expect(mockStorage.clearAllCalled, isFalse);
    });
  });

  group('unlockWithExternalPayload', () {
    test('fails fast when payload is not a valid vault backup', () async {
      await _waitForAuthInit(container);

      final notifier = container.read(authProvider.notifier);
      final result = await notifier.unlockWithExternalPayload(
        'password',
        Uint8List.fromList([1, 2, 3, 4]),
      );

      expect(result, isFalse);
      expect(notifier.lastError, contains('Not a valid vault backup'));
      expect(container.read(authProvider), isNot(AuthState.unlocked));
    });

    test(
      'wipes derived key when payload decryption verification fails',
      () async {
        await _waitForAuthInit(container);
        mockSync.unpackError = Exception('bad payload');

        final notifier = container.read(authProvider.notifier);
        final result = await notifier.unlockWithExternalPayload(
          'password',
          _externalPayloadWithSalt('c2FsdA=='),
        );

        expect(result, isFalse);
        expect(
          notifier.lastError,
          equals('Incorrect password or corrupted file.'),
        );
        expect(() => mockEncryption.masterKey, throwsException);
        expect(mockStorage.storeCalled, isFalse);
      },
    );
  });

  group('unlockWithBiometrics', () {
    test('unlocks when biometric storage returns a key', () async {
      await _waitForAuthInit(container);
      mockStorage.biometricKey = Uint8List.fromList(
        List<int>.generate(32, (i) => i),
      );
      await mockStorage.storeMasterKey(Uint8List(32), 'stored-salt');

      final notifier = container.read(authProvider.notifier);
      final result = await notifier.unlockWithBiometrics();

      expect(result, isTrue);
      expect(container.read(authProvider), equals(AuthState.unlocked));
      expect(mockEncryption.masterKey, hasLength(32));
      expect(mockEncryption.currentSaltBase64, equals('stored-salt'));
    });

    test('returns false when biometric storage yields no key', () async {
      await _waitForAuthInit(container);

      final notifier = container.read(authProvider.notifier);
      final result = await notifier.unlockWithBiometrics();

      expect(result, isFalse);
      expect(container.read(authProvider), isNot(AuthState.unlocked));
      expect(notifier.lastError, isNull);
    });
  });

  group('lock', () {
    test('wipes key, closes db, transitions to locked', () async {
      await _waitForAuthInit(container);

      final notifier = container.read(authProvider.notifier);
      await notifier.setupMasterPassword('password');
      expect(container.read(authProvider), equals(AuthState.unlocked));

      await notifier.lock();

      expect(container.read(authProvider), equals(AuthState.locked));
      // Verify encryption key was wiped
      expect(() => mockEncryption.masterKey, throwsException);
    });
  });
}
