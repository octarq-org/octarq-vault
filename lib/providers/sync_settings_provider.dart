import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/sync_settings.dart';

const _keySyncMethods = 'sync_methods';

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
        state = SyncMethodX.listFromStrings(list);
      } catch (_) {
        final v = prefs.getString('sync_method');
        if (v != null) {
          final m = SyncMethodX.fromString(v);
          state = m == SyncMethod.none ? [] : [m];
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
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _keySyncMethods,
      jsonEncode(methods.map((m) => m.value).toList()),
    );
    state = methods;
  }

  bool hasSyncMethod(SyncMethod method) => state.contains(method);

  SyncSettingsExport exportSettings({String? webdavUrl}) {
    return SyncSettingsExport(
      syncMethods: state.map((m) => m.value).toList(),
      webdavUrl: webdavUrl,
    );
  }

  Future<void> importSettings(SyncSettingsExport data) async {
    state = SyncMethodX.listFromStrings(data.syncMethods);
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
