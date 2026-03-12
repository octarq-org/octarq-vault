import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';

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

    if (pwd.length < 8) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password too short (8 chars min)')),
      );
      return;
    }

    if (pwd != confirm) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Passwords do not match')));
      return;
    }

    setState(() => _isCreating = true);

    final success = await ref
        .read(authProvider.notifier)
        .setupMasterPassword(pwd);

    if (!success && mounted) {
      final error =
          ref.read(authProvider.notifier).lastError ?? 'Unknown error';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to create vault: $error'),
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
    final result = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: const Text('Vault Found'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Enter your Master Password to unlock it.'),
              const SizedBox(height: 16),
              TextField(
                controller: pwdController,
                obscureText: true,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'Master Password',
                  border: OutlineInputBorder(),
                ),
                onSubmitted: (val) => Navigator.pop(context, val),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, pwdController.text),
              child: const Text('Unlock'),
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
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Vault restored successfully!')),
            );
          }
        } catch (e) {
          // Handled during external payload unlock internally
        }
      } else {
        final error =
            ref.read(authProvider.notifier).lastError ?? 'Incorrect password';
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Unlock failed: $error')));
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
            const SnackBar(content: Text('No backup found on Drive.')),
          );
        }
        return;
      }
      if (mounted) setState(() => _isCreating = false);
      await _promptForPasswordToRestore(bytes);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
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
                SnackBar(content: Text('Fallback Error: $innerE')),
              );
            }
          }
        } else if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error: $e')));
        }
      }
      if (mounted) setState(() => _isCreating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Welcome to AssetVault')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Set your Master Password',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'This password encrypts all your data locally. If you forget it, the data cannot be recovered.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 32),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Master Password',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _confirmController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Confirm Password',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            _isCreating
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: _submit,
                    child: const Text('Create Vault'),
                  ),
            if (!_isCreating && kIsWeb) ...[
              const SizedBox(height: 32),
              const Divider(),
              const SizedBox(height: 16),
              const Text(
                'Or restore an existing vault',
                style: TextStyle(
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
                  label: const Text('Restore from Google Drive'),
                ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: _handleRestoreFromLocal,
                icon: const Icon(Icons.file_open),
                label: const Text('Restore from Local File'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
