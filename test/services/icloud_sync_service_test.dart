// Tests for the icloud_storage-based ICloudSyncService implementation.
//
// These tests use a FakeICloudStorageAdapter to avoid native platform channels.
// In the Red phase (task-022), these tests fail because icloud_sync_service_io.dart
// still uses getApplicationDocumentsDirectory() and has no ICloudStorageAdapter.
// In the Green phase (task-023), the implementation is rewritten and tests pass.

import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

import 'package:octarq_vault/models/attachment.dart';
import 'package:octarq_vault/services/icloud_sync_service_io.dart';

// ---------------------------------------------------------------------------
// Fake adapter
// ---------------------------------------------------------------------------

/// In-memory fake that records calls made to ICloudStorage methods.
class FakeICloudStorageAdapter implements ICloudStorageAdapter {
  /// Files stored as relativePath → bytes.
  final Map<String, Uint8List> _store = {};

  /// Set to true to make [download] throw (simulates file-not-found).
  bool throwOnDownload = false;

  /// Set to true to make [gather] throw (simulates iCloud unavailable).
  bool throwOnGather = false;

  /// Recorded upload calls: list of {containerId, filePath, destinationRelativePath}.
  final List<Map<String, String>> uploadCalls = [];

  /// Recorded download calls: list of {containerId, relativePath, destinationFilePath}.
  final List<Map<String, String>> downloadCalls = [];

  @override
  Future<void> upload({
    required String containerId,
    required String filePath,
    required String destinationRelativePath,
  }) async {
    uploadCalls.add({
      'containerId': containerId,
      'filePath': filePath,
      'destinationRelativePath': destinationRelativePath,
    });
    // Read the local file the service wrote before calling upload.
    final f = File(filePath);
    if (f.existsSync()) {
      _store[destinationRelativePath] = f.readAsBytesSync();
    }
  }

  @override
  Future<void> download({
    required String containerId,
    required String relativePath,
    required String destinationFilePath,
  }) async {
    downloadCalls.add({
      'containerId': containerId,
      'relativePath': relativePath,
      'destinationFilePath': destinationFilePath,
    });
    if (throwOnDownload) {
      throw Exception('iCloud file not found: $relativePath');
    }
    final bytes = _store[relativePath];
    if (bytes == null) {
      throw Exception('iCloud file not found: $relativePath');
    }
    // Write bytes to the destination so the service can read them back.
    await File(destinationFilePath).writeAsBytes(bytes);
  }

  @override
  Future<List<String>> gather({required String containerId}) async {
    if (throwOnGather) {
      throw Exception('iCloud not available');
    }
    return _store.keys.toList();
  }

  @override
  Future<void> delete({
    required String containerId,
    required String relativePath,
  }) async {
    _store.remove(relativePath);
  }

  /// Pre-populate the fake store with [bytes] at [path].
  void seedFile(String path, Uint8List bytes) {
    _store[path] = bytes;
  }
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

AssetAttachment _makeAttachment({String encFileName = 'abc123.enc'}) =>
    AssetAttachment(
      id: 'att-1',
      assetId: 'asset-1',
      name: 'test.bin',
      mimeType: 'application/octet-stream',
      size: 4,
      encFileName: encFileName,
      createdAt: 1000,
      updatedAt: 1000,
    );

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  late Directory tmpDir;
  late FakeICloudStorageAdapter fakeAdapter;
  late ICloudSyncServiceIO service;

  setUp(() async {
    tmpDir = await Directory.systemTemp.createTemp('icloud_test_');
    fakeAdapter = FakeICloudStorageAdapter();
    service = ICloudSyncServiceIO(adapter: fakeAdapter, cacheDir: tmpDir.path);
  });

  tearDown(() async {
    await tmpDir.delete(recursive: true);
  });

  // -------------------------------------------------------------------------
  // 1. backup() calls ICloudStorage.upload() with correct filename
  // -------------------------------------------------------------------------
  test('backup() calls upload with filename "octarq_vault.enc"', () async {
    final bytes = Uint8List.fromList([1, 2, 3, 4, 5]);
    await service.backup(bytes);

    expect(fakeAdapter.uploadCalls, hasLength(1));
    final call = fakeAdapter.uploadCalls.first;
    expect(call['destinationRelativePath'], equals('octarq_vault.enc'));
  });

  test('backup() passes the correct bytes to upload', () async {
    final bytes = Uint8List.fromList([10, 20, 30]);

    // Pre-seed nothing — the service writes a local temp file then calls upload.
    await service.backup(bytes);

    // The fake records the bytes from the local temp file on upload.
    expect(fakeAdapter._store['octarq_vault.enc'], equals(bytes));
  });

