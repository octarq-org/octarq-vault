import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/webdav_service.dart';
import '../providers/assets_provider.dart';
import '../models/asset.dart';

class WebDavSettingsScreen extends ConsumerStatefulWidget {
  const WebDavSettingsScreen({super.key});

  @override
  ConsumerState<WebDavSettingsScreen> createState() => _WebDavSettingsScreenState();
}

class _WebDavSettingsScreenState extends ConsumerState<WebDavSettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _urlController = TextEditingController();
  final _userController = TextEditingController();
  final _passController = TextEditingController();
  
  bool _isLoading = false;
  bool _isConnected = false;

  @override
  void initState() {
    super.initState();
    _checkStatus();
  }

  Future<void> _checkStatus() async {
    final webDavService = ref.read(webDavServiceProvider);
    final hasCreds = await webDavService.hasCredentials();
    setState(() {
      _isConnected = hasCreds;
    });
  }

  @override
  void dispose() {
    _urlController.dispose();
    _userController.dispose();
    _passController.dispose();
    super.dispose();
  }

  Future<void> _connect() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isLoading = true);
    try {
      final webDavService = ref.read(webDavServiceProvider);
      await webDavService.connect(_urlController.text, _userController.text, _passController.text);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Connected to WebDAV successfully!')));
      }
      setState(() => _isConnected = true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Connection failed: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _disconnect() async {
    final webDavService = ref.read(webDavServiceProvider);
    await webDavService.clearCredentials();
    setState(() {
      _isConnected = false;
      _urlController.clear();
      _userController.clear();
      _passController.clear();
    });
  }

  Future<void> _backup() async {
    setState(() => _isLoading = true);
    try {
      final assets = ref.read(assetsProvider);
      final jsonList = assets.map((a) => a.toJson()).toList();
      final jsonString = jsonEncode(jsonList);

      final webDavService = ref.read(webDavServiceProvider);
      await webDavService.backupJson(jsonString);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Backup successful!')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Backup failed: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _restore() async {
    setState(() => _isLoading = true);
    try {
      final webDavService = ref.read(webDavServiceProvider);
      final jsonString = await webDavService.restoreJson();
      
      final jsonList = jsonDecode(jsonString) as List;
      final assetsNotifier = ref.read(assetsProvider.notifier);
      
      int imported = 0;
      for (var jsonMap in jsonList) {
        final asset = Asset.fromJson(jsonMap as Map<String, dynamic>);
        await assetsNotifier.addAsset(asset);
        imported++;
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Restore successful! ($imported assets)')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Restore failed: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('WebDAV Backup'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: _isConnected
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.cloud_done, size: 80, color: Colors.green),
                        const SizedBox(height: 24),
                        const Text(
                          'WebDAV Connected',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 32),
                        ElevatedButton.icon(
                          onPressed: _backup,
                          icon: const Icon(Icons.cloud_upload),
                          label: const Text('Backup to WebDAV'),
                          style: ElevatedButton.styleFrom(padding: const EdgeInsets.all(16)),
                        ),
                        const SizedBox(height: 16),
                        OutlinedButton.icon(
                          onPressed: _restore,
                          icon: const Icon(Icons.cloud_download),
                          label: const Text('Restore from WebDAV'),
                          style: OutlinedButton.styleFrom(padding: const EdgeInsets.all(16)),
                        ),
                        const Spacer(),
                        TextButton(
                          onPressed: _disconnect,
                          style: TextButton.styleFrom(foregroundColor: Colors.red),
                          child: const Text('Disconnect & Clear Credentials'),
                        )
                      ],
                    )
                  : Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Text('Configure your WebDAV server (e.g., Nextcloud, ownCloud, Nutstore) to securely backup your encrypted database payload.', style: TextStyle(color: Colors.grey)),
                          const SizedBox(height: 24),
                          TextFormField(
                            controller: _urlController,
                            decoration: const InputDecoration(labelText: 'Server URL', hintText: 'https://example.com/remote.php/webdav/'),
                            validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _userController,
                            decoration: const InputDecoration(labelText: 'Username'),
                            validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _passController,
                            decoration: const InputDecoration(labelText: 'Password / App Token'),
                            obscureText: true,
                            validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                          ),
                          const SizedBox(height: 32),
                          ElevatedButton(
                            onPressed: _connect,
                            style: ElevatedButton.styleFrom(padding: const EdgeInsets.all(16)),
                            child: const Text('Connect'),
                          ),
                        ],
                      ),
                    ),
            ),
    );
  }
}
