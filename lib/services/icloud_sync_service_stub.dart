// Web stub — iCloud sync is not supported on Web.
// All methods throw; callers must check ICloudSyncService.isSupported first.

import 'dart:typed_data';

import '../models/attachment.dart';

Future<void> backup(Uint8List encryptedBlob) async {
  throw UnsupportedError('iCloud sync is not supported on Web.');
}

Future<Uint8List?> restore() async {
  throw UnsupportedError('iCloud sync is not supported on Web.');
}

Future<bool> hasBackup() async => false;

Future<void> backupAttachment(
  AssetAttachment attachment,
  Uint8List encBytes,
) async {
  throw UnsupportedError('iCloud sync is not supported on Web.');
}

Future<Uint8List?> restoreAttachment(AssetAttachment attachment) async {
  throw UnsupportedError('iCloud sync is not supported on Web.');
}

Future<bool> attachmentBackupExists(AssetAttachment attachment) async => false;

Future<void> deleteAttachmentBackup(AssetAttachment attachment) async {
  throw UnsupportedError('iCloud sync is not supported on Web.');
}

Future<bool> checkIsSupported() async => false;
