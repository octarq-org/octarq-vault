// Native (iOS / Android / desktop) implementation of iCloud sync helpers.
// On iOS, the Documents directory is backed up via iCloud Backup.
// For active iCloud Drive sync the user must have iCloud Drive enabled.

import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

const String _fileName = 'octarq_vault.enc';
const String _legacyFileName = 'asset_vault.enc';

Future<File> _vaultFile() async {
  final dir = await getApplicationDocumentsDirectory();
  // Migrate legacy filename if needed (idempotent).
  final legacy = File('${dir.path}/$_legacyFileName');
  final current = File('${dir.path}/$_fileName');
  if (await legacy.exists() && !await current.exists()) {
    await legacy.rename(current.path);
  }
  return current;
}

Future<void> backup(Uint8List encryptedBlob) async {
  final file = await _vaultFile();
  await file.writeAsBytes(encryptedBlob, flush: true);
  if (kDebugMode) print('ICloudSyncService: backup written to ${file.path}');
}

Future<Uint8List?> restore() async {
  final file = await _vaultFile();
  if (!file.existsSync()) return null;
  final bytes = await file.readAsBytes();
  return bytes.isEmpty ? null : Uint8List.fromList(bytes);
}

Future<bool> hasBackup() async {
  final file = await _vaultFile();
  return file.existsSync();
}
