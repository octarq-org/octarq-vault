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
  // Placeholder for future relations and custom asset types
  final List<AssetType> customAssetTypes;

  VaultSnapshot({
    required this.version,
    required this.assets,
    this.customAssetTypes = const [],
  });

  Map<String, dynamic> toJson() => {
    'version': version,
    'assets': assets.map((a) => a.toJson()).toList(),
    'customAssetTypes': customAssetTypes.map((t) => t.toJson()).toList(),
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
  }) {
    final snapshot = VaultSnapshot(
      version: 2,
      assets: assets,
      customAssetTypes: customAssetTypes,
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
