import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../providers/auth_provider.dart';
import '../providers/assets_provider.dart';
import '../models/asset.dart';
import '../main.dart';
import '../providers/service_providers.dart';
import '../providers/relations_provider.dart';

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
      final assetsNotifier = ref.read(assetsProvider.notifier);
      int imported = 0;
      for (var item in assetList) {
        final asset = Asset.fromJson(item as Map<String, dynamic>);
        await assetsNotifier.addAsset(asset);
        imported++;
      }
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
          SnackBar(content: Text('Successfully imported $imported assets!')),
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

  @override
  Widget build(BuildContext context) {
    final autoLockMinutes = ref.watch(autoLockMinutesProvider);

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
          const _SettingsSectionHeader('Data Management'),
          ListTile(
            leading: const Icon(Icons.cloud_sync),
            title: const Text('WebDAV Sync Settings'),
            subtitle: const Text('Backup encrypted vault to remote server'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.go('/settings/webdav'),
          ),
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
            leading: const Icon(Icons.download),
            title: const Text('Export JSON to Clipboard'),
            onTap: () => _exportJson(ref),
          ),
          ListTile(
            leading: const Icon(Icons.upload),
            title: const Text('Import JSON (from clipboard)'),
            onTap: () => _importJson(ref),
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
