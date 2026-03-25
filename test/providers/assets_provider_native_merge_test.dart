import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:octarq_vault/models/asset.dart';
import 'package:octarq_vault/models/asset_type.dart';
import 'package:octarq_vault/models/attachment.dart';
import 'package:octarq_vault/providers/assets_provider.dart';
import 'package:octarq_vault/providers/service_providers.dart';
import 'package:octarq_vault/services/database_service.dart';
import 'package:octarq_vault/services/e2ee_sync_service.dart';

class _SnapshotNotifier extends AssetsNotifier {
  @override
  List<Asset> build() => const [
    Asset(
      id: 'asset-1',
      typeId: 'type_generic',
      name: 'A',
      createdAt: 1,
      updatedAt: 1,
      isArchived: false,
      fields: [],
      tags: [],
      reminders: [],
    ),
  ];

  @override
  Future<void> loadAssets() async {}
}

class _MockDatabaseService extends DatabaseService {
  @override
  Future<List<OpLogEntry>> getAllOpLog() async => [
    OpLogEntry(
      id: 'op-1',
      op: OpType.upsert,
      entityType: OpEntityType.attachment,
      entityId: 'att-1',
      payload: const {'id': 'att-1'},
      createdAt: 1,
    ),
  ];

  @override
  Future<List<AssetAttachment>> getAllAttachments() async => const [
    AssetAttachment(
      id: 'att-1',
      assetId: 'asset-1',
      name: 'f.txt',
      mimeType: 'text/plain',
      size: 1,
      encFileName: 'att-1.enc',
      createdAt: 1,
      updatedAt: 1,
    ),
  ];
}

void main() {
  test(
    'native merge local snapshot includes attachmentManifest and opLog',
    () async {
      final container = ProviderContainer(
        overrides: [
          assetsProvider.overrideWith(() => _SnapshotNotifier()),
          databaseServiceProvider.overrideWithValue(_MockDatabaseService()),
        ],
      );
      addTearDown(container.dispose);

      final snapshot = await container
          .read(assetsProvider.notifier)
          .buildNativeLocalSnapshotForMerge(
            customAssetTypes: const <AssetType>[],
            relations: const [],
          );

      expect(snapshot.assets.length, 1);
      expect(snapshot.attachmentManifest.map((a) => a.id), contains('att-1'));
      expect(snapshot.opLog.map((e) => e.id), contains('op-1'));
    },
  );
}
