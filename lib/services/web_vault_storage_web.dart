import 'dart:async';
import 'dart:js_interop';
import 'package:flutter/foundation.dart';
import 'package:web/web.dart' as web;

const _dbName = 'OctarqVault';
const _storeName = 'vault';
const _key = 'enc';

/// Web: persist encrypted vault blob in IndexedDB.
class WebVaultStorage {
  web.IDBDatabase? _db;
  Completer<web.IDBDatabase>? _openCompleter;

  Future<web.IDBDatabase> _openDb() async {
    if (_db != null) return _db!;
    if (_openCompleter != null) return _openCompleter!.future;
    _openCompleter = Completer<web.IDBDatabase>();
    final request = web.window.indexedDB.open(_dbName, 1);
    request.onupgradeneeded = ((web.Event e) {
      final db = (e.target as web.IDBRequest).result as web.IDBDatabase;
      if (!db.objectStoreNames.contains(_storeName)) {
        db.createObjectStore(_storeName);
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
      final request = store.get(_key.toJS);
      final completer = Completer<Uint8List?>();
      request.onsuccess = ((web.Event e) {
        final result = (e.target as web.IDBRequest).result;
        if (result == null) {
          completer.complete(null);
          return;
        }
        final buf = (result as JSArrayBuffer).toDart;
        completer.complete(Uint8List.view(buf));
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
      store.put(blob.toJS, _key.toJS);
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
}
