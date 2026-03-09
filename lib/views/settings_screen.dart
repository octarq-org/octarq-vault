import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/auth_provider.dart';
import '../providers/assets_provider.dart';
import '../models/asset.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  void _exportJson(WidgetRef ref) {
    final assets = ref.read(assetsProvider);
    final jsonList = assets.map((a) => a.toJson()).toList();
    final jsonString = jsonEncode(jsonList);

    Clipboard.setData(ClipboardData(text: jsonString));

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Exported JSON copied to clipboard!')),
      );
    }
  }

  Future<void> _importJson(WidgetRef ref) async {
    final scaffoldMsgr = ScaffoldMessenger.of(context);

    try {
      final clipboardData = await Clipboard.getData(Clipboard.kTextPlain);
      if (clipboardData == null ||
          clipboardData.text == null ||
          clipboardData.text!.isEmpty) {
        throw Exception("Clipboard is empty");
      }

      final jsonList = jsonDecode(clipboardData.text!) as List;
      final assetsNotifier = ref.read(assetsProvider.notifier);

      int imported = 0;
      for (var jsonMap in jsonList) {
        final asset = Asset.fromJson(jsonMap as Map<String, dynamic>);
        await assetsNotifier.addAsset(asset);
        imported++;
      }

      if (mounted) {
        scaffoldMsgr.showSnackBar(
          SnackBar(content: Text('Successfully imported $imported assets!')),
        );
      }
    } catch (e) {
      if (mounted) {
        scaffoldMsgr.showSnackBar(
          const SnackBar(
            content: Text('Invalid JSON in clipboard for import.'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.lock_outline),
            title: const Text('Lock Vault'),
            onTap: () {
              ref.read(authProvider.notifier).lock();
            },
          ),
          ListTile(
            leading: const Icon(Icons.fingerprint),
            title: const Text('Biometric Settings'),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.cloud_sync),
            title: const Text('WebDAV Sync Settings'),
            subtitle: const Text('Backup encrypted db to remote server'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.go('/settings/webdav'),
          ),
          ListTile(
            leading: const Icon(Icons.schema),
            title: const Text('Manage Custom Asset Types'),
            subtitle: const Text(
              'Create your own custom asset templates and properties',
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.go('/settings/asset-types'),
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
        ],
      ),
    );
  }
}
