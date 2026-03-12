import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/auth_provider.dart';
import '../providers/assets_provider.dart';
import '../providers/sync_settings_provider.dart';
import '../models/asset.dart';
import '../models/sync_settings.dart';
import '../main.dart';
import '../providers/service_providers.dart';
import '../providers/relations_provider.dart';
import '../services/enc_file_io.dart';
import '../services/e2ee_sync_service.dart';

/// Returns error message if invalid; null if OK. Does not modify any data.
String? _validateImportJson(
  List<dynamic> assetList,
  List<dynamic>? relationList,
) {
  if (assetList.isEmpty) return 'No assets in JSON.';
  final assetIds = <String>{};
  for (var i = 0; i < assetList.length; i++) {
    final item = assetList[i];
    if (item is! Map<String, dynamic>) {
      return 'Item at index $i: expected object.';
    }
    try {
      final asset = Asset.fromJson(item);
      assetIds.add(asset.id);
    } catch (e) {
      return 'Asset at index $i: $e';
    }
  }
  if (relationList != null && relationList.isNotEmpty) {
    for (var i = 0; i < relationList.length; i++) {
      final r = relationList[i];
      if (r is! Map<String, dynamic>) {
        return 'Relation at index $i: expected object.';
      }
      if (r['id'] == null ||
          r['from_asset_id'] == null ||
          r['to_asset_id'] == null ||
          r['relation_type'] == null) {
        return 'Relation at index $i: missing id, from_asset_id, to_asset_id or relation_type.';
      }
      final from = r['from_asset_id'] as String;
      final to = r['to_asset_id'] as String;
      if (!assetIds.contains(from) || !assetIds.contains(to)) {
        return 'Relation at index $i: from_asset_id or to_asset_id not in assets.';
      }
    }
  }
  return null;
}

class AutoLockNotifier extends Notifier<int> {
  @override
  int build() => 5;

  void setMinutes(int minutes) {
    state = minutes;
  }
}

