import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:octarq_vault/services/database_service.dart';
import 'package:octarq_vault/services/encryption_service.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

Uint8List _key(int fill) => Uint8List.fromList(List.filled(32, fill));

EncryptionService _enc(int fill) {
  final svc = EncryptionService();
  svc.setMasterKey(_key(fill));
  return svc;
}

/// Opens an in-memory SQLite database (via FFI) and creates the tables that
/// DatabaseService manages, so tests can inject it via [DatabaseService.testDb].
Future<Database> _openTestDb() async {
  sqfliteFfiInit();
  final factory = databaseFactoryFfi;
  final db = await factory.openDatabase(
    inMemoryDatabasePath,
    options: OpenDatabaseOptions(
      version: 4,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: (db, _) async {
        await db.execute('''
          CREATE TABLE IF NOT EXISTS assets (
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
          CREATE TABLE IF NOT EXISTS asset_fields (
            id TEXT PRIMARY KEY,
            asset_id TEXT NOT NULL,
            key TEXT NOT NULL,
            value_enc TEXT NOT NULL,
            iv TEXT NOT NULL,
            is_sensitive INTEGER DEFAULT 0,
            FOREIGN KEY (asset_id) REFERENCES assets(id) ON DELETE CASCADE
          )
        ''');
      },
    ),
  );
  return db;
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('rekeyDatabase', () {
    test('throws when database is not initialised', () async {
      final svc = DatabaseService();
      // _db is null → db getter throws "Database not initialized"
      expect(() => svc.rekeyDatabase(_key(0x02)), throwsA(anything));
    });
  });

  group('reEncryptAllFields', () {
    late DatabaseService svc;
    late Database testDb;

    setUp(() async {
      testDb = await _openTestDb();
      svc = DatabaseService();
      // ignore: invalid_use_of_visible_for_testing_member
      svc.testDb = testDb;
    });

    tearDown(() async {
      await testDb.close();
    });

    test('re-encrypts all rows: each row decryptable with newEnc', () async {
      final oldEnc = _enc(0x01);
      final newEnc = _enc(0x02);
      final plaintexts = ['alpha', 'beta', 'gamma'];

      // Insert a dummy asset to satisfy FK
      await testDb.insert('assets', {
        'id': 'asset-1',
        'type_id': 'type-test',
        'name': 'Test Asset',
        'created_at': 0,
        'updated_at': 0,
      });

      // Insert 3 asset_fields rows encrypted with oldEnc
      for (final pt in plaintexts) {
        final enc = oldEnc.encryptField(pt);
        await testDb.insert('asset_fields', {
          'id': 'field-$pt',
          'asset_id': 'asset-1',
          'key': pt,
          'value_enc': enc['valueEnc']!,
          'iv': enc['iv']!,
          'is_sensitive': 0,
        });
      }

      await svc.reEncryptAllFields(oldEnc, newEnc);

      // Every row must now be decryptable with newEnc
      final rows = await testDb.query('asset_fields');
      expect(rows.length, equals(3));
      for (final row in rows) {
        final decrypted = newEnc.decryptField(
          row['value_enc'] as String,
          row['iv'] as String,
        );
        expect(plaintexts, contains(decrypted));
      }
    });

    test('rows are NOT decryptable with old key after re-encryption', () async {
      final oldEnc = _enc(0x01);
      final newEnc = _enc(0x02);
      final plaintext = 'secret-value';

      await testDb.insert('assets', {
        'id': 'asset-1',
        'type_id': 'type-test',
        'name': 'Test Asset',
        'created_at': 0,
        'updated_at': 0,
      });

      final enc = oldEnc.encryptField(plaintext);
      await testDb.insert('asset_fields', {
        'id': 'field-1',
        'asset_id': 'asset-1',
        'key': 'secret',
        'value_enc': enc['valueEnc']!,
        'iv': enc['iv']!,
        'is_sensitive': 0,
      });

      await svc.reEncryptAllFields(oldEnc, newEnc);

      final row = (await testDb.query('asset_fields')).first;
      // Decrypting with the old key must fail
      expect(
        () => oldEnc.decryptField(
          row['value_enc'] as String,
          row['iv'] as String,
        ),
        throwsA(anything),
      );
    });

    test(
      're-encryption failure rolls back — original ciphertext preserved',
      () async {
        final oldEnc = _enc(0x01);
        final brokenEnc =
            EncryptionService(); // key not set → encryptField throws

        await testDb.insert('assets', {
          'id': 'asset-1',
          'type_id': 'type-test',
          'name': 'Test Asset',
          'created_at': 0,
          'updated_at': 0,
        });

        final original = oldEnc.encryptField('secret');
        await testDb.insert('asset_fields', {
          'id': 'field-1',
          'asset_id': 'asset-1',
          'key': 'password',
          'value_enc': original['valueEnc']!,
          'iv': original['iv']!,
          'is_sensitive': 0,
        });

        // brokenEnc.encryptField() throws because the key is not set
        await expectLater(
          () => svc.reEncryptAllFields(oldEnc, brokenEnc),
          throwsA(anything),
        );

        // Row must still hold the original ciphertext (transaction rolled back)
        final rows = await testDb.query('asset_fields');
        expect(rows.first['value_enc'], equals(original['valueEnc']!));
        expect(rows.first['iv'], equals(original['iv']!));
      },
    );
  });
}
