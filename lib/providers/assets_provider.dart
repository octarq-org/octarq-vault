import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/asset.dart';
import '../models/field.dart';
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
    if (kIsWeb) {
      // In web, initial load is triggered via user interaction with Drive or Local File.
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
          ),
        );
      }

      state = assets;
    } catch (e) {
      // Database not ready, probably locked.
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

  void setWebAssets(List<Asset> assets) {
    if (kIsWeb) {
      state = assets;
    }
  }

  void _triggerWebSync() {
    if (!kIsWeb) return;

    // Push the new state to all active Sync services
    // The services will internally check if they have sessions/handles established
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
