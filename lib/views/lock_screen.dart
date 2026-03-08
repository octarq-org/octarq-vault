import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';

class LockScreen extends ConsumerStatefulWidget {
  const LockScreen({super.key});

  @override
  ConsumerState<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends ConsumerState<LockScreen> {
  final _passwordController = TextEditingController();
  bool _isUnlocking = false;

  @override
  void initState() {
    super.initState();
    // Only attempt biometric unlock if available — don't block the UI
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _tryBiometricUnlock();
    });
  }

  Future<void> _tryBiometricUnlock() async {
    try {
      await ref.read(authProvider.notifier).unlockWithBiometrics();
    } catch (_) {
      // Biometric not available or failed — user can use password
    }
  }

  Future<void> _unlock() async {
    if (_isUnlocking) return;
    final pwd = _passwordController.text;
    if (pwd.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your master password')),
      );
      return;
    }

    setState(() => _isUnlocking = true);
    
    final success = await ref.read(authProvider.notifier).unlockWithPassword(pwd);
    
    if (!success && mounted) {
      final error = ref.read(authProvider.notifier).lastError;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error ?? 'Incorrect password')),
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
            const Icon(Icons.lock, size: 80, color: Colors.blueAccent),
            const SizedBox(height: 24),
            const Text(
              'Vault Locked',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Enter your master password to unlock',
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
              onSubmitted: (_) => _unlock(),
            ),
            const SizedBox(height: 16),
            _isUnlocking
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: _unlock,
                    child: const Text('Unlock'),
                  ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: _isUnlocking ? null : _tryBiometricUnlock,
              child: const Text('Use Biometrics'),
            ),
          ],
        ),
      ),
    );
  }
}
