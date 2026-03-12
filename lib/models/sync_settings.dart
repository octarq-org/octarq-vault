import 'dart:convert';

/// How vault data is synced to a remote or local target.
enum SyncMethod {
  none,
  webdav,
  googleDrive,

  /// Web only: File System Access API linked file.
  localFile,
}

extension SyncMethodX on SyncMethod {
  String get value => name;
  static SyncMethod fromString(String? v) {
    if (v == null || v.isEmpty) return SyncMethod.none;
    return SyncMethod.values.firstWhere(
      (e) => e.name == v,
      orElse: () => SyncMethod.none,
    );
  }
}

/// Sync settings stored in SharedPreferences (export/import as JSON, no secrets).
class SyncSettingsExport {
  final String syncMethod;
  final String? webdavUrl; // no password/username in export

  const SyncSettingsExport({required this.syncMethod, this.webdavUrl});

  Map<String, dynamic> toJson() => {
    'syncMethod': syncMethod,
    'webdavUrl': webdavUrl,
  };

  factory SyncSettingsExport.fromJson(Map<String, dynamic> json) {
    return SyncSettingsExport(
      syncMethod: json['syncMethod'] as String? ?? 'none',
      webdavUrl: json['webdavUrl'] as String?,
    );
  }

  String toJsonString() => jsonEncode(toJson());
  static SyncSettingsExport fromJsonString(String s) {
    return SyncSettingsExport.fromJson(jsonDecode(s) as Map<String, dynamic>);
  }
}
