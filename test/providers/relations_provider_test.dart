import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:octarq_vault/providers/relations_provider.dart';
import 'package:octarq_vault/providers/service_providers.dart';
import 'package:octarq_vault/services/database_service.dart';
import 'package:octarq_vault/services/e2ee_sync_service.dart';

class MockDatabaseService extends DatabaseService {
  final List<Map<String, dynamic>> insertedRelations = [];
  final List<String> deletedRelationIds = [];
  final Map<String, int> getRelationsCalls = {};

  /// In-memory mock — no SQLCipher file; skip [ensureOpen]/[init] in tests.
  @override
  bool get isOpen => true;

  @override
  Future<List<Map<String, dynamic>>> getRelationsForAsset(
    String assetId,
  ) async {
    getRelationsCalls[assetId] = (getRelationsCalls[assetId] ?? 0) + 1;
    return insertedRelations
        .where(
          (relation) =>
              relation['from_asset_id'] == assetId ||
              relation['to_asset_id'] == assetId,
        )
        .toList();
  }

  @override
  Future<void> insertRelation(Map<String, dynamic> relationData) async {
    insertedRelations.add(Map<String, dynamic>.from(relationData));
  }

  @override
  Future<void> deleteRelation(String id) async {
    deletedRelationIds.add(id);
    insertedRelations.removeWhere((relation) => relation['id'] == id);
  }

  @override
  Future<OpLogEntry> appendOpLog(OpLogEntry entry) async => entry;
}

void main() {
  group('relations provider', () {
    test(
      'assetRelationsProvider returns relations for the requested asset',
      () async {
        final db = MockDatabaseService()
          ..insertedRelations.addAll([
            {
              'id': 'r1',
              'from_asset_id': 'asset-a',
              'to_asset_id': 'asset-b',
              'relation_type': 'depends_on',
            },
            {
              'id': 'r2',
              'from_asset_id': 'asset-c',
              'to_asset_id': 'asset-a',
              'relation_type': 'linked_to',
            },
          ]);

        final container = ProviderContainer(
          overrides: [databaseServiceProvider.overrideWithValue(db)],
        );
        addTearDown(container.dispose);

        final relations = await container.read(
          assetRelationsProvider('asset-a').future,
        );

        expect(relations.length, equals(2));
        expect(db.getRelationsCalls['asset-a'], equals(1));
      },
    );

    test(
      'linkAssets inserts relation and invalidates both asset queries',
      () async {
        final db = MockDatabaseService();
        final container = ProviderContainer(
          overrides: [databaseServiceProvider.overrideWithValue(db)],
        );
        addTearDown(container.dispose);

        await container.read(assetRelationsProvider('asset-a').future);
        await container.read(assetRelationsProvider('asset-b').future);
        expect(db.getRelationsCalls['asset-a'], equals(1));
        expect(db.getRelationsCalls['asset-b'], equals(1));

        final controller = container.read(relationsControllerProvider);
        await controller.linkAssets('asset-a', 'asset-b', 'depends_on');

        expect(db.insertedRelations, hasLength(1));
        expect(
          db.insertedRelations.single['relation_type'],
          equals('depends_on'),
        );
        expect(db.insertedRelations.single['from_asset_id'], equals('asset-a'));
        expect(db.insertedRelations.single['to_asset_id'], equals('asset-b'));
        expect(db.insertedRelations.single['id'], isA<String>());
        expect(db.insertedRelations.single['id'], isNotEmpty);

        final assetARelations = await container.read(
          assetRelationsProvider('asset-a').future,
        );
        final assetBRelations = await container.read(
          assetRelationsProvider('asset-b').future,
        );

        expect(assetARelations, hasLength(1));
        expect(assetBRelations, hasLength(1));
        expect(db.getRelationsCalls['asset-a'], equals(2));
        expect(db.getRelationsCalls['asset-b'], equals(2));
      },
    );

    test(
      'removeRelation deletes relation and invalidates both asset queries',
      () async {
        final db = MockDatabaseService()
          ..insertedRelations.add({
            'id': 'r1',
            'from_asset_id': 'asset-a',
            'to_asset_id': 'asset-b',
            'relation_type': 'depends_on',
          });

        final container = ProviderContainer(
          overrides: [databaseServiceProvider.overrideWithValue(db)],
        );
        addTearDown(container.dispose);

        await container.read(assetRelationsProvider('asset-a').future);
        await container.read(assetRelationsProvider('asset-b').future);

        final controller = container.read(relationsControllerProvider);
        await controller.removeRelation('r1', 'asset-a', 'asset-b');

        expect(db.deletedRelationIds, equals(['r1']));

        final assetARelations = await container.read(
          assetRelationsProvider('asset-a').future,
        );
        final assetBRelations = await container.read(
          assetRelationsProvider('asset-b').future,
        );

        expect(assetARelations, isEmpty);
        expect(assetBRelations, isEmpty);
        expect(db.getRelationsCalls['asset-a'], equals(2));
        expect(db.getRelationsCalls['asset-b'], equals(2));
      },
    );
  });
}
