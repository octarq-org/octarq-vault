import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'package:flutter/foundation.dart';
import '../services/webdav_service.dart';
import '../services/e2ee_sync_service.dart';
import '../services/local_file_sync_service.dart';
import '../services/google_drive_service.dart';
import '../providers/assets_provider.dart';
import '../providers/asset_types_provider.dart';
import '../widgets/google_sign_in_button.dart';

class WebDavSettingsScreen extends ConsumerStatefulWidget {
  const WebDavSettingsScreen({super.key});

  @override
  ConsumerState<WebDavSettingsScreen> createState() =>
      _WebDavSettingsScreenState();
}

class _WebDavSettingsScreenState extends ConsumerState<WebDavSettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _urlController = TextEditingController();
  final _userController = TextEditingController();
  final _passController = TextEditingController();

  bool _isLoading = false;
  bool _isConnected = false;
  bool _isGoogleSignedIn = false;
  bool _googleSignInReady = false;
  StreamSubscription? _googleSignSub;

  @override
  void initState() {
    super.initState();
    _checkStatus();
    if (kIsWeb) _initWebSignIn();
  }

  Future<void> _initWebSignIn() async {
    try {
      await GoogleSignIn.instance.initialize();
      if (!mounted) return;
      setState(() => _googleSignInReady = true);
      _googleSignSub = GoogleSignIn.instance.authenticationEvents.listen((
        event,
      ) {
        if (event is GoogleSignInAuthenticationEventSignIn) {
          setState(() => _isGoogleSignedIn = true);
        } else if (event is GoogleSignInAuthenticationEventSignOut) {
          setState(() => _isGoogleSignedIn = false);
        }
      });
    } catch (e) {
      if (kDebugMode) print('Init web sign in failed: $e');
      if (mounted) setState(() => _googleSignInReady = true);
    }
  }

  Future<void> _checkStatus() async {
    final webDavService = ref.read(webDavServiceProvider);
    final hasCreds = await webDavService.hasCredentials();

    final driveService = ref.read(googleDriveServiceProvider);
    final hasGoogleCreds = await driveService.hasCredentials();

    setState(() {
      _isConnected = hasCreds;
      _isGoogleSignedIn = hasGoogleCreds;
    });
  }

  @override
  void dispose() {
    _googleSignSub?.cancel();
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
      await webDavService.connect(
        _urlController.text,
        _userController.text,
        _passController.text,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Connected to WebDAV successfully!')),
        );
      }
      setState(() => _isConnected = true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Connection failed: $e')));
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
      final syncService = ref.read(e2eeSyncServiceProvider);
      final customTypes = ref
          .read(assetTypesProvider)
          .where((t) => !t.isBuiltIn)
          .toList();
      final encrypted = syncService.packSnapshotTOCiphertext(
        assets,
        customAssetTypes: customTypes,
      );

      final webDavService = ref.read(webDavServiceProvider);
      await webDavService.backupEncrypted(encrypted);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('E2EE backup successful!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Backup failed: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _restore() async {
    setState(() => _isLoading = true);
    try {
      final webDavService = ref.read(webDavServiceProvider);
      final encrypted = await webDavService.restoreEncrypted();
      final syncService = ref.read(e2eeSyncServiceProvider);
      final snapshot = syncService.unpackCiphertextToSnapshot(encrypted);

      await ref
          .read(assetsProvider.notifier)
          .replaceFromSnapshot(snapshot, encryptedBlob: encrypted);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Restored ${snapshot.assets.length} assets (E2EE)'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Restore failed: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      return _buildWebSyncUI(context);
    }
    return _buildWebDavUI(context);
  }

  Widget _buildWebDavUI(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('WebDAV Backup')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: _isConnected
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.cloud_done,
                          size: 80,
                          color: Colors.green,
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          'WebDAV Connected',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 32),
                        ElevatedButton.icon(
                          onPressed: _backup,
                          icon: const Icon(Icons.cloud_upload),
                          label: const Text('Backup to WebDAV'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.all(16),
                          ),
                        ),
                        const SizedBox(height: 16),
                        OutlinedButton.icon(
                          onPressed: _restore,
                          icon: const Icon(Icons.cloud_download),
                          label: const Text('Restore from WebDAV'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.all(16),
                          ),
                        ),
                        const Spacer(),
                        TextButton(
                          onPressed: _disconnect,
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.red,
                          ),
                          child: const Text('Disconnect & Clear Credentials'),
                        ),
                      ],
                    )
                  : Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Text(
                            'Configure your WebDAV server (e.g., Nextcloud, ownCloud, Nutstore) to securely backup your encrypted database payload.',
                            style: TextStyle(color: Colors.grey),
                          ),
                          const SizedBox(height: 24),
                          TextFormField(
                            controller: _urlController,
                            decoration: const InputDecoration(
                              labelText: 'Server URL',
                              hintText:
                                  'https://example.com/remote.php/webdav/',
                            ),
                            validator: (val) =>
                                val == null || val.isEmpty ? 'Required' : null,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _userController,
                            decoration: const InputDecoration(
                              labelText: 'Username',
                            ),
                            validator: (val) =>
                                val == null || val.isEmpty ? 'Required' : null,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _passController,
                            decoration: const InputDecoration(
                              labelText: 'Password / App Token',
                            ),
                            obscureText: true,
                            validator: (val) =>
                                val == null || val.isEmpty ? 'Required' : null,
                          ),
                          const SizedBox(height: 32),
                          ElevatedButton(
                            onPressed: _connect,
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.all(16),
                            ),
                            child: const Text('Connect'),
                          ),
                        ],
                      ),
                    ),
            ),
    );
  }

  Widget _buildWebSyncUI(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('E2EE Web Sync')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: ListView(
                children: [
                  const Text(
                    'Local Disk Sync (E2EE Encrypted)',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Maintain a local encrypted vault file. This file will be silently updated on your desktop after every change.',
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () => _handleLocalSync(createNew: true),
                    icon: const Icon(Icons.add_box),
                    label: const Text('Create New Encrypted Vault File'),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: () => _handleLocalSync(createNew: false),
                    icon: const Icon(Icons.file_open),
                    label: const Text('Link Existing Vault File'),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      TextButton.icon(
                        onPressed: _handleLocalImportFallback,
                        icon: const Icon(Icons.upload_file),
                        label: const Text('Import Fallback'),
                      ),
                      TextButton.icon(
                        onPressed: _handleLocalExportFallback,
                        icon: const Icon(Icons.download),
                        label: const Text('Export Fallback'),
                      ),
                    ],
                  ),
                  const Divider(height: 48),
                  const Text(
                    'Google Drive Sync (E2EE Encrypted)',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Sync automatically to a hidden appDataFolder in your Google Drive. Completely zero-knowledge.',
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  if (kIsWeb && !_isGoogleSignedIn)
                    _googleSignInReady
                        ? Padding(
                            padding: const EdgeInsets.only(bottom: 8.0),
                            child: SizedBox(
                              height: 44,
                              width: 250,
                              child: buildWebGoogleSignInButton(),
                            ),
                          )
                        : const SizedBox(height: 44, width: 250)
                  else ...[
                    ElevatedButton.icon(
                      onPressed: _handleGoogleDriveSignInAndSync,
                      icon: const Icon(Icons.cloud_sync),
                      label: const Text('Authorize & Sync with Google Drive'),
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: _handleGoogleDrivePull,
                      icon: const Icon(Icons.cloud_download),
                      label: const Text(
                        'Pull from Google Drive (Overwrite Local)',
                      ),
                    ),
                  ],
                ],
              ),
            ),
    );
  }

  Future<void> _handleLocalSync({required bool createNew}) async {
    setState(() => _isLoading = true);
    try {
      final localSync = ref.read(localFileSyncServiceProvider);
      await localSync.linkFileForSync(createNew: createNew);

      if (!createNew) {
        final snapshot = await localSync.readFromLocal();
        if (snapshot != null) {
          await ref.read(assetsProvider.notifier).replaceFromSnapshot(snapshot);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Restored ${snapshot.assets.length} assets from file',
                ),
              ),
            );
          }
        }
      } else {
        // It's a brand new file, immediately flush the current state to it
        final currentAssets = ref.read(assetsProvider);
        await localSync.syncToLocal(currentAssets);
      }
    } catch (e) {
      if (mounted) {
        if (e.toString().contains('File System Access API')) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Your browser does not support picking files directly. Please use the Import/Export fallback buttons below.',
              ),
              duration: Duration(seconds: 4),
            ),
          );
        } else {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error: $e')));
        }
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleLocalImportFallback() async {
    setState(() => _isLoading = true);
    try {
      final localSync = ref.read(localFileSyncServiceProvider);
      final snapshot = await localSync.importFromUpload();
      if (snapshot != null) {
        await ref.read(assetsProvider.notifier).replaceFromSnapshot(snapshot);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Imported ${snapshot.assets.length} assets!'),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Import Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _handleLocalExportFallback() {
    final localSync = ref.read(localFileSyncServiceProvider);
    localSync.exportToDownload(ref.read(assetsProvider));
  }

  Future<void> _handleGoogleDriveSignInAndSync() async {
    setState(() => _isLoading = true);
    try {
      final driveSync = ref.read(googleDriveServiceProvider);
      await driveSync.signIn();
      await driveSync.syncToDrive(ref.read(assetsProvider));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Successfully securely pushed to Google Drive'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Drive Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleGoogleDrivePull() async {
    setState(() => _isLoading = true);
    try {
      final driveSync = ref.read(googleDriveServiceProvider);
      await driveSync.signIn();
      final snapshot = await driveSync.readFromDrive();
      if (snapshot != null) {
        await ref.read(assetsProvider.notifier).replaceFromSnapshot(snapshot);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Restored ${snapshot.assets.length} assets from Drive',
              ),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No backup found on Drive.')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Drive Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}
