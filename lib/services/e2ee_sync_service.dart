import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'encryption_service.dart';
import '../providers/service_providers.dart';
import '../models/asset.dart';
import '../models/asset_type.dart';
import '../models/attachment.dart';

final e2eeSyncServiceProvider = Provider<E2EESyncService>((ref) {
  return E2EESyncService(ref.read(encryptionServiceProvider));
});

// ---------------------------------------------------------------------------
// OpLog
// ---------------------------------------------------------------------------

/// Operation types recorded in the op-log.
enum OpType {
  upsert,
  delete;

  String toJson() => name;
  static OpType fromJson(String s) => values.byName(s);
}

/// Entity types tracked by the op-log.
enum OpEntityType {
  asset,
  assetType,
  relation,
  attachment,
  tag,
  assetTag,
  reminder;

  String toJson() => name;
  static OpEntityType fromJson(String s) => values.byName(s);
}

/// A single entry in the append-only operation log.
///
/// Each write operation (create, update, delete) on any tracked entity
/// produces one [OpLogEntry]. Entries are ordered by [seq], an
/// auto-incremented integer assigned by [DatabaseService].
class OpLogEntry {
  /// UUID assigned at creation time (used for cross-device deduplication).
  final String id;

  final OpType op;
  final OpEntityType entityType;

  /// The UUID of the affected entity.
  final String entityId;

  /// Full serialised entity for [OpType.upsert]; `null` for [OpType.delete].
  final Map<String, dynamic>? payload;

  /// Monotonically increasing local sequence number (assigned by the DB).
  /// Value is 0 when not yet persisted.
  final int seq;

  final int createdAt;

  const OpLogEntry({
    required this.id,
    required this.op,
    required this.entityType,
    required this.entityId,
    this.payload,
    this.seq = 0,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'op': op.toJson(),
    'entityType': entityType.toJson(),
    'entityId': entityId,
    if (payload != null) 'payload': payload,
    'seq': seq,
    'createdAt': createdAt,
  };

  factory OpLogEntry.fromJson(Map<String, dynamic> json) => OpLogEntry(
    id: json['id'] as String,
    op: OpType.fromJson(json['op'] as String),
    entityType: OpEntityType.fromJson(json['entityType'] as String),
    entityId: json['entityId'] as String,
    payload: json['payload'] != null
        ? Map<String, dynamic>.from(json['payload'] as Map)
        : null,
    seq: (json['seq'] as num? ?? 0).toInt(),
    createdAt: (json['createdAt'] as num).toInt(),
  );

  @override
  String toString() =>
      'OpLogEntry(id: $id, op: $op, entityType: $entityType, '
      'entityId: $entityId, seq: $seq)';
}

// ---------------------------------------------------------------------------
// Conflict
// ---------------------------------------------------------------------------

/// A pair of conflicting asset versions (same id, same updatedAt, different
/// content) detected during LWW merge. The caller can present a UI to resolve.
class AssetConflict {
  final Asset local;
  final Asset remote;
  const AssetConflict({required this.local, required this.remote});
}

// ---------------------------------------------------------------------------
// VaultSnapshot
// ---------------------------------------------------------------------------

/// Describes the plaintext payload exchanged between devices.
///
/// [payloadType] distinguishes full snapshots from delta (op-log-only)
/// payloads:
/// - `'full'`: contains the complete [assets], [customAssetTypes],
///   [relations], [tombstones], and optionally [opLog] / [attachmentManifest].
/// - `'delta'`: [assets] is empty; only [opLog] carries the mutations since
///   [baseSeq].
class VaultSnapshot {
  final int version;

  /// `'full'` or `'delta'`.
  final String payloadType;

  /// For delta payloads: the sequence number of the last entry the sender
  /// already knows the receiver has. Receivers should only apply entries with
  /// [OpLogEntry.seq] > [baseSeq].
  final int baseSeq;

  final List<Asset> assets;
  final List<AssetType> customAssetTypes;

  /// Asset-to-asset relations: each map has keys id, from_asset_id,
  /// to_asset_id, relation_type.
  final List<Map<String, dynamic>> relations;

  /// Tombstones: soft-deleted asset IDs and their deletion timestamp (ms since
  /// epoch). Format: [{id: String, deletedAt: int}]
  final List<Map<String, dynamic>> tombstones;

  /// Operation log entries included in this payload.
  ///
  /// Full snapshots may include recent entries for newly joining peers.
  /// Delta snapshots carry only the new entries since [baseSeq].
  final List<OpLogEntry> opLog;

  /// Metadata for all attachments the sender owns.
  /// Receivers use this to discover which blobs to download.
  final List<AssetAttachment> attachmentManifest;

