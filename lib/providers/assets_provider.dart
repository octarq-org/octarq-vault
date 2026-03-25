import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite_sqlcipher/sqflite.dart';
import 'package:uuid/uuid.dart';
import '../models/asset.dart';
import '../models/asset_type.dart';
import '../models/field.dart';
import '../models/tag.dart';
import '../models/reminder.dart';
import '../services/local_file_sync_service.dart';
import '../services/google_drive_service.dart';
import '../services/webdav_service.dart';
import '../services/e2ee_sync_service.dart';
import 'service_providers.dart';
import '../models/sync_settings.dart';
import '../models/attachment.dart';
import 'sync_settings_provider.dart';
import 'sync_conflicts_provider.dart';
import 'auth_provider.dart';
import 'asset_types_provider.dart';
import 'relation_providers.dart';
import '../utils/tombstone_registry.dart';

class AssetsNotifier extends Notifier<List<Asset>> {
  /// In-memory tombstone registry.
  /// Persisted through snapshots via the tombstones field in VaultSnapshot.
  final _tombstones = TombstoneRegistry();

  /// Web: attachment metadata and op-log (native uses SQLCipher).
  final List<AssetAttachment> _webAttachments = [];
  final List<OpLogEntry> _webOpLog = [];
  int _webNextOpSeq = 1;

  void _recomputeWebNextOpSeq() {
    if (_webOpLog.isEmpty) {
      _webNextOpSeq = 1;
    } else {
      var maxSeq = 0;
      for (final e in _webOpLog) {
        if (e.seq > maxSeq) maxSeq = e.seq;
      }
      _webNextOpSeq = maxSeq + 1;
    }
  }

  /// Web-only: attachments for [assetId] from in-memory manifest.
  List<AssetAttachment> webAttachmentsFor(String assetId) {
    return _webAttachments
        .where((a) => a.assetId == assetId)
        .toList(growable: false);
  }

  Future<void> recordWebAttachmentUpsert(AssetAttachment attachment) async {
    if (!kIsWeb) return;
    _webAttachments.removeWhere((a) => a.id == attachment.id);
    _webAttachments.add(attachment);
    _webOpLog.add(
      OpLogEntry(
        id: const Uuid().v4(),
        op: OpType.upsert,
        entityType: OpEntityType.attachment,
        entityId: attachment.id,
        payload: attachment.toJson(),
        seq: _webNextOpSeq++,
        createdAt: DateTime.now().millisecondsSinceEpoch,
      ),
    );
  }

  Future<void> recordWebAttachmentDelete(AssetAttachment attachment) async {
    if (!kIsWeb) return;
    _webAttachments.removeWhere((a) => a.id == attachment.id);
    _webOpLog.add(
      OpLogEntry(
        id: const Uuid().v4(),
        op: OpType.delete,
        entityType: OpEntityType.attachment,
        entityId: attachment.id,
        payload: null,
        seq: _webNextOpSeq++,
        createdAt: DateTime.now().millisecondsSinceEpoch,
      ),
    );
    await ref
        .read(webVaultStorageProvider)
        .deleteAttachmentBlob(attachment.encFileName);
  }

  Future<Database> _vaultDb() async {
    final dbSvc = ref.read(databaseServiceProvider);
    if (dbSvc.isOpen) return dbSvc.db;
    final key = ref.read(encryptionServiceProvider).masterKey;
    return dbSvc.ensureOpen(key);
  }

