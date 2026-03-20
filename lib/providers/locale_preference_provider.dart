import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _keyLocaleOverride = 'locale_override'; // 'system' | 'en' | 'es' | 'zh'

class LocalePreferenceNotifier extends Notifier<String> {
  @override
  String build() {
    Future.microtask(() => load());
    return 'system';
  }

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getString(_keyLocaleOverride) ?? 'system';
  }

  Future<void> setLocaleOverride(String value) async {
    if (value != 'system' && value != 'zh' && value != 'en' && value != 'es') {
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyLocaleOverride, value);
    state = value;
  }
}

final localePreferenceProvider =
    NotifierProvider<LocalePreferenceNotifier, String>(() {
      return LocalePreferenceNotifier();
    });

/// 当前生效的 Locale：优先使用用户设置，否则跟随系统。
final localeProvider = Provider<Locale>((ref) {
  final override = ref.watch(localePreferenceProvider);
  if (override == 'system') {
    return ui.PlatformDispatcher.instance.locale;
  }
  return Locale(override);
});
