import 'package:flutter/foundation.dart';

import '../models/attachment.dart';

// Conditional implementation: dart:io (native) vs stub (web).
import 'icloud_sync_service_io.dart'
    if (dart.library.html) 'icloud_sync_service_stub.dart'
    as impl;

/// Provides iCloud Drive-backed encrypted vault sync for iOS.
///
/// The encrypted blob is written to the app's iCloud ubiquity container via
/// the `icloud_storage` package. The file `octarq_vault.enc` appears in
/// Files.app under the app's iCloud Drive folder when the user has iCloud
/// Drive enabled.
///
/// **iOS project setup**:
/// 1. Enable iCloud capability in Xcode → Signing & Capabilities.
/// 2. Ensure iCloud Drive (Documents) and the iCloud Container
///    `iCloud.org.octarq.vault` are checked.
///
/// Check [isAvailable] before calling any sync method so the app degrades
/// gracefully when the user is not signed in to iCloud.
class ICloudSyncService {
  /// Returns `true` on native (non-web) platforms where iCloud is *potentially*
  /// supported.  Use [isAvailable] to confirm at runtime that the ubiquity
  /// container is actually accessible (signed-in Apple ID, correct entitlement).
  bool get isSupported =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;

  /// Async runtime check: returns `true` when the iCloud ubiquity container is
  /// reachable. Returns `false` if the entitlement is missing, the user is not
  /// signed in, or any other error prevents access — without throwing.
  Future<bool> get isAvailable async {
    if (!isSupported) return false;
    return impl.checkIsSupported();
  }

  /// Writes [encryptedBlob] to iCloud Drive ubiquity container.
  Future<void> backup(Uint8List encryptedBlob) async {
    if (!isSupported) throw UnsupportedError('iCloud sync is iOS-only.');
    await impl.backup(encryptedBlob);
  }

  /// Reads the encrypted blob from iCloud Drive, or null if absent.
  Future<Uint8List?> restore() async {
    if (!isSupported) throw UnsupportedError('iCloud sync is iOS-only.');
    return impl.restore();
  }

  /// Returns true if a vault backup file exists in the ubiquity container.
  Future<bool> hasBackup() async {
    if (!isSupported) return false;
    return impl.hasBackup();
  }

  /// Uploads [encBytes] for [attachment] to the iCloud container.
  Future<void> backupAttachment(
    AssetAttachment attachment,
    Uint8List encBytes,
  ) async {
    if (!isSupported) throw UnsupportedError('iCloud sync is iOS-only.');
    await impl.backupAttachment(attachment, encBytes);
  }

  /// Downloads the encrypted bytes for [attachment], or null if absent.
  Future<Uint8List?> restoreAttachment(AssetAttachment attachment) async {
    if (!isSupported) throw UnsupportedError('iCloud sync is iOS-only.');
    return impl.restoreAttachment(attachment);
  }

  /// Returns true if [attachment] has a backup in the ubiquity container.
  Future<bool> attachmentBackupExists(AssetAttachment attachment) async {
    if (!isSupported) return false;
    return impl.attachmentBackupExists(attachment);
  }

  /// Removes [attachment]'s backup from the ubiquity container.
  Future<void> deleteAttachmentBackup(AssetAttachment attachment) async {
    if (!isSupported) throw UnsupportedError('iCloud sync is iOS-only.');
    await impl.deleteAttachmentBackup(attachment);
  }
}
