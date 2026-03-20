// Stub for platforms that do not support native file-system attachment storage
// (currently the Web platform). Attachment operations throw [UnsupportedError].

import 'dart:typed_data';

import '../models/attachment.dart';
import 'encryption_service.dart';

class AttachmentService {
  // ignore: avoid_unused_constructor_parameters
  AttachmentService(EncryptionService _);

  static Never _unsupported() =>
      throw UnsupportedError(
        'Attachment storage is not supported on this platform. '
        'Use a native (iOS / Android / macOS / Linux / Windows) build.',
      );

  Future<AssetAttachment> saveAttachment({
    required String assetId,
    required String name,
    required String mimeType,
    required Uint8List bytes,
  }) => _unsupported();

  Future<void> saveEncryptedBytes(
    AssetAttachment attachment,
    Uint8List encBytes,
  ) => _unsupported();

  Future<Uint8List> loadAttachmentBytes(AssetAttachment attachment) =>
      _unsupported();

  Future<Uint8List> loadEncryptedBytes(AssetAttachment attachment) =>
      _unsupported();

  Future<bool> attachmentExists(AssetAttachment attachment) => _unsupported();

  Future<void> deleteAttachmentFile(AssetAttachment attachment) =>
      _unsupported();
}
