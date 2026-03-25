// RED phase: these tests WILL NOT compile because AssetsNotifier does not yet
// expose pullSync(VaultSnapshot). The compile error is intentional — this is
// the failing test that drives the implementation in task #11.
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

// ---------------------------------------------------------------------------
// Mocks
// ---------------------------------------------------------------------------

class _MockEncSvc extends EncryptionService {
  @override
  Uint8List get masterKey => Uint8List(32);
}

class _MockAttachmentService extends AttachmentService {
  final bool existsResult;
  final List<AssetAttachment> savedAttachments = [];
  Exception? saveError;

  _MockAttachmentService({required this.existsResult}) : super(_MockEncSvc());

  @override
  Future<bool> attachmentExists(AssetAttachment a) async => existsResult;

  @override
  Future<void> saveEncryptedBytes(AssetAttachment a, Uint8List bytes) async {
    if (saveError != null) throw saveError!;
    savedAttachments.add(a);
  }
}

class _MockGoogleDriveService extends GoogleDriveService {
  final Uint8List? downloadResult;
  Exception? downloadError;
  int downloadCallCount = 0;

  _MockGoogleDriveService({this.downloadResult})
    : super(_MockE2EESyncService());

  @override
  Future<bool> hasCredentials() async => true;

  @override
  Future<Uint8List?> downloadAttachment(AssetAttachment attachment) async {
    downloadCallCount++;
    if (downloadError != null) throw downloadError!;
    return downloadResult;
  }
}

class _MockE2EESyncService extends E2EESyncService {
  _MockE2EESyncService() : super(_MockEncSvc());
}

class _MockICloudSyncService extends ICloudSyncService {
  final Uint8List? restoreResult;
  int restoreCallCount = 0;

  _MockICloudSyncService({this.restoreResult});

  @override
  bool get isSupported => true;

  @override
  Future<Uint8List?> restoreAttachment(AssetAttachment attachment) async {
    restoreCallCount++;
    return restoreResult;
  }
}

// ---------------------------------------------------------------------------
// Fake AssetsNotifier — no DB, no real sync; exposes pullSync() once it
// exists on the base class (that missing method is the RED compile error).
// ---------------------------------------------------------------------------

class _PullSyncNotifier extends AssetsNotifier {
  @override
  List<Asset> build() => [];

