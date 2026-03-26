import 'dart:async';
import 'dart:convert';
import 'dart:js_interop';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:web/web.dart' as web;

import 'e2ee_sync_service.dart';
import '../models/asset.dart';
import '../models/asset_type.dart';
import '../models/attachment.dart';

final localFileSyncServiceProvider = Provider<LocalFileSyncService>((ref) {
  return LocalFileSyncService(ref.read(e2eeSyncServiceProvider));
});

@JS('window.showOpenFilePicker')
external JSAny? get _showOpenFilePickerFunc;

@JS('window.showOpenFilePicker')
external JSPromise<JSArray<web.FileSystemFileHandle>>? _showOpenFilePicker();

@JS('window.showSaveFilePicker')
external JSPromise<web.FileSystemFileHandle>? _showSaveFilePicker([
  JSAny? options,
]);

extension FileSystemFileHandleExtension on web.FileSystemFileHandle {
  @JS('createWritable')
  external JSPromise<web.FileSystemWritableFileStream> createWritable();

  @JS('getFile')
  external JSPromise<web.File> getFile();
}

extension FileSystemWritableFileStreamExtension
    on web.FileSystemWritableFileStream {
  @JS('write')
  external JSPromise<JSAny> write(JSAny data);

  @JS('close')
  external JSPromise<JSAny> close();
}

/// Manages native local file reading and writing on Web via File System Access
/// API. Attachments are not stored on-device on the web platform; their
/// metadata is included in the exported snapshot for cross-device discovery.
class LocalFileSyncService {
  final E2EESyncService _syncService;

  // The active file handle, if any. Only works on Chrome/Edge.
  web.FileSystemFileHandle? _currentFileHandle;

  LocalFileSyncService(this._syncService);

  bool get isSupported => kIsWeb && _showOpenFilePickerFunc != null;

  bool get hasActiveHandle => _currentFileHandle != null;

  /// Prompt the user to pick an existing `octarq_vault.enc` or save to a new one.
  Future<void> linkFileForSync({bool createNew = false}) async {
    if (!kIsWeb) return;

    if (!isSupported) {
      throw Exception(
        "File System Access API is not supported in this browser or environment. "
        "Please use the Import/Export fallback buttons.",
      );
    }

    try {
      if (createNew) {
        final options = {'suggestedName': 'octarq_vault.enc'}.jsify();
        final handle = await _showSaveFilePicker(options)?.toDart;
        _currentFileHandle = handle;
      } else {
        final jsHandles = await _showOpenFilePicker()?.toDart;
        if (jsHandles != null) {
          final handlesList = jsHandles.toDart;
          if (handlesList.isNotEmpty) {
            _currentFileHandle = handlesList.first;
          }
        }
      }
    } catch (e) {
      if (e.toString().contains('not a function') ||
          e.toString().contains('NoSuchMethodError')) {
        throw Exception(
          "File System Access API is not supported in this browser or environment. "
          "Please use the Import/Export fallback buttons.",
        );
      }
      if (kDebugMode) {
        debugPrint('User cancelled or File System API failed: $e');
      }
      rethrow;
    }
  }

  // -------------------------------------------------------------------------
  // Full snapshot sync
  // -------------------------------------------------------------------------

  /// Encrypts the vault state and writes it to the linked file handle.
  Future<void> syncToLocal(
    List<Asset> assets, {
    List<AssetType> customAssetTypes = const [],
    List<Map<String, dynamic>> tombstones = const [],
    List<Map<String, dynamic>> relations = const [],
    List<OpLogEntry> opLog = const [],
    List<AssetAttachment> attachmentManifest = const [],
  }) async {
    if (!kIsWeb || _currentFileHandle == null) return;

    try {
      final encryptedBlob = _syncService.packSnapshotTOCiphertext(
        assets,
        customAssetTypes: customAssetTypes,
        tombstones: tombstones,
        relations: relations,
        opLog: opLog,
        attachmentManifest: attachmentManifest,
      );

      final writableStream = await _currentFileHandle!.createWritable().toDart;
      await writableStream.write(encryptedBlob.toJS).toDart;
      await writableStream.close().toDart;

      if (kDebugMode) {
        debugPrint("Successfully synced E2EE snapshot to local file.");
      }
    } catch (e) {
      if (kDebugMode) debugPrint('Error syncing to local file: $e');
      rethrow;
    }
  }

