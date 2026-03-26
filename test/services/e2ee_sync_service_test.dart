import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:octarq_vault/services/encryption_service.dart';
import 'package:octarq_vault/services/e2ee_sync_service.dart';
import 'package:octarq_vault/models/asset.dart';
import 'package:octarq_vault/models/asset_type.dart';
import 'package:octarq_vault/models/attachment.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

EncryptionService _makeEncService() {
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

OpLogEntry _makeOpLogEntry({
  required String id,
  required String entityId,
  int seq = 1,
  OpType op = OpType.upsert,
  OpEntityType entityType = OpEntityType.asset,
  Map<String, dynamic>? payload,
}) {
  return OpLogEntry(
    id: id,
    op: op,
    entityType: entityType,
    entityId: entityId,
    payload: payload,
    seq: seq,
    createdAt: 1_000_000,
  );
}

AssetAttachment _makeAttachment({required String id, required String assetId}) {
  return AssetAttachment(
    id: id,
    assetId: assetId,
    name: 'test.pdf',
    mimeType: 'application/pdf',
    size: 1024,
    encFileName: '$id.enc',
    createdAt: 1000,
    updatedAt: 2000,
  );
}

// ---------------------------------------------------------------------------
// VaultSnapshot serialisation
// ---------------------------------------------------------------------------

void main() {
  group('VaultSnapshot serialisation', () {
    test('toJson / fromJson roundtrip preserves all fields', () {
      final entry = _makeOpLogEntry(id: 'op1', entityId: 'a1');
      final attachment = _makeAttachment(id: 'att1', assetId: 'a1');
      final snapshot = VaultSnapshot(
        version: 3,
        assets: [_makeAsset(id: 'a1', name: 'Asset 1')],
        customAssetTypes: [
          AssetType(
            id: 'ct1',
            name: 'Custom',
            icon: '🔑',
            fieldSchema: [],
            isBuiltIn: false,
            updatedAt: 4242,
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
        opLog: [entry],
        attachmentManifest: [attachment],
      );

      final json = snapshot.toJson();
      final restored = VaultSnapshot.fromJson(json);

      expect(restored.version, 3);
      expect(restored.assets.length, 1);
      expect(restored.assets.first.name, 'Asset 1');
      expect(restored.customAssetTypes.length, 1);
      expect(restored.customAssetTypes.first.id, 'ct1');
      expect(restored.customAssetTypes.first.updatedAt, 4242);
      expect(restored.relations.length, 1);
      expect(restored.relations.first['id'], 'r1');
      expect(restored.relations.first['relation_type'], 'depends_on');
      expect(restored.opLog.length, 1);
      expect(restored.opLog.first.id, 'op1');
      expect(restored.attachmentManifest.length, 1);
      expect(restored.attachmentManifest.first.id, 'att1');
    });

    test('fromJson defaults missing optional fields to empty', () {
      final json = {
        'version': 3,
        'assets': [],
        'customAssetTypes': [],
        // no relations, tombstones, opLog, attachmentManifest
      };
      final snapshot = VaultSnapshot.fromJson(json);
      expect(snapshot.relations, isEmpty);
      expect(snapshot.tombstones, isEmpty);
      expect(snapshot.opLog, isEmpty);
      expect(snapshot.attachmentManifest, isEmpty);
      expect(snapshot.payloadType, 'full');
      expect(snapshot.baseSeq, 0);
    });

    test('delta snapshot serialises payloadType and baseSeq', () {
      final snapshot = VaultSnapshot(
        version: 3,
        payloadType: 'delta',
        baseSeq: 42,
        assets: [],
        opLog: [_makeOpLogEntry(id: 'op2', entityId: 'a2', seq: 43)],
      );
      final restored = VaultSnapshot.fromJson(snapshot.toJson());
      expect(restored.payloadType, 'delta');
      expect(restored.baseSeq, 42);
      expect(restored.opLog.length, 1);
      expect(restored.opLog.first.seq, 43);
    });
  });

  // -------------------------------------------------------------------------
  // OpLogEntry
  // -------------------------------------------------------------------------

  group('OpLogEntry serialisation', () {
    test('upsert entry roundtrips with payload', () {
      final entry = OpLogEntry(
        id: 'uuid-1',
        op: OpType.upsert,
        entityType: OpEntityType.asset,
        entityId: 'asset-1',
        payload: {'name': 'My Asset', 'typeId': 't1'},
        seq: 7,
        createdAt: 999,
      );
      final restored = OpLogEntry.fromJson(entry.toJson());
      expect(restored.id, 'uuid-1');
      expect(restored.op, OpType.upsert);
      expect(restored.entityType, OpEntityType.asset);
      expect(restored.entityId, 'asset-1');
      expect(restored.payload!['name'], 'My Asset');
      expect(restored.seq, 7);
      expect(restored.createdAt, 999);
    });

    test('delete entry has null payload', () {
      final entry = OpLogEntry(
        id: 'uuid-2',
        op: OpType.delete,
        entityType: OpEntityType.attachment,
        entityId: 'att-1',
        seq: 8,
        createdAt: 1001,
      );
      final restored = OpLogEntry.fromJson(entry.toJson());
      expect(restored.op, OpType.delete);
      expect(restored.entityType, OpEntityType.attachment);
      expect(restored.payload, isNull);
    });

    test('all OpEntityType values serialise correctly', () {
      for (final et in OpEntityType.values) {
        expect(OpEntityType.fromJson(et.toJson()), et);
      }
    });

    test('all OpType values serialise correctly', () {
      for (final op in OpType.values) {
        expect(OpType.fromJson(op.toJson()), op);
      }
    });
  });

  // -------------------------------------------------------------------------
  // AVV3 pack / unpack roundtrip
  // -------------------------------------------------------------------------

  group('E2EE pack / unpack roundtrip (AVV3)', () {
    late E2EESyncService service;

    setUp(() {
      service = E2EESyncService(_makeEncService());
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

    test('pack → unpack preserves opLog entries', () {
      final opLog = [
        _makeOpLogEntry(id: 'op1', entityId: 'a1', seq: 1),
        _makeOpLogEntry(id: 'op2', entityId: 'a2', seq: 2),
      ];
      final blob = service.packSnapshotTOCiphertext([], opLog: opLog);
      final snapshot = service.unpackCiphertextToSnapshot(blob);

      expect(snapshot.opLog.length, 2);
      expect(snapshot.opLog[0].id, 'op1');
      expect(snapshot.opLog[1].id, 'op2');
    });

    test('pack → unpack preserves attachment manifest', () {
      final manifest = [_makeAttachment(id: 'att1', assetId: 'a1')];
      final blob = service.packSnapshotTOCiphertext(
        [],
        attachmentManifest: manifest,
      );
      final snapshot = service.unpackCiphertextToSnapshot(blob);

      expect(snapshot.attachmentManifest.length, 1);
      expect(snapshot.attachmentManifest.first.id, 'att1');
      expect(snapshot.attachmentManifest.first.mimeType, 'application/pdf');
    });

    test('pack → unpack preserves tombstones', () {
      final tombstones = [
        {'id': 'del-1', 'deletedAt': 5000},
        {'id': 'del-2', 'deletedAt': 6000},
      ];
      final blob = service.packSnapshotTOCiphertext([], tombstones: tombstones);
      final snapshot = service.unpackCiphertextToSnapshot(blob);

      expect(snapshot.tombstones.length, 2);
      expect(snapshot.tombstones[0]['id'], 'del-1');
      expect(snapshot.tombstones[1]['id'], 'del-2');
      expect(snapshot.tombstones[0]['deletedAt'], 5000);
      expect(snapshot.tombstones[1]['deletedAt'], 6000);
    });

    test('AVV3 magic header is present in packed blob', () {
      final blob = service.packSnapshotTOCiphertext([]);
      final header = String.fromCharCodes(blob.sublist(0, 4));
      expect(header, 'AVV3');
    });

    test('extractSaltFromPayload returns correct salt', () {
      final blob = service.packSnapshotTOCiphertext([]);
      final salt = E2EESyncService.extractSaltFromPayload(blob);
      expect(salt, isNotNull);
      expect(salt, isNotEmpty);
    });

    test(
      'extractSaltFromPayload returns null for invalid or truncated payload',
      () {
        expect(
          E2EESyncService.extractSaltFromPayload(Uint8List.fromList([1, 2, 3])),
          isNull,
        );

        final wrongMagic = Uint8List.fromList([
          ...'NOPE'.codeUnits,
          0,
          4,
          ...'salt'.codeUnits,
        ]);
        expect(E2EESyncService.extractSaltFromPayload(wrongMagic), isNull);

        final truncated = Uint8List.fromList([
          ...'AVV3'.codeUnits,
          0,
          10,
          ...'salt'.codeUnits, // only 4 bytes, but saltLen says 10
        ]);
        expect(E2EESyncService.extractSaltFromPayload(truncated), isNull);
      },
    );

    test('stripHeader returns null payloadType for non-AVV3 payload', () {
      final payload = Uint8List.fromList([9, 8, 7, 6, 5]);
      final result = E2EESyncService.stripHeader(payload);
      expect(result.payloadType, isNull);
    });

    test('stripHeader returns correct payloadType byte for full snapshot', () {
      final blob = service.packSnapshotTOCiphertext([]);
      final result = E2EESyncService.stripHeader(blob);
      expect(result.payloadType, 0x00); // _ptFull
    });

    test('tampered ciphertext throws on unpack', () {
      final blob = service.packSnapshotTOCiphertext([
        _makeAsset(id: 'a', name: 'Test'),
      ]);
      final tampered = Uint8List.fromList(blob);
      tampered[tampered.length - 1] ^= 0xFF;
      expect(
        () => service.unpackCiphertextToSnapshot(tampered),
        throwsA(anything),
      );
    });

    test('rejects non-AVV3 payload', () {
      final garbage = Uint8List.fromList(utf8.encode('not a valid blob'));
      expect(
        () => service.unpackCiphertextToSnapshot(garbage),
        throwsA(anything),
      );
    });

    test('payload encrypted with different key cannot be decrypted', () {
      final blob = service.packSnapshotTOCiphertext([
        _makeAsset(id: 'a1', name: 'Secret'),
      ]);

      // Create a service with a DIFFERENT key
      final otherEnc = EncryptionService();
      final otherKey = Uint8List(32);
      for (int i = 0; i < 32; i++) {
        otherKey[i] = 255 - i;
      }
      otherEnc.setMasterKey(otherKey);
      otherEnc.setSalt('b3RoZXJzYWx0'); // base64('othersalt')
      final otherService = E2EESyncService(otherEnc);

      expect(
        () => otherService.unpackCiphertextToSnapshot(blob),
        throwsA(anything),
      );
    });

    test('extractSaltFromPayload returns correct salt from AVV3 header', () {
      final blob = service.packSnapshotTOCiphertext([]);
      final salt = E2EESyncService.extractSaltFromPayload(blob);
      expect(salt, equals('dGVzdHNhbHQ=')); // the salt from _makeEncService
    });

    test('extractSaltFromPayload returns null for garbage input', () {
      final garbage = Uint8List.fromList([1, 2, 3]);
      expect(E2EESyncService.extractSaltFromPayload(garbage), isNull);
    });
  });

  // -------------------------------------------------------------------------
  // Cross-platform export → import simulation
  // -------------------------------------------------------------------------

  group('Cross-platform export → import', () {
    EncryptionService makeEncWithPassword(String salt) {
      final enc = EncryptionService();
      final key = Uint8List(32);
      for (int i = 0; i < 32; i++) {
        key[i] = i;
      }
      enc.setMasterKey(key);
      enc.setSalt(salt);
      return enc;
    }

    test(
      'same key+salt: platform A export → platform B import round-trips all data',
      () {
        final enc = makeEncWithPassword('dGVzdHNhbHQ=');
        final exportService = E2EESyncService(enc);

        final assets = [
          _makeAsset(id: 'a1', name: 'SSH Key'),
          _makeAsset(id: 'a2', name: 'API Token'),
        ];
        final relations = [
          {
            'id': 'r1',
            'from_asset_id': 'a1',
            'to_asset_id': 'a2',
            'relation_type': 'uses',
          },
        ];
        final tombstones = [
          {'id': 'del-1', 'deletedAt': 9999},
        ];
        final opLog = [_makeOpLogEntry(id: 'op1', entityId: 'a1', seq: 1)];
        final attachments = [_makeAttachment(id: 'att1', assetId: 'a1')];

        final blob = exportService.packSnapshotTOCiphertext(
          assets,
          relations: relations,
          tombstones: tombstones,
          opLog: opLog,
          attachmentManifest: attachments,
        );

        // "Another platform" with identical key — simulates same password
        final importEnc = EncryptionService();
        importEnc.setMasterKey(Uint8List.fromList(enc.masterKey));
        importEnc.setSalt('dGVzdHNhbHQ=');
        final importService = E2EESyncService(importEnc);

        final snapshot = importService.unpackCiphertextToSnapshot(blob);
        expect(snapshot.assets.length, 2);
        expect(
          snapshot.assets.map((a) => a.name),
          containsAll(['SSH Key', 'API Token']),
        );
        expect(snapshot.relations.length, 1);
        expect(snapshot.tombstones.length, 1);
        expect(snapshot.tombstones.first['id'], 'del-1');
        expect(snapshot.opLog.length, 1);
        expect(snapshot.attachmentManifest.length, 1);
      },
    );

    test('different key: import fails with decryption error', () {
      final exportEnc = makeEncWithPassword('dGVzdHNhbHQ=');
      final exportService = E2EESyncService(exportEnc);
      final blob = exportService.packSnapshotTOCiphertext([
        _makeAsset(id: 'a1', name: 'Secret'),
      ]);

      final wrongEnc = EncryptionService();
      final wrongKey = Uint8List(32);
      for (int i = 0; i < 32; i++) {
        wrongKey[i] = 255 - i;
      }
      wrongEnc.setMasterKey(wrongKey);
      wrongEnc.setSalt('dGVzdHNhbHQ=');
      final importService = E2EESyncService(wrongEnc);

      expect(
        () => importService.unpackCiphertextToSnapshot(blob),
        throwsA(anything),
      );
    });

    test(
      'same key but different salt in header: extractSaltFromPayload detects mismatch',
      () {
        final encA = makeEncWithPassword('c2FsdEE='); // 'saltA'
        final encB = makeEncWithPassword('c2FsdEI='); // 'saltB'
        final serviceA = E2EESyncService(encA);

        final blob = serviceA.packSnapshotTOCiphertext([]);
        final extractedSalt = E2EESyncService.extractSaltFromPayload(blob);

        expect(extractedSalt, equals('c2FsdEE='));
        expect(extractedSalt, isNot(equals(encB.currentSaltBase64)));
      },
    );

    test('blob from export is pure AVV3 binary, not base64-wrapped', () {
      final enc = makeEncWithPassword('dGVzdHNhbHQ=');
      final service = E2EESyncService(enc);
      final blob = service.packSnapshotTOCiphertext([
        _makeAsset(id: 'a1', name: 'Test'),
      ]);

      expect(String.fromCharCodes(blob.sublist(0, 4)), 'AVV3');
      // Should NOT be valid UTF-8 text throughout (it's binary)
      final isAllAsciiPrintable = blob.every((b) => b >= 32 && b <= 126);
      expect(isAllAsciiPrintable, isFalse);
    });
  });

  // -------------------------------------------------------------------------
  // Delta pack / unpack
  // -------------------------------------------------------------------------

  group('Delta pack / unpack (AVV3)', () {
    late E2EESyncService service;

    setUp(() {
      service = E2EESyncService(_makeEncService());
    });

    test('packDelta → unpack gives delta payloadType and correct opLog', () {
      final entries = [
        _makeOpLogEntry(id: 'op1', entityId: 'a1', seq: 11),
        _makeOpLogEntry(id: 'op2', entityId: 'a2', seq: 12),
      ];
      final blob = service.packDeltaToCiphertext(
        opLogEntries: entries,
        baseSeq: 10,
      );

      // Header should be AVV3.
      expect(String.fromCharCodes(blob.sublist(0, 4)), 'AVV3');

      // PayloadType byte should be 0x01 (delta).
      final stripped = E2EESyncService.stripHeader(blob);
      expect(stripped.payloadType, 0x01);

      final snapshot = service.unpackCiphertextToSnapshot(blob);
      expect(snapshot.payloadType, 'delta');
      expect(snapshot.baseSeq, 10);
      expect(snapshot.assets, isEmpty);
      expect(snapshot.opLog.length, 2);
      expect(snapshot.opLog[0].id, 'op1');
      expect(snapshot.opLog[1].id, 'op2');
    });

    test('delta blob includes attachment manifest', () {
      final entries = [_makeOpLogEntry(id: 'op3', entityId: 'att1', seq: 5)];
      final manifest = [_makeAttachment(id: 'att1', assetId: 'a1')];
      final blob = service.packDeltaToCiphertext(
        opLogEntries: entries,
        baseSeq: 4,
        attachmentManifest: manifest,
      );

      final snapshot = service.unpackCiphertextToSnapshot(blob);
      expect(snapshot.attachmentManifest.length, 1);
      expect(snapshot.attachmentManifest.first.encFileName, 'att1.enc');
    });

    test('full snapshot payloadType byte is 0x00', () {
      final blob = service.packSnapshotTOCiphertext([]);
      final result = E2EESyncService.stripHeader(blob);
      expect(result.payloadType, 0x00);
    });
  });

  // -------------------------------------------------------------------------
  // VaultSnapshot.mergeSnapshots (LWW)
  // -------------------------------------------------------------------------

  group('VaultSnapshot.mergeSnapshots (LWW)', () {
    test('remote asset wins when updatedAt is newer', () {
      final local = VaultSnapshot(
        version: 3,
        assets: [_makeAsset(id: 'a1', name: 'Old Name', updatedAt: 1000)],
      );
      final remote = VaultSnapshot(
        version: 3,
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
        version: 3,
        assets: [_makeAsset(id: 'a1', name: 'Local Fresh', updatedAt: 5000)],
      );
      final remote = VaultSnapshot(
        version: 3,
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
        version: 3,
        assets: [_makeAsset(id: 'local-only', name: 'Local Only')],
      );
      final remote = VaultSnapshot(
        version: 3,
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
        version: 3,
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
        version: 3,
        assets: [],
        relations: [
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

      expect(merged.relations.length, 3);
      final r1 = merged.relations.firstWhere((r) => r['id'] == 'r1');
      expect(r1['relation_type'], 'hosted_on');
      final ids = merged.relations.map((r) => r['id'] as String).toSet();
      expect(ids, containsAll(['r1', 'r2', 'r3']));
    });

    test('custom asset types LWW: remote wins when newer', () {
      final localType = AssetType(
        id: 'ct1',
        name: 'Local Version',
        icon: '📁',
        fieldSchema: [],
        isBuiltIn: false,
        updatedAt: 100,
      );
      final remoteType = AssetType(
        id: 'ct1',
        name: 'Remote Version',
        icon: '🔑',
        fieldSchema: [],
        isBuiltIn: false,
        updatedAt: 200,
      );
      final uniqueType = AssetType(
        id: 'ct2',
        name: 'Unique',
        icon: '🗝',
        fieldSchema: [],
        isBuiltIn: false,
        updatedAt: 1,
      );

      final local = VaultSnapshot(
        version: 3,
        assets: [],
        customAssetTypes: [localType],
      );
      final remote = VaultSnapshot(
        version: 3,
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

    test('custom asset types LWW: local wins when newer', () {
      final localType = AssetType(
        id: 'ct1',
        name: 'Local Wins',
        icon: '📁',
        fieldSchema: [],
        isBuiltIn: false,
        updatedAt: 500,
      );
      final remoteType = AssetType(
        id: 'ct1',
        name: 'Remote Stale',
        icon: '🔑',
        fieldSchema: [],
        isBuiltIn: false,
        updatedAt: 100,
      );

      final merged = VaultSnapshot.mergeSnapshots(
        local: VaultSnapshot(
          version: 3,
          assets: [],
          customAssetTypes: [localType],
        ),
        remote: VaultSnapshot(
          version: 3,
          assets: [],
          customAssetTypes: [remoteType],
        ),
      ).snapshot;

      expect(merged.customAssetTypes.single.name, 'Local Wins');
    });

    test(
      'same timestamp but different asset content yields conflict and keeps local',
      () {
        final local = VaultSnapshot(
          version: 3,
          assets: [_makeAsset(id: 'a1', name: 'Local Name', updatedAt: 2000)],
        );
        final remote = VaultSnapshot(
          version: 3,
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
        version: 3,
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
        version: 3,
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
        version: 3,
        assets: [_makeAsset(id: 'a1', name: 'Same Time', updatedAt: 1500)],
      );
      final remote = VaultSnapshot(
        version: 3,
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
          version: 3,
          assets: const [],
          tombstones: [
            {'id': 'a1', 'deletedAt': 1000},
          ],
        );
        final remote = VaultSnapshot(
          version: 3,
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

    test('opLog entries are unioned by id and sorted by seq', () {
      final local = VaultSnapshot(
        version: 3,
        assets: [],
        opLog: [
          _makeOpLogEntry(id: 'op1', entityId: 'a1', seq: 1),
          _makeOpLogEntry(id: 'op3', entityId: 'a3', seq: 3),
        ],
      );
      final remote = VaultSnapshot(
        version: 3,
        assets: [],
        opLog: [
          _makeOpLogEntry(id: 'op2', entityId: 'a2', seq: 2),
          _makeOpLogEntry(id: 'op3', entityId: 'a3', seq: 3), // duplicate
        ],
      );

      final merged = VaultSnapshot.mergeSnapshots(
        local: local,
        remote: remote,
      ).snapshot;

      expect(merged.opLog.length, 3);
      expect(merged.opLog.map((e) => e.seq).toList(), [1, 2, 3]);
    });

    test(
      'attachment manifest is merged, tombstoned asset attachments removed',
      () {
        final local = VaultSnapshot(
          version: 3,
          assets: [_makeAsset(id: 'a1', name: 'A1', updatedAt: 1000)],
          attachmentManifest: [
            _makeAttachment(id: 'att1', assetId: 'a1'),
            _makeAttachment(id: 'att2', assetId: 'a2'),
          ],
        );
        final remote = VaultSnapshot(
          version: 3,
          assets: [],
          tombstones: [
            {'id': 'a1', 'deletedAt': 2000},
          ],
          attachmentManifest: [_makeAttachment(id: 'att3', assetId: 'a2')],
        );

        final merged = VaultSnapshot.mergeSnapshots(
          local: local,
          remote: remote,
        ).snapshot;

        // att1 belongs to tombstoned a1 → removed
        final attIds = merged.attachmentManifest.map((a) => a.id).toSet();
        expect(attIds, isNot(contains('att1')));
        expect(attIds, containsAll(['att2', 'att3']));
      },
    );
  });

  // -------------------------------------------------------------------------
  // AssetAttachment
  // -------------------------------------------------------------------------

  group('AssetAttachment', () {
    test('toJson / fromJson roundtrip', () {
      final att = AssetAttachment(
        id: 'att-id',
        assetId: 'asset-id',
        name: 'passport.pdf',
        mimeType: 'application/pdf',
        size: 204800,
        encFileName: 'att-id.enc',
        createdAt: 1_000_000,
        updatedAt: 2_000_000,
      );
      final restored = AssetAttachment.fromJson(att.toJson());
      expect(restored, equals(att));
    });

    test('copyWith changes only specified fields', () {
      final att = AssetAttachment(
        id: 'id1',
        assetId: 'a1',
        name: 'file.jpg',
        mimeType: 'image/jpeg',
        size: 512,
        encFileName: 'id1.enc',
        createdAt: 100,
        updatedAt: 200,
      );
      final updated = att.copyWith(name: 'renamed.jpg', size: 1024);
      expect(updated.name, 'renamed.jpg');
      expect(updated.size, 1024);
      expect(updated.id, 'id1');
      expect(updated.mimeType, 'image/jpeg');
    });

    test('equality is value-based', () {
      final a = AssetAttachment(
        id: 'x',
        assetId: 'y',
        name: 'f',
        mimeType: 'm',
        size: 1,
        encFileName: 'x.enc',
        createdAt: 1,
        updatedAt: 2,
      );
      final b = a.copyWith();
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });
  });
}