  @override
  List<Asset> build() {
    // Security: Clear in-memory assets when vault is locked; reload from DB
    // when unlocking (build()'s microtask only runs once for the notifier).
    ref.listen(authProvider, (previous, next) {
      if (next == AuthState.locked || next == AuthState.unsetup) {
        state = [];
        _tombstones.clear();
        _webAttachments.clear();
        _webOpLog.clear();
        _webNextOpSeq = 1;
      } else if (next == AuthState.unlocked && previous != AuthState.unlocked) {
        Future.microtask(() => loadAssets());
      }
    });

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
                  if (result.conflicts.isNotEmpty) {
                    ref
                        .read(pendingSyncConflictsProvider.notifier)
                        .mergeFrom(result.conflicts);
                  }
                  // Persist merged blob back to IndexedDB
                  final mergedBlob = syncService.packSnapshotTOCiphertext(
                    localSnapshot.assets,
                    customAssetTypes: localSnapshot.customAssetTypes,
                    relations: localSnapshot.relations,
                    tombstones: localSnapshot.tombstones,
                    opLog: localSnapshot.opLog,
                    attachmentManifest: localSnapshot.attachmentManifest,
                  );
                  await storage.writeEncrypted(mergedBlob);
                }
              }
            }
          } catch (e) {
            if (kDebugMode) debugPrint('loadAssets(web) Drive pull: $e');
          }
        }

        if (localSnapshot == null) {
          _webAttachments.clear();
          _webOpLog.clear();
          _webNextOpSeq = 1;
          return;
        }
        state = localSnapshot.assets;
        _tombstones.loadFromList(localSnapshot.tombstones);
        _webAttachments
          ..clear()
          ..addAll(localSnapshot.attachmentManifest);
        _webOpLog
          ..clear()
          ..addAll(localSnapshot.opLog);
        _recomputeWebNextOpSeq();
        ref
            .read(webVaultRelationsProvider.notifier)
            .replace(localSnapshot.relations);
        await ref
            .read(assetTypesProvider.notifier)
            .setCustomTypesFromSnapshot(localSnapshot.customAssetTypes);
      } catch (e) {
        if (kDebugMode) {
          debugPrint('loadAssets(web): $e');
        }
      }
      return;
    }
    try {
      final db = await _vaultDb();
      final dbService = ref.read(databaseServiceProvider);
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

      // Native Cold Start: Check Google Drive for updates and merge into local SQLCipher.
      final methods = ref.read(syncSettingsProvider);
      if (methods.contains(SyncMethod.googleDrive)) {
        try {
          final drive = ref.read(googleDriveServiceProvider);
          final hasCreds = await drive.hasCredentials();
          if (hasCreds) {
            final syncService = ref.read(e2eeSyncServiceProvider);
            final remoteBlob = await drive.readRawBytesFromDrive();
            if (remoteBlob != null && remoteBlob.isNotEmpty) {
              final remoteSnapshot = syncService.unpackCiphertextToSnapshot(
                remoteBlob,
              );
              final customTypes = ref
                  .read(assetTypesProvider)
                  .where((t) => !t.isBuiltIn)
                  .toList();
              final relations = await dbService.getAllRelations();
              final localSnapshot = await buildNativeLocalSnapshotForMerge(
                customAssetTypes: customTypes,
                relations: relations,
              );

              final result = VaultSnapshot.mergeSnapshots(
                local: localSnapshot,
                remote: remoteSnapshot,
              );
              await pullSync(result.snapshot);

              if (result.conflicts.isNotEmpty) {
                ref
                    .read(pendingSyncConflictsProvider.notifier)
                    .mergeFrom(result.conflicts);
              }

              // Persist merge when remote wins on timestamps/count, or when
              // conflicts need the merged non-tie state reflected locally.
              if (result.snapshot.updatedAt > localSnapshot.updatedAt ||
                  result.snapshot.assets.length != state.length ||
                  result.conflicts.isNotEmpty) {
                await replaceFromSnapshot(result.snapshot);
              }
            }
          }
        } catch (e) {
          if (kDebugMode) debugPrint('loadAssets(native) Drive pull: $e');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('loadAssets: $e');
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
      final db = await _vaultDb();
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
      final db = await _vaultDb();
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
      final db = await _vaultDb();
      final dbService = ref.read(databaseServiceProvider);
      final now = DateTime.now().millisecondsSinceEpoch;

      await db.transaction((txn) async {
        await txn.update(
          'assets',
          {
            'type_id': updatedAsset.typeId,
            'name': updatedAsset.name,
            'expire_at': updatedAsset.expireAt,
            'updated_at': now,
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

      // Record oplog entry for asset upsert
      await dbService.recordAssetOperation(
        updatedAsset.id,
        OpType.upsert,
        payload: {...updatedAsset.toJson(), 'updated_at': now},
      );
    }
    state = [
      for (final asset in state)
        if (asset.id == updatedAsset.id) updatedAsset else asset,
    ];
    await _triggerSync();
  }

  Future<void> deleteAsset(String id) async {
    final now = DateTime.now().millisecondsSinceEpoch;

    if (kIsWeb) {
      final storage = ref.read(webVaultStorageProvider);
      final removed = _webAttachments.where((a) => a.assetId == id).toList();
      for (final a in removed) {
        _webAttachments.removeWhere((x) => x.id == a.id);
        await storage.deleteAttachmentBlob(a.encFileName);
        _webOpLog.add(
          OpLogEntry(
            id: const Uuid().v4(),
            op: OpType.delete,
            entityType: OpEntityType.attachment,
            entityId: a.id,
            payload: null,
            seq: _webNextOpSeq++,
            createdAt: now,
          ),
        );
      }
    } else {
      final db = await _vaultDb();
      final dbService = ref.read(databaseServiceProvider);

      await db.transaction((txn) async {
        await txn.delete('assets', where: 'id = ?', whereArgs: [id]);
      });

      // Record oplog entry for asset delete
      await dbService.recordAssetOperation(id, OpType.delete, payload: {});
    }
    state = state.where((a) => a.id != id).toList();
    // Record tombstone so deletions propagate across devices via LWW merge
    _tombstones.record(id, now);
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

  /// Write IndexedDB / cloud snapshot on Web (e.g. after relation edits).
  Future<void> flushWebVaultToStorage() async {
    if (!kIsWeb) return;
    await _triggerSync();
  }

  /// Push local encrypted attachment blobs to enabled remote providers.
  ///
  /// Missing local blobs are skipped; existing blobs are uploaded.
  /// Upload failures are isolated per provider/attachment and do not throw.
  Future<void> pushSync({required List<AssetAttachment> attachments}) async {
    if (kIsWeb || attachments.isEmpty) return;
    final methods = ref.read(syncSettingsProvider);
    final attachmentService = ref.read(attachmentServiceProvider);

    for (final attachment in attachments) {
      try {
        if (!await attachmentService.attachmentExists(attachment)) {
          continue;
        }
        final encBytes = await attachmentService.loadEncryptedBytes(attachment);

        for (final method in methods) {
          try {
            if (method == SyncMethod.googleDrive) {
              final drive = ref.read(googleDriveServiceProvider);
              if (await drive.hasCredentials()) {
                await drive.uploadAttachment(attachment, encBytes);
              }
            } else if (method == SyncMethod.webdav) {
              final webdav = ref.read(webDavServiceProvider);
              if (await webdav.hasCredentials()) {
                await webdav.uploadAttachment(attachment, encBytes);
              }
            } else if (method == SyncMethod.icloud && !kIsWeb) {
              final icloud = ref.read(iCloudSyncServiceProvider);
              if (icloud.isSupported) {
                await icloud.backupAttachment(attachment, encBytes);
              }
            }
          } catch (e) {
            if (kDebugMode) {
              debugPrint('Attachment push failed ($method): $e');
            }
          }
        }
      } catch (e) {
        if (kDebugMode) debugPrint('Attachment push skipped: $e');
      }
    }
  }

  /// Pull missing encrypted attachment blobs from enabled remote providers.
  ///
  /// Attachments marked as deleted in remote op-log are ignored.
  /// Download/save failures are isolated per attachment and do not throw.
  Future<void> pullSync(VaultSnapshot snapshot) async {
    if (kIsWeb || snapshot.attachmentManifest.isEmpty) return;
    final methods = ref.read(syncSettingsProvider);
    final attachmentService = ref.read(attachmentServiceProvider);
    final deletedIds = snapshot.opLog
        .where(
          (op) =>
              op.op == OpType.delete &&
              op.entityType == OpEntityType.attachment,
        )
        .map((op) => op.entityId)
        .toSet();

    for (final attachment in snapshot.attachmentManifest) {
      if (deletedIds.contains(attachment.id)) continue;

      try {
        if (await attachmentService.attachmentExists(attachment)) {
          continue;
        }
      } catch (_) {
        // Continue with remote fetch if local existence check fails.
      }

      for (final method in methods) {
        try {
          Uint8List? encBytes;
          if (method == SyncMethod.googleDrive) {
            final drive = ref.read(googleDriveServiceProvider);
            if (await drive.hasCredentials()) {
              encBytes = await drive.downloadAttachment(attachment);
            }
          } else if (method == SyncMethod.webdav) {
            final webdav = ref.read(webDavServiceProvider);
            if (await webdav.hasCredentials()) {
              encBytes = await webdav.downloadAttachment(attachment);
            }
          } else if (method == SyncMethod.icloud && !kIsWeb) {
            final icloud = ref.read(iCloudSyncServiceProvider);
            if (icloud.isSupported) {
              encBytes = await icloud.restoreAttachment(attachment);
            }
          }

          if (encBytes != null) {
            await attachmentService.saveEncryptedBytes(attachment, encBytes);
            break;
          }
        } catch (e) {
          if (kDebugMode) {
            debugPrint('Attachment pull failed ($method): $e');
          }
        }
      }
    }
  }

  /// Clear all assets (and related data). Used before JSON import to replace vault.
  Future<void> clearAll() async {
    state = [];
    if (kIsWeb) {
      final storage = ref.read(webVaultStorageProvider);
      for (final a in _webAttachments) {
        await storage.deleteAttachmentBlob(a.encFileName);
      }
      _webAttachments.clear();
      _webOpLog.clear();
      _webNextOpSeq = 1;
      ref.read(webVaultRelationsProvider.notifier).replace([]);
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
      final db = await _vaultDb();
      await db.delete('relations');
      await db.delete('assets');
      final dbService = ref.read(databaseServiceProvider);
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
      final storage = ref.read(webVaultStorageProvider);
      final keepEnc = snapshot.attachmentManifest
          .map((a) => a.encFileName)
          .toSet();
      for (final a in _webAttachments) {
        if (!keepEnc.contains(a.encFileName)) {
          await storage.deleteAttachmentBlob(a.encFileName);
        }
      }
      _webAttachments
        ..clear()
        ..addAll(snapshot.attachmentManifest);
      _webOpLog
        ..clear()
        ..addAll(snapshot.opLog);
      _recomputeWebNextOpSeq();
      ref.read(webVaultRelationsProvider.notifier).replace(snapshot.relations);
      await ref
          .read(assetTypesProvider.notifier)
          .setCustomTypesFromSnapshot(snapshot.customAssetTypes);
      if (encryptedBlob != null) {
        await ref.read(webVaultStorageProvider).writeEncrypted(encryptedBlob);
      }
    } else {
      final dbService = ref.read(databaseServiceProvider);
      final attachmentService = ref.read(attachmentServiceProvider);
      final db = await dbService.ensureOpen(
        ref.read(encryptionServiceProvider).masterKey,
      );
      final deletedAttachmentIds = snapshot.opLog
          .where(
            (op) =>
                op.op == OpType.delete &&
                op.entityType == OpEntityType.attachment,
          )
          .map((op) => op.entityId)
          .toSet();
      final existingAttachments = await dbService.getAllAttachments();
      final keepEncFileNames = snapshot.attachmentManifest
          .where((a) => !deletedAttachmentIds.contains(a.id))
          .map((a) => a.encFileName)
          .toSet();
      for (final attachment in existingAttachments) {
        if (!keepEncFileNames.contains(attachment.encFileName)) {
          try {
            await attachmentService.deleteAttachmentFile(attachment);
          } catch (_) {}
        }
      }
      await db.delete('assets');
      await dbService.deleteAllTags();
      await dbService.deleteAllAssetTypes();
      await dbService.deleteAllRelations();
      await db.delete('asset_attachments');
      await dbService.replaceOpLog(snapshot.opLog);
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
      for (final attachment in snapshot.attachmentManifest) {
        if (deletedAttachmentIds.contains(attachment.id)) continue;
        await dbService.insertAttachment(attachment);
      }
      ref.invalidate(assetRelationsProvider);
      await pullSync(snapshot);
    }
    await _triggerSync();
  }

  /// Deletes [attachment] blob from all enabled remote providers.
  ///
  /// Errors are isolated per provider and intentionally swallowed.
  Future<void> deleteRemoteAttachment(AssetAttachment attachment) async {
    if (kIsWeb) return;
    final methods = ref.read(syncSettingsProvider);
    for (final method in methods) {
      try {
        if (method == SyncMethod.googleDrive) {
          final drive = ref.read(googleDriveServiceProvider);
          if (await drive.hasCredentials()) {
            await drive.deleteRemoteAttachment(attachment);
          }
        } else if (method == SyncMethod.webdav) {
          final webdav = ref.read(webDavServiceProvider);
          if (await webdav.hasCredentials()) {
            await webdav.deleteRemoteAttachment(attachment);
          }
        } else if (method == SyncMethod.icloud) {
          final icloud = ref.read(iCloudSyncServiceProvider);
          if (icloud.isSupported) {
            await icloud.deleteAttachmentBackup(attachment);
          }
        }
      } catch (e) {
        if (kDebugMode) {
          debugPrint('Remote attachment delete failed ($method): $e');
        }
      }
    }
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

  List<Map<String, dynamic>> get _tombstoneListForSync =>
      _tombstones.toListForSync();

  Future<void> _triggerSync() async {
    final methods = ref.read(syncSettingsProvider);
    final customTypes = ref
        .read(assetTypesProvider)
        .where((t) => !t.isBuiltIn)
        .toList();

    // Fetch current relations: native from DB, web from in-memory mirror.
    List<Map<String, dynamic>> relations = [];
    if (kIsWeb) {
      relations = ref.read(webVaultRelationsProvider);
    } else {
      try {
        final dbSvc = ref.read(databaseServiceProvider);
        await dbSvc.ensureOpen(ref.read(encryptionServiceProvider).masterKey);
        relations = await dbSvc.getAllRelations();
      } catch (_) {}
    }

    final tombstones = _tombstoneListForSync;
    List<OpLogEntry> opLog = const [];
    List<AssetAttachment> attachmentManifest = const [];
    bool synced = false;

    // 1. Always update local cache/IndexedDB
    if (kIsWeb) {
      opLog = List<OpLogEntry>.from(_webOpLog);
      attachmentManifest = List<AssetAttachment>.from(_webAttachments);
      final syncService = ref.read(e2eeSyncServiceProvider);
      final blob = syncService.packSnapshotTOCiphertext(
        state,
        customAssetTypes: customTypes,
        relations: relations,
        tombstones: tombstones,
        opLog: opLog,
        attachmentManifest: attachmentManifest,
      );
      await ref.read(webVaultStorageProvider).writeEncrypted(blob);
      synced = true;
    } else {
      try {
        final dbSvc = ref.read(databaseServiceProvider);
        await dbSvc.ensureOpen(ref.read(encryptionServiceProvider).masterKey);
        opLog = await dbSvc.getAllOpLog();
        attachmentManifest = await dbSvc.getAllAttachments();
      } catch (_) {}
    }

    // 2. Dispatch to enabled cloud/file providers
    for (final syncMethod in methods) {
      try {
        if (syncMethod == SyncMethod.googleDrive) {
          final driveService = ref.read(googleDriveServiceProvider);
          if (await driveService.hasCredentials()) {
            await driveService.syncToDrive(
              state,
              customAssetTypes: customTypes,
              relations: relations,
              tombstones: tombstones,
              opLog: opLog,
              attachmentManifest: attachmentManifest,
            );
            synced = true;
          }
        } else if (syncMethod == SyncMethod.webdav) {
          final webDav = ref.read(webDavServiceProvider);
          if (await webDav.hasCredentials()) {
            final syncService = ref.read(e2eeSyncServiceProvider);
            final blob = syncService.packSnapshotTOCiphertext(
              state,
              customAssetTypes: customTypes,
              relations: relations,
              tombstones: tombstones,
              opLog: opLog,
              attachmentManifest: attachmentManifest,
            );
            await webDav.backupEncrypted(blob);
            synced = true;
          }
        } else if (syncMethod == SyncMethod.icloud && !kIsWeb) {
          final icloud = ref.read(iCloudSyncServiceProvider);
          if (icloud.isSupported) {
            final syncService = ref.read(e2eeSyncServiceProvider);
            final blob = syncService.packSnapshotTOCiphertext(
              state,
              customAssetTypes: customTypes,
              relations: relations,
              tombstones: tombstones,
              opLog: opLog,
              attachmentManifest: attachmentManifest,
            );
            await icloud.backup(blob);
            synced = true;
          }
        } else if (syncMethod == SyncMethod.localFile && kIsWeb) {
          final localSync = ref.read(localFileSyncServiceProvider);
          if (localSync.hasActiveHandle) {
            await localSync.syncToLocal(
              state,
              customAssetTypes: customTypes,
              tombstones: tombstones,
              relations: relations,
              opLog: opLog,
              attachmentManifest: attachmentManifest,
            );
            synced = true;
          }
        }
      } catch (e) {
        if (kDebugMode) debugPrint('Sync error ($syncMethod): $e');
      }
    }

    if (synced) {
      await ref.read(lastSyncAtProvider.notifier).recordSync();
    }
  }

  /// Public hook for screens that changed non-asset entities (e.g. attachments)
  /// and need to push a fresh full snapshot through the regular sync pipeline.
  Future<void> syncNow() => _triggerSync();

  /// Builds the native local snapshot used during cold-start merge.
  ///
  /// Includes attachment manifest and op-log to avoid dropping local-only
  /// attachment metadata/history when merging with a remote snapshot.
  Future<VaultSnapshot> buildNativeLocalSnapshotForMerge({
    required List<AssetType> customAssetTypes,
    required List<Map<String, dynamic>> relations,
  }) async {
    final dbService = ref.read(databaseServiceProvider);
    final opLog = await dbService.getAllOpLog();
    final attachmentManifest = await dbService.getAllAttachments();
    return VaultSnapshot(
      version: 3,
      assets: state,
      customAssetTypes: customAssetTypes,
      relations: relations,
      tombstones: _tombstoneList,
      opLog: opLog,
      attachmentManifest: attachmentManifest,
    );
  }
}

final assetsProvider = NotifierProvider<AssetsNotifier, List<Asset>>(() {
  return AssetsNotifier();
});
