import 'dart:io';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'e2ee_sync_service.dart';
import '../providers/assets_provider.dart';
import '../providers/asset_types_provider.dart';

Future<Uint8List?> pickEncFileBytes(WidgetRef ref) async {
  final result = await FilePicker.platform.pickFiles(
    type: FileType.any,
    allowMultiple: false,
    withData: true,
  );
  if (result == null || result.files.isEmpty) return null;
  final file = result.files.single;
  if (file.bytes != null) return file.bytes;
  if (file.path != null) {
    final f = File(file.path!);
    if (await f.exists()) return await f.readAsBytes();
  }
  return null;
}

Future<void> exportEncToFile(WidgetRef ref) async {
  final path = await FilePicker.platform.saveFile(
    dialogTitle: 'Export encrypted backup',
    fileName: 'asset_vault_backup.enc',
    type: FileType.any,
  );
  if (path == null || path.isEmpty) return;

  final syncService = ref.read(e2eeSyncServiceProvider);
  final assets = ref.read(assetsProvider);
  final customTypes = ref
      .read(assetTypesProvider)
      .where((t) => !t.isBuiltIn)
      .toList();
  final blob = syncService.packSnapshotTOCiphertext(
    assets,
    customAssetTypes: customTypes,
  );
  await File(path).writeAsBytes(blob);
}