  VaultSnapshot({
    required this.version,
    this.payloadType = 'full',
    this.baseSeq = 0,
    required this.assets,
    this.customAssetTypes = const [],
    this.relations = const [],
    this.tombstones = const [],
    this.opLog = const [],
    this.attachmentManifest = const [],
  });

  /// Returns the maximum updatedAt among assets, tombstones, and custom types.
  int get updatedAt {
    int maxTs = 0;
    for (final a in assets) {
      if (a.updatedAt > maxTs) maxTs = a.updatedAt;
    }
    for (final t in tombstones) {
      final ts = t['deletedAt'] as int? ?? 0;
      if (ts > maxTs) maxTs = ts;
    }
    for (final ct in customAssetTypes) {
      if (ct.updatedAt > maxTs) maxTs = ct.updatedAt;
    }
    return maxTs;
  }

  Map<String, dynamic> toJson() => {
    'version': version,
    'payloadType': payloadType,
    'baseSeq': baseSeq,
    'assets': assets.map((a) => a.toJson()).toList(),
    'customAssetTypes': customAssetTypes.map((t) => t.toJson()).toList(),
    'relations': relations,
    'tombstones': tombstones,
    'opLog': opLog.map((e) => e.toJson()).toList(),
    'attachmentManifest': attachmentManifest.map((a) => a.toJson()).toList(),
  };

