import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../l10n/app_localizations.dart';
import '../services/webdav_service.dart';
import '../services/e2ee_sync_service.dart';
import '../services/local_file_sync_service.dart';
import '../services/google_drive_service.dart';
import '../services/enc_file_io.dart';
import '../providers/assets_provider.dart';
import '../providers/asset_types_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/service_providers.dart';
import '../providers/sync_conflicts_provider.dart';
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
  final _webProxyRefController = TextEditingController();

  static const _webdavProxyPrefKey = 'webdav_proxy_base_url_web';

  Future<String?> _askBackupPassword(BuildContext context) {
    return showDialog<String>(
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
  }

  /// Try to decrypt with the current key; on failure, prompt for password.
  Future<VaultSnapshot?> _unpackOrAskPassword(Uint8List encrypted) async {
    final syncService = ref.read(e2eeSyncServiceProvider);
    try {
      return syncService.unpackCiphertextToSnapshot(encrypted);
    } catch (_) {
      // Current key can't decrypt — ask for the backup's password.
    }
    if (!mounted) return null;
    final pwd = await _askBackupPassword(context);
    if (pwd == null || pwd.isEmpty || !mounted) return null;
    final authNotifier = ref.read(authProvider.notifier);
    final success = await authNotifier.unlockWithExternalPayload(
      pwd,
      encrypted,
    );
    if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            authNotifier.lastError ??
                AppLocalizations.of(context)!.wrongPassword,
          ),
        ),
      );
      return null;
    }
    return authNotifier.consumeLastExternalSnapshot();
  }

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
    _loadWebProxyPref();
  }

  Future<void> _loadWebProxyPref() async {
    if (!kIsWeb) return;
    final prefs = await SharedPreferences.getInstance();
    final v = prefs.getString(_webdavProxyPrefKey);
    if (!mounted) return;
    if (v != null && v.isNotEmpty) {
      _webProxyRefController.text = v;
    }
    setState(() {});
  }

  Future<void> _saveWebProxyPref() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _webdavProxyPrefKey,
      _webProxyRefController.text.trim(),
    );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.webdavProxySaved)),
      );
    }
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
    _webProxyRefController.dispose();
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
      final snapshot = await _unpackOrAskPassword(encrypted);
      if (snapshot == null) return;

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
                    ExpansionTile(
                      tilePadding: const EdgeInsets.symmetric(horizontal: 4),
                      title: Text(l10n.webdavWebGuideTitle),
                      subtitle: Text(
                        l10n.webdavCorsWarning,
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 12,
                        ),
                      ),
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                l10n.webdavWebGuideBody,
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 13,
                                  height: 1.35,
                                ),
                              ),
                              const SizedBox(height: 16),
                              TextField(
                                controller: _webProxyRefController,
                                decoration: InputDecoration(
                                  labelText: l10n.webdavProxyBaseUrlLabel,
                                  hintText: l10n.webdavProxyBaseUrlHint,
                                  border: const OutlineInputBorder(),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                l10n.webdavProxySaveNote,
                                style: const TextStyle(
                                  color: Colors.white54,
                                  fontSize: 11,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Align(
                                alignment: Alignment.centerLeft,
                                child: FilledButton(
                                  onPressed: _saveWebProxyPref,
                                  child: Text(l10n.save),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
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
                              labelText: l10n.usernameOptional,
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _passController,
                            decoration: InputDecoration(
                              labelText: l10n.passwordOrAppTokenOptional,
                            ),
                            obscureText: true,
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
                      label: Text(l10n.restoreFromIcloud),
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
      final snapshot = await _unpackOrAskPassword(blob);
      if (snapshot == null) return;
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
      Uint8List? bytes;
      if (kIsWeb) {
        final localSync = ref.read(localFileSyncServiceProvider);
        bytes = await localSync.importRawBytesFromUpload();
      } else {
        bytes = await pickEncFileBytes(ref);
      }
      if (bytes == null || bytes.isEmpty || !mounted) return;
      final l10n = AppLocalizations.of(context)!;
      final pwd = await _askBackupPassword(context);
      if (pwd == null || pwd.isEmpty || !mounted) return;
      final authNotifier = ref.read(authProvider.notifier);
      final success = await authNotifier.unlockWithExternalPayload(pwd, bytes);
      if (!success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(authNotifier.lastError ?? l10n.wrongPassword)),
        );
        return;
      }
      final snapshot = authNotifier.consumeLastExternalSnapshot();
      if (snapshot == null) return;
      await ref
          .read(assetsProvider.notifier)
          .replaceFromSnapshot(snapshot, encryptedBlob: bytes);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.importSuccessCount(snapshot.assets.length)),
          ),
        );
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
      await exportEncToFile(ref);
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
      final remoteSnapshot = await _unpackOrAskPassword(remoteBlob);
      if (remoteSnapshot == null) return;
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

      if (mergeResult.conflicts.isNotEmpty) {
        ref
            .read(pendingSyncConflictsProvider.notifier)
            .mergeFrom(mergeResult.conflicts);
      }

      await ref
          .read(assetsProvider.notifier)
          .replaceFromSnapshot(mergeResult.snapshot);

      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        if (mergeResult.conflicts.isNotEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                l10n.driveMergeConflictsSnack(mergeResult.conflicts.length),
              ),
              action: SnackBarAction(
                label: l10n.openSyncConflictsAction,
                onPressed: () => context.push('/settings/sync-conflicts'),
              ),
            ),
          );
        } else {
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
