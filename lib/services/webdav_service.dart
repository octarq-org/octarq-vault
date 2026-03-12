import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:webdav_client/webdav_client.dart' as webdav;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('webdav_url', url);
      await prefs.setString('webdav_user', username);
      await prefs.setString('webdav_pass', password);
    } else {
      final storage = const FlutterSecureStorage();
      await storage.write(key: 'webdav_url', value: url);
      await storage.write(key: 'webdav_user', value: username);
      await storage.write(key: 'webdav_pass', value: password);
    }
  }

  Future<bool> hasCredentials() async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      final url = prefs.getString('webdav_url');
      return url != null && url.isNotEmpty;
    }
    final storage = const FlutterSecureStorage();
    final url = await storage.read(key: 'webdav_url');
    return url != null && url.isNotEmpty;
  }

  Future<void> _connectFromStorage() async {
    if (_client != null) return;
    String? url, user, pass;

    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      url = prefs.getString('webdav_url');
      user = prefs.getString('webdav_user');
      pass = prefs.getString('webdav_pass');
    } else {
      final storage = const FlutterSecureStorage();
      url = await storage.read(key: 'webdav_url');
      user = await storage.read(key: 'webdav_user');
      pass = await storage.read(key: 'webdav_pass');
    }

    if (url != null && user != null && pass != null) {
      _client = webdav.newClient(url, user: user, password: pass);
    } else {
      throw Exception('WebDAV credentials not stored.');
    }
  }

  Future<void> backupJson(String jsonPayload) async {
    await _connectFromStorage();
    try {
      await _client!.mkdir('/AssetVault');
    } catch (_) {}
    final bytes = jsonPayload.codeUnits;
    await _client!.write('/AssetVault/backup.json', Uint8List.fromList(bytes));
  }

  Future<String> restoreJson() async {
    await _connectFromStorage();
    final bytes = await _client!.read('/AssetVault/backup.json');
    return String.fromCharCodes(bytes);
  }

  Future<void> backupEncrypted(Uint8List encryptedPayload) async {
    await _connectFromStorage();
    try {
      await _client!.mkdir('/AssetVault');
    } catch (_) {}
    await _client!.write('/AssetVault/backup.avault', encryptedPayload);
  }

  Future<Uint8List> restoreEncrypted() async {
    await _connectFromStorage();
    final bytes = await _client!.read('/AssetVault/backup.avault');
    return Uint8List.fromList(bytes);
  }

  Future<void> clearCredentials() async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('webdav_url');
      await prefs.remove('webdav_user');
      await prefs.remove('webdav_pass');
    } else {
      final storage = const FlutterSecureStorage();
      await storage.delete(key: 'webdav_url');
      await storage.delete(key: 'webdav_user');
      await storage.delete(key: 'webdav_pass');
    }
    _client = null;
  }
}
