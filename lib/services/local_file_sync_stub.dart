import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'e2ee_sync_service.dart';
import '../models/asset.dart';
import '../models/asset_type.dart';

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
  }) async {}

  Future<Uint8List?> readRawBytesFromLocal() async {
    return null;
  }

  Future<VaultSnapshot?> readFromLocal() async {
    return null;
  }

  void exportToDownload(
    List<Asset> assets, {
    List<AssetType> customAssetTypes = const [],
  }) {}

  Future<Uint8List?> importRawBytesFromUpload() async {
    return null;
  }

  Future<VaultSnapshot?> importFromUpload() async {
    return null;
  }
}
