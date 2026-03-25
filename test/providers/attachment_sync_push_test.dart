// RED phase: these tests WILL NOT compile because AssetsNotifier does not yet
// expose pushSync(). The compile error is intentional — this is the failing
// test that drives the implementation in task #9.
//
// ignore_for_file: unused_import

import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:octarq_vault/models/asset.dart';
import 'package:octarq_vault/models/attachment.dart';
import 'package:octarq_vault/models/sync_settings.dart';
import 'package:octarq_vault/providers/assets_provider.dart';
import 'package:octarq_vault/providers/service_providers.dart';
import 'package:octarq_vault/providers/sync_settings_provider.dart';
import 'package:octarq_vault/services/attachment_service.dart';
import 'package:octarq_vault/services/database_service.dart';
import 'package:octarq_vault/services/encryption_service.dart';
import 'package:octarq_vault/services/e2ee_sync_service.dart';
import 'package:octarq_vault/services/google_drive_service.dart';
import 'package:octarq_vault/services/icloud_sync_service.dart';
import 'package:octarq_vault/services/webdav_service.dart';

// ---------------------------------------------------------------------------
// Mocks
// ---------------------------------------------------------------------------

class _MockEncSvc extends EncryptionService {
  @override
  Uint8List get masterKey => Uint8List(32);
}

class _MockAttachmentService extends AttachmentService {
  final bool existsResult;
  final Uint8List encBytes;

  _MockAttachmentService({required this.existsResult, required this.encBytes})
    : super(_MockEncSvc());

  @override
  Future<bool> attachmentExists(AssetAttachment a) async => existsResult;

  @override
  Future<Uint8List> loadEncryptedBytes(AssetAttachment a) async => encBytes;
}

class _MockGoogleDriveService extends GoogleDriveService {
  final List<AssetAttachment> uploaded = [];
  Exception? uploadError;

  _MockGoogleDriveService() : super(_MockE2EESyncService());

  @override
  Future<bool> hasCredentials() async => true;

  @override
  Future<void> uploadAttachment(
    AssetAttachment attachment,
    Uint8List encBytes,
  ) async {
    if (uploadError != null) throw uploadError!;
    uploaded.add(attachment);
  }
}

class _MockWebDavService extends WebDavService {
  final List<AssetAttachment> uploaded = [];
  Exception? uploadError;

  _MockWebDavService();

  @override
  Future<bool> hasCredentials() async => true;

  @override
  Future<void> uploadAttachment(
    AssetAttachment attachment,
    Uint8List encBytes,
  ) async {
    if (uploadError != null) throw uploadError!;
    uploaded.add(attachment);
  }
}

class _MockE2EESyncService extends E2EESyncService {
  _MockE2EESyncService() : super(_MockEncSvc());
}

class _MockICloudSyncService extends ICloudSyncService {
  final List<AssetAttachment> uploaded = [];

  @override
  bool get isSupported => true;

  @override
  Future<void> backupAttachment(
    AssetAttachment attachment,
    Uint8List encBytes,
  ) async {
    uploaded.add(attachment);
  }
}

// ---------------------------------------------------------------------------
// Fake AssetsNotifier — no DB, no real sync; exposes pushSync() once it
// exists on the base class (that missing method is the RED compile error).
// ---------------------------------------------------------------------------

class _PushSyncNotifier extends AssetsNotifier {
  @override
  List<Asset> build() => [];

