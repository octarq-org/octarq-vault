import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../l10n/app_localizations.dart';
import '../providers/auth_provider.dart';
import '../providers/service_providers.dart';

class LockScreen extends ConsumerStatefulWidget {
  const LockScreen({super.key});

  @override
  ConsumerState<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends ConsumerState<LockScreen> {
  final _passwordController = TextEditingController();
  bool _isUnlocking = false;
  bool _biometricEnabled = true;
  bool _passkeyEnabled = false;

  @override
  void initState() {
    super.initState();
    if (!kIsWeb) {
      _loadBiometricSetting().then((_) {
        if (_biometricEnabled) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _tryBiometricUnlock();
          });
        }
      });
    } else {
      _loadPasskeySetting();
    }
  }

  Future<void> _loadBiometricSetting() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _biometricEnabled = prefs.getBool('biometric_enabled') ?? true;
    });
  }

  Future<void> _tryBiometricUnlock() async {
    try {
      await ref.read(authProvider.notifier).unlockWithBiometrics();
    } catch (_) {
      // Biometric not available or failed — user can use password
    }
  }

  Future<void> _loadPasskeySetting() async {
    final enabled = await ref
        .read(secureStorageServiceProvider)
        .isWebPasskeyEnabled();
    if (!mounted) return;
    setState(() => _passkeyEnabled = enabled);
  }

  Future<void> _unlock() async {
    if (_isUnlocking) return;
    final pwd = _passwordController.text;
    if (pwd.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context)!.pleaseEnterMasterPassword,
          ),
        ),
      );
      return;
    }

    setState(() => _isUnlocking = true);

    final success = await ref
        .read(authProvider.notifier)
        .unlockWithPassword(pwd);

    if (!success && mounted) {
      final error = ref.read(authProvider.notifier).lastError;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            error ?? AppLocalizations.of(context)!.incorrectPassword,
          ),
        ),
      );
    }

    if (mounted) {
      setState(() => _isUnlocking = false);
    }
  }

  Future<void> _unlockWithPasskey() async {
    if (_isUnlocking) return;
    setState(() => _isUnlocking = true);
    final success = await ref.read(authProvider.notifier).unlockWithPasskey();
    if (!success && mounted) {
      final error = ref.read(authProvider.notifier).lastError;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            error ?? AppLocalizations.of(context)!.passkeyAuthFailed,
          ),
        ),
      );
    }
    if (mounted) {
      setState(() => _isUnlocking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/logo.png',
              width: 64,
              height: 64,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 16),
            const Icon(Icons.lock_outline, size: 48, color: Colors.grey),
            const SizedBox(height: 24),
            Text(
              AppLocalizations.of(context)!.vaultLocked,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              AppLocalizations.of(context)!.enterMasterPasswordToUnlock,
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
              onSubmitted: (_) => _unlock(),
            ),
            const SizedBox(height: 16),
            _isUnlocking
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: _unlock,
                    child: Text(AppLocalizations.of(context)!.unlock),
                  ),
            if (!kIsWeb && _biometricEnabled) ...[
              const SizedBox(height: 8),
              TextButton(
                onPressed: _isUnlocking ? null : _tryBiometricUnlock,
                child: Text(AppLocalizations.of(context)!.useBiometrics),
              ),
            ],
            if (kIsWeb && _passkeyEnabled) ...[
              const SizedBox(height: 8),
              TextButton(
                onPressed: _isUnlocking ? null : _unlockWithPasskey,
                child: Text(AppLocalizations.of(context)!.usePasskey),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