  @override
  Future<void> loadAssets() async {}
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

AssetAttachment _attachment({String id = 'att-1'}) => AssetAttachment(
  id: id,
  assetId: 'asset-1',
  name: 'secret.pem',
  mimeType: 'application/octet-stream',
  size: 512,
  encFileName: '$id.enc',
  createdAt: 0,
  updatedAt: 0,
);

VaultSnapshot _snapshot(List<AssetAttachment> attachments) =>
    VaultSnapshot(version: 3, assets: [], attachmentManifest: attachments);

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('attachment sync pull', () {
    test('downloads missing blob after pull', () async {
      final remoteBytes = Uint8List(32);
      final mockAttachmentSvc = _MockAttachmentService(existsResult: false);
      final mockDrive = _MockGoogleDriveService(downloadResult: remoteBytes);

      final container = ProviderContainer(
        overrides: [
          assetsProvider.overrideWith(() => _PullSyncNotifier()),
          attachmentServiceProvider.overrideWithValue(mockAttachmentSvc),
          googleDriveServiceProvider.overrideWithValue(mockDrive),
          syncSettingsProvider.overrideWith(
            () => _FixedSyncSettingsNotifier([SyncMethod.googleDrive]),
          ),
        ],
      );
      addTearDown(container.dispose);

      final snapshot = _snapshot([_attachment()]);

      // RED: pullSync() does not exist yet — this line will not compile until
      //      AssetsNotifier gains the method.
      await container.read(assetsProvider.notifier).pullSync(snapshot);

      expect(mockAttachmentSvc.savedAttachments.length, 1);
    });

    test('does not download already-present blob', () async {
      final mockAttachmentSvc = _MockAttachmentService(existsResult: true);
      final mockDrive = _MockGoogleDriveService(downloadResult: Uint8List(32));

      final container = ProviderContainer(
        overrides: [
          assetsProvider.overrideWith(() => _PullSyncNotifier()),
          attachmentServiceProvider.overrideWithValue(mockAttachmentSvc),
          googleDriveServiceProvider.overrideWithValue(mockDrive),
          syncSettingsProvider.overrideWith(
            () => _FixedSyncSettingsNotifier([SyncMethod.googleDrive]),
          ),
        ],
      );
      addTearDown(container.dispose);

      final snapshot = _snapshot([_attachment()]);

      // RED: same missing method.
      await container.read(assetsProvider.notifier).pullSync(snapshot);

      expect(mockDrive.downloadCallCount, 0);
    });

    test('null download result handled gracefully', () async {
      final mockAttachmentSvc = _MockAttachmentService(existsResult: false);
      final mockDrive = _MockGoogleDriveService(downloadResult: null);

      final container = ProviderContainer(
        overrides: [
          assetsProvider.overrideWith(() => _PullSyncNotifier()),
          attachmentServiceProvider.overrideWithValue(mockAttachmentSvc),
          googleDriveServiceProvider.overrideWithValue(mockDrive),
          syncSettingsProvider.overrideWith(
            () => _FixedSyncSettingsNotifier([SyncMethod.googleDrive]),
          ),
        ],
      );
      addTearDown(container.dispose);

      final snapshot = _snapshot([_attachment()]);

      // RED: same missing method; verifies null safety of download path.
      await expectLater(
        container.read(assetsProvider.notifier).pullSync(snapshot),
        completes,
      );

      expect(mockAttachmentSvc.savedAttachments, isEmpty);
    });

    test('download failure does not fail pull', () async {
      final mockAttachmentSvc = _MockAttachmentService(existsResult: false);
      final mockDrive = _MockGoogleDriveService()
        ..downloadError = Exception('network');

      final container = ProviderContainer(
        overrides: [
          assetsProvider.overrideWith(() => _PullSyncNotifier()),
          attachmentServiceProvider.overrideWithValue(mockAttachmentSvc),
          googleDriveServiceProvider.overrideWithValue(mockDrive),
          syncSettingsProvider.overrideWith(
            () => _FixedSyncSettingsNotifier([SyncMethod.googleDrive]),
          ),
        ],
      );
      addTearDown(container.dispose);

      final snapshot = _snapshot([_attachment()]);

      // RED: same missing method; verifies error isolation during pull.
      await expectLater(
        container.read(assetsProvider.notifier).pullSync(snapshot),
        completes,
      );
    });

    test('deleted attachment not re-downloaded', () async {
      // The remote manifest includes 'att-del', but the local op_log carries a
      // delete tombstone for that id — pullSync() must skip re-downloading it.
      final mockAttachmentSvc = _MockAttachmentService(existsResult: false);
      final mockDrive = _MockGoogleDriveService(downloadResult: Uint8List(32));

      final deletedAttachment = _attachment(id: 'att-del');

      // A snapshot whose opLog contains a delete entry for att-del.
      final snapshotWithTombstone = VaultSnapshot(
        version: 3,
        assets: [],
        attachmentManifest: [deletedAttachment],
        opLog: [
          OpLogEntry(
            id: 'op-1',
            op: OpType.delete,
            entityType: OpEntityType.attachment,
            entityId: 'att-del',
            createdAt: 1000,
          ),
        ],
      );

      final container = ProviderContainer(
        overrides: [
          assetsProvider.overrideWith(() => _PullSyncNotifier()),
          attachmentServiceProvider.overrideWithValue(mockAttachmentSvc),
          googleDriveServiceProvider.overrideWithValue(mockDrive),
          syncSettingsProvider.overrideWith(
            () => _FixedSyncSettingsNotifier([SyncMethod.googleDrive]),
          ),
        ],
      );
      addTearDown(container.dispose);

      // RED: same missing method; verifies tombstone-aware pull logic.
      await container
          .read(assetsProvider.notifier)
          .pullSync(snapshotWithTombstone);

      expect(mockDrive.downloadCallCount, 0);
    });

    test('icloud pull also downloads missing attachment', () async {
      final mockAttachmentSvc = _MockAttachmentService(existsResult: false);
      final mockIcloud = _MockICloudSyncService(restoreResult: Uint8List(16));

      final container = ProviderContainer(
        overrides: [
          assetsProvider.overrideWith(() => _PullSyncNotifier()),
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
          .pullSync(_snapshot([_attachment()]));

      expect(mockIcloud.restoreCallCount, 1);
      expect(mockAttachmentSvc.savedAttachments.length, 1);
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
