import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:octarq_vault/models/sync_settings.dart';
import 'package:octarq_vault/providers/sync_settings_provider.dart';

Future<void> _flushMicrotasks() async {
  for (int i = 0; i < 10; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SyncSettingsNotifier', () {
    test('loads persisted sync methods and filters invalid values', () async {
      SharedPreferences.setMockInitialValues({
        'sync_methods': jsonEncode([
          'webdav',
          'invalid-method',
          'googleDrive',
          'webdav',
        ]),
      });

      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(syncSettingsProvider);
      await _flushMicrotasks();

      expect(
        container.read(syncSettingsProvider),
        unorderedEquals([SyncMethod.webdav, SyncMethod.googleDrive]),
      );
    });

    test(
      'falls back to legacy sync_method when sync_methods is malformed',
      () async {
        SharedPreferences.setMockInitialValues({
          'sync_methods': '{bad json',
          'sync_method': 'localFile',
        });

        final container = ProviderContainer();
        addTearDown(container.dispose);

        container.read(syncSettingsProvider);
        await _flushMicrotasks();

        expect(
          container.read(syncSettingsProvider),
          equals([SyncMethod.localFile]),
        );
      },
    );

    test('toggleSyncMethod ignores none and persists add/remove', () async {
      SharedPreferences.setMockInitialValues({});

      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(syncSettingsProvider.notifier);

      await notifier.toggleSyncMethod(SyncMethod.none);
      expect(container.read(syncSettingsProvider), isEmpty);

      await notifier.toggleSyncMethod(SyncMethod.webdav);
      expect(container.read(syncSettingsProvider), equals([SyncMethod.webdav]));

      await notifier.toggleSyncMethod(SyncMethod.webdav);
      expect(container.read(syncSettingsProvider), isEmpty);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('sync_methods'), equals(jsonEncode(<String>[])));
    });

    test(
      'setSyncMethods and importSettings both remove none and invalid values',
      () async {
        SharedPreferences.setMockInitialValues({});

        final container = ProviderContainer();
        addTearDown(container.dispose);

        final notifier = container.read(syncSettingsProvider.notifier);

        await notifier.setSyncMethods([
          SyncMethod.none,
          SyncMethod.webdav,
          SyncMethod.googleDrive,
        ]);
        expect(
          container.read(syncSettingsProvider),
          equals([SyncMethod.webdav, SyncMethod.googleDrive]),
        );

        await notifier.importSettings(
          const SyncSettingsExport(
            syncMethods: ['none', 'icloud', 'unknown', 'icloud'],
          ),
        );
        expect(container.read(syncSettingsProvider), isEmpty);
      },
    );

    test(
      'exportSettings returns current methods with optional webdav url',
      () async {
        SharedPreferences.setMockInitialValues({});

        final container = ProviderContainer();
        addTearDown(container.dispose);

        final notifier = container.read(syncSettingsProvider.notifier);
        await notifier.setSyncMethods([
          SyncMethod.googleDrive,
          SyncMethod.webdav,
        ]);

        final exported = notifier.exportSettings(
          webdavUrl: 'https://dav.example.com/vault',
        );

        expect(exported.syncMethods, equals(['googleDrive', 'webdav']));
        expect(exported.webdavUrl, equals('https://dav.example.com/vault'));
      },
    );
  });

  group('LastSyncAtNotifier', () {
    test('build returns null when no persisted timestamp exists', () async {
      SharedPreferences.setMockInitialValues({});

      final container = ProviderContainer();
      addTearDown(container.dispose);

      final value = await container.read(lastSyncAtProvider.future);
      expect(value, isNull);
    });

    test('recordSync persists and exposes a timestamp', () async {
      SharedPreferences.setMockInitialValues({});

      final container = ProviderContainer();
      addTearDown(container.dispose);

      await container.read(lastSyncAtProvider.notifier).recordSync();

      final recorded = container.read(lastSyncAtProvider).value;
      expect(recorded, isNotNull);

      final prefs = await SharedPreferences.getInstance();
      final persistedMs = prefs.getInt('last_sync_at');
      expect(persistedMs, isNotNull);
      expect(recorded!.millisecondsSinceEpoch, equals(persistedMs));
    });
  });
}
