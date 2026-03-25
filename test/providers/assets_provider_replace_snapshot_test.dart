import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:octarq_vault/models/attachment.dart';
import 'package:octarq_vault/models/sync_settings.dart';
import 'package:octarq_vault/providers/assets_provider.dart';
import 'package:octarq_vault/providers/service_providers.dart';
import 'package:octarq_vault/providers/sync_settings_provider.dart';
import 'package:octarq_vault/services/attachment_service.dart';
import 'package:octarq_vault/services/database_service.dart';
import 'package:octarq_vault/services/e2ee_sync_service.dart';
import 'package:octarq_vault/services/encryption_service.dart';

Future<Database> _openTestDb() async {
  sqfliteFfiInit();
  final factory = databaseFactoryFfi;
  return factory.openDatabase(
    inMemoryDatabasePath,
    options: OpenDatabaseOptions(
      version: 4,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: (db, _) async {
        await db.execute('''
          CREATE TABLE assets (
            id TEXT PRIMARY KEY,
            type_id TEXT NOT NULL,
            name TEXT NOT NULL,
            expire_at INTEGER,
            created_at INTEGER NOT NULL,
            updated_at INTEGER NOT NULL,
            is_archived INTEGER DEFAULT 0
          )
        ''');
        await db.execute('''
          CREATE TABLE asset_fields (
            id TEXT PRIMARY KEY,
            asset_id TEXT NOT NULL,
            key TEXT NOT NULL,
            value_enc TEXT NOT NULL,
            iv TEXT NOT NULL,
            is_sensitive INTEGER DEFAULT 0,
            FOREIGN KEY (asset_id) REFERENCES assets(id) ON DELETE CASCADE
          )
        ''');
        await db.execute('''
          CREATE TABLE tags (
            id TEXT PRIMARY KEY,
            name TEXT NOT NULL,
            color TEXT NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE asset_tags (
            asset_id TEXT NOT NULL,
            tag_id TEXT NOT NULL,
            PRIMARY KEY (asset_id, tag_id)
          )
        ''');
        await db.execute('''
          CREATE TABLE reminders (
            id TEXT PRIMARY KEY,
            asset_id TEXT NOT NULL,
            trigger_type TEXT NOT NULL,
            offset_days INTEGER NOT NULL,
            channels TEXT NOT NULL,
            is_recurring INTEGER DEFAULT 0
          )
        ''');
        await db.execute('''
          CREATE TABLE asset_types (
            id TEXT PRIMARY KEY,
            name TEXT NOT NULL,
            icon TEXT NOT NULL,
            field_schema TEXT NOT NULL,
            is_built_in INTEGER DEFAULT 0,
            updated_at INTEGER NOT NULL DEFAULT 0
          )
        ''');
        await db.execute('''
          CREATE TABLE relations (
            id TEXT PRIMARY KEY,
            from_asset_id TEXT NOT NULL,
            to_asset_id TEXT NOT NULL,
            relation_type TEXT NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE op_log (
            seq INTEGER PRIMARY KEY AUTOINCREMENT,
            id TEXT NOT NULL UNIQUE,
            op TEXT NOT NULL,
            entity_type TEXT NOT NULL,
            entity_id TEXT NOT NULL,
            payload TEXT,
            created_at INTEGER NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE asset_attachments (
            id TEXT PRIMARY KEY,
            asset_id TEXT NOT NULL,
            name TEXT NOT NULL,
            mime_type TEXT NOT NULL,
            size INTEGER NOT NULL,
            enc_file_name TEXT NOT NULL,
            created_at INTEGER NOT NULL,
            updated_at INTEGER NOT NULL
          )
        ''');
      },
    ),
  );
}

class _MockEncryptionService extends EncryptionService {
  @override
  Uint8List get masterKey => Uint8List(32);
}

class _MockAttachmentService extends AttachmentService {
  _MockAttachmentService() : super(_MockEncryptionService());

  @override
  Future<bool> attachmentExists(AssetAttachment attachment) async => true;

  @override
  Future<void> saveEncryptedBytes(
    AssetAttachment attachment,
    Uint8List encBytes,
  ) async {}

  @override
  Future<void> deleteAttachmentFile(AssetAttachment attachment) async {}
}

class _NoSyncSettingsNotifier extends SyncSettingsNotifier {
  @override
  List<SyncMethod> build() => const [];
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test(
    'replaceFromSnapshot clears old op_log and skips tombstoned manifest attachment',
    () async {
      final db = await _openTestDb();
      final dbSvc = DatabaseService();
      // ignore: invalid_use_of_visible_for_testing_member
      dbSvc.testDb = db;

      // seed old op_log and local attachment metadata
      await db.insert('op_log', {
        'id': 'old-op',
        'op': 'upsert',
        'entity_type': 'attachment',
        'entity_id': 'att-old',
        'payload': '{"id":"att-old"}',
        'created_at': 1,
      });
      await db.insert('asset_attachments', {
        'id': 'att-old',
        'asset_id': 'asset-1',
        'name': 'old.txt',
        'mime_type': 'text/plain',
        'size': 1,
        'enc_file_name': 'old.enc',
        'created_at': 1,
        'updated_at': 1,
      });

      final tombstonedAttachment = AssetAttachment(
        id: 'att-del',
        assetId: 'asset-1',
        name: 'deleted.txt',
        mimeType: 'text/plain',
        size: 1,
        encFileName: 'att-del.enc',
        createdAt: 2,
        updatedAt: 2,
      );
      final snapshot = VaultSnapshot(
        version: 3,
        assets: const [],
        attachmentManifest: [tombstonedAttachment],
        opLog: const [
          OpLogEntry(
            id: 'snap-op-del',
            op: OpType.delete,
            entityType: OpEntityType.attachment,
            entityId: 'att-del',
            createdAt: 2,
          ),
        ],
      );

      final container = ProviderContainer(
        overrides: [
          databaseServiceProvider.overrideWithValue(dbSvc),
          encryptionServiceProvider.overrideWithValue(_MockEncryptionService()),
          attachmentServiceProvider.overrideWithValue(_MockAttachmentService()),
          syncSettingsProvider.overrideWith(() => _NoSyncSettingsNotifier()),
        ],
      );
      addTearDown(() async {
        container.dispose();
        await db.close();
      });

      await container
          .read(assetsProvider.notifier)
          .replaceFromSnapshot(snapshot);

      final opLogRows = await db.query('op_log', orderBy: 'seq ASC');
      expect(opLogRows.map((r) => r['id']), isNot(contains('old-op')));
      expect(opLogRows.map((r) => r['id']), contains('snap-op-del'));

      final attachmentRows = await db.query('asset_attachments');
      expect(attachmentRows, isEmpty);
    },
  );
}
