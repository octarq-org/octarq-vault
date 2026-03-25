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
import '../providers/locale_preference_provider.dart';
import '../providers/sync_settings_provider.dart';
import '../providers/sync_conflicts_provider.dart';
import '../providers/change_password_provider.dart';
import '../models/asset.dart';
import '../models/sync_settings.dart';
import '../main.dart';
import '../providers/service_providers.dart';
import '../providers/relations_provider.dart';
import '../l10n/app_localizations.dart';
import '../services/enc_file_io.dart';
import '../services/e2ee_sync_service.dart';
import '../providers/auto_lock_provider.dart';

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

String _formatSyncTime(DateTime dt) {
  final now = DateTime.now();
  final diff = now.difference(dt);
  if (diff.inSeconds < 60) return 'Just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
  if (diff.inHours < 24) return '${diff.inHours}h ago';
  String pad(int n) => n.toString().padLeft(2, '0');
  return '${dt.year}-${pad(dt.month)}-${pad(dt.day)} ${pad(dt.hour)}:${pad(dt.minute)}';
}

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

  void _showChangePasswordDialog() {
    showDialog(
      context: context,
      builder: (ctx) => const _ChangePasswordDialog(),
    );
  }

  void _showAutoLockPicker() {
    final current = ref.read(autoLockMinutesProvider);
    final l10n = AppLocalizations.of(context)!;
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
            title: Text(l10n.autoLockTimeout),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [1, 2, 5, 10, 15, 30].map((m) {
                final isSelected = selected == m;
                return ListTile(
                  title: Text(m == 1 ? l10n.oneMinute : l10n.minutesPlural(m)),
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
                child: Text(l10n.cancel),
              ),
              FilledButton(
                onPressed: () async {
                  await ref
                      .read(autoLockMinutesProvider.notifier)
                      .setMinutes(selected);
                  if (ctx.mounted) Navigator.pop(ctx);
                },
                style: FilledButton.styleFrom(
                  backgroundColor: kPrimaryGreen,
                  foregroundColor: Colors.black,
                ),
                child: Text(l10n.save),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _exportJson(WidgetRef ref) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: kSurfaceColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: Text(l10n.exportJsonSecurityTitle),
        content: SingleChildScrollView(
          child: Text(
            l10n.exportJsonSecurityBody,
            style: const TextStyle(fontSize: 14, height: 1.4),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: kPrimaryGreen,
              foregroundColor: Colors.black,
            ),
            child: Text(l10n.exportJsonContinueExport),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

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
          SnackBar(
            content: Text(
              AppLocalizations.of(context)!.exportedJsonCopiedToClipboard,
            ),
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        scaffoldMsgr.showSnackBar(
          SnackBar(
            content: Text(
              kIsWeb ? l10n.clipboardUnavailableWeb : l10n.clipboardUnavailable,
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
              content: Text(AppLocalizations.of(context)!.clipboardEmpty),
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
              SnackBar(
                content: Text(
                  AppLocalizations.of(context)!.validationNoAssetsInJson,
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
            SnackBar(
              content: Text(AppLocalizations.of(context)!.invalidJsonOrFormat),
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
            SnackBar(
              content: Text(
                AppLocalizations.of(context)!.importInvalid(validationError),
              ),
            ),
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
            content: Text(
              AppLocalizations.of(context)!.importSuccessCount(toAdd.length),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        final msg = e is TypeError
            ? l10n.invalidJsonOrFormat
            : (e.toString().toLowerCase().contains('clipboard') ||
                  e.toString().toLowerCase().contains('permission') ||
                  e.toString().toLowerCase().contains('secure'))
            ? l10n.clipboardUnavailable
            : l10n.importFailed(e.toString());
        scaffoldMsgr.showSnackBar(SnackBar(content: Text(msg)));
      }
    }
  }

  Future<void> _importEncFile(WidgetRef ref) async {
    final bytes = await pickEncFileBytes(ref);
    if (bytes == null || bytes.isEmpty || !mounted) return;
    final l10n = AppLocalizations.of(context)!;
    final pwd = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        final ctxL10n = AppLocalizations.of(ctx)!;
        final c = TextEditingController();
        return AlertDialog(
          title: Text(ctxL10n.unlockBackup),
          content: TextField(
            controller: c,
            obscureText: true,
            decoration: InputDecoration(
              labelText: ctxL10n.masterPassword,
              border: const OutlineInputBorder(),
            ),
            onSubmitted: (v) => Navigator.pop(ctx, v),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(ctxL10n.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, c.text),
              child: Text(ctxL10n.unlock),
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
            ref.read(authProvider.notifier).lastError ?? l10n.wrongPassword,
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
              AppLocalizations.of(
                context,
              )!.importedEncCount(snapshot.assets.length),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)!.errorGeneric(e.toString()),
            ),
          ),
        );
      }
    }
  }

  Future<void> _exportSyncSettings(WidgetRef ref) async {
    final data = ref.read(syncSettingsProvider.notifier).exportSettings();
    await Clipboard.setData(ClipboardData(text: data.toJsonString()));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context)!.syncSettingsCopiedToClipboard,
          ),
        ),
      );
    }
  }

  Future<void> _importSyncSettings(WidgetRef ref) async {
    final text = await Clipboard.getData(Clipboard.kTextPlain);
    if (text?.text == null || text!.text!.trim().isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.clipboardEmpty)),
        );
      }
      return;
    }
    try {
      final data = SyncSettingsExport.fromJsonString(text.text!);
      await ref.read(syncSettingsProvider.notifier).importSettings(data);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.syncSettingsApplied),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(
                context,
              )!.invalidSyncSettingsJson(e.toString()),
            ),
          ),
        );
      }
    }
  }

  void _showSyncMethodPicker() {
    final options = [
      SyncMethod.webdav,
      SyncMethod.googleDrive,
      SyncMethod.localFile,
      SyncMethod.icloud,
    ];
    showDialog(
      context: context,
      builder: (ctx) => Consumer(
        builder: (context, ref, _) {
          final current = ref.watch(syncSettingsProvider);
          final l10n = AppLocalizations.of(ctx)!;
          return AlertDialog(
            backgroundColor: kSurfaceColor,
            title: Text(l10n.syncMethod),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: options
                  .map(
                    (m) => CheckboxListTile(
                      value: current.contains(m),
                      onChanged: (_) async {
                        if (m == SyncMethod.icloud && !current.contains(m)) {
                          final icloud = ref.read(iCloudSyncServiceProvider);
                          final available =
                              icloud.isSupported && await icloud.isAvailable;
                          if (!available) {
                            if (ctx.mounted) {
                              ScaffoldMessenger.of(ctx).showSnackBar(
                                SnackBar(
                                  content: Text(l10n.icloudNotAvailable),
                                ),
                              );
                            }
                            return;
                          }
                        }
                        await ref
                            .read(syncSettingsProvider.notifier)
                            .toggleSyncMethod(m);
                      },
                      title: Text(_syncMethodLabel(l10n, m)),
                      activeColor: kPrimaryGreen,
                      controlAffinity: ListTileControlAffinity.leading,
                    ),
                  )
                  .toList(),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(l10n.ok),
              ),
            ],
          );
        },
      ),
    );
  }

  static String _syncMethodLabel(AppLocalizations l10n, SyncMethod m) {
    switch (m) {
      case SyncMethod.none:
        return l10n.syncMethodNone;
      case SyncMethod.webdav:
        return l10n.syncMethodWebdav;
      case SyncMethod.googleDrive:
        return l10n.syncMethodGoogleDrive;
      case SyncMethod.localFile:
        return l10n.syncMethodLocalFile;
      case SyncMethod.icloud:
        return l10n.icloudBackup;
    }
  }

  static String _syncMethodsSubtitle(
    AppLocalizations l10n,
    List<SyncMethod> methods,
  ) {
    if (methods.isEmpty) return l10n.syncMethodNone;
    return methods.map((m) => _syncMethodLabel(l10n, m)).join('、');
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.cannotOpenUrl(url)),
        ),
      );
    }
  }

  static String _localeOverrideLabel(AppLocalizations l10n, String value) {
    switch (value) {
      case 'zh':
        return l10n.localeZh;
      case 'en':
        return l10n.localeEn;
      case 'es':
        return l10n.localeEs;
      default:
        return l10n.localeSystem;
    }
  }

  void _showLanguagePicker() {
    final current = ref.read(localePreferenceProvider);
    showDialog(
      context: context,
      builder: (ctx) {
        final l10n = AppLocalizations.of(ctx)!;
        String selected = current;
        return StatefulBuilder(
          builder: (context, setDlgState) => AlertDialog(
            backgroundColor: kSurfaceColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            title: Text(l10n.language),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: Icon(
                    selected == 'system'
                        ? Icons.radio_button_checked
                        : Icons.radio_button_unchecked,
                    color: kPrimaryGreen,
                  ),
                  title: Text(l10n.localeSystem),
                  onTap: () => setDlgState(() => selected = 'system'),
                ),
                ListTile(
                  leading: Icon(
                    selected == 'zh'
                        ? Icons.radio_button_checked
                        : Icons.radio_button_unchecked,
                    color: kPrimaryGreen,
                  ),
                  title: Text(l10n.localeZh),
                  onTap: () => setDlgState(() => selected = 'zh'),
                ),
                ListTile(
                  leading: Icon(
                    selected == 'en'
                        ? Icons.radio_button_checked
                        : Icons.radio_button_unchecked,
                    color: kPrimaryGreen,
                  ),
                  title: Text(l10n.localeEn),
                  onTap: () => setDlgState(() => selected = 'en'),
                ),
                ListTile(
                  leading: Icon(
                    selected == 'es'
                        ? Icons.radio_button_checked
                        : Icons.radio_button_unchecked,
                    color: kPrimaryGreen,
                  ),
                  title: Text(l10n.localeEs),
                  onTap: () => setDlgState(() => selected = 'es'),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(l10n.cancel),
              ),
              FilledButton(
                onPressed: () {
                  ref
                      .read(localePreferenceProvider.notifier)
                      .setLocaleOverride(selected);
                  Navigator.pop(ctx);
                },
                child: Text(l10n.ok),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final autoLockMinutes = ref.watch(autoLockMinutesProvider);
    final syncMethods = ref.watch(syncSettingsProvider);
    final localeOverride = ref.watch(localePreferenceProvider);
    final lastSyncAt = ref.watch(lastSyncAtProvider);
    final pendingConflicts = ref.watch(pendingSyncConflictsProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsTitle)),
      body: ListView(
        children: [
          if (kIsWeb) _WebSecurityBanner(l10n: l10n),
          _SettingsSectionHeader(l10n.language),
          ListTile(
            leading: const Icon(Icons.translate),
            title: Text(l10n.language),
            subtitle: Text(_localeOverrideLabel(l10n, localeOverride)),
            trailing: const Icon(Icons.chevron_right),
            onTap: _showLanguagePicker,
          ),
          const Divider(),
          _SettingsSectionHeader(l10n.security),
          ListTile(
            leading: const Icon(Icons.lock_outline),
            title: Text(l10n.lockVault),
            onTap: () => ref.read(authProvider.notifier).lock(),
          ),
          if (!kIsWeb)
            SwitchListTile(
              secondary: const Icon(Icons.fingerprint),
              title: Text(l10n.biometricUnlock),
              subtitle: Text(l10n.biometricUnlockSubtitle),
              value: _biometricEnabled,
              activeTrackColor: kPrimaryGreen.withValues(alpha: 0.5),
              thumbColor: WidgetStatePropertyAll(
                _biometricEnabled ? kPrimaryGreen : null,
              ),
              onChanged: _toggleBiometric,
            ),
          ListTile(
            leading: const Icon(Icons.lock_reset_outlined),
            title: Text(l10n.changeMasterPassword),
            trailing: const Icon(Icons.chevron_right),
            onTap: _showChangePasswordDialog,
          ),
          ListTile(
            leading: const Icon(Icons.timer_outlined),
            title: Text(l10n.autoLockTimeout),
            subtitle: Text(l10n.lockAfterMinutes(autoLockMinutes)),
            trailing: const Icon(Icons.chevron_right),
            onTap: _showAutoLockPicker,
          ),
          const Divider(),
          _SettingsSectionHeader(l10n.sync),
          ListTile(
            leading: const Icon(Icons.sync),
            title: Text(l10n.syncMethod),
            subtitle: Text(_syncMethodsSubtitle(l10n, syncMethods)),
            trailing: const Icon(Icons.chevron_right),
            onTap: _showSyncMethodPicker,
          ),
          ListTile(
            leading: const Icon(Icons.cloud_sync),
            title: Text(l10n.webdavDriveLocalFile),
            subtitle: Text(l10n.configureCredentialsAndLinkFiles),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.go('/settings/webdav'),
          ),
          if (pendingConflicts.isNotEmpty)
            ListTile(
              leading: Badge(
                label: Text('${pendingConflicts.length}'),
                backgroundColor: Colors.redAccent,
                child: const Icon(Icons.merge_type),
              ),
              title: Text(l10n.syncConflictsScreenTitle),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.go('/settings/sync-conflicts'),
            ),
          ListTile(
            leading: const Icon(Icons.access_time),
            title: const Text('Last Sync'),
            subtitle: Text(
              lastSyncAt.when(
                data: (dt) => dt != null ? _formatSyncTime(dt) : 'Never',
                loading: () => '…',
                error: (error, stackTrace) => 'Unknown',
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.upload_file),
            title: Text(l10n.exportSyncSettings),
            subtitle: Text(l10n.exportSyncSettingsSubtitle),
            onTap: () => _exportSyncSettings(ref),
          ),
          ListTile(
            leading: const Icon(Icons.download),
            title: Text(l10n.importSyncSettings),
            subtitle: Text(l10n.importSyncSettingsSubtitle),
            onTap: () => _importSyncSettings(ref),
          ),
          const Divider(),
          _SettingsSectionHeader(l10n.dataManagement),
          ListTile(
            leading: const Icon(Icons.schema),
            title: Text(l10n.manageCustomAssetTypes),
            subtitle: Text(l10n.manageCustomAssetTypesSubtitle),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.go('/settings/asset-types'),
          ),
          ListTile(
            leading: const Icon(Icons.label_outline),
            title: Text(l10n.manageTags),
            subtitle: Text(l10n.manageTagsSubtitle),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.go('/settings/tags'),
          ),
          const Divider(),
          _SettingsSectionHeader(l10n.importExport),
          ListTile(
            leading: const Icon(Icons.file_download),
            title: Text(l10n.exportEncFile),
            subtitle: Text(l10n.exportEncFileSubtitle),
            onTap: () => exportEncToFile(ref),
          ),
          ListTile(
            leading: const Icon(Icons.file_upload),
            title: Text(l10n.importEncFile),
            subtitle: Text(l10n.importEncFileSubtitle),
            onTap: () => _importEncFile(ref),
          ),
          ListTile(
            leading: const Icon(Icons.download),
            title: Text(l10n.exportJsonToClipboard),
            onTap: () => _exportJson(ref),
          ),
          ListTile(
            leading: const Icon(Icons.upload),
            title: Text(l10n.importJsonFromClipboard),
            onTap: () => _importJson(ref),
          ),
          const Divider(),
          _SettingsSectionHeader(l10n.about),
          ListTile(
            leading: const Icon(Icons.language),
            title: Text(l10n.website),
            subtitle: Text(l10n.websiteUrl),
            trailing: const Icon(Icons.open_in_new, size: 18),
            onTap: () => _openUrl(kWebsiteUrl),
          ),
          ListTile(
            leading: const Icon(Icons.menu_book_outlined),
            title: Text(l10n.helpAndDocs),
            subtitle: Text(l10n.docsUrl),
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

/// Displays a security notice about the limitations of the web storage model.
class _WebSecurityBanner extends StatefulWidget {
  final AppLocalizations l10n;
  const _WebSecurityBanner({required this.l10n});

  @override
  State<_WebSecurityBanner> createState() => _WebSecurityBannerState();
}

class _ChangePasswordDialog extends ConsumerStatefulWidget {
  const _ChangePasswordDialog();

  @override
  ConsumerState<_ChangePasswordDialog> createState() =>
      _ChangePasswordDialogState();
}

class _ChangePasswordDialogState extends ConsumerState<_ChangePasswordDialog> {
  final _currentController = TextEditingController();
  final _newController = TextEditingController();
  final _confirmController = TextEditingController();

  @override
  void dispose() {
    _currentController.dispose();
    _newController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  bool get _isWeak =>
      _newController.text.isNotEmpty && _newController.text.length < 12;
  bool get _mismatch =>
      _confirmController.text.isNotEmpty &&
      _confirmController.text != _newController.text;

  bool get _canSubmit =>
      _currentController.text.isNotEmpty &&
      _newController.text.length >= 12 &&
      _confirmController.text == _newController.text;

  Future<void> _submit() async {
    if (!_canSubmit) return;
    await ref
        .read(changePasswordProvider.notifier)
        .changePassword(_currentController.text, _newController.text);

    if (!mounted) return;
    final nextState = ref.read(changePasswordProvider);
    if (nextState.isSuccess) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context)!.passwordChangedSuccessfully,
          ),
        ),
      );
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(changePasswordProvider);
    final submitEnabled = _canSubmit && !state.isLoading;

    return AlertDialog(
      backgroundColor: kSurfaceColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      title: Text(AppLocalizations.of(context)!.changeMasterPassword),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _currentController,
            obscureText: true,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              labelText: AppLocalizations.of(context)!.currentPassword,
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _newController,
            obscureText: true,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              labelText: AppLocalizations.of(context)!.newPassword,
              border: const OutlineInputBorder(),
            ),
          ),
          if (_isWeak)
            Padding(
              padding: EdgeInsets.only(top: 6),
              child: Text(
                AppLocalizations.of(context)!.passwordTooWeak,
                style: const TextStyle(
                  color: Colors.orangeAccent,
                  fontSize: 12,
                ),
              ),
            ),
          const SizedBox(height: 12),
          TextField(
            controller: _confirmController,
            obscureText: true,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              labelText: AppLocalizations.of(context)!.confirmNewPassword,
              border: const OutlineInputBorder(),
            ),
          ),
          if (_mismatch)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                AppLocalizations.of(context)!.passwordsDoNotMatch,
                style: const TextStyle(color: Colors.redAccent, fontSize: 12),
              ),
            ),
          if (state.hasError)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                state.errorMessage!,
                style: const TextStyle(color: Colors.redAccent, fontSize: 12),
              ),
            ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: state.isLoading ? null : () => Navigator.of(context).pop(),
          child: Text(AppLocalizations.of(context)!.cancel),
        ),
        FilledButton(
          onPressed: submitEnabled ? _submit : null,
          style: FilledButton.styleFrom(
            backgroundColor: kPrimaryGreen,
            foregroundColor: Colors.black,
            disabledBackgroundColor: kBorderColor,
          ),
          child: state.isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(AppLocalizations.of(context)!.changePasswordAction),
        ),
      ],
    );
  }
}

class _WebSecurityBannerState extends State<_WebSecurityBanner> {
  bool _dismissed = false;

  @override
  Widget build(BuildContext context) {
    if (_dismissed) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 12, 12, 0),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF2B2200),
        border: Border.all(color: const Color(0xFF7B6000)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.security_outlined,
            color: Color(0xFFFFC107),
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.l10n.webSecurityTitle,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFFFC107),
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.l10n.webSecurityBody,
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
                const SizedBox(height: 6),
                GestureDetector(
                  onTap: () async {
                    final uri = Uri.parse(kDocsUrl);
                    if (await canLaunchUrl(uri)) {
                      await launchUrl(
                        uri,
                        mode: LaunchMode.externalApplication,
                      );
                    }
                  },
                  child: Text(
                    widget.l10n.webSecurityLearnMore,
                    style: const TextStyle(
                      color: kPrimaryGreen,
                      fontSize: 12,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => setState(() => _dismissed = true),
            child: const Icon(Icons.close, size: 16, color: kTextMuted),
          ),
        ],
      ),
    );
  }
}
