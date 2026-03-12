import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'local_file_sync_service.dart';
import '../providers/assets_provider.dart';
import '../providers/asset_types_provider.dart';

Future<Uint8List?> pickEncFileBytes(WidgetRef ref) async {
  final localSync = ref.read(localFileSyncServiceProvider);
  return localSync.importRawBytesFromUpload();
}

Future<void> exportEncToFile(WidgetRef ref) async {
  final assets = ref.read(assetsProvider);
  final customTypes = ref
      .read(assetTypesProvider)
      .where((t) => !t.isBuiltIn)
      .toList();
  ref
      .read(localFileSyncServiceProvider)
      .exportToDownload(assets, customAssetTypes: customTypes);
}
