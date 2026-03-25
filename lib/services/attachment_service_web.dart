// Web: encrypted attachment blobs in IndexedDB (WebVaultStorage).

import 'dart:typed_data';

import 'package:uuid/uuid.dart';

import '../models/attachment.dart';
import 'encryption_service.dart';
import 'web_vault_storage.dart';

const _uuid = Uuid();

class AttachmentService {
  final EncryptionService _enc;
  final WebVaultStorage _storage;

  AttachmentService(this._enc, this._storage);

  Future<AssetAttachment> saveAttachment({
    required String assetId,
    required String name,
    required String mimeType,
    required Uint8List bytes,
  }) async {
    final id = _uuid.v4();
    final encFileName = '$id.enc';
    final encBytes = _enc.encryptBytes(bytes);
    await _storage.writeAttachment(encFileName, encBytes);

    final now = DateTime.now().millisecondsSinceEpoch;
    return AssetAttachment(
      id: id,
      assetId: assetId,
      name: name,
      mimeType: mimeType,
      size: bytes.length,
      encFileName: encFileName,
      createdAt: now,
      updatedAt: now,
    );
  }

  Future<void> saveEncryptedBytes(
    AssetAttachment attachment,
    Uint8List encBytes,
  ) => _storage.writeAttachment(attachment.encFileName, encBytes);

  Future<Uint8List> loadAttachmentBytes(AssetAttachment attachment) async {
    final enc = await _storage.readAttachment(attachment.encFileName);
    if (enc == null) {
      throw Exception('Attachment file not found: ${attachment.encFileName}');
    }
    return _enc.decryptBytes(enc);
  }

  Future<Uint8List> loadEncryptedBytes(AssetAttachment attachment) async {
    final enc = await _storage.readAttachment(attachment.encFileName);
    if (enc == null) {
      throw Exception('Attachment file not found: ${attachment.encFileName}');
    }
    return enc;
  }

  Future<bool> attachmentExists(AssetAttachment attachment) async {
    final enc = await _storage.readAttachment(attachment.encFileName);
    return enc != null && enc.isNotEmpty;
  }

  Future<void> deleteAttachmentFile(AssetAttachment attachment) =>
      _storage.deleteAttachmentBlob(attachment.encFileName);
}