  factory VaultSnapshot.fromJson(Map<String, dynamic> json) {
    return VaultSnapshot(
      version: json['version'] as int? ?? 3,
      payloadType: json['payloadType'] as String? ?? 'full',
      baseSeq: (json['baseSeq'] as num? ?? 0).toInt(),
      assets:
          (json['assets'] as List<dynamic>?)
              ?.map((e) => Asset.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      customAssetTypes:
          (json['customAssetTypes'] as List<dynamic>?)
              ?.map((e) => AssetType.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      relations:
          (json['relations'] as List<dynamic>?)
              ?.map((e) => Map<String, dynamic>.from(e as Map))
              .toList() ??
          [],
      tombstones:
          (json['tombstones'] as List<dynamic>?)
              ?.map((e) => Map<String, dynamic>.from(e as Map))
              .toList() ??
          [],
      opLog:
          (json['opLog'] as List<dynamic>?)
              ?.map((e) => OpLogEntry.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      attachmentManifest:
          (json['attachmentManifest'] as List<dynamic>?)
              ?.map((e) => AssetAttachment.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  // -------------------------------------------------------------------------
  // Merge
  // -------------------------------------------------------------------------

  /// Last-Write-Wins merge: merge [remote] into [local].
  ///
  /// Assets: the version with the larger `updatedAt` wins per id.
  ///   - Tombstone-aware: if a tombstone for an asset exists with
  ///     `deletedAt > asset.updatedAt`, the asset is omitted.
  ///   - Conflict detection: when local.updatedAt == remote.updatedAt but
  ///     content differs, the pair is returned in [conflicts].
  /// Relations: union by id (remote wins on conflict).
  /// Custom asset types: LWW by [AssetType.updatedAt] per id (tie keeps local).
  /// Tombstones: union by id, newest deletedAt wins.
  /// OpLog: union by entry id; entries are sorted by seq.
  /// AttachmentManifest: union by attachment id (remote wins on conflict).
  static ({VaultSnapshot snapshot, List<AssetConflict> conflicts})
  mergeSnapshots({
    required VaultSnapshot local,
    required VaultSnapshot remote,
  }) {
    // --- Tombstones: union, keep newest deletedAt per id ---
    final Map<String, int> tombstoneMap = {
      for (final t in local.tombstones)
        t['id'] as String: t['deletedAt'] as int,
    };
    for (final t in remote.tombstones) {
      final id = t['id'] as String;
      final deletedAt = t['deletedAt'] as int;
      if (!tombstoneMap.containsKey(id) || deletedAt > tombstoneMap[id]!) {
        tombstoneMap[id] = deletedAt;
      }
    }

    // --- Assets: LWW by updatedAt, tombstone-aware ---
    final Map<String, Asset> merged = {for (final a in local.assets) a.id: a};
    final conflicts = <AssetConflict>[];

    for (final remoteAsset in remote.assets) {
      final localAsset = merged[remoteAsset.id];
      if (localAsset == null) {
        merged[remoteAsset.id] = remoteAsset;
      } else if (remoteAsset.updatedAt > localAsset.updatedAt) {
        merged[remoteAsset.id] = remoteAsset;
      } else if (remoteAsset.updatedAt == localAsset.updatedAt) {
        if (remoteAsset.toJson().toString() != localAsset.toJson().toString()) {
          conflicts.add(AssetConflict(local: localAsset, remote: remoteAsset));
        }
        // Keep local on tie — user will be prompted to resolve conflicts
      }
    }

    // Apply tombstones: remove any asset whose tombstone deletedAt is newer.
    tombstoneMap.forEach((id, deletedAt) {
      final asset = merged[id];
      if (asset != null && deletedAt > asset.updatedAt) {
        merged.remove(id);
      }
    });

    // --- Relations: union by id ---
    final Map<String, Map<String, dynamic>> mergedRelations = {
      for (final r in local.relations) r['id'] as String: r,
    };
    for (final r in remote.relations) {
      mergedRelations[r['id'] as String] = r;
    }
    mergedRelations.removeWhere(
      (_, r) =>
          tombstoneMap.containsKey(r['from_asset_id']) ||
          tombstoneMap.containsKey(r['to_asset_id']),
    );

    // --- Custom asset types: LWW by updatedAt ---
    final Map<String, AssetType> mergedTypes = {
      for (final t in local.customAssetTypes) t.id: t,
    };
    for (final t in remote.customAssetTypes) {
      final localT = mergedTypes[t.id];
      if (localT == null) {
        mergedTypes[t.id] = t;
      } else if (t.updatedAt > localT.updatedAt) {
        mergedTypes[t.id] = t;
      }
    }

    final mergedTombstones = tombstoneMap.entries
        .map((e) => {'id': e.key, 'deletedAt': e.value})
        .toList();

    // --- OpLog: union by entry id, sort by seq ---
    final Map<String, OpLogEntry> mergedOpLog = {
      for (final e in local.opLog) e.id: e,
    };
    for (final e in remote.opLog) {
      mergedOpLog[e.id] = e;
    }
    final sortedOpLog = mergedOpLog.values.toList()
      ..sort((a, b) => a.seq.compareTo(b.seq));

    // --- Attachment manifest: union by id, remote wins ---
    final Map<String, AssetAttachment> mergedAttachments = {
      for (final a in local.attachmentManifest) a.id: a,
    };
    for (final a in remote.attachmentManifest) {
      mergedAttachments[a.id] = a;
    }
    // Remove attachment metadata for tombstoned assets.
    mergedAttachments.removeWhere(
      (_, a) => tombstoneMap.containsKey(a.assetId),
    );

    return (
      snapshot: VaultSnapshot(
        version: 3,
        assets: merged.values.toList(),
        customAssetTypes: mergedTypes.values.toList(),
        relations: mergedRelations.values.toList(),
        tombstones: mergedTombstones,
        opLog: sortedOpLog,
        attachmentManifest: mergedAttachments.values.toList(),
      ),
      conflicts: conflicts,
    );
  }
}

// ---------------------------------------------------------------------------
// AVV3 binary format
// ---------------------------------------------------------------------------
//
//  ┌─────────────────────────────────────────────────────┐
//  │ Magic  "AVV3"        4 bytes  (UTF-8)               │
//  │ SaltLen              2 bytes  (big-endian uint16)   │
//  │ Salt                 N bytes  (base64 UTF-8)        │
//  │ PayloadType          1 byte   (0x00=full 0x01=delta)│
//  │ IV                  12 bytes  (AES-GCM nonce)       │
//  │ Ciphertext + MAC     ≥ 17 bytes                     │
//  └─────────────────────────────────────────────────────┘

// ---------------------------------------------------------------------------
// E2EESyncService
// ---------------------------------------------------------------------------

/// Gateway between plaintext vault state and AVV3-encrypted binary blobs.
class E2EESyncService {
  final EncryptionService _encryptionService;

  static const String _magicHeader = 'AVV3';
  static const int _headerMagicLen = 4;
  static const int _headerSaltLenFieldLen = 2;
  static const int _payloadTypeByte = 1;

  // Payload type constants stored in the AVV3 header.
  static const int _ptFull = 0x00;
  static const int _ptDelta = 0x01;

  E2EESyncService(this._encryptionService);

  // -------------------------------------------------------------------------
  // Header helpers
  // -------------------------------------------------------------------------

  /// Extracts the base64 salt from an AVV3 payload, or `null` if invalid.
  static String? extractSaltFromPayload(Uint8List payload) {
    if (payload.length < _headerMagicLen + _headerSaltLenFieldLen) return null;
    try {
      final header = utf8.decode(
        payload.sublist(0, _headerMagicLen),
        allowMalformed: true,
      );
      if (header != _magicHeader) return null;

      final saltLen =
          (payload[_headerMagicLen] << 8) | payload[_headerMagicLen + 1];
      if (payload.length < _headerMagicLen + _headerSaltLenFieldLen + saltLen) {
        return null;
      }
      final saltBytes = payload.sublist(
        _headerMagicLen + _headerSaltLenFieldLen,
        _headerMagicLen + _headerSaltLenFieldLen + saltLen,
      );
      return utf8.decode(saltBytes, allowMalformed: true);
    } catch (_) {
      return null;
    }
  }

  /// Strips the AVV3 header, returning `(payloadTypeFlag, encryptedBytes)`.
  ///
  /// Returns `(null, payload)` if the header is absent or invalid.
  static ({int? payloadType, Uint8List encrypted}) stripHeader(
    Uint8List payload,
  ) {
    if (payload.length < _headerMagicLen + _headerSaltLenFieldLen) {
      return (payloadType: null, encrypted: payload);
    }
    try {
      final header = utf8.decode(
        payload.sublist(0, _headerMagicLen),
        allowMalformed: true,
      );
      if (header != _magicHeader) {
        return (payloadType: null, encrypted: payload);
      }

      final saltLen =
          (payload[_headerMagicLen] << 8) | payload[_headerMagicLen + 1];
      final afterSalt = _headerMagicLen + _headerSaltLenFieldLen + saltLen;
      if (payload.length <= afterSalt) {
        return (payloadType: null, encrypted: payload);
      }

      final ptByte = payload[afterSalt];
      final encrypted = payload.sublist(afterSalt + _payloadTypeByte);
      return (payloadType: ptByte, encrypted: encrypted);
    } catch (_) {
      return (payloadType: null, encrypted: payload);
    }
  }

  // -------------------------------------------------------------------------
  // Pack helpers
  // -------------------------------------------------------------------------

  Uint8List _buildPayload(
    Uint8List plainBytes, {
    required int payloadTypeFlag,
  }) {
    final cipherBytes = _encryptionService.encryptBytes(plainBytes);
    final currentSalt = _encryptionService.currentSaltBase64;
    final saltBytes = utf8.encode(currentSalt);

    final List<int> out = [];
    out.addAll(utf8.encode(_magicHeader));
    final saltLen = saltBytes.length;
    out.add((saltLen >> 8) & 0xFF);
    out.add(saltLen & 0xFF);
    out.addAll(saltBytes);
    out.add(payloadTypeFlag & 0xFF);
    out.addAll(cipherBytes);
    return Uint8List.fromList(out);
  }

  // -------------------------------------------------------------------------
  // Public API: pack
  // -------------------------------------------------------------------------

  /// Serialises and encrypts the full vault state into an AVV3 blob.
  ///
  /// Optionally includes recent [opLog] entries and [attachmentManifest] so
  /// that peers joining for the first time can catch up without a separate
  /// delta exchange.
  Uint8List packSnapshotTOCiphertext(
    List<Asset> assets, {
    List<AssetType> customAssetTypes = const [],
    List<Map<String, dynamic>> relations = const [],
    List<Map<String, dynamic>> tombstones = const [],
    List<OpLogEntry> opLog = const [],
    List<AssetAttachment> attachmentManifest = const [],
  }) {
    final snapshot = VaultSnapshot(
      version: 3,
      payloadType: 'full',
      assets: assets,
      customAssetTypes: customAssetTypes,
      relations: relations,
      tombstones: tombstones,
      opLog: opLog,
      attachmentManifest: attachmentManifest,
    );
    final plainBytes = utf8.encode(jsonEncode(snapshot.toJson()));
    return _buildPayload(plainBytes, payloadTypeFlag: _ptFull);
  }

  /// Serialises and encrypts a delta payload (op-log entries only) into an
  /// AVV3 blob.
  ///
  /// [baseSeq] is the sequence number of the last entry already acknowledged
  /// by the target peer; all entries in [opLogEntries] should have
  /// `seq > baseSeq`.
  Uint8List packDeltaToCiphertext({
    required List<OpLogEntry> opLogEntries,
    required int baseSeq,
    List<AssetAttachment> attachmentManifest = const [],
  }) {
    final snapshot = VaultSnapshot(
      version: 3,
      payloadType: 'delta',
      baseSeq: baseSeq,
      assets: const [],
      opLog: opLogEntries,
      attachmentManifest: attachmentManifest,
    );
    final plainBytes = utf8.encode(jsonEncode(snapshot.toJson()));
    return _buildPayload(plainBytes, payloadTypeFlag: _ptDelta);
  }

  // -------------------------------------------------------------------------
  // Public API: unpack
  // -------------------------------------------------------------------------

  /// Decrypts an AVV3 blob and deserialises it into a [VaultSnapshot].
  ///
  /// Inspect [VaultSnapshot.payloadType] to determine whether the result is
  /// a full snapshot (`'full'`) or a delta (`'delta'`).
  VaultSnapshot unpackCiphertextToSnapshot(Uint8List encryptedPayload) {
    final stripped = stripHeader(encryptedPayload);
    final plainBytes = _encryptionService.decryptBytes(stripped.encrypted);
    final jsonString = utf8.decode(plainBytes);
    final dynamic jsonMap = jsonDecode(jsonString);
    return VaultSnapshot.fromJson(jsonMap as Map<String, dynamic>);
  }
}
