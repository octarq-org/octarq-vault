import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../services/e2ee_sync_service.dart';
import 'assets_provider.dart';
import 'relation_providers.dart';
import 'service_providers.dart';

export 'relation_providers.dart';

final relationsControllerProvider = Provider((ref) => RelationsController(ref));

class RelationsController {
  final Ref _ref;
  RelationsController(this._ref);

  Future<void> linkAssets(
    String assetId1,
    String assetId2,
    String relationType,
  ) async {
    final relationId = const Uuid().v4();
    final relationData = {
      'id': relationId,
      'from_asset_id': assetId1,
      'to_asset_id': assetId2,
      'relation_type': relationType,
    };

    if (kIsWeb) {
      _ref.read(webVaultRelationsProvider.notifier).addRow(relationData);
      await _ref.read(assetsProvider.notifier).flushWebVaultToStorage();
    } else {
      await ensureRelationsDb(_ref);
      final db = _ref.read(databaseServiceProvider);
      await db.insertRelation(relationData);

      // Record oplog entry for relation upsert
      await db.recordRelationOperation(
        relationId,
        OpType.upsert,
        payload: relationData,
      );
    }
    _ref.invalidate(assetRelationsProvider(assetId1));
    _ref.invalidate(assetRelationsProvider(assetId2));
  }

  Future<void> removeRelation(
    String relationId,
    String asset1,
    String asset2,
  ) async {
    if (kIsWeb) {
      _ref.read(webVaultRelationsProvider.notifier).removeById(relationId);
      await _ref.read(assetsProvider.notifier).flushWebVaultToStorage();
    } else {
      await ensureRelationsDb(_ref);
      final db = _ref.read(databaseServiceProvider);
      await db.deleteRelation(relationId);

      // Record oplog entry for relation delete
      await db.recordRelationOperation(relationId, OpType.delete, payload: {});
    }
    _ref.invalidate(assetRelationsProvider(asset1));
    _ref.invalidate(assetRelationsProvider(asset2));
  }
}
