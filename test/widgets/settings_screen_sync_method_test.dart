import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:octarq_vault/l10n/app_localizations.dart';
import 'package:octarq_vault/models/sync_settings.dart';
import 'package:octarq_vault/providers/auto_lock_provider.dart';
import 'package:octarq_vault/providers/locale_preference_provider.dart';
import 'package:octarq_vault/providers/service_providers.dart';
import 'package:octarq_vault/providers/sync_conflicts_provider.dart';
import 'package:octarq_vault/providers/sync_settings_provider.dart';
import 'package:octarq_vault/services/e2ee_sync_service.dart';
import 'package:octarq_vault/services/icloud_sync_service.dart';
import 'package:octarq_vault/views/settings_screen.dart';

class _FakeAutoLockNotifier extends AutoLockNotifier {
  @override
  int build() => 5;
}

class _FakeLocaleNotifier extends LocalePreferenceNotifier {
  @override
  String build() => 'en';
}

class _FakeSyncSettingsNotifier extends SyncSettingsNotifier {
  @override
  List<SyncMethod> build() => const [];
}

class _FakeLastSyncAtNotifier extends LastSyncAtNotifier {
  @override
  Future<DateTime?> build() async => null;
}

class _FakePendingConflictsNotifier extends PendingSyncConflictsNotifier {
  @override
  List<AssetConflict> build() => [];
}

class _UnsupportedICloudSyncService extends ICloudSyncService {
  @override
  bool get isSupported => false;

  @override
  Future<bool> get isAvailable async => false;
}

Widget _wrap(List<Override> overrides) {
  return ProviderScope(
    overrides: overrides,
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
      home: const SettingsScreen(),
    ),
  );
}

List<Override> _baseOverrides() => [
  autoLockMinutesProvider.overrideWith(() => _FakeAutoLockNotifier()),
  localePreferenceProvider.overrideWith(() => _FakeLocaleNotifier()),
  syncSettingsProvider.overrideWith(() => _FakeSyncSettingsNotifier()),
  lastSyncAtProvider.overrideWith(() => _FakeLastSyncAtNotifier()),
  pendingSyncConflictsProvider.overrideWith(
    () => _FakePendingConflictsNotifier(),
  ),
  iCloudSyncServiceProvider.overrideWithValue(_UnsupportedICloudSyncService()),
];

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('sync method picker hides iCloud option', (tester) async {
    await tester.pumpWidget(_wrap(_baseOverrides()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Sync method'));
    await tester.pumpAndSettle();

    final tileFinder = find.widgetWithText(CheckboxListTile, 'iCloud Backup');
    expect(tileFinder, findsNothing);
  });
}
