import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:path_provider/path_provider.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'package:octarq_vault/services/attachment_service_io.dart';
import 'package:octarq_vault/services/encryption_service.dart';
import 'package:octarq_vault/models/attachment.dart';

// ---------------------------------------------------------------------------
// path_provider stub for tests
// ---------------------------------------------------------------------------

class _FakePathProvider
    with MockPlatformInterfaceMixin
    implements PathProviderPlatform {
  final Directory _tmpDir;
  _FakePathProvider(this._tmpDir);

  @override
  Future<String?> getApplicationSupportPath() async => _tmpDir.path;

  @override
  Future<String?> getApplicationDocumentsPath() async => _tmpDir.path;

  // Satisfy abstract interface stubs:
  @override
  Future<String?> getTemporaryPath() async => _tmpDir.path;

  @override
  Future<String?> getLibraryPath() async => null;

  @override
  Future<String?> getApplicationCachePath() async => _tmpDir.path;

  @override
  Future<String?> getExternalStoragePath() async => null;

  @override
  Future<List<String>?> getExternalCachePaths() async => null;

  @override
  Future<List<String>?> getExternalStoragePaths({
    StorageDirectory? type,
  }) async => null;

  @override
  Future<String?> getDownloadsPath() async => null;
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

EncryptionService _makeEncService() {
  final svc = EncryptionService();
  final key = Uint8List(32);
  for (int i = 0; i < 32; i++) {
    key[i] = i + 1;
  }
  svc.setMasterKey(key);
  svc.setSalt('dGVzdA=='); // base64('test')
  return svc;
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  late Directory tmpDir;
  late AttachmentService svc;

  setUp(() async {
    tmpDir = await Directory.systemTemp.createTemp('att_test_');
    PathProviderPlatform.instance = _FakePathProvider(tmpDir);
    svc = AttachmentService(_makeEncService());
  });

  tearDown(() async {
    await tmpDir.delete(recursive: true);
  });

  test('saveAttachment writes encrypted file to disk', () async {
    final plainBytes = Uint8List.fromList(List.generate(256, (i) => i % 256));
    final attachment = await svc.saveAttachment(
      assetId: 'asset-1',
      name: 'test.bin',
      mimeType: 'application/octet-stream',
      bytes: plainBytes,
    );

    // Metadata checks.
    expect(attachment.assetId, 'asset-1');
    expect(attachment.name, 'test.bin');
    expect(attachment.mimeType, 'application/octet-stream');
    expect(attachment.size, 256);
    expect(attachment.encFileName, endsWith('.enc'));

    // File should exist on disk.
    expect(await svc.attachmentExists(attachment), isTrue);

    // Encrypted file should differ from plaintext.
    final dir = Directory('${tmpDir.path}/octarq_attachments');
    final encFile = File('${dir.path}/${attachment.encFileName}');
    final encBytes = await encFile.readAsBytes();
    expect(encBytes, isNot(equals(plainBytes)));
  });

  test('loadAttachmentBytes decrypts to original plaintext', () async {
    final plainBytes = Uint8List.fromList(
      'Hello, OctarqVault attachments!'.codeUnits,
    );
    final attachment = await svc.saveAttachment(
      assetId: 'asset-2',
      name: 'note.txt',
      mimeType: 'text/plain',
      bytes: plainBytes,
    );

    final recovered = await svc.loadAttachmentBytes(attachment);
    expect(recovered, equals(plainBytes));
  });

  test('loadEncryptedBytes returns raw ciphertext', () async {
    final plain = Uint8List.fromList([1, 2, 3, 4, 5]);
    final attachment = await svc.saveAttachment(
      assetId: 'asset-3',
      name: 'tiny.bin',
      mimeType: 'application/octet-stream',
      bytes: plain,
    );

    final enc = await svc.loadEncryptedBytes(attachment);
    // Ciphertext = 12-byte IV + ciphertext + 16-byte GCM tag
    expect(enc.length, greaterThan(plain.length));
    expect(enc, isNot(equals(plain)));
  });

  test('saveEncryptedBytes then loadAttachmentBytes roundtrip', () async {
    // Simulate cross-device sync: device A encrypts, device B receives raw
    // bytes and saves them; device B then decrypts.
    final encSvc = _makeEncService();
    final plain = Uint8List.fromList('cross-device secret'.codeUnits);
    final encBytes = encSvc.encryptBytes(plain);

    // Build a fake attachment record.
    final attachment = AssetAttachment(
      id: 'sync-att',
      assetId: 'a99',
      name: 'sync.txt',
      mimeType: 'text/plain',
      size: plain.length,
      encFileName: 'sync-att.enc',
      createdAt: 1000,
      updatedAt: 1000,
    );

    await svc.saveEncryptedBytes(attachment, encBytes);
    expect(await svc.attachmentExists(attachment), isTrue);

    final recovered = await svc.loadAttachmentBytes(attachment);
    expect(recovered, equals(plain));
  });

  test('deleteAttachmentFile removes file from disk', () async {
    final attachment = await svc.saveAttachment(
      assetId: 'asset-4',
      name: 'temp.bin',
      mimeType: 'application/octet-stream',
      bytes: Uint8List.fromList([0, 1, 2]),
    );
    expect(await svc.attachmentExists(attachment), isTrue);

    await svc.deleteAttachmentFile(attachment);
    expect(await svc.attachmentExists(attachment), isFalse);
  });

  test('loadAttachmentBytes throws when file is missing', () async {
    final missing = AssetAttachment(
      id: 'no-such-id',
      assetId: 'a0',
      name: 'missing.bin',
      mimeType: 'application/octet-stream',
      size: 0,
      encFileName: 'no-such-id.enc',
      createdAt: 0,
      updatedAt: 0,
    );
    expect(
      () => svc.loadAttachmentBytes(missing),
      throwsA(isA<Exception>()),
    );
  });

  test('each save generates a unique encFileName', () async {
    final plain = Uint8List.fromList([42]);
    final a1 = await svc.saveAttachment(
      assetId: 'a',
      name: 'f.bin',
      mimeType: 'application/octet-stream',
      bytes: plain,
    );
    final a2 = await svc.saveAttachment(
      assetId: 'a',
      name: 'f.bin',
      mimeType: 'application/octet-stream',
      bytes: plain,
    );
    expect(a1.encFileName, isNot(equals(a2.encFileName)));
    expect(a1.id, isNot(equals(a2.id)));
  });
}