final autoLockMinutesProvider = NotifierProvider<AutoLockNotifier, int>(
  () => AutoLockNotifier(),
);

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _biometricEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadBiometricPref();
    ref.read(syncSettingsProvider.notifier).load();
  }

  Future<void> _loadBiometricPref() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _biometricEnabled = prefs.getBool('biometric_enabled') ?? true;
    });
  }

  Future<void> _toggleBiometric(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('biometric_enabled', value);
    setState(() => _biometricEnabled = value);
  }

  void _showAutoLockPicker() {
    final current = ref.read(autoLockMinutesProvider);
    showDialog(
      context: context,
      builder: (ctx) {
        int selected = current;
        return StatefulBuilder(
          builder: (context, setDlgState) => AlertDialog(
            backgroundColor: kSurfaceColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            title: const Text('Auto-Lock Timeout'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [1, 2, 5, 10, 15, 30].map((m) {
                final isSelected = selected == m;
                return ListTile(
                  title: Text('$m minute${m == 1 ? '' : 's'}'),
                  leading: Icon(
                    isSelected
                        ? Icons.radio_button_checked
                        : Icons.radio_button_unchecked,
                    color: isSelected ? kPrimaryGreen : kTextMuted,
                  ),
                  onTap: () => setDlgState(() => selected = m),
                );
              }).toList(),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () async {
                  ref
                      .read(autoLockMinutesProvider.notifier)
                      .setMinutes(selected);
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.setInt('auto_lock_minutes', selected);
                  if (ctx.mounted) Navigator.pop(ctx);
                },
                style: FilledButton.styleFrom(
                  backgroundColor: kPrimaryGreen,
                  foregroundColor: Colors.black,
                ),
                child: const Text('Save'),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _exportJson(WidgetRef ref) async {
    final scaffoldMsgr = ScaffoldMessenger.of(context);
    try {
      final assets = ref.read(assetsProvider);
      List<Map<String, dynamic>> relations = [];
      if (!kIsWeb) {
        final db = ref.read(databaseServiceProvider);
        relations = await db.getAllRelations();
      }
      final payload = <String, dynamic>{
        'assets': assets.map((a) => a.toJson()).toList(),
        'relations': relations,
      };
      final jsonString = jsonEncode(payload);
      await Clipboard.setData(ClipboardData(text: jsonString));
      if (mounted) {
        scaffoldMsgr.showSnackBar(
          const SnackBar(content: Text('Exported JSON copied to clipboard!')),
        );
      }
    } catch (_) {
      if (mounted) {
        scaffoldMsgr.showSnackBar(
          const SnackBar(
            content: Text(
              kIsWeb
                  ? 'Clipboard unavailable (browser may require HTTPS). Try saving to a file instead.'
                  : 'Could not copy to clipboard. Please try again.',
            ),
          ),
        );
      }
    }
  }

  Future<void> _importJson(WidgetRef ref) async {
    final scaffoldMsgr = ScaffoldMessenger.of(context);
    try {
      final clipboardData = await Clipboard.getData(Clipboard.kTextPlain);
      if (clipboardData == null ||
          clipboardData.text == null ||
          clipboardData.text!.trim().isEmpty) {
        if (mounted) {
          scaffoldMsgr.showSnackBar(
            SnackBar(
              content: Text(
                kIsWeb
                    ? 'Clipboard is empty or inaccessible (use HTTPS, or paste JSON into a text field first).'
                    : 'Clipboard is empty.',
              ),
            ),
          );
        }
        return;
      }
      final decoded = jsonDecode(clipboardData.text!);
      final List<dynamic> assetList;
      final List<dynamic>? relationList;
      if (decoded is List) {
        assetList = decoded;
        relationList = null;
      } else if (decoded is Map<String, dynamic>) {
        final a = decoded['assets'];
        if (a == null || a is! List) {
          if (mounted) {
            scaffoldMsgr.showSnackBar(
              const SnackBar(
                content: Text(
                  'Invalid JSON: missing or invalid "assets" array.',
                ),
              ),
            );
          }
          return;
        }
        assetList = a;
        final r = decoded['relations'];
        relationList = r is List ? r : null;
      } else {
        if (mounted) {
          scaffoldMsgr.showSnackBar(
            const SnackBar(
              content: Text(
                'Invalid JSON: expected array or object with "assets".',
              ),
            ),
          );
        }
        return;
      }

      // Validate before touching data: parse all assets and relations
      String? validationError = _validateImportJson(assetList, relationList);
      if (validationError != null) {
        if (mounted) {
          scaffoldMsgr.showSnackBar(
            SnackBar(content: Text('Import invalid: $validationError')),
          );
        }
        return;
      }

      final toAdd = assetList
          .map((item) => Asset.fromJson(item as Map<String, dynamic>))
          .toList();
      final assetsNotifier = ref.read(assetsProvider.notifier);
      await assetsNotifier.clearAll();
      await assetsNotifier.batchAddAssets(toAdd);
      if (!kIsWeb && relationList != null && relationList.isNotEmpty) {
        final db = ref.read(databaseServiceProvider);
        for (var r in relationList) {
          final map = r as Map<String, dynamic>;
          if (map['id'] != null &&
              map['from_asset_id'] != null &&
              map['to_asset_id'] != null &&
              map['relation_type'] != null) {
            await db.insertRelation(map);
          }
        }
        ref.invalidate(assetRelationsProvider);
      }
      if (mounted) {
        scaffoldMsgr.showSnackBar(
          SnackBar(
            content: Text('Successfully imported ${toAdd.length} assets!'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        final msg = e is TypeError
            ? 'Invalid JSON or format.'
            : (e.toString().toLowerCase().contains('clipboard') ||
                  e.toString().toLowerCase().contains('permission') ||
                  e.toString().toLowerCase().contains('secure'))
            ? (kIsWeb
                  ? 'Clipboard inaccessible. Use HTTPS or paste the JSON into a text field, then try again.'
                  : 'Could not read clipboard. Please try again.')
            : 'Import failed: ${e.toString()}';
        scaffoldMsgr.showSnackBar(SnackBar(content: Text(msg)));
      }
    }
  }

  Future<void> _importEncFile(WidgetRef ref) async {
    final bytes = await pickEncFileBytes(ref);
    if (bytes == null || bytes.isEmpty || !mounted) return;
    final pwd = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        final c = TextEditingController();
        return AlertDialog(
          title: const Text('Unlock backup'),
          content: TextField(
            controller: c,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: 'Master password',
              border: OutlineInputBorder(),
            ),
            onSubmitted: (v) => Navigator.pop(ctx, v),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, c.text),
              child: const Text('Unlock'),
            ),
          ],
        );
      },
    );
    if (pwd == null || pwd.isEmpty || !mounted) return;
    final success = await ref
        .read(authProvider.notifier)
        .unlockWithExternalPayload(pwd, bytes);
    if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            ref.read(authProvider.notifier).lastError ?? 'Wrong password',
          ),
        ),
      );
      return;
    }
    try {
      final syncService = ref.read(e2eeSyncServiceProvider);
      final snapshot = syncService.unpackCiphertextToSnapshot(bytes);
      await ref
          .read(assetsProvider.notifier)
          .replaceFromSnapshot(snapshot, encryptedBlob: bytes);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Imported ${snapshot.assets.length} assets from .enc file',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Import failed: $e')));
      }
    }
  }

  Future<void> _exportSyncSettings(WidgetRef ref) async {
    final data = ref.read(syncSettingsProvider.notifier).exportSettings();
    await Clipboard.setData(ClipboardData(text: data.toJsonString()));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sync settings copied to clipboard')),
      );
    }
  }

  Future<void> _importSyncSettings(WidgetRef ref) async {
    final text = await Clipboard.getData(Clipboard.kTextPlain);
    if (text?.text == null || text!.text!.trim().isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Clipboard empty')));
      }
      return;
    }
    try {
      final data = SyncSettingsExport.fromJsonString(text.text!);
      await ref.read(syncSettingsProvider.notifier).importSettings(data);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Sync settings applied')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Invalid sync settings JSON: $e')),
        );
      }
    }
  }

  void _showSyncMethodPicker() {
    final current = ref.read(syncSettingsProvider);
    final options = [
      SyncMethod.none,
      SyncMethod.webdav,
      if (kIsWeb) SyncMethod.googleDrive,
      if (kIsWeb) SyncMethod.localFile,
    ];
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDlgState) => AlertDialog(
          backgroundColor: kSurfaceColor,
          title: const Text('Sync method'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: options.map((m) {
              final isSelected = current == m;
              return ListTile(
                title: Text(_syncMethodLabel(m)),
                leading: Icon(
                  isSelected
                      ? Icons.radio_button_checked
                      : Icons.radio_button_unchecked,
                  color: isSelected ? kPrimaryGreen : kTextMuted,
                ),
                onTap: () async {
                  await ref
                      .read(syncSettingsProvider.notifier)
                      .setSyncMethod(m);
                  if (ctx.mounted) Navigator.pop(ctx);
                },
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  static String _syncMethodLabel(SyncMethod m) {
    switch (m) {
      case SyncMethod.none:
        return 'None';
      case SyncMethod.webdav:
        return 'WebDAV';
      case SyncMethod.googleDrive:
        return 'Google Drive';
      case SyncMethod.localFile:
        return 'Local file (browser)';
    }
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Cannot open: $url')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final autoLockMinutes = ref.watch(autoLockMinutesProvider);
    final syncMethod = ref.watch(syncSettingsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          const _SettingsSectionHeader('Security'),
          ListTile(
            leading: const Icon(Icons.lock_outline),
            title: const Text('Lock Vault'),
            onTap: () => ref.read(authProvider.notifier).lock(),
          ),
          if (!kIsWeb)
            SwitchListTile(
              secondary: const Icon(Icons.fingerprint),
              title: const Text('Biometric Unlock'),
              subtitle: const Text('Use Face ID / fingerprint to unlock'),
              value: _biometricEnabled,
              activeTrackColor: kPrimaryGreen.withValues(alpha: 0.5),
              thumbColor: WidgetStatePropertyAll(
                _biometricEnabled ? kPrimaryGreen : null,
              ),
              onChanged: _toggleBiometric,
            ),
          ListTile(
            leading: const Icon(Icons.timer_outlined),
            title: const Text('Auto-Lock Timeout'),
            subtitle: Text('Lock after $autoLockMinutes min in background'),
            trailing: const Icon(Icons.chevron_right),
            onTap: _showAutoLockPicker,
          ),
          const Divider(),
          const _SettingsSectionHeader('Sync'),
          ListTile(
            leading: const Icon(Icons.sync),
            title: const Text('Sync method'),
            subtitle: Text(_syncMethodLabel(syncMethod)),
            trailing: const Icon(Icons.chevron_right),
            onTap: _showSyncMethodPicker,
          ),
          ListTile(
            leading: const Icon(Icons.cloud_sync),
            title: const Text('WebDAV / Drive / Local file'),
            subtitle: const Text('Configure credentials and link files'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.go('/settings/webdav'),
          ),
          ListTile(
            leading: const Icon(Icons.upload_file),
            title: const Text('Export sync settings'),
            subtitle: const Text('Copy sync method to clipboard (JSON)'),
            onTap: () => _exportSyncSettings(ref),
          ),
          ListTile(
            leading: const Icon(Icons.download),
            title: const Text('Import sync settings'),
            subtitle: const Text('Paste JSON from clipboard'),
            onTap: () => _importSyncSettings(ref),
          ),
          const Divider(),
          const _SettingsSectionHeader('Data Management'),
          ListTile(
            leading: const Icon(Icons.schema),
            title: const Text('Manage Custom Asset Types'),
            subtitle: const Text('Create custom asset templates'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.go('/settings/asset-types'),
          ),
          ListTile(
            leading: const Icon(Icons.label_outline),
            title: const Text('Manage Tags'),
            subtitle: const Text('View and organize all tags'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.go('/settings/tags'),
          ),
          const Divider(),
          const _SettingsSectionHeader('Import / Export'),
          ListTile(
            leading: const Icon(Icons.file_download),
            title: const Text('Export .enc file'),
            subtitle: const Text('Encrypted backup (all platforms)'),
            onTap: () => exportEncToFile(ref),
          ),
          ListTile(
            leading: const Icon(Icons.file_upload),
            title: const Text('Import .enc file'),
            subtitle: const Text('Replace vault with backup (enter password)'),
            onTap: () => _importEncFile(ref),
          ),
          ListTile(
            leading: const Icon(Icons.download),
            title: const Text('Export JSON to Clipboard'),
            onTap: () => _exportJson(ref),
          ),
          ListTile(
            leading: const Icon(Icons.upload),
            title: const Text('Import JSON (from clipboard)'),
            onTap: () => _importJson(ref),
          ),
          const Divider(),
          const _SettingsSectionHeader('About'),
          ListTile(
            leading: const Icon(Icons.language),
            title: const Text('Website'),
            subtitle: const Text('vault.octarq.org'),
            trailing: const Icon(Icons.open_in_new, size: 18),
            onTap: () => _openUrl(kWebsiteUrl),
          ),
          ListTile(
            leading: const Icon(Icons.menu_book_outlined),
            title: const Text('Help & Docs'),
            subtitle: const Text('vault.octarq.org/docs'),
            trailing: const Icon(Icons.open_in_new, size: 18),
            onTap: () => _openUrl(kDocsUrl),
          ),
        ],
      ),
    );
  }
}

class _SettingsSectionHeader extends StatelessWidget {
  final String title;
  const _SettingsSectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: kTextMuted,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}
