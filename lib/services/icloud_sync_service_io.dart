// Native (iOS / macOS / desktop) implementation of iCloud sync helpers.
//
// Uses the `icloud_storage` package's ubiquity container API for true
// iCloud Drive sync (files visible in Files.app under the app's folder).
//
// The vault snapshot is stored as `octarq_vault.enc` in the container root.
// Attachments live under `octarq_attachments/<uuid>.enc`.
//
// For testability, all ICloudStorage calls are routed through the
// [ICloudStorageAdapter] abstraction, which can be replaced with a fake in
// unit tests without requiring native platform channels.

import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:icloud_storage/icloud_storage.dart';
import 'package:path_provider/path_provider.dart';

import '../models/attachment.dart';

const String _containerId = 'iCloud.org.octarq.vault';
const String _vaultFileName = 'octarq_vault.enc';
const String _attachmentDirName = 'octarq_attachments';

// ---------------------------------------------------------------------------
// Adapter abstraction (enables unit testing without native channels)
// ---------------------------------------------------------------------------

/// Thin abstraction over [ICloudStorage] static methods.
///
/// Production code uses [RealICloudStorageAdapter]; tests inject a fake.
abstract class ICloudStorageAdapter {
  Future<void> upload({
    required String containerId,
    required String filePath,
    required String destinationRelativePath,
  });

  Future<void> download({
    required String containerId,
    required String relativePath,
    required String destinationFilePath,
  });

  /// Returns all relative paths currently in the container.
  Future<List<String>> gather({required String containerId});

  Future<void> delete({
    required String containerId,
    required String relativePath,
  });
}

/// Production adapter that delegates to [ICloudStorage] static methods.
class RealICloudStorageAdapter implements ICloudStorageAdapter {
  @override
  Future<void> upload({
    required String containerId,
    required String filePath,
    required String destinationRelativePath,
  }) => ICloudStorage.upload(
    containerId: containerId,
    filePath: filePath,
    destinationRelativePath: destinationRelativePath,
  );

  @override
  Future<void> download({
    required String containerId,
    required String relativePath,
    required String destinationFilePath,
  }) => ICloudStorage.download(
    containerId: containerId,
    relativePath: relativePath,
    destinationFilePath: destinationFilePath,
  );

  @override
  Future<List<String>> gather({required String containerId}) async {
    final files = await ICloudStorage.gather(containerId: containerId);
    return files.map((f) => f.relativePath).toList();
  }

  @override
  Future<void> delete({
    required String containerId,
    required String relativePath,
  }) => ICloudStorage.delete(
    containerId: containerId,
    relativePath: relativePath,
  );
}

// ---------------------------------------------------------------------------
// ICloudSyncServiceIO — class-based service (injectable for tests)
// ---------------------------------------------------------------------------

/// iCloud Drive-backed sync service using the ubiquity container.
///
/// Inject a custom [adapter] and [cacheDir] in unit tests to avoid native
/// platform channels.
class ICloudSyncServiceIO {
  final ICloudStorageAdapter _adapter;

  /// Local cache directory used as a staging area for up/downloads.
  /// In production this is the app's ApplicationSupport directory.
  final String? _cacheDirOverride;

  ICloudSyncServiceIO({ICloudStorageAdapter? adapter, String? cacheDir})
    : _adapter = adapter ?? RealICloudStorageAdapter(),
      _cacheDirOverride = cacheDir;

  // -------------------------------------------------------------------------
  // Internal helpers
  // -------------------------------------------------------------------------

  Future<String> _cacheDir() async {
    if (_cacheDirOverride != null) return _cacheDirOverride;
    final dir = await getApplicationSupportDirectory();
    return dir.path;
  }

  Future<String> _tmpVaultPath() async {
    final base = await _cacheDir();
    return '$base/$_vaultFileName.tmp';
  }

  Future<String> _tmpAttachmentPath(String encFileName) async {
    final base = await _cacheDir();
    final dir = Directory('$base/$_attachmentDirName');
    if (!dir.existsSync()) dir.createSync(recursive: true);
    return '${dir.path}/$encFileName.tmp';
  }

  // -------------------------------------------------------------------------
  // Snapshot backup / restore
  // -------------------------------------------------------------------------

