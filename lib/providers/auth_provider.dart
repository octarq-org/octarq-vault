import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'service_providers.dart';

enum AuthState { initializing, unsetup, locked, unlocked }

class AuthNotifier extends StateNotifier<AuthState> {
  final Ref ref;

  AuthNotifier(this.ref) : super(AuthState.initializing) {
    _init();
  }

  Future<void> _init() async {
    final storage = ref.read(secureStorageServiceProvider);
    final hasKey = await storage.hasStoredKey();
    if (!hasKey) {
      state = AuthState.unsetup; 
    } else {
      state = AuthState.locked;
      // Optionally attempt implicit biometric unlock here:
      // await unlockWithBiometrics();
    }
  }

  Future<bool> setupMasterPassword(String password) async {
    try {
      final encryption = ref.read(encryptionServiceProvider);
      final storage = ref.read(secureStorageServiceProvider);
      
      final saltBase64 = encryption.generateSaltBase64();
      await encryption.deriveKey(password, saltBase64);
      final key = encryption.masterKey;
      
      await storage.storeMasterKey(key, saltBase64);
      
      final db = ref.read(databaseServiceProvider);
      await db.init(key);
      
      state = AuthState.unlocked;
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> unlockWithPassword(String password) async {
    try {
      final encryption = ref.read(encryptionServiceProvider);
      final storage = ref.read(secureStorageServiceProvider);
      
      final saltBase64 = await storage.getSalt();
      if (saltBase64 == null) return false;

      await encryption.deriveKey(password, saltBase64);
      final key = encryption.masterKey;
      
      final db = ref.read(databaseServiceProvider);
      await db.init(key);
      
      state = AuthState.unlocked;
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> unlockWithBiometrics() async {
    try {
      final storage = ref.read(secureStorageServiceProvider);
      final key = await storage.getMasterKeyWithBiometrics('Unlock AssetVault');
      
      if (key != null) {
        final encryption = ref.read(encryptionServiceProvider);
        encryption.setMasterKey(key);
        
        final db = ref.read(databaseServiceProvider);
        await db.init(key);
        
        state = AuthState.unlocked;
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<void> lock() async {
    ref.read(encryptionServiceProvider).wipeKey();
    await ref.read(databaseServiceProvider).close();
    state = AuthState.locked;
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref);
});
