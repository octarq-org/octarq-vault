import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../l10n/app_localizations.dart';
import '../providers/auth_provider.dart';
import '../providers/assets_provider.dart';
import '../services/e2ee_sync_service.dart';
import '../services/google_drive_service.dart';
import '../services/local_file_sync_service.dart';
import '../widgets/google_sign_in_button.dart';

class SetupScreen extends ConsumerStatefulWidget {
  const SetupScreen({super.key});

  @override
  ConsumerState<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends ConsumerState<SetupScreen> {
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _isCreating = false;
  bool _googleSignInReady = false;
  StreamSubscription? _googleSignSub;

  @override
  void initState() {
    super.initState();
    if (kIsWeb) {
      _initWebSignIn();
    }
  }

  Future<void> _initWebSignIn() async {
    try {
      // await GoogleSignIn.instance.initialize();
      if (!mounted) return;
      setState(() => _googleSignInReady = true);
      _googleSignSub = GoogleSignIn.instance.authenticationEvents.listen((
        event,
      ) {
        if (event is GoogleSignInAuthenticationEventSignIn) {
          _handleRestoreFromDrive(isAlreadySignedIn: true);
        }
      });
    } catch (e) {
      if (kDebugMode) print('Init web sign in failed: $e');
      if (mounted) {
        setState(
          () => _googleSignInReady = true,
        ); // show button anyway to avoid blocking UI
      }
    }
  }

  @override
  void dispose() {
    _googleSignSub?.cancel();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final pwd = _passwordController.text;
    final confirm = _confirmController.text;

    final l10n = AppLocalizations.of(context)!;
    if (pwd.length < 8) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.passwordTooShort)));
      return;
    }

    if (pwd != confirm) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.passwordsDoNotMatch)));
      return;
    }

    setState(() => _isCreating = true);

    final success = await ref
        .read(authProvider.notifier)
        .setupMasterPassword(pwd);

    if (!success && mounted) {
      final l10n = AppLocalizations.of(context)!;
      final error =
          ref.read(authProvider.notifier).lastError ?? l10n.unknownError;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.createVaultFailed(error)),
          duration: const Duration(seconds: 5),
        ),
      );
    }

    if (mounted) {
      setState(() => _isCreating = false);
    }
  }

  Future<void> _promptForPasswordToRestore(Uint8List payload) async {
    final pwdController = TextEditingController();
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);

    final result = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: Text(l10n.vaultFound),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(l10n.enterMasterPasswordToUnlock),
              const SizedBox(height: 16),
              TextField(
                controller: pwdController,
                obscureText: true,
                autofocus: true,
                decoration: InputDecoration(
                  labelText: l10n.masterPassword,
                  border: const OutlineInputBorder(),
                ),
                onSubmitted: (val) => Navigator.pop(context, val),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(l10n.cancel),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, pwdController.text),
              child: Text(l10n.unlock),
            ),
          ],
        );
      },
    );

    if (result != null && result.isNotEmpty) {
      setState(() => _isCreating = true);
      final success = await ref
          .read(authProvider.notifier)
          .unlockWithExternalPayload(result, payload);

      if (success) {
        try {
          final syncService = ref.read(e2eeSyncServiceProvider);
          final snapshot = syncService.unpackCiphertextToSnapshot(payload);
          await ref
              .read(assetsProvider.notifier)
              .replaceFromSnapshot(snapshot, encryptedBlob: payload);
          if (mounted) {
            messenger.showSnackBar(
              SnackBar(content: Text(l10n.vaultRestoredSuccess)),
            );
          }
        } catch (e) {
          // Handled during external payload unlock internally
        }
      } else {
        final error =
            ref.read(authProvider.notifier).lastError ?? l10n.incorrectPassword;
        if (mounted) {
          messenger.showSnackBar(
            SnackBar(content: Text(l10n.unlockFailed(error))),
          );
        }
      }
      if (mounted) setState(() => _isCreating = false);
    }
  }

  Future<void> _handleRestoreFromDrive({bool isAlreadySignedIn = false}) async {
    setState(() => _isCreating = true);
    try {
      final driveSync = ref.read(googleDriveServiceProvider);
      if (!isAlreadySignedIn) {
        await driveSync.signIn();
      }
      final bytes = await driveSync.readRawBytesFromDrive();
      if (bytes == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context)!.noBackupFoundOnDrive),
            ),
          );
        }
        return;
      }
      if (mounted) setState(() => _isCreating = false);
      await _promptForPasswordToRestore(bytes);
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
    } finally {
      if (mounted) setState(() => _isCreating = false);
    }
  }

  Future<void> _handleRestoreFromLocal() async {
    setState(() => _isCreating = true);
    try {
      final localSync = ref.read(localFileSyncServiceProvider);
      await localSync.linkFileForSync(createNew: false);
      Uint8List? bytes = await localSync.readRawBytesFromLocal();
      bytes ??= await localSync.importRawBytesFromUpload();

      if (bytes != null) {
        if (mounted) setState(() => _isCreating = false);
        await _promptForPasswordToRestore(bytes);
      } else {
        if (mounted) setState(() => _isCreating = false);
      }
    } catch (e) {
      if (mounted) {
        if (e.toString().contains('File System Access API')) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Your browser does not support picking files directly. Please use the Fallback method (Upload File).',
              ),
              duration: Duration(seconds: 4),
            ),
          );
          // 自动回退触发 fallback 选文件
          try {
            final localSync = ref.read(localFileSyncServiceProvider);
            final bytes = await localSync.importRawBytesFromUpload();
            if (bytes != null && mounted) {
              setState(() => _isCreating = false);
              await _promptForPasswordToRestore(bytes);
            }
          } catch (innerE) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    AppLocalizations.of(
                      context,
                    )!.fallbackError(innerE.toString()),
                  ),
                ),
              );
            }
          }
        } else if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                AppLocalizations.of(context)!.errorGeneric(e.toString()),
              ),
            ),
          );
        }
      }
      if (mounted) setState(() => _isCreating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/logo.png',
              width: 28,
              height: 28,
              fit: BoxFit.contain,
            ),
            const SizedBox(width: 10),
            Text(AppLocalizations.of(context)!.welcomeToOctarqVault),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              AppLocalizations.of(context)!.setMasterPassword,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              AppLocalizations.of(context)!.setupPasswordDescription,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 32),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context)!.masterPassword,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _confirmController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context)!.confirmPassword,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            _isCreating
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: _submit,
                    child: Text(AppLocalizations.of(context)!.createVault),
                  ),
            if (!_isCreating && kIsWeb) ...[
              const SizedBox(height: 32),
              const Divider(),
              const SizedBox(height: 16),
              Text(
                AppLocalizations.of(context)!.orRestoreExistingVault,
                style: const TextStyle(
                  color: Colors.grey,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              if (kIsWeb)
                _googleSignInReady
                    ? Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: SizedBox(
                          height: 44,
                          width: 280,
                          child: buildWebGoogleSignInButton(),
                        ),
                      )
                    : const SizedBox(height: 44, width: 280)
              else
                OutlinedButton.icon(
                  onPressed: () => _handleRestoreFromDrive(),
                  icon: const Icon(Icons.cloud_download),
                  label: Text(
                    AppLocalizations.of(context)!.restoreFromGoogleDrive,
                  ),
                ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: _handleRestoreFromLocal,
                icon: const Icon(Icons.file_open),
                label: Text(AppLocalizations.of(context)!.restoreFromLocalFile),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
