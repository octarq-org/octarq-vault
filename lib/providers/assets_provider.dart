import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite_sqlcipher/sqflite.dart';
import '../models/asset.dart';
import '../models/field.dart';
import '../models/tag.dart';
import '../models/reminder.dart';
import '../services/local_file_sync_service.dart';
import '../services/google_drive_service.dart';
import 'service_providers.dart';

class AssetsNotifier extends Notifier<List<Asset>> {
  @override
  List<Asset> build() {
    Future.microtask(() => loadAssets());
    return [];
  }

  Future<void> loadAssets() async {
    if (kIsWeb) return;
    try {
      final dbService = ref.read(databaseServiceProvider);
      final db = dbService.db;
      final List<Map<String, dynamic>> assetMaps = await db.query('assets');

      final List<Asset> assets = [];

      for (var aMap in assetMaps) {
        final List<Map<String, dynamic>> fieldMaps = await db.query(
          'asset_fields',
          where: 'asset_id = ?',
          whereArgs: [aMap['id']],
        );
        final List<AssetField> fields = fieldMaps.map((fMap) {
          return AssetField(
            id: fMap['id'] as String,
            assetId: fMap['asset_id'] as String,
            key: fMap['key'] as String,
            valueEnc: fMap['value_enc'] as String,
            iv: fMap['iv'] as String,
            isSensitive: (fMap['is_sensitive'] as int) == 1,
          );
        }).toList();

        final List<Map<String, dynamic>> tagMaps = await db.rawQuery(
          'SELECT t.* FROM tags t INNER JOIN asset_tags at ON t.id = at.tag_id WHERE at.asset_id = ?',
          [aMap['id']],
        );
        final List<Tag> tags = tagMaps.map((tMap) {
          return Tag(
            id: tMap['id'] as String,
            name: tMap['name'] as String,
            color: tMap['color'] as String,
          );
        }).toList();

        final List<Map<String, dynamic>> reminderMaps = await db.query(
          'reminders',
          where: 'asset_id = ?',
          whereArgs: [aMap['id']],
        );
        final List<Reminder> reminders = reminderMaps.map((rMap) {
          List<String> channels = [];
          try {
            channels = (jsonDecode(rMap['channels'] as String) as List)
                .cast<String>();
          } catch (_) {}
          return Reminder(
            id: rMap['id'] as String,
            assetId: rMap['asset_id'] as String,
            triggerType: rMap['trigger_type'] as String,
            offsetDays: rMap['offset_days'] as int,
            channels: channels,
            isRecurring: (rMap['is_recurring'] as int) == 1,
          );
        }).toList();

        assets.add(
          Asset(
            id: aMap['id'] as String,
            typeId: aMap['type_id'] as String,
            name: aMap['name'] as String,
            expireAt: aMap['expire_at'] as int?,
            createdAt: aMap['created_at'] as int,
            updatedAt: aMap['updated_at'] as int,
            isArchived: (aMap['is_archived'] as int) == 1,
            fields: fields,
            tags: tags,
            reminders: reminders,
          ),
        );
      }

      state = assets;
    } catch (e) {
      // Database not ready, probably locked.
    }
  }

