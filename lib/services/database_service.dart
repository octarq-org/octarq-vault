import 'package:sqflite_sqlcipher/sqflite.dart';
import 'package:path/path.dart';
import 'dart:typed_data';

class DatabaseService {
  Database? _db;

  Future<void> init(Uint8List masterKeyBytes) async {
    final hexKey = _bytesToHex(masterKeyBytes);
    final dbPath = join(await getDatabasesPath(), 'asset_vault_enc.db');

    _db = await openDatabase(
      dbPath,
      password: hexKey,
      version: 2,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: (db, version) async {
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
            PRIMARY KEY (asset_id, tag_id),
            FOREIGN KEY (asset_id) REFERENCES assets(id) ON DELETE CASCADE,
            FOREIGN KEY (tag_id) REFERENCES tags(id) ON DELETE CASCADE
          )
        ''');

        await db.execute('''
          CREATE TABLE reminders (
            id TEXT PRIMARY KEY,
            asset_id TEXT NOT NULL,
            trigger_type TEXT NOT NULL,
            offset_days INTEGER NOT NULL,
            channels TEXT NOT NULL,
            is_recurring INTEGER DEFAULT 0,
            FOREIGN KEY (asset_id) REFERENCES assets(id) ON DELETE CASCADE
          )
        ''');

        await db.execute('''
          CREATE TABLE asset_types (
            id TEXT PRIMARY KEY,
            name TEXT NOT NULL,
            icon TEXT NOT NULL,
            field_schema TEXT NOT NULL,
            is_built_in INTEGER DEFAULT 0
          )
        ''');

        await db.execute('''
          CREATE TABLE relations (
            id TEXT PRIMARY KEY,
            from_asset_id TEXT NOT NULL,
            to_asset_id TEXT NOT NULL,
            relation_type TEXT NOT NULL,
            FOREIGN KEY (from_asset_id) REFERENCES assets(id) ON DELETE CASCADE,
            FOREIGN KEY (to_asset_id) REFERENCES assets(id) ON DELETE CASCADE
          )
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute('''
            CREATE TABLE asset_types (
              id TEXT PRIMARY KEY,
              name TEXT NOT NULL,
              icon TEXT NOT NULL,
              field_schema TEXT NOT NULL,
              is_built_in INTEGER DEFAULT 0
            )
          ''');

          await db.execute('''
            CREATE TABLE relations (
              id TEXT PRIMARY KEY,
              from_asset_id TEXT NOT NULL,
              to_asset_id TEXT NOT NULL,
              relation_type TEXT NOT NULL,
              FOREIGN KEY (from_asset_id) REFERENCES assets(id) ON DELETE CASCADE,
              FOREIGN KEY (to_asset_id) REFERENCES assets(id) ON DELETE CASCADE
            )
          ''');
        }
      },
    );
  }

  String _bytesToHex(Uint8List bytes) {
    return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join('');
  }

  Database get db {
    if (_db == null) throw Exception("Database not initialized");
    return _db!;
  }

  Future<void> close() async {
    await _db?.close();
    _db = null;
  }

  // --- Asset Types ---
  Future<List<Map<String, dynamic>>> getCustomAssetTypes() async {
    return await db.query('asset_types');
  }

  Future<void> insertAssetType(Map<String, dynamic> typeData) async {
    await db.insert(
      'asset_types',
      typeData,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> deleteAssetType(String id) async {
    await db.delete('asset_types', where: 'id = ?', whereArgs: [id]);
  }

  // --- Relations ---
  Future<List<Map<String, dynamic>>> getRelationsForAsset(
    String assetId,
  ) async {
    return await db.query(
      'relations',
      where: 'from_asset_id = ? OR to_asset_id = ?',
      whereArgs: [assetId, assetId],
    );
  }

  Future<void> insertRelation(Map<String, dynamic> relationData) async {
    await db.insert(
      'relations',
      relationData,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> deleteRelation(String id) async {
    await db.delete('relations', where: 'id = ?', whereArgs: [id]);
  }
}
