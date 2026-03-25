import 'dart:typed_data';

/// Stub: no IndexedDB on non-Web. Encrypted vault is stored in SQLite / not applicable.
class WebVaultStorage {
  Future<Uint8List?> readEncrypted() async => null;
  Future<void> writeEncrypted(Uint8List blob) async {}

  Future<Uint8List?> readAttachment(String encFileName) async => null;
  Future<void> writeAttachment(String encFileName, Uint8List bytes) async {}
  Future<void> deleteAttachmentBlob(String encFileName) async {}
}
