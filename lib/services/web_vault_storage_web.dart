import 'dart:async';
import 'dart:js_interop';
import 'package:flutter/foundation.dart';
import 'package:web/web.dart' as web;

const _dbName = 'OctarqVault';
const _storeName = 'vault';
const _attachmentsStoreName = 'attachments';
const _vaultKey = 'enc';
const _idbVersion = 2;

/// Web: persist encrypted vault blob and attachment ciphertext in IndexedDB.
class WebVaultStorage {
  web.IDBDatabase? _db;
  Completer<web.IDBDatabase>? _openCompleter;

  Future<web.IDBDatabase> _openDb() async {
    if (_db != null) return _db!;
    if (_openCompleter != null) return _openCompleter!.future;
    _openCompleter = Completer<web.IDBDatabase>();
    final request = web.window.indexedDB.open(_dbName, _idbVersion);
    request.onupgradeneeded = ((web.Event e) {
      final db = (e.target as web.IDBRequest).result as web.IDBDatabase;
      if (!db.objectStoreNames.contains(_storeName)) {
        db.createObjectStore(_storeName);
      }
      if (!db.objectStoreNames.contains(_attachmentsStoreName)) {
        db.createObjectStore(_attachmentsStoreName);
      }
    }).toJS;
    request.onsuccess = ((web.Event e) {
      _db = (e.target as web.IDBRequest).result as web.IDBDatabase;
      _openCompleter!.complete(_db!);
    }).toJS;
    request.onerror = ((web.Event e) {
      _openCompleter!.completeError(
        (e.target as web.IDBRequest).error ??
            Exception('IndexedDB open failed'),
      );
    }).toJS;
    return _openCompleter!.future;
  }

  Future<Uint8List?> readEncrypted() async {
    if (!kIsWeb) return null;
    try {
      final db = await _openDb();
      final txn = db.transaction(_storeName.toJS, 'readonly');
      final store = txn.objectStore(_storeName);
      final request = store.get(_vaultKey.toJS);
      final completer = Completer<Uint8List?>();
      request.onsuccess = ((web.Event e) {
        final result = (e.target as web.IDBRequest).result;
        if (result == null) {
          completer.complete(null);
          return;
        }
        try {
          // Preferred path: value stored as ArrayBuffer.
          final buf = (result as JSArrayBuffer).toDart;
          completer.complete(Uint8List.view(buf));
        } catch (_) {
          try {
            // Backward-compatible path: value stored as Uint8Array.
            final bytes = (result as JSUint8Array).toDart;
            completer.complete(Uint8List.fromList(bytes.toList()));
          } catch (e) {
            completer.completeError(
              Exception(
                'IndexedDB value type unsupported: ${result.runtimeType}',
              ),
            );
          }
        }
      }).toJS;
      request.onerror = ((web.Event e) {
        completer.completeError(
          (e.target as web.IDBRequest).error ??
              Exception('IndexedDB get failed'),
        );
      }).toJS;
      return completer.future;
    } catch (e) {
      if (kDebugMode) print('WebVaultStorage readEncrypted: $e');
      return null;
    }
  }

  Future<void> writeEncrypted(Uint8List blob) async {
    if (!kIsWeb) return;
    try {
      final db = await _openDb();
      final txn = db.transaction(_storeName.toJS, 'readwrite');
      final store = txn.objectStore(_storeName);
      // Uint8Array avoids storing a sliced view's full ArrayBuffer by mistake.
      store.put(blob.toJS, _vaultKey.toJS);
      final completer = Completer<void>();
      txn.oncomplete = ((web.Event _) {
        if (!completer.isCompleted) completer.complete();
      }).toJS;
      txn.onerror = ((web.Event e) {
        if (!completer.isCompleted) {
          completer.completeError(
            (e.target as web.IDBTransaction).error ??
                Exception('IndexedDB put failed'),
          );
        }
      }).toJS;
      await completer.future;
    } catch (e) {
      if (kDebugMode) print('WebVaultStorage writeEncrypted: $e');
      rethrow;
    }
  }

  Future<Uint8List?> readAttachment(String encFileName) async {
    if (!kIsWeb) return null;
    try {
      final db = await _openDb();
      final txn = db.transaction(_attachmentsStoreName.toJS, 'readonly');
      final store = txn.objectStore(_attachmentsStoreName);
      final request = store.get(encFileName.toJS);
      final completer = Completer<Uint8List?>();
      request.onsuccess = ((web.Event e) {
        final result = (e.target as web.IDBRequest).result;
        if (result == null) {
          completer.complete(null);
          return;
        }
        try {
          final buf = (result as JSArrayBuffer).toDart;
          completer.complete(Uint8List.view(buf));
        } catch (_) {
          try {
            final bytes = (result as JSUint8Array).toDart;
            completer.complete(Uint8List.fromList(bytes.toList()));
          } catch (err) {
            completer.completeError(
              Exception(
                'IndexedDB attachment value unsupported: ${result.runtimeType}',
              ),
            );
          }
        }
      }).toJS;
      request.onerror = ((web.Event e) {
        completer.completeError(
          (e.target as web.IDBRequest).error ??
              Exception('IndexedDB attachment get failed'),
        );
      }).toJS;
      return completer.future;
    } catch (e) {
      if (kDebugMode) print('WebVaultStorage readAttachment: $e');
      return null;
    }
  }

  Future<void> writeAttachment(String encFileName, Uint8List bytes) async {
    if (!kIsWeb) return;
    final db = await _openDb();
    final txn = db.transaction(_attachmentsStoreName.toJS, 'readwrite');
    final store = txn.objectStore(_attachmentsStoreName);
    store.put(bytes.toJS, encFileName.toJS);
    final completer = Completer<void>();
    txn.oncomplete = ((web.Event _) {
      if (!completer.isCompleted) completer.complete();
    }).toJS;
    txn.onerror = ((web.Event e) {
      if (!completer.isCompleted) {
        completer.completeError(
          (e.target as web.IDBTransaction).error ??
              Exception('IndexedDB attachment put failed'),
        );
      }
    }).toJS;
    await completer.future;
  }

  Future<void> deleteAttachmentBlob(String encFileName) async {
    if (!kIsWeb) return;
    try {
      final db = await _openDb();
      final txn = db.transaction(_attachmentsStoreName.toJS, 'readwrite');
      final store = txn.objectStore(_attachmentsStoreName);
      store.delete(encFileName.toJS);
      final completer = Completer<void>();
      txn.oncomplete = ((web.Event _) {
        if (!completer.isCompleted) completer.complete();
      }).toJS;
      txn.onerror = ((web.Event e) {
        if (!completer.isCompleted) {
          completer.completeError(
            (e.target as web.IDBTransaction).error ??
                Exception('IndexedDB attachment delete failed'),
          );
        }
      }).toJS;
      await completer.future;
    } catch (e) {
      if (kDebugMode) print('WebVaultStorage deleteAttachmentBlob: $e');
    }
  }
}
