Future<String> getDatabasesPath() =>
    throw UnsupportedError('getDatabasesPath is not supported on Web');

Future<String> getVaultDatabasePath() =>
    throw UnsupportedError('getVaultDatabasePath is not supported on Web');

bool get isMacOS => false;

Future<bool> fileExists(String path) => Future.value(false);

Future<void> deleteDatabase(String path) => Future.value();

void forceDeleteFile(String path) =>
    throw UnsupportedError('forceDeleteFile is not supported on Web');

/// No-op on Web — DB file lives in IndexedDB.
Future<void> migrateDbFileIfNeeded() => Future.value();
