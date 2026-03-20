import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _kAutoLockMinutesKey = 'auto_lock_minutes';
const _kAutoLockDefault = 5;

class AutoLockNotifier extends Notifier<int> {
  @override
  int build() {
    // Load persisted value asynchronously; start with default.
    Future.microtask(_load);
    return _kAutoLockDefault;
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getInt(_kAutoLockMinutesKey);
    if (saved != null && ref.mounted) state = saved;
  }

  Future<void> setMinutes(int minutes) async {
    state = minutes;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kAutoLockMinutesKey, minutes);
  }
}

final autoLockMinutesProvider = NotifierProvider<AutoLockNotifier, int>(
  () => AutoLockNotifier(),
);
