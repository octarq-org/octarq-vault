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
import '../services/webdav_service.dart';
import '../services/e2ee_sync_service.dart';
import 'service_providers.dart';
import '../models/sync_settings.dart';
import 'sync_settings_provider.dart';
import 'asset_types_provider.dart';
import 'relations_provider.dart';
import '../utils/tombstone_registry.dart';

class AssetsNotifier extends Notifier<List<Asset>> {
  /// In-memory tombstone registry.
  /// Persisted through snapshots via the tombstones field in VaultSnapshot.
  final _tombstones = TombstoneRegistry();

  @override
  List<Asset> build() {
    Future.microtask(() => loadAssets());
    return [];
  }

  Future<void> loadAssets() async {
    if (kIsWeb) {
      try {
        final storage = ref.read(webVaultStorageProvider);
        final blob = await storage.readEncrypted();
        final syncService = ref.read(e2eeSyncServiceProvider);

        VaultSnapshot? localSnapshot;
        if (blob != null && blob.isNotEmpty) {
          try {
            localSnapshot = syncService.unpackCiphertextToSnapshot(blob);
          } catch (_) {}
        }

        // Attempt cold-start pull from Google Drive and LWW-merge with local.
        final methods = ref.read(syncSettingsProvider);
        if (methods.contains(SyncMethod.googleDrive)) {
          try {
            final drive = ref.read(googleDriveServiceProvider);
            final hasCreds = await drive.hasCredentials();
            if (hasCreds) {
              final remoteBlob = await drive.readRawBytesFromDrive();
              if (remoteBlob != null && remoteBlob.isNotEmpty) {
                final remoteSnapshot = syncService.unpackCiphertextToSnapshot(
                  remoteBlob,
                );
                if (localSnapshot == null) {
                  localSnapshot = remoteSnapshot;
                } else {
                  final result = VaultSnapshot.mergeSnapshots(
                    local: localSnapshot,
                    remote: remoteSnapshot,
                  );
                  localSnapshot = result.snapshot;
                  if (result.conflicts.isNotEmpty && kDebugMode) {
                    // Conflicts (same id, same updatedAt, different content)
                    // are kept as local during cold-start merge. Users can
                    // manually resolve via Settings → Pull from Google Drive.
                    print(
                      'loadAssets: ${result.conflicts.length} conflict(s) '
                      'detected during cold-start merge. Local versions kept. '
                      'Use "Pull from Google Drive" to resolve interactively.',
                    );
                  }
                  // Persist merged blob back to IndexedDB
                  final mergedBlob = syncService.packSnapshotTOCiphertext(
                    localSnapshot.assets,
                    customAssetTypes: localSnapshot.customAssetTypes,
                    relations: localSnapshot.relations,
                  );
                  await storage.writeEncrypted(mergedBlob);
                }
              }
            }
          } catch (e) {
            if (kDebugMode) print('loadAssets(web) Drive pull: $e');
          }
        }

        if (localSnapshot == null) return;
        state = localSnapshot.assets;
        _tombstones.loadFromList(localSnapshot.tombstones);
        await ref
            .read(assetTypesProvider.notifier)
            .setCustomTypesFromSnapshot(localSnapshot.customAssetTypes);
      } catch (e) {
        if (kDebugMode) {
          print('loadAssets(web): $e');
        }
      }
      return;
    }
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
      if (kDebugMode) {
        print('loadAssets: $e');
      }
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
    await _triggerSync();
  }

