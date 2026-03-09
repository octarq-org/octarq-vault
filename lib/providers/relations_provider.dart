import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'service_providers.dart';

final assetRelationsProvider =
    FutureProvider.family<List<Map<String, dynamic>>, String>((
      ref,
      assetId,
    ) async {
      if (kIsWeb) return [];
      final db = ref.watch(databaseServiceProvider);
      return await db.getRelationsForAsset(assetId);
    });

final relationsControllerProvider = Provider((ref) => RelationsController(ref));

class RelationsController {
  final Ref _ref;
  RelationsController(this._ref);

  Future<void> linkAssets(
    String assetId1,
    String assetId2,
    String relationType,
  ) async {
    if (!kIsWeb) {
      final db = _ref.read(databaseServiceProvider);
      await db.insertRelation({
        'id': const Uuid().v4(),
        'from_asset_id': assetId1,
        'to_asset_id': assetId2,
        'relation_type': relationType,
      });
    }
    _ref.invalidate(assetRelationsProvider(assetId1));
    _ref.invalidate(assetRelationsProvider(assetId2));
  }

  Future<void> removeRelation(
    String relationId,
    String asset1,
    String asset2,
  ) async {
    if (!kIsWeb) {
      final db = _ref.read(databaseServiceProvider);
      await db.deleteRelation(relationId);
    }
    _ref.invalidate(assetRelationsProvider(asset1));
    _ref.invalidate(assetRelationsProvider(asset2));
  }
}