  @override
  Future<void> loadAssets() async {}
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

AssetAttachment _attachment() => const AssetAttachment(
  id: 'att-1',
  assetId: 'asset-1',
  name: 'server_key.pem',
  mimeType: 'application/octet-stream',
  size: 1024,
  encFileName: 'att-1.enc',
  createdAt: 0,
  updatedAt: 0,
);

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('attachment sync push', () {
    test('uploads existing local blob to Google Drive on push', () async {
      final mockAttachmentSvc = _MockAttachmentService(
        existsResult: true,
        encBytes: Uint8List.fromList(List.filled(64, 0xAB)),
      );
      final mockDrive = _MockGoogleDriveService();

      final container = ProviderContainer(
        overrides: [
          assetsProvider.overrideWith(() => _PushSyncNotifier()),
          attachmentServiceProvider.overrideWithValue(mockAttachmentSvc),
          googleDriveServiceProvider.overrideWithValue(mockDrive),
          syncSettingsProvider.overrideWith(
            () => _FixedSyncSettingsNotifier([SyncMethod.googleDrive]),
          ),
        ],
      );
      addTearDown(container.dispose);

      // RED: pushSync() does not exist yet — this line will not compile until
      //      AssetsNotifier gains the method.
      await container
          .read(assetsProvider.notifier)
          .pushSync(attachments: [_attachment()]);

      expect(mockDrive.uploaded.length, 1);
    });

    test('does not upload blob when local file is missing', () async {
      final mockAttachmentSvc = _MockAttachmentService(
        existsResult: false,
        encBytes: Uint8List(64),
      );
      final mockDrive = _MockGoogleDriveService();

      final container = ProviderContainer(
        overrides: [
          assetsProvider.overrideWith(() => _PushSyncNotifier()),
          attachmentServiceProvider.overrideWithValue(mockAttachmentSvc),
          googleDriveServiceProvider.overrideWithValue(mockDrive),
          syncSettingsProvider.overrideWith(
            () => _FixedSyncSettingsNotifier([SyncMethod.googleDrive]),
          ),
        ],
      );
      addTearDown(container.dispose);

      // RED: same missing method.
      await container
          .read(assetsProvider.notifier)
          .pushSync(attachments: [_attachment()]);

      expect(mockDrive.uploaded, isEmpty);
    });

    test('upload failure does not fail overall push', () async {
      final mockAttachmentSvc = _MockAttachmentService(
        existsResult: true,
        encBytes: Uint8List.fromList(List.filled(32, 0xFF)),
      );
      final mockDrive = _MockGoogleDriveService()
        ..uploadError = Exception('network');

      final container = ProviderContainer(
        overrides: [
          assetsProvider.overrideWith(() => _PushSyncNotifier()),
          attachmentServiceProvider.overrideWithValue(mockAttachmentSvc),
          googleDriveServiceProvider.overrideWithValue(mockDrive),
          syncSettingsProvider.overrideWith(
            () => _FixedSyncSettingsNotifier([SyncMethod.googleDrive]),
          ),
        ],
      );
      addTearDown(container.dispose);

      // RED: same missing method; also verifies error isolation.
      await expectLater(
        container
            .read(assetsProvider.notifier)
            .pushSync(attachments: [_attachment()]),
        completes,
      );
    });

    test('webdav push also uploads attachments', () async {
      final mockAttachmentSvc = _MockAttachmentService(
        existsResult: true,
        encBytes: Uint8List.fromList(List.filled(64, 0xCD)),
      );
      final mockWebDav = _MockWebDavService();

      final container = ProviderContainer(
        overrides: [
          assetsProvider.overrideWith(() => _PushSyncNotifier()),
          attachmentServiceProvider.overrideWithValue(mockAttachmentSvc),
          webDavServiceProvider.overrideWithValue(mockWebDav),
          syncSettingsProvider.overrideWith(
            () => _FixedSyncSettingsNotifier([SyncMethod.webdav]),
          ),
        ],
      );
      addTearDown(container.dispose);

      // RED: same missing method.
      await container
          .read(assetsProvider.notifier)
          .pushSync(attachments: [_attachment()]);

      expect(mockWebDav.uploaded.length, 1);
    });

    test('icloud push also uploads attachments', () async {
      final mockAttachmentSvc = _MockAttachmentService(
        existsResult: true,
        encBytes: Uint8List.fromList(List.filled(32, 0xAA)),
      );
      final mockIcloud = _MockICloudSyncService();

      final container = ProviderContainer(
        overrides: [
          assetsProvider.overrideWith(() => _PushSyncNotifier()),
          attachmentServiceProvider.overrideWithValue(mockAttachmentSvc),
          iCloudSyncServiceProvider.overrideWithValue(mockIcloud),
          syncSettingsProvider.overrideWith(
            () => _FixedSyncSettingsNotifier([SyncMethod.icloud]),
          ),
        ],
      );
      addTearDown(container.dispose);

      await container
          .read(assetsProvider.notifier)
          .pushSync(attachments: [_attachment()]);

      expect(mockIcloud.uploaded.length, 1);
    });
  });
}

// ---------------------------------------------------------------------------
// Helper notifier for overriding syncSettingsProvider inline
// ---------------------------------------------------------------------------

class _FixedSyncSettingsNotifier extends SyncSettingsNotifier {
  final List<SyncMethod> _methods;
  _FixedSyncSettingsNotifier(this._methods);

  @override
  List<SyncMethod> build() => _methods;
}
