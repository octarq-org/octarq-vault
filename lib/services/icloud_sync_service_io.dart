// Native (iOS / Android / desktop) implementation of iCloud sync helpers.
// On iOS the Documents directory is backed up via iCloud Backup.
// For active iCloud Drive sync the user must have iCloud Drive enabled.
//
// Attachments are stored in a sibling directory:
// `<Documents>/octarq_attachments/<uuid>.enc`

import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import '../models/attachment.dart';

const String _fileName = 'octarq_vault.enc';
const String _legacyFileName = 'asset_vault.enc';
const String _attachmentDirName = 'octarq_attachments';

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

Future<Directory> _attachmentsDir() async {
  final docs = await getApplicationDocumentsDirectory();
  final dir = Directory('${docs.path}/$_attachmentDirName');
  if (!dir.existsSync()) dir.createSync(recursive: true);
  return dir;
}

// -------------------------------------------------------------------------
// Snapshot backup / restore
// -------------------------------------------------------------------------

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

// -------------------------------------------------------------------------
// Attachment backup / restore
// -------------------------------------------------------------------------

/// Writes [encBytes] to `<Documents>/octarq_attachments/<encFileName>`.
Future<void> backupAttachment(
  AssetAttachment attachment,
  Uint8List encBytes,
) async {
  final dir = await _attachmentsDir();
  final file = File('${dir.path}/${attachment.encFileName}');
  await file.writeAsBytes(encBytes, flush: true);
  if (kDebugMode) {
    print('ICloudSyncService: attachment ${attachment.encFileName} backed up.');
  }
}

/// Reads and returns raw encrypted bytes for [attachment], or `null`.
Future<Uint8List?> restoreAttachment(AssetAttachment attachment) async {
  final dir = await _attachmentsDir();
  final file = File('${dir.path}/${attachment.encFileName}');
  if (!file.existsSync()) return null;
  final bytes = await file.readAsBytes();
  return bytes.isEmpty ? null : Uint8List.fromList(bytes);
}

/// Returns `true` if the attachment blob exists in the backup directory.
Future<bool> attachmentBackupExists(AssetAttachment attachment) async {
  final dir = await _attachmentsDir();
  return File('${dir.path}/${attachment.encFileName}').existsSync();
}

/// Removes the attachment blob from the backup directory.
Future<void> deleteAttachmentBackup(AssetAttachment attachment) async {
  final dir = await _attachmentsDir();
  final file = File('${dir.path}/${attachment.encFileName}');
  if (file.existsSync()) await file.delete();
}
