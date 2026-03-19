// Web stub — iCloud sync is not supported on Web.
// All methods throw; callers must check ICloudSyncService.isSupported first.

import 'dart:typed_data';

Future<void> backup(Uint8List encryptedBlob) async {
  throw UnsupportedError('iCloud sync is not supported on Web.');
}

Future<Uint8List?> restore() async {
  throw UnsupportedError('iCloud sync is not supported on Web.');
}

Future<bool> hasBackup() async => false;
