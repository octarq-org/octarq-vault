import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/sync_settings.dart';

const _keySyncMethods = 'sync_methods';
const _keyLastSyncAt = 'last_sync_at';

List<SyncMethod> _withoutDisabledMethods(List<SyncMethod> methods) {
  // Temporary policy: iCloud sync is paused for macOS testing.
  return methods.where((m) => m != SyncMethod.icloud).toList();
}

class SyncSettingsNotifier extends Notifier<List<SyncMethod>> {
  @override
  List<SyncMethod> build() {
    Future.microtask(() => load());
    return [];
  }

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_keySyncMethods);
    if (raw != null) {
      try {
        final list = jsonDecode(raw) as List<dynamic>?;
        state = _withoutDisabledMethods(SyncMethodX.listFromStrings(list));
      } catch (_) {
        final v = prefs.getString('sync_method');
        if (v != null) {
          final m = SyncMethodX.fromString(v);
          state = m == SyncMethod.none ? [] : _withoutDisabledMethods([m]);
        }
      }
    }
  }

  Future<void> toggleSyncMethod(SyncMethod method) async {
    if (method == SyncMethod.none) return;
    final next = state.contains(method)
        ? state.where((m) => m != method).toList()
        : [...state, method];
    await _save(next);
  }

  Future<void> setSyncMethods(List<SyncMethod> methods) async {
    await _save(methods.where((m) => m != SyncMethod.none).toList());
  }

  Future<void> _save(List<SyncMethod> methods) async {
    final sanitized = _withoutDisabledMethods(methods);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _keySyncMethods,
      jsonEncode(sanitized.map((m) => m.value).toList()),
    );
    state = sanitized;
  }

  bool hasSyncMethod(SyncMethod method) => state.contains(method);

  SyncSettingsExport exportSettings({String? webdavUrl}) {
    return SyncSettingsExport(
      syncMethods: state.map((m) => m.value).toList(),
      webdavUrl: webdavUrl,
    );
  }

  Future<void> importSettings(SyncSettingsExport data) async {
    state = _withoutDisabledMethods(
      SyncMethodX.listFromStrings(data.syncMethods),
    );
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _keySyncMethods,
      jsonEncode(state.map((m) => m.value).toList()),
    );
  }
}

final syncSettingsProvider =
    NotifierProvider<SyncSettingsNotifier, List<SyncMethod>>(() {
      return SyncSettingsNotifier();
    });

// ---------------------------------------------------------------------------
// lastSyncAt — persisted timestamp of the last successful sync
// ---------------------------------------------------------------------------

class LastSyncAtNotifier extends AsyncNotifier<DateTime?> {
  @override
  Future<DateTime?> build() async {
    final prefs = await SharedPreferences.getInstance();
    final ms = prefs.getInt(_keyLastSyncAt);
    return ms != null ? DateTime.fromMillisecondsSinceEpoch(ms) : null;
  }

  Future<void> recordSync() async {
    final now = DateTime.now();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyLastSyncAt, now.millisecondsSinceEpoch);
    state = AsyncValue.data(now);
  }
}

final lastSyncAtProvider = AsyncNotifierProvider<LastSyncAtNotifier, DateTime?>(
  () {
    return LastSyncAtNotifier();
  },
);
