import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:webdav_client/webdav_client.dart' as webdav;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'secure_storage_service.dart';

final webDavServiceProvider = Provider<WebDavService>((ref) {
  return WebDavService();
});

class WebDavService {
  webdav.Client? _client;

  WebDavService();

  Future<void> connect(String url, String username, String password) async {
    _client = webdav.newClient(
      url,
      user: username,
      password: password,
      debug: false,
    );
    await _client!.ping(); // Validate credentials
    
    // Store credentials securely for future automated use
    final storage = const FlutterSecureStorage();
    await storage.write(key: 'webdav_url', value: url);
    await storage.write(key: 'webdav_user', value: username);
    await storage.write(key: 'webdav_pass', value: password);
  }

  Future<bool> hasCredentials() async {
    final storage = const FlutterSecureStorage();
    final url = await storage.read(key: 'webdav_url');
    return url != null && url.isNotEmpty;
  }

  Future<void> _connectFromStorage() async {
    if (_client != null) return;
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
    
    // Ensure directory exists
    try {
      await _client!.mkdir('/AssetVault');
    } catch (_) {
      // Might already exist
    }

    // Convert string to bytes
    final bytes = jsonPayload.codeUnits;
    await _client!.write('/AssetVault/backup.json', Uint8List.fromList(bytes));
  }

  Future<String> restoreJson() async {
    await _connectFromStorage();
    
    // Read bytes from remote server
    final bytes = await _client!.read('/AssetVault/backup.json');
    return String.fromCharCodes(bytes);
  }

  Future<void> clearCredentials() async {
    final storage = const FlutterSecureStorage();
    await storage.delete(key: 'webdav_url');
    await storage.delete(key: 'webdav_user');
    await storage.delete(key: 'webdav_pass');
    _client = null;
  }
}
