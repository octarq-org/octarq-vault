import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:webdav_client/webdav_client.dart' as webdav;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

final webDavServiceProvider = Provider<WebDavService>((ref) {
  return WebDavService();
});

class WebDavService {
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
    final storage = const FlutterSecureStorage();
    await storage.write(key: 'webdav_url', value: url);
    await storage.write(key: 'webdav_user', value: username);
    await storage.write(key: 'webdav_pass', value: password);
  }

  Future<bool> hasCredentials() async {
    if (kIsWeb) return false;
    final storage = const FlutterSecureStorage();
    final url = await storage.read(key: 'webdav_url');
    return url != null && url.isNotEmpty;
  }

  Future<void> _connectFromStorage() async {
    if (_client != null) return;
    if (kIsWeb) throw UnsupportedError('WebDAV is not supported on web.');

    final storage = const FlutterSecureStorage();
    final url = await storage.read(key: 'webdav_url');
    final user = await storage.read(key: 'webdav_user');
    final pass = await storage.read(key: 'webdav_pass');

    if (url != null && user != null && pass != null) {
      _client = webdav.newClient(url, user: user, password: pass);
    } else {
      throw Exception('WebDAV credentials not stored.');
    }
  }

  Future<void> backupJson(String jsonPayload) async {
    await _connectFromStorage();
    try {
      await _client!.mkdir('/OctarqVault');
    } catch (_) {}
    final bytes = jsonPayload.codeUnits;
    await _client!.write('/OctarqVault/backup.json', Uint8List.fromList(bytes));
  }

  Future<String> restoreJson() async {
    await _connectFromStorage();
    final bytes = await _client!.read('/OctarqVault/backup.json');
    return String.fromCharCodes(bytes);
  }

  Future<void> backupEncrypted(Uint8List encryptedPayload) async {
    await _connectFromStorage();
    try {
      await _client!.mkdir('/OctarqVault');
    } catch (_) {}
    await _client!.write('/OctarqVault/backup.avault', encryptedPayload);
  }

  Future<Uint8List> restoreEncrypted() async {
    await _connectFromStorage();
    final bytes = await _client!.read('/OctarqVault/backup.avault');
    return Uint8List.fromList(bytes);
  }

  Future<void> clearCredentials() async {
    if (!kIsWeb) {
      final storage = const FlutterSecureStorage();
      await storage.delete(key: 'webdav_url');
      await storage.delete(key: 'webdav_user');
      await storage.delete(key: 'webdav_pass');
    }
    _client = null;
  }
}
