import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'package:flutter/foundation.dart';
import '../l10n/app_localizations.dart';
import '../services/webdav_service.dart';
import '../services/e2ee_sync_service.dart';
import '../services/local_file_sync_service.dart';
import '../services/google_drive_service.dart';
import '../services/enc_file_io.dart';
import '../models/asset.dart';
import '../providers/assets_provider.dart';
import '../providers/asset_types_provider.dart';
import '../providers/service_providers.dart';
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
    _initWebSignIn();
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
          SnackBar(
            content: Text(AppLocalizations.of(context)!.webdavConnectedSuccess),
          ),
        );
      }
      setState(() => _isConnected = true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(
                context,
              )!.webdavConnectionFailed(e.toString()),
            ),
          ),
        );
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
          SnackBar(
            content: Text(AppLocalizations.of(context)!.e2eeBackupSuccess),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)!.backupFailed(e.toString()),
            ),
          ),
        );
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
            content: Text(
              AppLocalizations.of(
                context,
              )!.restoredAssetsE2ee(snapshot.assets.length),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)!.restoreFailed(e.toString()),
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _buildUnifiedSyncUI(context);
  }

  Widget _buildUnifiedSyncUI(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.e2eeWebSync)),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: ListView(
                children: [
                  // ─── WebDAV ─────────────────────────────────────────────
                  Text(
                    l10n.webdavBackup,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (kIsWeb)
                    Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1C1A00),
                        border: Border.all(color: const Color(0xFF5C5000)),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.warning_amber_rounded,
                            color: Color(0xFFFFD600),
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              l10n.webdavCorsWarning,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (_isConnected)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Icon(
                          Icons.cloud_done,
                          size: 64,
                          color: Colors.green,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          l10n.webdavConnected,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: _backup,
                          icon: const Icon(Icons.cloud_upload),
                          label: Text(l10n.backupToWebdav),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.all(16),
                          ),
                        ),
                        const SizedBox(height: 8),
                        OutlinedButton.icon(
                          onPressed: _restore,
                          icon: const Icon(Icons.cloud_download),
                          label: Text(l10n.restoreFromWebdav),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.all(16),
                          ),
                        ),
                        TextButton(
                          onPressed: _disconnect,
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.red,
                          ),
                          child: Text(l10n.disconnectClearCredentials),
                        ),
                      ],
                    )
                  else
                    Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            l10n.webdavConfigureDescription,
                            style: const TextStyle(color: Colors.grey),
                          ),
                          const SizedBox(height: 24),
                          TextFormField(
                            controller: _urlController,
                            decoration: InputDecoration(
                              labelText: l10n.serverUrl,
                              hintText: l10n.serverUrlHint,
                            ),
                            validator: (val) => val == null || val.isEmpty
                                ? l10n.required
                                : null,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _userController,
                            decoration: InputDecoration(
                              labelText: l10n.username,
                            ),
                            validator: (val) => val == null || val.isEmpty
                                ? l10n.required
                                : null,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _passController,
                            decoration: InputDecoration(
                              labelText: l10n.passwordOrAppToken,
                            ),
                            obscureText: true,
                            validator: (val) => val == null || val.isEmpty
                                ? l10n.required
                                : null,
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton(
                            onPressed: _connect,
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.all(16),
                            ),
                            child: Text(l10n.connect),
                          ),
                        ],
                      ),
                    ),
                  const Divider(height: 48),
                  // ─── 本地磁盘同步 ───────────────────────────────────────
                  Text(
                    l10n.localDiskSyncE2ee,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.localDiskSyncDescription,
                    style: const TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () => _handleLocalSync(createNew: true),
                    icon: const Icon(Icons.add_box),
                    label: Text(l10n.createNewEncryptedVaultFile),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: () => _handleLocalSync(createNew: false),
                    icon: const Icon(Icons.file_open),
                    label: Text(l10n.linkExistingVaultFile),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      TextButton.icon(
                        onPressed: _handleLocalImportFallback,
                        icon: const Icon(Icons.upload_file),
                        label: Text(l10n.importFallback),
                      ),
                      TextButton.icon(
                        onPressed: _handleLocalExportFallback,
                        icon: const Icon(Icons.download),
                        label: Text(l10n.exportFallback),
                      ),
                    ],
                  ),
                  const Divider(height: 48),
                  // ─── Google 云端硬盘 ─────────────────────────────────────
                  Text(
                    l10n.googleDriveSyncE2ee,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.googleDriveSyncDescription,
                    style: const TextStyle(color: Colors.grey),
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
                      label: Text(l10n.authorizeSyncGoogleDrive),
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: _handleGoogleDrivePull,
                      icon: const Icon(Icons.cloud_download),
                      label: Text(l10n.pullFromGoogleDrive),
                    ),
                  ],
                  // ─── iCloud (iOS only) ────────────────────────────────────
                  if (!kIsWeb &&
                      defaultTargetPlatform == TargetPlatform.iOS) ...[
                    const Divider(height: 48),
                    Text(
                      l10n.icloudBackup,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l10n.icloudBackupSubtitle,
                      style: const TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _handleICloudBackup,
                      icon: const Icon(Icons.backup),
                      label: Text(l10n.icloudBackup),
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: _handleICloudRestore,
                      icon: const Icon(Icons.restore),
                      label: Text(l10n.restoreFromWebdav),
                    ),
                  ],
                ],
              ),
            ),
    );
  }

  Future<void> _handleICloudBackup() async {
    setState(() => _isLoading = true);
    try {
      final assets = ref.read(assetsProvider);
      final syncService = ref.read(e2eeSyncServiceProvider);
      final customTypes = ref
          .read(assetTypesProvider)
          .where((t) => !t.isBuiltIn)
          .toList();
      final blob = syncService.packSnapshotTOCiphertext(
        assets,
        customAssetTypes: customTypes,
      );
      await ref.read(iCloudSyncServiceProvider).backup(blob);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.icloudBackupSuccess),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)!.backupFailed(e.toString()),
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleICloudRestore() async {
    setState(() => _isLoading = true);
    try {
      final icloud = ref.read(iCloudSyncServiceProvider);
      final blob = await icloud.restore();
      if (blob == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context)!.icloudNotAvailable),
            ),
          );
        }
        return;
      }
      final syncService = ref.read(e2eeSyncServiceProvider);
      final snapshot = syncService.unpackCiphertextToSnapshot(blob);
      await ref
          .read(assetsProvider.notifier)
          .replaceFromSnapshot(snapshot, encryptedBlob: blob);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(
                context,
              )!.icloudRestoreSuccess(snapshot.assets.length),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)!.restoreFailed(e.toString()),
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
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
                  AppLocalizations.of(
                    context,
                  )!.restoredAssetsFromFile(snapshot.assets.length),
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
        final l10n = AppLocalizations.of(context)!;
        if (e.toString().contains('File System Access API')) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.browserNoFilePickUseFallback),
              duration: const Duration(seconds: 4),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.errorGeneric(e.toString()))),
          );
        }
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleLocalImportFallback() async {
    setState(() => _isLoading = true);
    try {
      if (kIsWeb) {
        final localSync = ref.read(localFileSyncServiceProvider);
        final snapshot = await localSync.importFromUpload();
        if (snapshot != null) {
          await ref.read(assetsProvider.notifier).replaceFromSnapshot(snapshot);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  AppLocalizations.of(
                    context,
                  )!.importSuccessCount(snapshot.assets.length),
                ),
              ),
            );
          }
        }
      } else {
        final bytes = await pickEncFileBytes(ref);
        if (bytes != null && bytes.isNotEmpty && mounted) {
          final syncService = ref.read(e2eeSyncServiceProvider);
          final snapshot = syncService.unpackCiphertextToSnapshot(bytes);
          await ref.read(assetsProvider.notifier).replaceFromSnapshot(snapshot);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  AppLocalizations.of(
                    context,
                  )!.importSuccessCount(snapshot.assets.length),
                ),
              ),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)!.importError(e.toString()),
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleLocalExportFallback() async {
    if (kIsWeb) {
      final localSync = ref.read(localFileSyncServiceProvider);
      localSync.exportToDownload(ref.read(assetsProvider));
    } else {
      await exportEncToFile(ref);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.exportEncFileSubtitle),
          ),
        );
      }
    }
  }

  Future<void> _handleGoogleDriveSignInAndSync() async {
    setState(() => _isLoading = true);
    try {
      final driveSync = ref.read(googleDriveServiceProvider);
      await driveSync.signIn();
      await driveSync.syncToDrive(ref.read(assetsProvider));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)!.pushedToGoogleDriveSuccess,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)!.driveError(e.toString()),
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// Shows a dialog to resolve a sync conflict. Returns the asset the user chose
  /// to keep, or null to skip (keep current winner from LWW).
  Future<Asset?> _showConflictDialog(AssetConflict conflict) async {
    if (!mounted) return null;
    return showDialog<Asset>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: Text('Sync Conflict: "${conflict.local.name}"'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Both devices edited this asset at the same time. Choose which version to keep:',
                style: TextStyle(fontSize: 13),
              ),
              const SizedBox(height: 16),
              _ConflictVersionCard(label: 'This device', asset: conflict.local),
              const SizedBox(height: 8),
              _ConflictVersionCard(
                label: 'Remote device',
                asset: conflict.remote,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, conflict.local),
            child: const Text('Keep This Device'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, conflict.remote),
            child: const Text('Keep Remote'),
          ),
        ],
      ),
    );
  }

  Future<void> _handleGoogleDrivePull() async {
    setState(() => _isLoading = true);
    try {
      final driveSync = ref.read(googleDriveServiceProvider);
      await driveSync.signIn();
      final remoteBlob = await driveSync.readRawBytesFromDrive();
      if (remoteBlob == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context)!.noBackupFoundOnDrive),
            ),
          );
        }
        return;
      }

      // LWW merge: remote wins for same-id assets with newer updatedAt.
      final syncService = ref.read(e2eeSyncServiceProvider);
      final remoteSnapshot = syncService.unpackCiphertextToSnapshot(remoteBlob);
      final localAssets = ref.read(assetsProvider);
      final localCustomTypes = ref
          .read(assetTypesProvider)
          .where((t) => !t.isBuiltIn)
          .toList();

      final localSnapshot = VaultSnapshot(
        version: 2,
        assets: localAssets,
        customAssetTypes: localCustomTypes,
      );
      final mergeResult = VaultSnapshot.mergeSnapshots(
        local: localSnapshot,
        remote: remoteSnapshot,
      );
      var merged = mergeResult.snapshot;

      // Resolve conflicts (same id, same updatedAt, different content)
      if (mergeResult.conflicts.isNotEmpty && mounted) {
        for (final conflict in mergeResult.conflicts) {
          final winner = await _showConflictDialog(conflict);
          if (winner != null) {
            final assets = merged.assets.toList();
            final idx = assets.indexWhere((a) => a.id == winner.id);
            if (idx >= 0) assets[idx] = winner;
            merged = VaultSnapshot(
              version: merged.version,
              assets: assets,
              customAssetTypes: merged.customAssetTypes,
              relations: merged.relations,
              tombstones: merged.tombstones,
            );
          }
        }
      }

      await ref.read(assetsProvider.notifier).replaceFromSnapshot(merged);

      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              l10n.driveSmartMergeSuccess(
                localAssets.length,
                remoteSnapshot.assets.length,
              ),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)!.driveError(e.toString()),
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}

/// A card summarising one version of an asset for conflict resolution.
class _ConflictVersionCard extends StatelessWidget {
  final String label;
  final Asset asset;

  const _ConflictVersionCard({required this.label, required this.asset});

  @override
  Widget build(BuildContext context) {
    final updated = DateTime.fromMillisecondsSinceEpoch(asset.updatedAt);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.white24),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          ),
          const SizedBox(height: 4),
          Text(
            'Updated: ${updated.toLocal()}',
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
          Text(
            '${asset.fields.length} field(s)',
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
