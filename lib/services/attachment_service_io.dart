// Native (IO) implementation of AttachmentService.
// Blobs are stored in <ApplicationSupport>/octarq_attachments/<uuid>.enc,
// encrypted with AES-256-GCM via [EncryptionService.encryptBytes].

import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import '../models/attachment.dart';
import 'encryption_service.dart';

const _dirName = 'octarq_attachments';
const _uuid = Uuid();

class AttachmentService {
  final EncryptionService _enc;

  AttachmentService(this._enc);

  Future<Directory> _dir() async {
    final base = await getApplicationSupportDirectory();
    final dir = Directory('${base.path}/$_dirName');
    if (!dir.existsSync()) dir.createSync(recursive: true);
    return dir;
  }

  File _file(Directory dir, AssetAttachment a) =>
      File('${dir.path}/${a.encFileName}');

  // -------------------------------------------------------------------------
  // Write
  // -------------------------------------------------------------------------

  /// Encrypts [bytes] and persists them to disk.
  ///
  /// Returns an [AssetAttachment] record with the generated [encFileName];
  /// the caller is responsible for saving the record to [DatabaseService].
  Future<AssetAttachment> saveAttachment({
    required String assetId,
    required String name,
    required String mimeType,
    required Uint8List bytes,
  }) async {
    final id = _uuid.v4();
    final encFileName = '$id.enc';
    final dir = await _dir();
    final encBytes = _enc.encryptBytes(bytes);
    await File('${dir.path}/$encFileName').writeAsBytes(encBytes, flush: true);

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

  /// Writes raw pre-encrypted [encBytes] received from a sync backend.
  ///
  /// Use this when downloading an attachment blob that was encrypted by
  /// another device — the bytes are already AES-GCM encrypted.
  Future<void> saveEncryptedBytes(
    AssetAttachment attachment,
    Uint8List encBytes,
  ) async {
    final dir = await _dir();
    await _file(dir, attachment).writeAsBytes(encBytes, flush: true);
  }

  // -------------------------------------------------------------------------
  // Read
  // -------------------------------------------------------------------------

  /// Decrypts and returns the plaintext bytes of [attachment].
  Future<Uint8List> loadAttachmentBytes(AssetAttachment attachment) async {
    final dir = await _dir();
    final f = _file(dir, attachment);
    if (!f.existsSync()) {
      throw Exception(
        'Attachment file not found: ${attachment.encFileName}',
      );
    }
    final encBytes = await f.readAsBytes();
    return _enc.decryptBytes(encBytes);
  }

  /// Returns the raw encrypted bytes of [attachment] for sync upload.
  Future<Uint8List> loadEncryptedBytes(AssetAttachment attachment) async {
    final dir = await _dir();
    final f = _file(dir, attachment);
    if (!f.existsSync()) {
      throw Exception(
        'Attachment file not found: ${attachment.encFileName}',
      );
    }
    return f.readAsBytes();
  }

  /// Returns `true` if the encrypted blob for [attachment] is present locally.
  Future<bool> attachmentExists(AssetAttachment attachment) async {
    final dir = await _dir();
    return _file(dir, attachment).existsSync();
  }

  // -------------------------------------------------------------------------
  // Delete
  // -------------------------------------------------------------------------

  /// Removes the encrypted blob for [attachment] from disk.
  Future<void> deleteAttachmentFile(AssetAttachment attachment) async {
    final dir = await _dir();
    final f = _file(dir, attachment);
    if (f.existsSync()) await f.delete();
  }
}