  // -------------------------------------------------------------------------
  // 2. restore() calls ICloudStorage.download() and returns bytes
  // -------------------------------------------------------------------------
  test('restore() calls download and returns the bytes', () async {
    final expected = Uint8List.fromList([9, 8, 7, 6]);
    fakeAdapter.seedFile('octarq_vault.enc', expected);

    final result = await service.restore();

    expect(fakeAdapter.downloadCalls, hasLength(1));
    expect(
      fakeAdapter.downloadCalls.first['relativePath'],
      equals('octarq_vault.enc'),
    );
    expect(result, equals(expected));
  });

  // -------------------------------------------------------------------------
  // 3. restore() returns null when file not found
  // -------------------------------------------------------------------------
  test(
    'restore() returns null when download throws (file not found)',
    () async {
      fakeAdapter.throwOnDownload = true;

      final result = await service.restore();

      expect(result, isNull);
    },
  );

  // -------------------------------------------------------------------------
  // 4. hasBackup() returns false when container is empty
  // -------------------------------------------------------------------------
  test('hasBackup() returns false when container is empty', () async {
    final result = await service.hasBackup();

    expect(result, isFalse);
  });

  test('hasBackup() returns true after backup()', () async {
    final bytes = Uint8List.fromList([1]);
    await service.backup(bytes);

    final result = await service.hasBackup();
    expect(result, isTrue);
  });

  // -------------------------------------------------------------------------
  // 5. isSupported returns false when ICloudStorage is unavailable
  // -------------------------------------------------------------------------
  test(
    'isSupported returns false when gather throws (iCloud unavailable)',
    () async {
      fakeAdapter.throwOnGather = true;

      final supported = await service.checkIsSupported();

      expect(supported, isFalse);
    },
  );

  test('isSupported returns true when gather succeeds', () async {
    final supported = await service.checkIsSupported();
    expect(supported, isTrue);
  });

  // -------------------------------------------------------------------------
  // 6. backupAttachment() calls upload with the attachment's encFileName
  // -------------------------------------------------------------------------
  test('backupAttachment() calls upload with attachment encFileName', () async {
    final attachment = _makeAttachment(encFileName: 'deadbeef.enc');
    final encBytes = Uint8List.fromList([0xDE, 0xAD, 0xBE, 0xEF]);

    await service.backupAttachment(attachment, encBytes);

    expect(fakeAdapter.uploadCalls, hasLength(1));
    final call = fakeAdapter.uploadCalls.first;
    expect(call['destinationRelativePath'], contains(attachment.encFileName));
  });

  // -------------------------------------------------------------------------
  // 7. restoreAttachment() returns bytes for existing attachment
  // -------------------------------------------------------------------------
  test('restoreAttachment() returns correct bytes', () async {
    final attachment = _makeAttachment(encFileName: 'restore-me.enc');
    final encBytes = Uint8List.fromList([1, 2, 3]);
    fakeAdapter.seedFile(
      'octarq_attachments/${attachment.encFileName}',
      encBytes,
    );

    final result = await service.restoreAttachment(attachment);

    expect(result, equals(encBytes));
  });

  test('restoreAttachment() returns null when not found', () async {
    final attachment = _makeAttachment(encFileName: 'missing.enc');
    fakeAdapter.throwOnDownload = true;

    final result = await service.restoreAttachment(attachment);
    expect(result, isNull);
  });

  // -------------------------------------------------------------------------
  // 8. attachmentBackupExists() checks container
  // -------------------------------------------------------------------------
  test(
    'attachmentBackupExists() returns false when not in container',
    () async {
      final attachment = _makeAttachment(encFileName: 'ghost.enc');

      final exists = await service.attachmentBackupExists(attachment);
      expect(exists, isFalse);
    },
  );

  test(
    'attachmentBackupExists() returns true after backupAttachment()',
    () async {
      final attachment = _makeAttachment(encFileName: 'present.enc');
      await service.backupAttachment(attachment, Uint8List.fromList([1]));

      final exists = await service.attachmentBackupExists(attachment);
      expect(exists, isTrue);
    },
  );

  // -------------------------------------------------------------------------
  // 9. deleteAttachmentBackup() removes from container
  // -------------------------------------------------------------------------
  test(
    'deleteAttachmentBackup() removes the attachment from container',
    () async {
      final attachment = _makeAttachment(encFileName: 'delete-me.enc');
      fakeAdapter.seedFile(
        'octarq_attachments/${attachment.encFileName}',
        Uint8List.fromList([1]),
      );

      await service.deleteAttachmentBackup(attachment);

      final exists = await service.attachmentBackupExists(attachment);
      expect(exists, isFalse);
    },
  );
}