  Future<void> backup(Uint8List encryptedBlob) async {
    final tmpPath = await _tmpVaultPath();
    await File(tmpPath).writeAsBytes(encryptedBlob, flush: true);
    await _adapter.upload(
      containerId: _containerId,
      filePath: tmpPath,
      destinationRelativePath: _vaultFileName,
    );
    if (kDebugMode) {
      print('ICloudSyncService: backup uploaded as $_vaultFileName');
    }
  }

  Future<Uint8List?> restore() async {
    final tmpPath = await _tmpVaultPath();
    try {
      await _adapter.download(
        containerId: _containerId,
        relativePath: _vaultFileName,
        destinationFilePath: tmpPath,
      );
    } catch (_) {
      return null;
    }
    final file = File(tmpPath);
    if (!file.existsSync()) return null;
    final bytes = await file.readAsBytes();
    return bytes.isEmpty ? null : Uint8List.fromList(bytes);
  }

  Future<bool> hasBackup() async {
    try {
      final files = await _adapter.gather(containerId: _containerId);
      return files.any(
        (f) => f == _vaultFileName || f.endsWith('/$_vaultFileName'),
      );
    } catch (_) {
      return false;
    }
  }

  // -------------------------------------------------------------------------
  // Availability check
  // -------------------------------------------------------------------------

  /// Returns `true` if the iCloud ubiquity container is accessible.
  ///
  /// Returns `false` if the entitlement is missing, the user is not signed in
  /// to iCloud, or any other error prevents container access — without throwing.
  Future<bool> checkIsSupported() async {
    try {
      await _adapter.gather(containerId: _containerId);
      return true;
    } catch (_) {
      return false;
    }
  }

  // -------------------------------------------------------------------------
  // Attachment backup / restore
  // -------------------------------------------------------------------------

  Future<void> backupAttachment(
    AssetAttachment attachment,
    Uint8List encBytes,
  ) async {
    final tmpPath = await _tmpAttachmentPath(attachment.encFileName);
    await File(tmpPath).writeAsBytes(encBytes, flush: true);
    await _adapter.upload(
      containerId: _containerId,
      filePath: tmpPath,
      destinationRelativePath: '$_attachmentDirName/${attachment.encFileName}',
    );
    if (kDebugMode) {
      print(
        'ICloudSyncService: attachment ${attachment.encFileName} backed up.',
      );
    }
  }

  Future<Uint8List?> restoreAttachment(AssetAttachment attachment) async {
    final tmpPath = await _tmpAttachmentPath(attachment.encFileName);
    try {
      await _adapter.download(
        containerId: _containerId,
        relativePath: '$_attachmentDirName/${attachment.encFileName}',
        destinationFilePath: tmpPath,
      );
    } catch (_) {
      return null;
    }
    final file = File(tmpPath);
    if (!file.existsSync()) return null;
    final bytes = await file.readAsBytes();
    return bytes.isEmpty ? null : Uint8List.fromList(bytes);
  }

  Future<bool> attachmentBackupExists(AssetAttachment attachment) async {
    try {
      final files = await _adapter.gather(containerId: _containerId);
      final target = '$_attachmentDirName/${attachment.encFileName}';
      return files.any(
        (f) => f == target || f.endsWith(attachment.encFileName),
      );
    } catch (_) {
      return false;
    }
  }

  Future<void> deleteAttachmentBackup(AssetAttachment attachment) async {
    await _adapter.delete(
      containerId: _containerId,
      relativePath: '$_attachmentDirName/${attachment.encFileName}',
    );
  }
}

// ---------------------------------------------------------------------------
// Module-level free functions (called by the ICloudSyncService wrapper via
// the `impl.` alias).
// ---------------------------------------------------------------------------

final _defaultService = ICloudSyncServiceIO();

Future<void> backup(Uint8List encryptedBlob) =>
    _defaultService.backup(encryptedBlob);
Future<Uint8List?> restore() => _defaultService.restore();
Future<bool> hasBackup() => _defaultService.hasBackup();
Future<void> backupAttachment(AssetAttachment attachment, Uint8List encBytes) =>
    _defaultService.backupAttachment(attachment, encBytes);
Future<Uint8List?> restoreAttachment(AssetAttachment attachment) =>
    _defaultService.restoreAttachment(attachment);
Future<bool> attachmentBackupExists(AssetAttachment attachment) =>
    _defaultService.attachmentBackupExists(attachment);
Future<void> deleteAttachmentBackup(AssetAttachment attachment) =>
    _defaultService.deleteAttachmentBackup(attachment);
Future<bool> checkIsSupported() => _defaultService.checkIsSupported();
