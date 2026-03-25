import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:octarq_vault/models/attachment.dart';
import 'package:octarq_vault/providers/attachments_provider.dart';
import 'package:octarq_vault/providers/service_providers.dart';
import 'package:octarq_vault/services/database_service.dart';
import 'package:octarq_vault/services/encryption_service.dart';
import 'package:octarq_vault/services/e2ee_sync_service.dart';

// ---------------------------------------------------------------------------
// Mocks
// ---------------------------------------------------------------------------

class _MockDatabaseService extends DatabaseService {
  final Map<String, List<AssetAttachment>> _attachments = {};
  bool _open = true;
  bool ensureOpenCalled = false;

  void setAttachments(String assetId, List<AssetAttachment> list) {
    _attachments[assetId] = list;
  }

  @override
  bool get isOpen => _open;

  void setOpen(bool v) => _open = v;

  @override
  Future<Database> ensureOpen(Uint8List masterKeyBytes) async {
    ensureOpenCalled = true;
    _open = true;
    // Open a throw-away in-memory DB via FFI; caller ignores the return value.
    return await databaseFactoryFfi.openDatabase(inMemoryDatabasePath)
        as dynamic;
  }

  @override
  Future<List<AssetAttachment>> getAttachmentsForAsset(String assetId) async {
    return _attachments[assetId] ?? [];
  }

  @override
  Future<OpLogEntry> appendOpLog(OpLogEntry entry) async => entry;
}

class _MockEncryptionService extends EncryptionService {
  @override
  Uint8List get masterKey => Uint8List(32);
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

AssetAttachment _attachment(String id, String name) => AssetAttachment(
  id: id,
  assetId: 'asset-1',
  name: name,
  mimeType: 'application/octet-stream',
  size: 1024,
  encFileName: '$id.enc',
  createdAt: 0,
  updatedAt: 0,
);

ProviderContainer _container({
  required _MockDatabaseService db,
  _MockEncryptionService? enc,
}) {
  return ProviderContainer(
    overrides: [
      databaseServiceProvider.overrideWithValue(db),
      if (enc != null) encryptionServiceProvider.overrideWithValue(enc),
    ],
  );
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('attachmentsProvider', () {
    test('returns list of attachments from DatabaseService', () async {
      final db = _MockDatabaseService();
      db.setAttachments('asset-1', [
        _attachment('a1', 'server_key.pem'),
        _attachment('a2', 'notes.txt'),
      ]);

      final container = _container(db: db);
      addTearDown(container.dispose);

      final result = await container.read(
        attachmentsProvider('asset-1').future,
      );
      expect(result.length, equals(2));
      expect(
        result.map((a) => a.name),
        containsAll(['server_key.pem', 'notes.txt']),
      );
    });

    test('returns empty list when DB has no attachments for asset', () async {
      final db = _MockDatabaseService();

      final container = _container(db: db);
      addTearDown(container.dispose);

      final result = await container.read(
        attachmentsProvider('asset-99').future,
      );
      expect(result, isEmpty);
    });

    test('calls ensureOpen when DB is not open', () async {
      final db = _MockDatabaseService()..setOpen(false);
      final enc = _MockEncryptionService();

      final container = _container(db: db, enc: enc);
      addTearDown(container.dispose);

      await container.read(attachmentsProvider('asset-1').future);
      expect(db.ensureOpenCalled, isTrue);
    });

    test('does not call ensureOpen when DB is already open', () async {
      final db = _MockDatabaseService(); // isOpen = true by default

      final container = _container(db: db);
      addTearDown(container.dispose);

      await container.read(attachmentsProvider('asset-1').future);
      expect(db.ensureOpenCalled, isFalse);
    });
  });

  group('attachmentServiceProvider', () {
    test('returns an AttachmentService instance without throwing', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      // If provider doesn't exist → Red phase (compile error)
      expect(() => container.read(attachmentServiceProvider), returnsNormally);
    });
  });
}
