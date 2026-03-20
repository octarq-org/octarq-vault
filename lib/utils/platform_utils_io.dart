import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_sqlcipher/sqflite.dart' as sqflite;

Future<String> getDatabasesPath() => sqflite.getDatabasesPath();

/// App-controlled DB path (Application Support), stable across runs and bundle ID.
Future<String> getVaultDatabasePath() async {
  final dir = await getApplicationSupportDirectory();
  return p.join(dir.path, 'octarq_vault.db');
}

bool get isMacOS => Platform.isMacOS;

Future<bool> fileExists(String path) => File(path).exists();

Future<void> deleteDatabase(String path) => sqflite.deleteDatabase(path);

/// Force-remove DB file (e.g. when deleteDatabase does not remove it on macOS).
void forceDeleteFile(String path) {
  File(path).deleteSync();
}

/// Renames the legacy `asset_vault_enc.db` to `octarq_vault.db` if needed.
/// Idempotent — safe to call on every app start.
Future<void> migrateDbFileIfNeeded() async {
  final dir = await getApplicationSupportDirectory();
  final legacyPath = p.join(dir.path, 'asset_vault_enc.db');
  final newPath = p.join(dir.path, 'octarq_vault.db');
  final legacyFile = File(legacyPath);
  final newFile = File(newPath);
  if (await legacyFile.exists() && !await newFile.exists()) {
    await legacyFile.rename(newPath);
  }
}
