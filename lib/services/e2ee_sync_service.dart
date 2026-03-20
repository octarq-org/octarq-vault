import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'encryption_service.dart';
import '../providers/service_providers.dart';
import '../models/asset.dart';
import '../models/asset_type.dart';

final e2eeSyncServiceProvider = Provider<E2EESyncService>((ref) {
  return E2EESyncService(ref.read(encryptionServiceProvider));
});

/// A pair of conflicting asset versions (same id, same updatedAt, different
/// content) detected during LWW merge. The caller can present a UI to resolve.
class AssetConflict {
  final Asset local;
  final Asset remote;
  const AssetConflict({required this.local, required this.remote});
}

/// Describes the plaintext payload snapshot structure
class VaultSnapshot {
  final int version;
  final List<Asset> assets;
  final List<AssetType> customAssetTypes;

  /// Asset-to-asset relations: each map has keys id, from_asset_id,
  /// to_asset_id, relation_type.
  final List<Map<String, dynamic>> relations;

  /// Tombstones: soft-deleted asset IDs and their deletion timestamp (ms since
  /// epoch). Format: [{id: String, deletedAt: int}]
  final List<Map<String, dynamic>> tombstones;

  VaultSnapshot({
    required this.version,
    required this.assets,
    this.customAssetTypes = const [],
    this.relations = const [],
    this.tombstones = const [],
  });

  Map<String, dynamic> toJson() => {
    'version': version,
    'assets': assets.map((a) => a.toJson()).toList(),
    'customAssetTypes': customAssetTypes.map((t) => t.toJson()).toList(),
    'relations': relations,
    'tombstones': tombstones,
  };

  factory VaultSnapshot.fromJson(Map<String, dynamic> json) {
    return VaultSnapshot(
      version: json['version'] as int? ?? 1,
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
    );
  }

  /// Last-Write-Wins merge: merge [remote] into [local].
  ///
  /// Assets: the version with the larger `updatedAt` wins per id.
  ///   - Tombstone-aware: if a tombstone for an asset exists with
  ///     `deletedAt > asset.updatedAt`, the asset is omitted (deletion wins).
  ///   - Conflict detection: when local.updatedAt == remote.updatedAt but
  ///     content differs, the pair is returned in [conflicts].
  /// Relations: union by id (if same id, keep remote as source of truth).
  /// Custom asset types: union by id (remote wins on conflict).
  /// Tombstones: union by id, newest deletedAt wins.
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
        // Detect conflict: same timestamp but different serialized content
        if (remoteAsset.toJson().toString() != localAsset.toJson().toString()) {
          conflicts.add(AssetConflict(local: localAsset, remote: remoteAsset));
        }
        // Keep local on tie — user will be prompted to resolve conflicts
      }
      // else localAsset is newer — keep it (nothing to do)
    }

    // Apply tombstones: remove any asset whose tombstone deletedAt is newer
    // than the asset's own updatedAt.
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
    // Remove relations that reference tombstoned assets
    mergedRelations.removeWhere(
      (_, r) =>
          tombstoneMap.containsKey(r['from_asset_id']) ||
          tombstoneMap.containsKey(r['to_asset_id']),
    );

    // --- Custom asset types: union by id, remote wins ---
    final Map<String, AssetType> mergedTypes = {
      for (final t in local.customAssetTypes) t.id: t,
    };
    for (final t in remote.customAssetTypes) {
      mergedTypes[t.id] = t;
    }

    final mergedTombstones = tombstoneMap.entries
        .map((e) => {'id': e.key, 'deletedAt': e.value})
        .toList();

    return (
      snapshot: VaultSnapshot(
        version: 2,
        assets: merged.values.toList(),
        customAssetTypes: mergedTypes.values.toList(),
        relations: mergedRelations.values.toList(),
        tombstones: mergedTombstones,
      ),
      conflicts: conflicts,
    );
  }
}

/// The core Gateway for transforming Plaintext State -> E2EE Encrypted Blob -> Plaintext State
class E2EESyncService {
  final EncryptionService _encryptionService;

  static const String _v2MagicHeader = 'AVV2';

  E2EESyncService(this._encryptionService);

  /// Extracts the salt from a V2 payload, returning base64 Salt or null if legacy/invalid.
  static String? extractSaltFromPayload(Uint8List payload) {
    if (payload.length < 6) return null;
    try {
      final header = utf8.decode(payload.sublist(0, 4), allowMalformed: true);
      if (header != _v2MagicHeader) return null;

      final saltLen = (payload[4] << 8) | payload[5];
      if (payload.length < 6 + saltLen) return null;

      final saltBytes = payload.sublist(6, 6 + saltLen);
      return utf8.decode(saltBytes, allowMalformed: true);
    } catch (_) {
      return null;
    }
  }

  /// Extracts the raw encrypted payload (Ciphertext) stripping the AVV2 header.
  static Uint8List stripHeader(Uint8List payload) {
    if (payload.length < 6) return payload;
    try {
      final header = utf8.decode(payload.sublist(0, 4), allowMalformed: true);
      if (header != _v2MagicHeader) return payload; // Legacy V1 (no header)

      final saltLen = (payload[4] << 8) | payload[5];
      if (payload.length < 6 + saltLen) return payload; // Invalid

      return payload.sublist(6 + saltLen);
    } catch (_) {
      return payload;
    }
  }

  /// Takes current state, serializes to JSON, and encrypts the entire JSON bytes
  Uint8List packSnapshotTOCiphertext(
    List<Asset> assets, {
    List<AssetType> customAssetTypes = const [],
    List<Map<String, dynamic>> relations = const [],
    List<Map<String, dynamic>> tombstones = const [],
  }) {
    final snapshot = VaultSnapshot(
      version: 2,
      assets: assets,
      customAssetTypes: customAssetTypes,
      relations: relations,
      tombstones: tombstones,
    );
    final snapshotJson = jsonEncode(snapshot.toJson());
    final plainBytes = utf8.encode(snapshotJson);

    // Encrypt via AES-GCM
    final cipherBytes = _encryptionService.encryptBytes(plainBytes);

    // Get current salt
    final currentSalt = _encryptionService.currentSaltBase64;
    final saltBytes = utf8.encode(currentSalt);

    // Build V2 Payload
    final List<int> payload = [];
    payload.addAll(utf8.encode(_v2MagicHeader));
    final saltLen = saltBytes.length;
    payload.add((saltLen >> 8) & 0xFF);
    payload.add(saltLen & 0xFF);
    payload.addAll(saltBytes);
    payload.addAll(cipherBytes);

    return Uint8List.fromList(payload);
  }

  /// Takes an encrypted binary blob, decrypts to JSON bytes, and deserializes back to State Objects
  VaultSnapshot unpackCiphertextToSnapshot(Uint8List encryptedPayload) {
    try {
      final strippedPayload = stripHeader(encryptedPayload);
      final plainBytes = _encryptionService.decryptBytes(strippedPayload);
      final jsonString = utf8.decode(plainBytes);
      final dynamic jsonMap = jsonDecode(jsonString);
      return VaultSnapshot.fromJson(jsonMap as Map<String, dynamic>);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('unpackCiphertextToSnapshot Failed: $e');
      }
      rethrow;
    }
  }
}
