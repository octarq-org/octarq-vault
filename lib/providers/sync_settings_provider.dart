import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/sync_settings.dart';

const _keySyncMethod = 'sync_method';

class SyncSettingsNotifier extends Notifier<SyncMethod> {
  @override
  SyncMethod build() {
    Future.microtask(() => load());
    return SyncMethod.none;
  }

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final v = prefs.getString(_keySyncMethod);
    state = SyncMethodX.fromString(v);
  }

  Future<void> setSyncMethod(SyncMethod method) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keySyncMethod, method.value);
    state = method;
  }

  SyncSettingsExport exportSettings({String? webdavUrl}) {
    return SyncSettingsExport(syncMethod: state.value, webdavUrl: webdavUrl);
  }

  Future<void> importSettings(SyncSettingsExport data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keySyncMethod, data.syncMethod);
    state = SyncMethodX.fromString(data.syncMethod);
  }
}

final syncSettingsProvider = NotifierProvider<SyncSettingsNotifier, SyncMethod>(
  () {
    return SyncSettingsNotifier();
  },
);
