import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:web/web.dart' as web;

import 'local_file_sync_service.dart';
import '../providers/assets_provider.dart';

Future<Uint8List?> pickEncFileBytes(WidgetRef ref) async {
  final localSync = ref.read(localFileSyncServiceProvider);
  return localSync.importRawBytesFromUpload();
}

Future<void> exportEncToFile(WidgetRef ref) async {
  final blob = await ref.read(assetsProvider.notifier).packFullExportBlob();

  final b64 = base64.encode(blob);
  final dataUri = 'data:application/octet-stream;base64,$b64';

  final anchor = web.HTMLAnchorElement()
    ..href = dataUri
    ..download = 'octarq_vault_backup.enc';

  web.document.body!.appendChild(anchor);
  anchor.click();
  web.document.body!.removeChild(anchor);
}
