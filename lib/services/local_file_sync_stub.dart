import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'e2ee_sync_service.dart';
import '../models/asset.dart';
import '../models/asset_type.dart';
import '../models/attachment.dart';

final localFileSyncServiceProvider = Provider<LocalFileSyncService>((ref) {
  return LocalFileSyncService(ref.read(e2eeSyncServiceProvider));
});

/// Stub implementation for non-web platforms.
class LocalFileSyncService {
  LocalFileSyncService(E2EESyncService _);

  bool get isSupported => false;
  bool get hasActiveHandle => false;

  Future<void> linkFileForSync({bool createNew = false}) async {}

  Future<void> syncToLocal(
    List<Asset> assets, {
    List<AssetType> customAssetTypes = const [],
    List<Map<String, dynamic>> tombstones = const [],
    List<Map<String, dynamic>> relations = const [],
    List<OpLogEntry> opLog = const [],
    List<AssetAttachment> attachmentManifest = const [],
  }) async {}

  Future<void> syncDeltaToLocal({
    required List<OpLogEntry> opLogEntries,
    required int baseSeq,
    List<AssetAttachment> attachmentManifest = const [],
  }) async {}

  Future<Uint8List?> readRawBytesFromLocal() async => null;

  Future<VaultSnapshot?> readFromLocal() async => null;

  void exportToDownload(
    List<Asset> assets, {
    List<AssetType> customAssetTypes = const [],
    List<Map<String, dynamic>> tombstones = const [],
    List<Map<String, dynamic>> relations = const [],
    List<OpLogEntry> opLog = const [],
    List<AssetAttachment> attachmentManifest = const [],
  }) {}

  Future<Uint8List?> importRawBytesFromUpload() async => null;

  Future<VaultSnapshot?> importFromUpload() async => null;
}