  Future<void> _persistTags(dynamic txn, Asset asset) async {
    await txn.delete(
      'asset_tags',
      where: 'asset_id = ?',
      whereArgs: [asset.id],
    );
    for (var tag in asset.tags) {
      await txn.insert('tags', {
        'id': tag.id,
        'name': tag.name,
        'color': tag.color,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
      await txn.insert('asset_tags', {
        'asset_id': asset.id,
        'tag_id': tag.id,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    }
  }

  Future<void> _persistReminders(dynamic txn, Asset asset) async {
    await txn.delete('reminders', where: 'asset_id = ?', whereArgs: [asset.id]);
    for (var reminder in asset.reminders) {
      await txn.insert('reminders', {
        'id': reminder.id,
        'asset_id': reminder.assetId,
        'trigger_type': reminder.triggerType,
        'offset_days': reminder.offsetDays,
        'channels': jsonEncode(reminder.channels),
        'is_recurring': reminder.isRecurring ? 1 : 0,
      });
    }
  }

  Future<void> addAsset(Asset asset) async {
    if (!kIsWeb) {
      final db = ref.read(databaseServiceProvider).db;
      await db.transaction((txn) async {
        await txn.insert('assets', {
          'id': asset.id,
          'type_id': asset.typeId,
          'name': asset.name,
          'expire_at': asset.expireAt,
          'created_at': asset.createdAt,
          'updated_at': asset.updatedAt,
          'is_archived': asset.isArchived ? 1 : 0,
        });
        for (var field in asset.fields) {
          await txn.insert('asset_fields', {
            'id': field.id,
            'asset_id': field.assetId,
            'key': field.key,
            'value_enc': field.valueEnc,
            'iv': field.iv,
            'is_sensitive': field.isSensitive ? 1 : 0,
          });
        }
        await _persistTags(txn, asset);
        await _persistReminders(txn, asset);
      });
    }
    state = [...state, asset];
    _triggerWebSync();
  }

  Future<void> updateAsset(Asset updatedAsset) async {
    if (!kIsWeb) {
      final db = ref.read(databaseServiceProvider).db;
      await db.transaction((txn) async {
        await txn.update(
          'assets',
          {
            'type_id': updatedAsset.typeId,
            'name': updatedAsset.name,
            'expire_at': updatedAsset.expireAt,
            'updated_at': DateTime.now().millisecondsSinceEpoch,
            'is_archived': updatedAsset.isArchived ? 1 : 0,
          },
          where: 'id = ?',
          whereArgs: [updatedAsset.id],
        );
        await txn.delete(
          'asset_fields',
          where: 'asset_id = ?',
          whereArgs: [updatedAsset.id],
        );
        for (var field in updatedAsset.fields) {
          await txn.insert('asset_fields', {
            'id': field.id,
            'asset_id': field.assetId,
            'key': field.key,
            'value_enc': field.valueEnc,
            'iv': field.iv,
            'is_sensitive': field.isSensitive ? 1 : 0,
          });
        }
        await _persistTags(txn, updatedAsset);
        await _persistReminders(txn, updatedAsset);
      });
    }
    state = [
      for (final asset in state)
        if (asset.id == updatedAsset.id) updatedAsset else asset,
    ];
    _triggerWebSync();
  }

  Future<void> deleteAsset(String id) async {
    if (!kIsWeb) {
      final db = ref.read(databaseServiceProvider).db;
      await db.delete('assets', where: 'id = ?', whereArgs: [id]);
    }
    state = state.where((a) => a.id != id).toList();
    _triggerWebSync();
  }

  Future<void> archiveAsset(String id) async {
    final asset = state.firstWhere((a) => a.id == id);
    await updateAsset(asset.copyWith(isArchived: true));
  }

  Future<void> unarchiveAsset(String id) async {
    final asset = state.firstWhere((a) => a.id == id);
    await updateAsset(asset.copyWith(isArchived: false));
  }

  Future<void> batchArchive(List<String> ids) async {
    for (final id in ids) {
      await archiveAsset(id);
    }
  }

  Future<void> batchDelete(List<String> ids) async {
    for (final id in ids) {
      await deleteAsset(id);
    }
  }

  Future<void> batchAddTag(List<String> assetIds, Tag tag) async {
    for (final id in assetIds) {
      final asset = state.firstWhere((a) => a.id == id);
      if (!asset.tags.any((t) => t.id == tag.id)) {
        await updateAsset(asset.copyWith(tags: [...asset.tags, tag]));
      }
    }
  }

  void setWebAssets(List<Asset> assets) {
    if (kIsWeb) {
      state = assets;
    }
  }

  void _triggerWebSync() {
    if (!kIsWeb) return;
    final localSync = ref.read(localFileSyncServiceProvider);
    if (localSync.hasActiveHandle) {
      localSync.syncToLocal(state);
    }
    final driveSync = ref.read(googleDriveServiceProvider);
    driveSync.hasCredentials().then((hasCreds) {
      if (hasCreds) {
        driveSync.syncToDrive(state);
      }
    });
  }
}

final assetsProvider = NotifierProvider<AssetsNotifier, List<Asset>>(() {
  return AssetsNotifier();
});
