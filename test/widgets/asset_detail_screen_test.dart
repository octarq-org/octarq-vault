// RED PHASE — these tests are expected to FAIL until the Attachments section
// is implemented in AssetDetailScreen.

import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_riverpod/misc.dart' show Override;

import 'package:octarq_vault/l10n/app_localizations.dart';
import 'package:octarq_vault/models/asset.dart';
import 'package:octarq_vault/models/asset_type.dart';
import 'package:octarq_vault/models/attachment.dart';
import 'package:octarq_vault/providers/assets_provider.dart';
import 'package:octarq_vault/providers/asset_types_provider.dart';
import 'package:octarq_vault/providers/attachments_provider.dart';
import 'package:octarq_vault/providers/relation_providers.dart';
import 'package:octarq_vault/providers/service_providers.dart';
import 'package:octarq_vault/services/attachment_service.dart';
import 'package:octarq_vault/services/database_service.dart';
import 'package:octarq_vault/services/e2ee_sync_service.dart';
import 'package:octarq_vault/services/encryption_service.dart';
import 'package:octarq_vault/services/file_picker_service.dart';
import 'package:octarq_vault/views/asset_detail_screen.dart';

// ─── Mocks ──────────────────────────────────────────────────────────────────

class _MockEncryptionService extends EncryptionService {
  @override
  Uint8List get masterKey => Uint8List(32);
}

class _MockAssetsNotifier extends AssetsNotifier {
  bool pushSyncCalled = false;
  bool syncNowCalled = false;
  bool deleteRemoteAttachmentCalled = false;
  final List<String> callOrder = [];

  @override
  List<Asset> build() => [_testAsset()];

  @override
  Future<void> loadAssets() async {}

  @override
  Future<void> pushSync({required List<AssetAttachment> attachments}) async {
    pushSyncCalled = true;
  }

  @override
  Future<void> syncNow() async {
    syncNowCalled = true;
    callOrder.add('syncNow');
  }

  @override
  Future<void> deleteRemoteAttachment(AssetAttachment attachment) async {
    deleteRemoteAttachmentCalled = true;
    callOrder.add('deleteRemoteAttachment');
  }
}

class _MockAssetTypesNotifier extends AssetTypesNotifier {
  @override
  List<AssetType> build() => [
    const AssetType(
      id: 'type_generic',
      name: 'Generic',
      icon: 'lock',
      isBuiltIn: true,
      fieldSchema: [],
    ),
  ];

  @override
  Future<void> loadCustomTypes() async {}
}

class _MockAttachmentService extends AttachmentService {
  bool deleteCalled = false;
  Exception? deleteError;

  _MockAttachmentService() : super(_MockEncryptionService());

  @override
  Future<AssetAttachment> saveAttachment({
    required String assetId,
    required String name,
    required String mimeType,
    required Uint8List bytes,
  }) async => _attachment('mock-id', name);

  @override
  Future<void> deleteAttachmentFile(AssetAttachment attachment) async {
    if (deleteError != null) throw deleteError!;
    deleteCalled = true;
  }
}

class _MockDatabaseService extends DatabaseService {
  bool deleteAttachmentCalled = false;
  bool recordDeleteOpCalled = false;
  bool insertAttachmentCalled = false;
  bool recordUpsertOpCalled = false;

  @override
  bool get isOpen => true;

  @override
  Future<void> insertAttachment(AssetAttachment attachment) async {
    insertAttachmentCalled = true;
  }

  @override
  Future<void> deleteAttachment(String id) async {
    deleteAttachmentCalled = true;
  }

  @override
  Future<OpLogEntry> recordAttachmentOperation(
    String attachmentId,
    OpType op, {
    required Map<String, dynamic> payload,
  }) async {
    if (op == OpType.delete) recordDeleteOpCalled = true;
    if (op == OpType.upsert) recordUpsertOpCalled = true;
    return OpLogEntry(
      id: 'op-1',
      op: op,
      entityType: OpEntityType.attachment,
      entityId: attachmentId,
      payload: payload,
      createdAt: 0,
    );
  }
}

