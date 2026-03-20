import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:asset_vault/services/encryption_service.dart';
import 'package:asset_vault/services/e2ee_sync_service.dart';
import 'package:asset_vault/models/asset.dart';
import 'package:asset_vault/models/asset_type.dart';

/// Creates a minimal deterministic 32-byte master key.
EncryptionService _makeService() {
  final service = EncryptionService();
  final key = Uint8List(32);
  for (int i = 0; i < 32; i++) {
    key[i] = i;
  }
  service.setMasterKey(key);
  service.setSalt('dGVzdHNhbHQ='); // base64('testsalt')
  return service;
}

Asset _makeAsset({required String id, required String name, int? updatedAt}) {
  return Asset(
    id: id,
    typeId: 'type-1',
    name: name,
    createdAt: 1000,
    updatedAt: updatedAt ?? 2000,
    fields: [],
    tags: [],
    reminders: [],
  );
}

void main() {
  group('VaultSnapshot serialization', () {
    test('toJson / fromJson roundtrip preserves all fields', () {
      final snapshot = VaultSnapshot(
        version: 2,
        assets: [_makeAsset(id: 'a1', name: 'Asset 1')],
        customAssetTypes: [
          AssetType(
            id: 'ct1',
            name: 'Custom',
            icon: '🔑',
            fieldSchema: [],
            isBuiltIn: false,
          ),
        ],
        relations: [
          {
            'id': 'r1',
            'from_asset_id': 'a1',
            'to_asset_id': 'a2',
            'relation_type': 'depends_on',
          },
        ],
      );

      final json = snapshot.toJson();
      final restored = VaultSnapshot.fromJson(json);

      expect(restored.version, 2);
      expect(restored.assets.length, 1);
      expect(restored.assets.first.name, 'Asset 1');
      expect(restored.customAssetTypes.length, 1);
      expect(restored.customAssetTypes.first.id, 'ct1');
      expect(restored.relations.length, 1);
      expect(restored.relations.first['id'], 'r1');
      expect(restored.relations.first['relation_type'], 'depends_on');
    });

    test('fromJson is backwards-compatible (no relations field)', () {
      final json = {
        'version': 1,
        'assets': [],
        'customAssetTypes': [],
        // no 'relations' key — simulates old format
      };
      final snapshot = VaultSnapshot.fromJson(json);
      expect(snapshot.relations, isEmpty);
    });

    test('fromJson defaults missing tombstones to empty list', () {
      final snapshot = VaultSnapshot.fromJson({
        'version': 2,
        'assets': [],
        'customAssetTypes': [],
        'relations': [],
      });

      expect(snapshot.tombstones, isEmpty);
    });
  });

  group('E2EE pack / unpack roundtrip', () {
    late E2EESyncService service;

    setUp(() {
      service = E2EESyncService(_makeService());
    });

    test('pack → unpack restores assets', () {
      final assets = [
        _makeAsset(id: 'a1', name: 'Server SSH Key'),
        _makeAsset(id: 'a2', name: 'API Token'),
      ];
      final blob = service.packSnapshotTOCiphertext(assets);
      final snapshot = service.unpackCiphertextToSnapshot(blob);

      expect(snapshot.assets.length, 2);
      expect(snapshot.assets[0].name, 'Server SSH Key');
      expect(snapshot.assets[1].name, 'API Token');
    });

    test('pack → unpack preserves relations', () {
      final assets = [
        _makeAsset(id: 'a1', name: 'Asset A'),
        _makeAsset(id: 'a2', name: 'Asset B'),
      ];
      final relations = [
        {
          'id': 'rel-1',
          'from_asset_id': 'a1',
          'to_asset_id': 'a2',
          'relation_type': 'uses',
        },
      ];
      final blob = service.packSnapshotTOCiphertext(
        assets,
        relations: relations,
      );
      final snapshot = service.unpackCiphertextToSnapshot(blob);

      expect(snapshot.relations.length, 1);
      expect(snapshot.relations.first['id'], 'rel-1');
      expect(snapshot.relations.first['relation_type'], 'uses');
    });

    test('V2 magic header is present in packed blob', () {
      final blob = service.packSnapshotTOCiphertext([]);
      // First 4 bytes should be 'AVV2'
      final header = String.fromCharCodes(blob.sublist(0, 4));
      expect(header, 'AVV2');
    });

    test('stripHeader removes AVV2 header correctly', () {
      final assets = [_makeAsset(id: 'x', name: 'X')];
      final blob = service.packSnapshotTOCiphertext(assets);
      final stripped = E2EESyncService.stripHeader(blob);
      // Stripped payload must not start with 'AVV2'
      if (stripped.length >= 4) {
        final header = String.fromCharCodes(stripped.sublist(0, 4));
        expect(header, isNot('AVV2'));
      }
    });

    test('extractSaltFromPayload returns correct salt', () {
      final blob = service.packSnapshotTOCiphertext([]);
      final salt = E2EESyncService.extractSaltFromPayload(blob);
      expect(salt, isNotNull);
      expect(salt, isNotEmpty);
    });

    test(
      'extractSaltFromPayload returns null for invalid or truncated header',
      () {
        expect(
          E2EESyncService.extractSaltFromPayload(Uint8List.fromList([1, 2, 3])),
          isNull,
        );

        final invalidHeader = Uint8List.fromList([
          ...'NOPE'.codeUnits,
          0,
          4,
          ...'salt'.codeUnits,
        ]);
        expect(E2EESyncService.extractSaltFromPayload(invalidHeader), isNull);

        final truncated = Uint8List.fromList([
          ...'AVV2'.codeUnits,
          0,
          10,
          ...'salt'.codeUnits,
        ]);
        expect(E2EESyncService.extractSaltFromPayload(truncated), isNull);
      },
    );

    test('stripHeader leaves legacy payload unchanged', () {
      final payload = Uint8List.fromList([9, 8, 7, 6, 5]);
      expect(E2EESyncService.stripHeader(payload), equals(payload));
    });

    test('tampered ciphertext throws on unpack', () {
      final blob = service.packSnapshotTOCiphertext([
        _makeAsset(id: 'a', name: 'Test'),
      ]);
      // Flip last byte to corrupt MAC
      final tampered = Uint8List.fromList(blob);
      tampered[tampered.length - 1] ^= 0xFF;
      expect(
        () => service.unpackCiphertextToSnapshot(tampered),
        throwsA(anything),
      );
    });
  });

  group('VaultSnapshot.mergeSnapshots (LWW)', () {
    test('remote asset wins when updatedAt is newer', () {
      final local = VaultSnapshot(
        version: 2,
        assets: [_makeAsset(id: 'a1', name: 'Old Name', updatedAt: 1000)],
      );
      final remote = VaultSnapshot(
        version: 2,
        assets: [_makeAsset(id: 'a1', name: 'New Name', updatedAt: 2000)],
      );

      final merged = VaultSnapshot.mergeSnapshots(
        local: local,
        remote: remote,
      ).snapshot;

      expect(merged.assets.length, 1);
      expect(merged.assets.first.name, 'New Name');
    });

    test('local asset wins when updatedAt is newer', () {
      final local = VaultSnapshot(
        version: 2,
        assets: [_makeAsset(id: 'a1', name: 'Local Fresh', updatedAt: 5000)],
      );
      final remote = VaultSnapshot(
        version: 2,
        assets: [_makeAsset(id: 'a1', name: 'Remote Stale', updatedAt: 3000)],
      );

      final merged = VaultSnapshot.mergeSnapshots(
        local: local,
        remote: remote,
      ).snapshot;

      expect(merged.assets.first.name, 'Local Fresh');
    });

    test('assets unique to each side are all included in merge', () {
      final local = VaultSnapshot(
        version: 2,
        assets: [_makeAsset(id: 'local-only', name: 'Local Only')],
      );
      final remote = VaultSnapshot(
        version: 2,
        assets: [_makeAsset(id: 'remote-only', name: 'Remote Only')],
      );

      final merged = VaultSnapshot.mergeSnapshots(
        local: local,
        remote: remote,
      ).snapshot;

      expect(merged.assets.length, 2);
      final ids = merged.assets.map((a) => a.id).toSet();
      expect(ids, containsAll(['local-only', 'remote-only']));
    });

    test('relations are unioned by id (remote wins on conflict)', () {
      final local = VaultSnapshot(
        version: 2,
        assets: [],
        relations: [
          {
            'id': 'r1',
            'from_asset_id': 'a1',
            'to_asset_id': 'a2',
            'relation_type': 'uses',
          },
          {
            'id': 'r2',
            'from_asset_id': 'a3',
            'to_asset_id': 'a4',
            'relation_type': 'depends_on',
          },
        ],
      );
      final remote = VaultSnapshot(
        version: 2,
        assets: [],
        relations: [
          // r1 is also in remote with different type — remote wins
          {
            'id': 'r1',
            'from_asset_id': 'a1',
            'to_asset_id': 'a2',
            'relation_type': 'hosted_on',
          },
          {
            'id': 'r3',
            'from_asset_id': 'a5',
            'to_asset_id': 'a6',
            'relation_type': 'related_to',
          },
        ],
      );

      final merged = VaultSnapshot.mergeSnapshots(
        local: local,
        remote: remote,
      ).snapshot;

      expect(
        merged.relations.length,
        3,
      ); // r1 (remote), r2 (local), r3 (remote)
      final r1 = merged.relations.firstWhere((r) => r['id'] == 'r1');
      expect(r1['relation_type'], 'hosted_on'); // remote wins
      final ids = merged.relations.map((r) => r['id'] as String).toSet();
      expect(ids, containsAll(['r1', 'r2', 'r3']));
    });

    test('custom asset types unioned, remote wins on conflict', () {
      final localType = AssetType(
        id: 'ct1',
        name: 'Local Version',
        icon: '📁',
        fieldSchema: [],
        isBuiltIn: false,
      );
      final remoteType = AssetType(
        id: 'ct1',
        name: 'Remote Version',
        icon: '🔑',
        fieldSchema: [],
        isBuiltIn: false,
      );
      final uniqueType = AssetType(
        id: 'ct2',
        name: 'Unique',
        icon: '🗝',
        fieldSchema: [],
        isBuiltIn: false,
      );

      final local = VaultSnapshot(
        version: 2,
        assets: [],
        customAssetTypes: [localType],
      );
      final remote = VaultSnapshot(
        version: 2,
        assets: [],
        customAssetTypes: [remoteType, uniqueType],
      );

      final merged = VaultSnapshot.mergeSnapshots(
        local: local,
        remote: remote,
      ).snapshot;

      expect(merged.customAssetTypes.length, 2);
      final ct1 = merged.customAssetTypes.firstWhere((t) => t.id == 'ct1');
      expect(ct1.name, 'Remote Version');
    });

    test(
      'same timestamp but different asset content yields conflict and keeps local',
      () {
        final local = VaultSnapshot(
          version: 2,
          assets: [_makeAsset(id: 'a1', name: 'Local Name', updatedAt: 2000)],
        );
        final remote = VaultSnapshot(
          version: 2,
          assets: [_makeAsset(id: 'a1', name: 'Remote Name', updatedAt: 2000)],
        );

        final result = VaultSnapshot.mergeSnapshots(
          local: local,
          remote: remote,
        );

        expect(result.conflicts, hasLength(1));
        expect(result.conflicts.single.local.name, 'Local Name');
        expect(result.conflicts.single.remote.name, 'Remote Name');
        expect(result.snapshot.assets.single.name, 'Local Name');
      },
    );

    test('newer tombstone removes asset and relations that reference it', () {
      final local = VaultSnapshot(
        version: 2,
        assets: [_makeAsset(id: 'a1', name: 'Keep?', updatedAt: 1000)],
        relations: [
          {
            'id': 'r1',
            'from_asset_id': 'a1',
            'to_asset_id': 'a2',
            'relation_type': 'depends_on',
          },
          {
            'id': 'r2',
            'from_asset_id': 'a3',
            'to_asset_id': 'a4',
            'relation_type': 'related_to',
          },
        ],
      );
      final remote = VaultSnapshot(
        version: 2,
        assets: const [],
        tombstones: [
          {'id': 'a1', 'deletedAt': 2000},
        ],
      );

      final merged = VaultSnapshot.mergeSnapshots(
        local: local,
        remote: remote,
      ).snapshot;

      expect(merged.assets.where((asset) => asset.id == 'a1'), isEmpty);
      expect(merged.relations.map((r) => r['id']), equals(['r2']));
      expect(merged.tombstones, hasLength(1));
      expect(merged.tombstones.single['id'], equals('a1'));
      expect(merged.tombstones.single['deletedAt'], equals(2000));
    });

    test('tombstone with equal timestamp does not delete asset', () {
      final local = VaultSnapshot(
        version: 2,
        assets: [_makeAsset(id: 'a1', name: 'Same Time', updatedAt: 1500)],
      );
      final remote = VaultSnapshot(
        version: 2,
        assets: const [],
        tombstones: [
          {'id': 'a1', 'deletedAt': 1500},
        ],
      );

      final merged = VaultSnapshot.mergeSnapshots(
        local: local,
        remote: remote,
      ).snapshot;

      expect(merged.assets.single.id, 'a1');
    });

    test(
      'newest tombstone wins when both snapshots contain same tombstone id',
      () {
        final local = VaultSnapshot(
          version: 2,
          assets: const [],
          tombstones: [
            {'id': 'a1', 'deletedAt': 1000},
          ],
        );
        final remote = VaultSnapshot(
          version: 2,
          assets: const [],
          tombstones: [
            {'id': 'a1', 'deletedAt': 3000},
          ],
        );

        final merged = VaultSnapshot.mergeSnapshots(
          local: local,
          remote: remote,
        ).snapshot;

        expect(
          merged.tombstones,
          equals([
            {'id': 'a1', 'deletedAt': 3000},
          ]),
        );
      },
    );
  });
}