  /// Add multiple assets in one go; calls _triggerSync() once at the end.
  Future<void> batchAddAssets(List<Asset> assets) async {
    if (assets.isEmpty) return;
    if (!kIsWeb) {
      final db = ref.read(databaseServiceProvider).db;
      for (final asset in assets) {
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
    }
    state = [...state, ...assets];
    await _triggerSync();
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
    await _triggerSync();
  }

  Future<void> deleteAsset(String id) async {
    if (!kIsWeb) {
      final db = ref.read(databaseServiceProvider).db;
      await db.delete('assets', where: 'id = ?', whereArgs: [id]);
    }
    state = state.where((a) => a.id != id).toList();
    // Record tombstone so deletions propagate across devices via LWW merge
    _tombstones.record(id, DateTime.now().millisecondsSinceEpoch);
    await _triggerSync();
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

  /// Clear all assets (and related data). Used before JSON import to replace vault.
  Future<void> clearAll() async {
    state = [];
    if (kIsWeb) {
      final syncService = ref.read(e2eeSyncServiceProvider);
      final blob = syncService.packSnapshotTOCiphertext(
        [],
        customAssetTypes: ref
            .read(assetTypesProvider)
            .where((t) => !t.isBuiltIn)
            .toList(),
      );
      await ref.read(webVaultStorageProvider).writeEncrypted(blob);
    } else {
      final dbService = ref.read(databaseServiceProvider);
      final db = dbService.db;
      await db.delete('relations');
      await db.delete('assets');
      await dbService.deleteAllTags();
      await dbService.deleteAllAssetTypes();
    }
  }

  /// Replace vault with snapshot (e.g. after import .enc). On Web writes blob to IndexedDB.
  Future<void> replaceFromSnapshot(
    VaultSnapshot snapshot, {
    Uint8List? encryptedBlob,
  }) async {
    state = snapshot.assets;
    _tombstones.loadFromList(snapshot.tombstones);
    if (kIsWeb) {
      await ref
          .read(assetTypesProvider.notifier)
          .setCustomTypesFromSnapshot(snapshot.customAssetTypes);
      if (encryptedBlob != null) {
        await ref.read(webVaultStorageProvider).writeEncrypted(encryptedBlob);
      }
    } else {
      final dbService = ref.read(databaseServiceProvider);
      final db = dbService.db;
      await db.delete('assets');
      await dbService.deleteAllTags();
      await dbService.deleteAllAssetTypes();
      await dbService.deleteAllRelations();
      for (final a in snapshot.assets) {
        await _insertOneAssetRaw(db, a);
      }
      // Restore relations
      for (final r in snapshot.relations) {
        if (r['id'] != null &&
            r['from_asset_id'] != null &&
            r['to_asset_id'] != null &&
            r['relation_type'] != null) {
          await dbService.insertRelation(r);
        }
      }
      await ref
          .read(assetTypesProvider.notifier)
          .setCustomTypesFromSnapshot(snapshot.customAssetTypes);
      ref.invalidate(assetRelationsProvider);
    }
    await _triggerSync();
  }

  Future<void> _insertOneAssetRaw(Database db, Asset asset) async {
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

  List<Map<String, dynamic>> get _tombstoneList => _tombstones.toList();

  Future<void> _triggerSync() async {
    final methods = ref.read(syncSettingsProvider);
    final customTypes = ref
        .read(assetTypesProvider)
        .where((t) => !t.isBuiltIn)
        .toList();

    // Fetch current relations for native platforms.
    List<Map<String, dynamic>> relations = [];
    if (!kIsWeb) {
      try {
        relations = await ref.read(databaseServiceProvider).getAllRelations();
      } catch (_) {}
    }

    final tombstones = _tombstoneList;
    bool synced = false;

    if (kIsWeb) {
      final syncService = ref.read(e2eeSyncServiceProvider);
      final blob = syncService.packSnapshotTOCiphertext(
        state,
        customAssetTypes: customTypes,
        relations: relations,
        tombstones: tombstones,
      );
      await ref.read(webVaultStorageProvider).writeEncrypted(blob);
      synced = true;
      for (final syncMethod in methods) {
        if (syncMethod == SyncMethod.localFile) {
          final localSync = ref.read(localFileSyncServiceProvider);
          if (localSync.hasActiveHandle) {
            await localSync.syncToLocal(
              state,
              customAssetTypes: customTypes,
              tombstones: tombstones,
            );
          }
        } else if (syncMethod == SyncMethod.googleDrive) {
          final driveService = ref.read(googleDriveServiceProvider);
          final hasCreds = await driveService.hasCredentials();
          if (hasCreds) {
            await driveService.syncToDrive(
              state,
              customAssetTypes: customTypes,
              relations: relations,
              tombstones: tombstones,
            );
          }
        }
      }
    } else {
      for (final syncMethod in methods) {
        if (syncMethod == SyncMethod.webdav) {
          final webDav = ref.read(webDavServiceProvider);
          final hasCreds = await webDav.hasCredentials();
          if (hasCreds) {
            final syncService = ref.read(e2eeSyncServiceProvider);
            final blob = syncService.packSnapshotTOCiphertext(
              state,
              customAssetTypes: customTypes,
              relations: relations,
              tombstones: tombstones,
            );
            await webDav.backupEncrypted(blob);
            synced = true;
          }
        } else if (syncMethod == SyncMethod.icloud) {
          final icloud = ref.read(iCloudSyncServiceProvider);
          if (icloud.isSupported) {
            final syncService = ref.read(e2eeSyncServiceProvider);
            final blob = syncService.packSnapshotTOCiphertext(
              state,
              customAssetTypes: customTypes,
              relations: relations,
              tombstones: tombstones,
            );
            await icloud.backup(blob);
            synced = true;
          }
        }
      }
    }

    if (synced) {
      await ref.read(lastSyncAtProvider.notifier).recordSync();
    }
  }
}

final assetsProvider = NotifierProvider<AssetsNotifier, List<Asset>>(() {
  return AssetsNotifier();
});
