import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:octarq_vault/l10n/app_localizations.dart';
import 'package:octarq_vault/models/sync_settings.dart';
import 'package:octarq_vault/providers/auto_lock_provider.dart';
import 'package:octarq_vault/providers/change_password_provider.dart';
import 'package:octarq_vault/providers/locale_preference_provider.dart';
import 'package:octarq_vault/providers/sync_conflicts_provider.dart';
import 'package:octarq_vault/providers/sync_settings_provider.dart';
import 'package:octarq_vault/views/settings_screen.dart';
import 'package:octarq_vault/services/e2ee_sync_service.dart';

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

class _IdleChangePasswordNotifier extends ChangePasswordNotifier {
  @override
  ChangePasswordState build() => const ChangePasswordState();
}

class _LoadingChangePasswordNotifier extends ChangePasswordNotifier {
  @override
  ChangePasswordState build() => const ChangePasswordState(isLoading: true);
}

class _SuccessChangePasswordNotifier extends ChangePasswordNotifier {
  @override
  ChangePasswordState build() => const ChangePasswordState();

  @override
  Future<void> changePassword(String current, String newPwd) async {
    state = const ChangePasswordState(isSuccess: true);
  }
}

class _ErrorChangePasswordNotifier extends ChangePasswordNotifier {
  @override
  ChangePasswordState build() => const ChangePasswordState();

  @override
  Future<void> changePassword(String current, String newPwd) async {
    state = const ChangePasswordState(errorMessage: 'boom');
  }
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
];

Future<void> _openDialog(WidgetTester tester) async {
  await tester.tap(find.text('Change Master Password'));
  await tester.pump();
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('Settings shows Change Master Password tile', (tester) async {
    await tester.pumpWidget(
      _wrap([
        ..._baseOverrides(),
        changePasswordProvider.overrideWith(
          () => _IdleChangePasswordNotifier(),
        ),
      ]),
    );
    await tester.pumpAndSettle();

    expect(find.text('Change Master Password'), findsOneWidget);
  });

  testWidgets('Tapping tile opens dialog with three fields', (tester) async {
    await tester.pumpWidget(
      _wrap([
        ..._baseOverrides(),
        changePasswordProvider.overrideWith(
          () => _IdleChangePasswordNotifier(),
        ),
      ]),
    );
    await tester.pumpAndSettle();

    await _openDialog(tester);

    expect(find.text('Current Password'), findsOneWidget);
    expect(find.text('New Password'), findsOneWidget);
    expect(find.text('Confirm New Password'), findsOneWidget);
  });

  testWidgets('Weak new password disables submit and shows weak indicator', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap([
        ..._baseOverrides(),
        changePasswordProvider.overrideWith(
          () => _IdleChangePasswordNotifier(),
        ),
      ]),
    );
    await tester.pumpAndSettle();
    await _openDialog(tester);

    await tester.enterText(find.byType(TextField).at(0), 'OldPass123!');
    await tester.enterText(find.byType(TextField).at(1), 'abc');
    await tester.enterText(find.byType(TextField).at(2), 'abc');
    await tester.pumpAndSettle();

    expect(find.text('Too weak'), findsOneWidget);
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNull,
    );
  });

  testWidgets('Password mismatch disables submit and shows inline error', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap([
        ..._baseOverrides(),
        changePasswordProvider.overrideWith(
          () => _IdleChangePasswordNotifier(),
        ),
      ]),
    );
    await tester.pumpAndSettle();
    await _openDialog(tester);

    await tester.enterText(find.byType(TextField).at(0), 'OldPass123!');
    await tester.enterText(find.byType(TextField).at(1), 'NewPass123456!');
    await tester.enterText(find.byType(TextField).at(2), 'WrongConfirm!');
    await tester.pumpAndSettle();

    expect(find.text('Passwords do not match'), findsOneWidget);
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNull,
    );
  });

  testWidgets('Valid inputs enable submit button', (tester) async {
    await tester.pumpWidget(
      _wrap([
        ..._baseOverrides(),
        changePasswordProvider.overrideWith(
          () => _IdleChangePasswordNotifier(),
        ),
      ]),
    );
    await tester.pumpAndSettle();
    await _openDialog(tester);

    await tester.enterText(find.byType(TextField).at(0), 'OldPass123!');
    await tester.enterText(find.byType(TextField).at(1), 'NewPass123456!');
    await tester.enterText(find.byType(TextField).at(2), 'NewPass123456!');
    await tester.pumpAndSettle();

    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNotNull,
    );
  });

  testWidgets('Loading state shows spinner and disables submit', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap([
        ..._baseOverrides(),
        changePasswordProvider.overrideWith(
          () => _LoadingChangePasswordNotifier(),
        ),
      ]),
    );
    await tester.pumpAndSettle();
    await _openDialog(tester);

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNull,
    );
  });

  testWidgets('Success closes dialog and shows success snackbar', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap([
        ..._baseOverrides(),
        changePasswordProvider.overrideWith(
          () => _SuccessChangePasswordNotifier(),
        ),
      ]),
    );
    await tester.pumpAndSettle();
    await _openDialog(tester);

    await tester.enterText(find.byType(TextField).at(0), 'OldPass123!');
    await tester.enterText(find.byType(TextField).at(1), 'NewPass123456!');
    await tester.enterText(find.byType(TextField).at(2), 'NewPass123456!');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Change Password'));
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsNothing);
    expect(find.text('Password changed successfully'), findsOneWidget);
  });

  testWidgets('Error keeps dialog open and renders message', (tester) async {
    await tester.pumpWidget(
      _wrap([
        ..._baseOverrides(),
        changePasswordProvider.overrideWith(
          () => _ErrorChangePasswordNotifier(),
        ),
      ]),
    );
    await tester.pumpAndSettle();
    await _openDialog(tester);

    await tester.enterText(find.byType(TextField).at(0), 'OldPass123!');
    await tester.enterText(find.byType(TextField).at(1), 'NewPass123456!');
    await tester.enterText(find.byType(TextField).at(2), 'NewPass123456!');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Change Password'));
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsOneWidget);
    expect(find.text('boom'), findsOneWidget);
  });
}
