import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:webdav_client/webdav_client.dart' as webdav;

import 'platform_secure_storage.dart';

import '../models/attachment.dart';
import 'e2ee_sync_service.dart';

final webDavServiceProvider = Provider<WebDavService>((ref) {
  return WebDavService();
});

class WebDavService {
  static const String _vaultDir = '/OctarqVault';
  static const String _snapshotFile = '$_vaultDir/backup.avault';
  static const String _attachmentDir = '$_vaultDir/attachments';

  webdav.Client? _client;

  WebDavService();

  Future<void> connect(String url, String username, String password) async {
    // WebDAV credentials cannot be stored securely in the browser
    // (SharedPreferences / localStorage is plaintext). Use Google Drive
    // or local-file sync on the web platform instead.
    if (kIsWeb) {
      throw UnsupportedError(
        'WebDAV is not supported on the web platform because browser storage '
        'cannot protect credentials at rest. Use Google Drive or local file '
        'sync instead.',
      );
    }

    _client = webdav.newClient(
      url,
      user: username,
      password: password,
      debug: false,
    );
    await _client!.ping(); // Validate credentials

    // Store credentials securely in the platform Keychain / Keystore.
    final storage = platformFlutterSecureStorage();
    await storage.write(key: 'webdav_url', value: url);
    await storage.write(key: 'webdav_user', value: username);
    await storage.write(key: 'webdav_pass', value: password);
  }

  Future<bool> hasCredentials() async {
    if (kIsWeb) return false;
    final storage = platformFlutterSecureStorage();
    final url = await storage.read(key: 'webdav_url');
    return url != null && url.isNotEmpty;
  }

  Future<void> _connectFromStorage() async {
    if (_client != null) return;
    if (kIsWeb) throw UnsupportedError('WebDAV is not supported on web.');

    final storage = platformFlutterSecureStorage();
    final url = await storage.read(key: 'webdav_url');
    final user = await storage.read(key: 'webdav_user');
    final pass = await storage.read(key: 'webdav_pass');

    if (url != null && user != null && pass != null) {
      _client = webdav.newClient(url, user: user, password: pass);
    } else {
      throw Exception('WebDAV credentials not stored.');
    }
  }

  Future<void> _ensureDir(String path) async {
    try {
      await _client!.mkdir(path);
    } catch (_) {
      // Directory may already exist; ignore errors.
    }
  }

  // -------------------------------------------------------------------------
  // Full snapshot
  // -------------------------------------------------------------------------

  Future<void> backupEncrypted(Uint8List encryptedPayload) async {
    await _connectFromStorage();
    await _ensureDir(_vaultDir);
    await _client!.write(_snapshotFile, encryptedPayload);
  }

  Future<Uint8List> restoreEncrypted() async {
    await _connectFromStorage();
    final bytes = await _client!.read(_snapshotFile);
    return Uint8List.fromList(bytes);
  }

  // -------------------------------------------------------------------------
  // Delta sync
  // -------------------------------------------------------------------------

  /// Uploads a delta blob to `<vaultDir>/delta_<maxSeq>.avault`.
  Future<void> backupDelta({
    required List<OpLogEntry> opLogEntries,
    required int baseSeq,
    required E2EESyncService syncService,
    List<AssetAttachment> attachmentManifest = const [],
  }) async {
    if (opLogEntries.isEmpty) return;
    await _connectFromStorage();
    await _ensureDir(_vaultDir);

    final maxSeq = opLogEntries.last.seq;
    final blob = syncService.packDeltaToCiphertext(
      opLogEntries: opLogEntries,
      baseSeq: baseSeq,
      attachmentManifest: attachmentManifest,
    );
    await _client!.write('$_vaultDir/delta_$maxSeq.avault', blob);
  }

  /// Lists delta file names in the vault directory.
  Future<List<String>> listDeltaFiles() async {
    await _connectFromStorage();
    final items = await _client!.readDir(_vaultDir);
    return items
        .map((f) => f.name ?? '')
        .where((n) => n.startsWith('delta_') && n.endsWith('.avault'))
        .toList();
  }

  /// Downloads a delta blob by its file name.
  Future<Uint8List> downloadDelta(String fileName) async {
    await _connectFromStorage();
    final bytes = await _client!.read('$_vaultDir/$fileName');
    return Uint8List.fromList(bytes);
  }

  // -------------------------------------------------------------------------
  // Attachment sync
  // -------------------------------------------------------------------------

  /// Uploads an encrypted attachment blob to
  /// `<vaultDir>/attachments/<uuid>.enc`.
  Future<void> uploadAttachment(
    AssetAttachment attachment,
    Uint8List encBytes,
  ) async {
    await _connectFromStorage();
    await _ensureDir(_vaultDir);
    await _ensureDir(_attachmentDir);
    await _client!.write('$_attachmentDir/${attachment.encFileName}', encBytes);
  }

  /// Downloads the encrypted attachment blob.
  ///
  /// Returns `null` if the file does not exist on the server.
  Future<Uint8List?> downloadAttachment(AssetAttachment attachment) async {
    await _connectFromStorage();
    try {
      final bytes = await _client!.read(
        '$_attachmentDir/${attachment.encFileName}',
      );
      return Uint8List.fromList(bytes);
    } catch (_) {
      return null;
    }
  }

  /// Deletes a remote attachment blob.
  Future<void> deleteRemoteAttachment(AssetAttachment attachment) async {
    await _connectFromStorage();
    try {
      await _client!.remove('$_attachmentDir/${attachment.encFileName}');
    } catch (_) {}
  }

  // -------------------------------------------------------------------------
  // Credentials
  // -------------------------------------------------------------------------

  Future<void> clearCredentials() async {
    if (!kIsWeb) {
      final storage = platformFlutterSecureStorage();
      await storage.delete(key: 'webdav_url');
      await storage.delete(key: 'webdav_user');
      await storage.delete(key: 'webdav_pass');
    }
    _client = null;
  }
}
