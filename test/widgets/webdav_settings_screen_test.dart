import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:octarq_vault/l10n/app_localizations.dart';
import 'package:octarq_vault/services/e2ee_sync_service.dart';
import 'package:octarq_vault/services/encryption_service.dart';
import 'package:octarq_vault/services/google_drive_service.dart';
import 'package:octarq_vault/services/webdav_service.dart';
import 'package:octarq_vault/views/webdav_settings_screen.dart';

class _FakeWebDavService extends WebDavService {
  @override
  Future<bool> hasCredentials() async => false;
}

class _FakeGoogleDriveService extends GoogleDriveService {
  _FakeGoogleDriveService() : super(E2EESyncService(EncryptionService()));

  @override
  Future<bool> hasCredentials() async => false;
}

Widget _wrap(List<Override> overrides) {
  return ProviderScope(
    overrides: overrides,
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
      home: const WebDavSettingsScreen(),
    ),
  );
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets(
    'iCloud section uses iCloud restore copy',
    (tester) async {
      final overrides = <Override>[
        webDavServiceProvider.overrideWithValue(_FakeWebDavService()),
        googleDriveServiceProvider.overrideWithValue(_FakeGoogleDriveService()),
      ];

      await tester.pumpWidget(_wrap(overrides));
      await tester.pumpAndSettle();

      final restoreIcloud = find.widgetWithText(
        OutlinedButton,
        'Restore from iCloud',
      );
      await tester.scrollUntilVisible(
        restoreIcloud,
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();

      expect(restoreIcloud, findsOneWidget);
      expect(
        find.widgetWithText(OutlinedButton, 'Restore from WebDAV'),
        findsNothing,
      );
    },
    variant: const TargetPlatformVariant(<TargetPlatform>{TargetPlatform.iOS}),
  );
}
