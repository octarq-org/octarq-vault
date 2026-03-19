import 'package:flutter/foundation.dart';

// Conditional implementation: dart:io (native) vs stub (web).
import 'icloud_sync_service_io.dart'
    if (dart.library.html) 'icloud_sync_service_stub.dart'
    as impl;

/// Provides iCloud Drive-backed encrypted vault sync for iOS.
///
/// The encrypted blob is written to the app's Documents directory, which iOS
/// automatically backs up to iCloud when iCloud Backup is enabled.
///
/// **iOS project setup**:
/// 1. Enable iCloud capability in Xcode → Signing & Capabilities.
/// 2. Ensure iCloud Documents is checked (for active iCloud Drive sync).
/// 3. The vault file `asset_vault.enc` is placed in the app Documents dir.
///
/// Note: For *active* cross-device sync (vs passive backup) the user must
/// have iCloud Drive enabled in iOS Settings → [Your Name] → iCloud.
class ICloudSyncService {
  bool get isSupported =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;

  /// Writes [encryptedBlob] to iCloud-synced storage.
  Future<void> backup(Uint8List encryptedBlob) async {
    if (!isSupported) throw UnsupportedError('iCloud sync is iOS-only.');
    await impl.backup(encryptedBlob);
  }

  /// Reads the encrypted blob from iCloud-synced storage, or null if absent.
  Future<Uint8List?> restore() async {
    if (!isSupported) throw UnsupportedError('iCloud sync is iOS-only.');
    return impl.restore();
  }

  /// Returns true if a backup file exists.
  Future<bool> hasBackup() async {
    if (!isSupported) return false;
    return impl.hasBackup();
  }
}
