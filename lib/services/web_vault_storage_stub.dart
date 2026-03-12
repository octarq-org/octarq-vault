import 'dart:typed_data';

/// Stub: no IndexedDB on non-Web. Encrypted vault is stored in SQLite / not applicable.
class WebVaultStorage {
  Future<Uint8List?> readEncrypted() async => null;
  Future<void> writeEncrypted(Uint8List blob) async {}
}
