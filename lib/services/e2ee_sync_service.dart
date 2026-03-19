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

/// Describes the plaintext payload snapshot structure
class VaultSnapshot {
  final int version;
  final List<Asset> assets;
  final List<AssetType> customAssetTypes;

  /// Asset-to-asset relations: each map has keys id, from_asset_id,
  /// to_asset_id, relation_type.
  final List<Map<String, dynamic>> relations;

  VaultSnapshot({
    required this.version,
    required this.assets,
    this.customAssetTypes = const [],
    this.relations = const [],
  });

  Map<String, dynamic> toJson() => {
    'version': version,
    'assets': assets.map((a) => a.toJson()).toList(),
    'customAssetTypes': customAssetTypes.map((t) => t.toJson()).toList(),
    'relations': relations,
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
    );
  }

  /// Last-Write-Wins merge: merge [remote] into [local].
  ///
  /// Assets: the version with the larger `updatedAt` wins per id.
  /// Relations: union by id (if same id, keep remote as source of truth).
  /// Custom asset types: union by id (remote wins on conflict).
  static VaultSnapshot mergeSnapshots({
    required VaultSnapshot local,
    required VaultSnapshot remote,
  }) {
    // --- Assets: LWW by updatedAt ---
    final Map<String, Asset> merged = {for (final a in local.assets) a.id: a};
    for (final remoteAsset in remote.assets) {
      final localAsset = merged[remoteAsset.id];
      if (localAsset == null || remoteAsset.updatedAt >= localAsset.updatedAt) {
        merged[remoteAsset.id] = remoteAsset;
      }
    }

    // --- Relations: union by id ---
    final Map<String, Map<String, dynamic>> mergedRelations = {
      for (final r in local.relations) r['id'] as String: r,
    };
    for (final r in remote.relations) {
      mergedRelations[r['id'] as String] = r;
    }

    // --- Custom asset types: union by id, remote wins ---
    final Map<String, AssetType> mergedTypes = {
      for (final t in local.customAssetTypes) t.id: t,
    };
    for (final t in remote.customAssetTypes) {
      mergedTypes[t.id] = t;
    }

    return VaultSnapshot(
      version: 2,
      assets: merged.values.toList(),
      customAssetTypes: mergedTypes.values.toList(),
      relations: mergedRelations.values.toList(),
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
  }) {
    final snapshot = VaultSnapshot(
      version: 2,
      assets: assets,
      customAssetTypes: customAssetTypes,
      relations: relations,
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
        print('unpackCiphertextToSnapshot Failed: $e');
      }
      rethrow;
    }
  }
}
