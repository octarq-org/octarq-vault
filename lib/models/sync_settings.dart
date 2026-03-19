import 'dart:convert';

/// How vault data is synced to a remote or local target.
enum SyncMethod {
  none,
  webdav,
  googleDrive,

  /// Web only: File System Access API linked file.
  localFile,

  /// iOS only: iCloud Documents backup (passive iCloud Backup sync).
  icloud,
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

  static List<SyncMethod> listFromStrings(List<dynamic>? list) {
    if (list == null || list.isEmpty) return [];
    return list
        .map((e) => fromString(e is String ? e : e?.toString()))
        .where((m) => m != SyncMethod.none)
        .toSet()
        .toList();
  }
}

/// Sync settings stored in SharedPreferences (export/import as JSON, no secrets).
class SyncSettingsExport {
  final List<String> syncMethods;
  final String? webdavUrl; // no password/username in export

  const SyncSettingsExport({required this.syncMethods, this.webdavUrl});

  Map<String, dynamic> toJson() => {
    'syncMethods': syncMethods,
    'webdavUrl': webdavUrl,
  };

  factory SyncSettingsExport.fromJson(Map<String, dynamic> json) {
    final methods = json['syncMethods'];
    return SyncSettingsExport(
      syncMethods: methods is List
          ? List<String>.from(methods.map((e) => e.toString()))
          : (json['syncMethod'] != null
                ? [json['syncMethod'] as String]
                : <String>[]),
      webdavUrl: json['webdavUrl'] as String?,
    );
  }

  String toJsonString() => jsonEncode(toJson());
  static SyncSettingsExport fromJsonString(String s) {
    return SyncSettingsExport.fromJson(jsonDecode(s) as Map<String, dynamic>);
  }
}