class _MockFilePickerService extends FilePickerService {
  final PickedLocalFile? pickedFile;
  _MockFilePickerService(this.pickedFile);

  @override
  Future<PickedLocalFile?> pickSingleFile() async => pickedFile;
}

// ─── Helpers ────────────────────────────────────────────────────────────────

Asset _testAsset() => const Asset(
  id: 'asset-1',
  typeId: 'type_generic',
  name: 'My VPS',
  createdAt: 0,
  updatedAt: 0,
  isArchived: false,
  fields: [],
  tags: [],
  reminders: [],
);

AssetAttachment _attachment(String id, String name) => AssetAttachment(
  id: id,
  assetId: 'asset-1',
  name: name,
  mimeType: 'text/plain',
  size: 1024,
  encFileName: '$id.enc',
  createdAt: 0,
  updatedAt: 0,
);

/// Wraps [child] in a [ProviderScope] + [MaterialApp] with English locale.
Widget _wrap(Widget child, List<Override> overrides) {
  return ProviderScope(
    overrides: overrides,
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
      home: child,
    ),
  );
}

/// Common provider overrides used by all tests (excludes attachmentsProvider
/// which is configured per-test).
List<Override> _baseOverrides({
  List<AssetAttachment> attachments = const [],
  _MockAssetsNotifier? assetsNotifier,
  _MockAttachmentService? attachmentService,
  _MockDatabaseService? databaseService,
  _MockFilePickerService? filePickerService,
}) => [
  assetsProvider.overrideWith(() => assetsNotifier ?? _MockAssetsNotifier()),
  assetTypesProvider.overrideWith(() => _MockAssetTypesNotifier()),
  encryptionServiceProvider.overrideWithValue(_MockEncryptionService()),
  attachmentServiceProvider.overrideWithValue(
    attachmentService ?? _MockAttachmentService(),
  ),
  databaseServiceProvider.overrideWithValue(
    databaseService ?? _MockDatabaseService(),
  ),
  assetRelationsProvider.overrideWith((ref, assetId) async => []),
  attachmentsProvider.overrideWith((ref, assetId) async => attachments),
  filePickerServiceProvider.overrideWithValue(
    filePickerService ?? _MockFilePickerService(null),
  ),
];

// ─── Tests ──────────────────────────────────────────────────────────────────

