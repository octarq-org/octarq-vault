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
      version: 1,
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
}
