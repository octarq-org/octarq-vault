import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/asset.dart';
import '../models/field.dart';
import 'service_providers.dart';

class AssetsNotifier extends StateNotifier<List<Asset>> {
  final Ref ref;

  AssetsNotifier(this.ref) : super([]) {
    loadAssets();
  }

  Future<void> loadAssets() async {
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

        assets.add(Asset(
          id: aMap['id'] as String,
          typeId: aMap['type_id'] as String,
          name: aMap['name'] as String,
          expireAt: aMap['expire_at'] as int?,
          createdAt: aMap['created_at'] as int,
          updatedAt: aMap['updated_at'] as int,
          isArchived: (aMap['is_archived'] as int) == 1,
          fields: fields,
        ));
      }

      state = assets;
    } catch(e) {
      // Database not ready, probably locked.
    }
  }

  Future<void> addAsset(Asset asset) async {
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

    state = [...state, asset];
  }

  Future<void> deleteAsset(String id) async {
    final db = ref.read(databaseServiceProvider).db;
    await db.delete('assets', where: 'id = ?', whereArgs: [id]);
    state = state.where((a) => a.id != id).toList();
  }
}

final assetsProvider = StateNotifierProvider<AssetsNotifier, List<Asset>>((ref) {
  return AssetsNotifier(ref);
});
