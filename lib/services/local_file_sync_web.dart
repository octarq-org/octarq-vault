import 'dart:async';
import 'dart:js_interop';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:web/web.dart' as web;

import 'e2ee_sync_service.dart';
import '../models/asset.dart';
import '../models/asset_type.dart';

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

/// Manages native local file reading and writing on Web via File System Access API.
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
        "File System Access API is not supported in this browser or environment. Please use the Import/Export fallback buttons.",
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
          "File System Access API is not supported in this browser or environment. Please use the Import/Export fallback buttons.",
        );
      }
      if (kDebugMode) {
        debugPrint('User cancelled or File System API failed: $e');
      }
      rethrow;
    }
  }

  /// Write current assets to the linked file handle securely.
  Future<void> syncToLocal(
    List<Asset> assets, {
    List<AssetType> customAssetTypes = const [],
    List<Map<String, dynamic>> tombstones = const [],
  }) async {
    if (!kIsWeb || _currentFileHandle == null) return;

    try {
      final encryptedBlob = _syncService.packSnapshotTOCiphertext(
        assets,
        customAssetTypes: customAssetTypes,
        tombstones: tombstones,
      );

      final writableStream = await _currentFileHandle!.createWritable().toDart;
      await writableStream.write(encryptedBlob.toJS).toDart;
      await writableStream.close().toDart;

      if (kDebugMode) {
        debugPrint("Successfully synced E2EE snapshot to local file.");
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error syncing to local file: $e');
      }
      rethrow;
    }
  }

  /// Read the linked file into raw bytes for Cold Start recovery.
  Future<Uint8List?> readRawBytesFromLocal() async {
    if (!kIsWeb || _currentFileHandle == null) return null;

    try {
      final file = await _currentFileHandle!.getFile().toDart;
      final arrayBuffer = await file.arrayBuffer().toDart;
      final uint8List = arrayBuffer.toDart.asUint8List();

      if (uint8List.isEmpty) return null;
      return uint8List;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error reading from local file: $e');
      }
      rethrow;
    }
  }

  /// Read the linked file and decrypt it into a Snapshot.
  Future<VaultSnapshot?> readFromLocal() async {
    final uint8List = await readRawBytesFromLocal();
    if (uint8List == null) return null;
    return _syncService.unpackCiphertextToSnapshot(uint8List);
  }

  /// Fallback: Force download of the encrypted snapshot (For Safari/Firefox)
  void exportToDownload(
    List<Asset> assets, {
    List<AssetType> customAssetTypes = const [],
    List<Map<String, dynamic>> tombstones = const [],
  }) {
    if (!kIsWeb) return;

    final encryptedBlob = _syncService.packSnapshotTOCiphertext(
      assets,
      customAssetTypes: customAssetTypes,
      tombstones: tombstones,
    );

    final parts = [encryptedBlob.toJS].toJS;
    final blob = web.Blob(
      parts,
      web.BlobPropertyBag(type: 'application/octet-stream'),
    );
    final url = web.URL.createObjectURL(blob);

    final anchor = web.HTMLAnchorElement()
      ..href = url
      ..download = 'octarq_vault_backup.enc';

    web.document.body!.appendChild(anchor);
    anchor.click();
    web.document.body!.removeChild(anchor);
    web.URL.revokeObjectURL(url);
  }

  /// Fallback: Prompt user to upload a file and return raw bytes
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

  /// Fallback: Prompt user to upload a file (For Safari/Firefox)
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

    // We can't easily detect cancellation reliably across all browsers for input[type=file],
    // so we just trigger click.
    input.click();

    return completer.future;
  }
}