  /// Reads and returns raw encrypted bytes from the linked file.
  Future<Uint8List?> readRawBytesFromLocal() async {
    if (!kIsWeb || _currentFileHandle == null) return null;

    try {
      final file = await _currentFileHandle!.getFile().toDart;
      final arrayBuffer = await file.arrayBuffer().toDart;
      final uint8List = arrayBuffer.toDart.asUint8List();
      return uint8List.isEmpty ? null : uint8List;
    } catch (e) {
      if (kDebugMode) debugPrint('Error reading from local file: $e');
      rethrow;
    }
  }

  /// Reads and decrypts the linked file into a [VaultSnapshot].
  Future<VaultSnapshot?> readFromLocal() async {
    final uint8List = await readRawBytesFromLocal();
    if (uint8List == null) return null;
    return _syncService.unpackCiphertextToSnapshot(uint8List);
  }

  // -------------------------------------------------------------------------
  // Delta sync (web — file-handle variant)
  // -------------------------------------------------------------------------

  /// Writes a delta blob to the linked file handle.
  ///
  /// Note: overwrites the file. On web, full-snapshot and delta blobs share
  /// the same linked file; the receiver distinguishes them via
  /// [VaultSnapshot.payloadType].
  Future<void> syncDeltaToLocal({
    required List<OpLogEntry> opLogEntries,
    required int baseSeq,
    List<AssetAttachment> attachmentManifest = const [],
  }) async {
    if (!kIsWeb || _currentFileHandle == null) return;
    if (opLogEntries.isEmpty) return;

    final blob = _syncService.packDeltaToCiphertext(
      opLogEntries: opLogEntries,
      baseSeq: baseSeq,
      attachmentManifest: attachmentManifest,
    );

    final writableStream = await _currentFileHandle!.createWritable().toDart;
    await writableStream.write(blob.toJS).toDart;
    await writableStream.close().toDart;
  }

  // -------------------------------------------------------------------------
  // Fallback: browser download / upload (Safari / Firefox)
  // -------------------------------------------------------------------------

  /// Forces a browser download of the encrypted snapshot.
  void exportToDownload(
    List<Asset> assets, {
    List<AssetType> customAssetTypes = const [],
    List<Map<String, dynamic>> tombstones = const [],
    List<Map<String, dynamic>> relations = const [],
    List<OpLogEntry> opLog = const [],
    List<AssetAttachment> attachmentManifest = const [],
  }) {
    if (!kIsWeb) return;

    final encryptedBlob = _syncService.packSnapshotTOCiphertext(
      assets,
      customAssetTypes: customAssetTypes,
      tombstones: tombstones,
      relations: relations,
      opLog: opLog,
      attachmentManifest: attachmentManifest,
    );

    final b64 = base64.encode(encryptedBlob);
    final dataUri = 'data:application/octet-stream;base64,$b64';

    final anchor = web.HTMLAnchorElement()
      ..href = dataUri
      ..download = 'octarq_vault_backup.enc';

    web.document.body!.appendChild(anchor);
    anchor.click();
    web.document.body!.removeChild(anchor);
  }

  /// Prompts the user to upload a file and returns raw encrypted bytes.
  Future<Uint8List?> importRawBytesFromUpload() async {
    if (!kIsWeb) return null;

    final input = web.HTMLInputElement()..type = 'file';
    web.document.body!.appendChild(input);

    final result = await _pickFile(input);
    web.document.body!.removeChild(input);

    if (result != null) {
      final arrayBuffer = await result.arrayBuffer().toDart;
      return arrayBuffer.toDart.asUint8List();
    }
    return null;
  }

  /// Prompts the user to upload a file and decrypts it into a [VaultSnapshot].
  Future<VaultSnapshot?> importFromUpload() async {
    final uint8List = await importRawBytesFromUpload();
    if (uint8List != null && uint8List.isNotEmpty) {
      return _syncService.unpackCiphertextToSnapshot(uint8List);
    }
    return null;
  }

  Future<web.File?> _pickFile(web.HTMLInputElement input) {
    final completer = Completer<web.File?>();

    input.onChange.listen((event) {
      final files = input.files;
      if (files != null && files.length > 0) {
        completer.complete(files.item(0));
      } else {
        completer.complete(null);
      }
    });

    input.click();
    return completer.future;
  }
}
