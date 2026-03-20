import 'dart:convert';
import 'dart:typed_data';

import 'package:sqflite_sqlcipher/sqflite.dart';

import '../models/attachment.dart';
import '../utils/platform_utils.dart';
import 'e2ee_sync_service.dart';

class DatabaseService {
  Database? _db;

  Future<void> init(Uint8List masterKeyBytes) async {
    await close();
    final hexKey = _bytesToHex(masterKeyBytes);
    final dbPath = await getVaultDatabasePath();

    _db = await openDatabase(
      dbPath,
      password: hexKey,
      version: 3,
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

        await _createV3Tables(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute('''
            CREATE TABLE IF NOT EXISTS asset_types (
              id TEXT PRIMARY KEY,
              name TEXT NOT NULL,
              icon TEXT NOT NULL,
              field_schema TEXT NOT NULL,
              is_built_in INTEGER DEFAULT 0
            )
          ''');

          await db.execute('''
            CREATE TABLE IF NOT EXISTS relations (
              id TEXT PRIMARY KEY,
              from_asset_id TEXT NOT NULL,
              to_asset_id TEXT NOT NULL,
              relation_type TEXT NOT NULL,
              FOREIGN KEY (from_asset_id) REFERENCES assets(id) ON DELETE CASCADE,
              FOREIGN KEY (to_asset_id) REFERENCES assets(id) ON DELETE CASCADE
            )
          ''');
        }
        if (oldVersion < 3) {
          await _createV3Tables(db);
        }
      },
    );
  }

  /// Creates tables introduced in schema version 3.
  static Future<void> _createV3Tables(Database db) async {
    // Append-only operation log: every mutation creates one entry.
    await db.execute('''
      CREATE TABLE IF NOT EXISTS op_log (
        seq        INTEGER PRIMARY KEY AUTOINCREMENT,
        id         TEXT    NOT NULL UNIQUE,
        op         TEXT    NOT NULL,
        entity_type TEXT   NOT NULL,
        entity_id  TEXT    NOT NULL,
        payload    TEXT,
        created_at INTEGER NOT NULL
      )
    ''');

    // Attachment metadata (blob lives on disk, not in the DB).
    await db.execute('''
      CREATE TABLE IF NOT EXISTS asset_attachments (
        id           TEXT    PRIMARY KEY,
        asset_id     TEXT    NOT NULL,
        name         TEXT    NOT NULL,
        mime_type    TEXT    NOT NULL,
        size         INTEGER NOT NULL,
        enc_file_name TEXT   NOT NULL,
        created_at   INTEGER NOT NULL,
        updated_at   INTEGER NOT NULL,
        FOREIGN KEY (asset_id) REFERENCES assets(id) ON DELETE CASCADE
      )
    ''');
  }

  String _bytesToHex(Uint8List bytes) {
    return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join('');
  }

  Database get db {
    if (_db == null) throw Exception("Database not initialized");
    return _db!;
  }

  /// True when [init]/[ensureOpen] has assigned a live [Database] handle.
  bool get isOpen => _db != null;

  /// Opens SQLCipher when [init] has not finished or was never called for this
  /// process (e.g. race right after first `setupMasterPassword` / unlock).
  Future<Database> ensureOpen(Uint8List masterKeyBytes) async {
    if (_db != null) return _db!;
    await init(masterKeyBytes);
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

  Future<void> deleteAllAssetTypes() async {
    await db.delete('asset_types');
  }

  Future<void> deleteAllTags() async {
    await db.delete('asset_tags');
    await db.delete('tags');
  }

  // --- Relations ---
  Future<List<Map<String, dynamic>>> getAllRelations() async {
    return await db.query('relations');
  }

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

  Future<void> deleteAllRelations() async {
    await db.delete('relations');
  }

  // -------------------------------------------------------------------------
  // Op-log
  // -------------------------------------------------------------------------

  /// Appends one entry to the op-log and returns it with its assigned [seq].
  Future<OpLogEntry> appendOpLog(OpLogEntry entry) async {
    final row = {
      'id': entry.id,
      'op': entry.op.toJson(),
      'entity_type': entry.entityType.toJson(),
      'entity_id': entry.entityId,
      'payload': entry.payload != null ? jsonEncode(entry.payload) : null,
      'created_at': entry.createdAt,
    };
    final seq = await db.insert(
      'op_log',
      row,
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
    return OpLogEntry(
      id: entry.id,
      op: entry.op,
      entityType: entry.entityType,
      entityId: entry.entityId,
      payload: entry.payload,
      seq: seq,
      createdAt: entry.createdAt,
    );
  }

  /// Returns all op-log entries with [seq] > [afterSeq], in ascending order.
  Future<List<OpLogEntry>> getOpLogSince(int afterSeq) async {
    final rows = await db.query(
      'op_log',
      where: 'seq > ?',
      whereArgs: [afterSeq],
      orderBy: 'seq ASC',
    );
    return rows.map(_rowToOpLogEntry).toList();
  }

  /// Returns all op-log entries, in ascending seq order.
  Future<List<OpLogEntry>> getAllOpLog() async {
    final rows = await db.query('op_log', orderBy: 'seq ASC');
    return rows.map(_rowToOpLogEntry).toList();
  }

  /// Returns the highest sequence number currently in the op-log, or 0.
  Future<int> getMaxOpLogSeq() async {
    final result = await db.rawQuery(
      'SELECT COALESCE(MAX(seq), 0) AS max_seq FROM op_log',
    );
    return (result.first['max_seq'] as int? ?? 0);
  }

  /// Deletes entries with [seq] <= [upToSeq], keeping at least [keepCount]
  /// recent entries for peers that are still catching up.
  Future<void> pruneOpLog({int keepCount = 500}) async {
    final maxSeq = await getMaxOpLogSeq();
    final cutoff = maxSeq - keepCount;
    if (cutoff > 0) {
      await db.delete('op_log', where: 'seq <= ?', whereArgs: [cutoff]);
    }
  }

  OpLogEntry _rowToOpLogEntry(Map<String, dynamic> row) {
    Map<String, dynamic>? payload;
    final payloadStr = row['payload'] as String?;
    if (payloadStr != null) {
      payload = Map<String, dynamic>.from(jsonDecode(payloadStr) as Map);
    }
    return OpLogEntry(
      id: row['id'] as String,
      op: OpType.fromJson(row['op'] as String),
      entityType: OpEntityType.fromJson(row['entity_type'] as String),
      entityId: row['entity_id'] as String,
      payload: payload,
      seq: row['seq'] as int,
      createdAt: row['created_at'] as int,
    );
  }

  // -------------------------------------------------------------------------
  // Asset attachments
  // -------------------------------------------------------------------------

  Future<void> insertAttachment(AssetAttachment attachment) async {
    await db.insert('asset_attachments', {
      'id': attachment.id,
      'asset_id': attachment.assetId,
      'name': attachment.name,
      'mime_type': attachment.mimeType,
      'size': attachment.size,
      'enc_file_name': attachment.encFileName,
      'created_at': attachment.createdAt,
      'updated_at': attachment.updatedAt,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<AssetAttachment>> getAttachmentsForAsset(String assetId) async {
    final rows = await db.query(
      'asset_attachments',
      where: 'asset_id = ?',
      whereArgs: [assetId],
      orderBy: 'created_at ASC',
    );
    return rows.map(_rowToAttachment).toList();
  }

  Future<List<AssetAttachment>> getAllAttachments() async {
    final rows = await db.query('asset_attachments', orderBy: 'created_at ASC');
    return rows.map(_rowToAttachment).toList();
  }

  Future<void> deleteAttachment(String id) async {
    await db.delete('asset_attachments', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> deleteAttachmentsForAsset(String assetId) async {
    await db.delete(
      'asset_attachments',
      where: 'asset_id = ?',
      whereArgs: [assetId],
    );
  }

  AssetAttachment _rowToAttachment(Map<String, dynamic> row) => AssetAttachment(
    id: row['id'] as String,
    assetId: row['asset_id'] as String,
    name: row['name'] as String,
    mimeType: row['mime_type'] as String,
    size: row['size'] as int,
    encFileName: row['enc_file_name'] as String,
    createdAt: row['created_at'] as int,
    updatedAt: row['updated_at'] as int,
  );
}