void main() {
  group('AssetDetailScreen attachments', () {
    testWidgets(
      'shows Attachments section header when provider returns items',
      (tester) async {
        // WILL FAIL (Red): AssetDetailScreen has no Attachments section yet.
        await tester.pumpWidget(
          _wrap(
            const AssetDetailScreen(assetId: 'asset-1'),
            _baseOverrides(
              attachments: [
                _attachment('a1', 'server_key.pem'),
                _attachment('a2', 'notes.txt'),
              ],
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Attachments'), findsOneWidget);
      },
    );

    testWidgets('shows attach_file button in Attachments section', (
      tester,
    ) async {
      // WILL FAIL (Red): no attach_file icon button exists yet.
      await tester.pumpWidget(
        _wrap(
          const AssetDetailScreen(assetId: 'asset-1'),
          _baseOverrides(
            attachments: [
              _attachment('a1', 'server_key.pem'),
              _attachment('a2', 'notes.txt'),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.attach_file), findsOneWidget);
    });

    testWidgets('shows each attachment name and size', (tester) async {
      // WILL FAIL (Red): attachment rows not rendered yet.
      await tester.pumpWidget(
        _wrap(
          const AssetDetailScreen(assetId: 'asset-1'),
          _baseOverrides(attachments: [_attachment('a1', 'server_key.pem')]),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('server_key.pem'), findsOneWidget);
    });

    testWidgets('delete icon shows confirmation dialog', (tester) async {
      // WILL FAIL (Red): no delete icon in attachments section yet.
      await tester.pumpWidget(
        _wrap(
          const AssetDetailScreen(assetId: 'asset-1'),
          _baseOverrides(attachments: [_attachment('a1', 'server_key.pem')]),
        ),
      );
      await tester.pumpAndSettle();

      // The AppBar already contains an Icons.delete_outline for the asset;
      // the *last* one should be the per-attachment delete icon once
      // the section is implemented.
      await tester.tap(find.byKey(const Key('attachment_delete_a1')));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsOneWidget);
    });

    testWidgets('confirm delete triggers DB delete and file delete', (
      tester,
    ) async {
      final mockAttachmentSvc = _MockAttachmentService();
      final mockDbSvc = _MockDatabaseService();
      final mockAssetsNotifier = _MockAssetsNotifier();
      await tester.pumpWidget(
        _wrap(
          const AssetDetailScreen(assetId: 'asset-1'),
          _baseOverrides(
            attachments: [_attachment('a1', 'server_key.pem')],
            assetsNotifier: mockAssetsNotifier,
            attachmentService: mockAttachmentSvc,
            databaseService: mockDbSvc,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('attachment_delete_a1')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete').last);
      await tester.pumpAndSettle();

      expect(mockDbSvc.deleteAttachmentCalled, isTrue);
      expect(mockDbSvc.recordDeleteOpCalled, isTrue);
      expect(mockAttachmentSvc.deleteCalled, isTrue);
      expect(mockAssetsNotifier.deleteRemoteAttachmentCalled, isTrue);
      expect(mockAssetsNotifier.syncNowCalled, isTrue);
      expect(
        mockAssetsNotifier.callOrder,
        equals(['syncNow', 'deleteRemoteAttachment']),
      );
    });

    testWidgets(
      'local file delete failure does not block sync or remote delete',
      (tester) async {
        final mockAttachmentSvc = _MockAttachmentService()
          ..deleteError = Exception('io');
        final mockDbSvc = _MockDatabaseService();
        final mockAssetsNotifier = _MockAssetsNotifier();
        await tester.pumpWidget(
          _wrap(
            const AssetDetailScreen(assetId: 'asset-1'),
            _baseOverrides(
              attachments: [_attachment('a1', 'server_key.pem')],
              assetsNotifier: mockAssetsNotifier,
              attachmentService: mockAttachmentSvc,
              databaseService: mockDbSvc,
            ),
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const Key('attachment_delete_a1')));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Delete').last);
        await tester.pumpAndSettle();

        expect(mockDbSvc.deleteAttachmentCalled, isTrue);
        expect(mockDbSvc.recordDeleteOpCalled, isTrue);
        expect(mockAssetsNotifier.syncNowCalled, isTrue);
        expect(mockAssetsNotifier.deleteRemoteAttachmentCalled, isTrue);
      },
    );

    testWidgets('attach button triggers save, DB insert/upsert and push sync', (
      tester,
    ) async {
      final mockAttachmentSvc = _MockAttachmentService();
      final mockDbSvc = _MockDatabaseService();
      final mockAssetsNotifier = _MockAssetsNotifier();
      final mockFilePicker = _MockFilePickerService(
        PickedLocalFile(
          name: 'new-note.txt',
          mimeType: 'text/plain',
          bytes: Uint8List.fromList([1, 2, 3]),
        ),
      );
      await tester.pumpWidget(
        _wrap(
          const AssetDetailScreen(assetId: 'asset-1'),
          _baseOverrides(
            attachments: [_attachment('a1', 'server_key.pem')],
            assetsNotifier: mockAssetsNotifier,
            attachmentService: mockAttachmentSvc,
            databaseService: mockDbSvc,
            filePickerService: mockFilePicker,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.attach_file));
      await tester.pumpAndSettle();

      expect(mockDbSvc.insertAttachmentCalled, isTrue);
      expect(mockDbSvc.recordUpsertOpCalled, isTrue);
      expect(mockAssetsNotifier.pushSyncCalled, isTrue);
      expect(mockAssetsNotifier.syncNowCalled, isTrue);
    });

    testWidgets('shows attach button even when provider returns empty list', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(const AssetDetailScreen(assetId: 'asset-1'), _baseOverrides()),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('attachments_section')), findsOneWidget);
      expect(find.byIcon(Icons.attach_file), findsOneWidget);
    });
  });
}
