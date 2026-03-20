import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:asset_vault/providers/locale_preference_provider.dart';

Future<void> _flushMicrotasks() async {
  for (int i = 0; i < 10; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('LocalePreferenceNotifier', () {
    test('loads persisted locale override from SharedPreferences', () async {
      SharedPreferences.setMockInitialValues({'locale_override': 'en'});

      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(localePreferenceProvider);
      await _flushMicrotasks();

      expect(container.read(localePreferenceProvider), equals('en'));
      expect(container.read(localeProvider).languageCode, equals('en'));
    });

    test('defaults to system when no preference is stored', () async {
      SharedPreferences.setMockInitialValues({});

      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(localePreferenceProvider);
      await _flushMicrotasks();

      expect(container.read(localePreferenceProvider), equals('system'));
      expect(
        container.read(localeProvider),
        equals(ui.PlatformDispatcher.instance.locale),
      );
    });

    test(
      'setLocaleOverride persists valid values and updates localeProvider',
      () async {
        SharedPreferences.setMockInitialValues({});

        final container = ProviderContainer();
        addTearDown(container.dispose);

        final notifier = container.read(localePreferenceProvider.notifier);
        await notifier.setLocaleOverride('zh');

        expect(container.read(localePreferenceProvider), equals('zh'));
        expect(container.read(localeProvider).languageCode, equals('zh'));

        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getString('locale_override'), equals('zh'));
      },
    );

    test('setLocaleOverride ignores invalid values', () async {
      SharedPreferences.setMockInitialValues({'locale_override': 'es'});

      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(localePreferenceProvider);
      await _flushMicrotasks();

      final notifier = container.read(localePreferenceProvider.notifier);
      await notifier.setLocaleOverride('de');

      expect(container.read(localePreferenceProvider), equals('es'));
      expect(container.read(localeProvider).languageCode, equals('es'));

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('locale_override'), equals('es'));
    });
  });
}
