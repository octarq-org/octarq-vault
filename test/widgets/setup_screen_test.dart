import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:asset_vault/l10n/app_localizations.dart';
import 'package:asset_vault/providers/auth_provider.dart';
import 'package:asset_vault/views/setup_screen.dart';

Widget wrapSetupScreen(Widget child) {
  return MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    locale: const Locale('en'),
    home: child,
  );
}

// A simple test wrapper that provides a mock auth state
class MockAuthNotifier extends AuthNotifier {
  final bool Function(String)? _onSetup;

  MockAuthNotifier({bool Function(String)? onSetup}) : _onSetup = onSetup;

  @override
  AuthState build() {
    return AuthState.unsetup;
  }

  @override
  Future<bool> setupMasterPassword(String password) async {
    if (_onSetup != null) {
      final result = _onSetup(password);
      if (result) {
        state = AuthState.unlocked;
      }
      return result;
    }
    state = AuthState.unlocked;
    return true;
  }
}

void main() {
  group('SetupScreen', () {
    testWidgets('renders setup UI elements', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [authProvider.overrideWith(() => MockAuthNotifier())],
          child: wrapSetupScreen(const SetupScreen()),
        ),
      );

      expect(find.text('Set your Master Password'), findsOneWidget);
      expect(find.text('Master Password'), findsOneWidget);
      expect(find.text('Confirm Password'), findsOneWidget);
      expect(find.text('Create Vault'), findsOneWidget);
    });

    testWidgets('shows error for short password', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [authProvider.overrideWith(() => MockAuthNotifier())],
          child: wrapSetupScreen(const SetupScreen()),
        ),
      );

      // Enter a short password
      await tester.enterText(
        find.widgetWithText(TextField, 'Master Password'),
        'short',
      );
      await tester.enterText(
        find.widgetWithText(TextField, 'Confirm Password'),
        'short',
      );
      await tester.tap(find.text('Create Vault'));
      await tester.pump();

      expect(find.text('Password too short (8 chars min)'), findsOneWidget);
    });

    testWidgets('shows error for mismatched passwords', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [authProvider.overrideWith(() => MockAuthNotifier())],
          child: wrapSetupScreen(const SetupScreen()),
        ),
      );

      await tester.enterText(
        find.widgetWithText(TextField, 'Master Password'),
        'password123',
      );
      await tester.enterText(
        find.widgetWithText(TextField, 'Confirm Password'),
        'different12',
      );
      await tester.tap(find.text('Create Vault'));
      await tester.pump();

      expect(find.text('Passwords do not match'), findsOneWidget);
    });

    testWidgets('submits valid password', (tester) async {
      String? capturedPassword;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authProvider.overrideWith(
              () => MockAuthNotifier(
                onSetup: (pwd) {
                  capturedPassword = pwd;
                  return true;
                },
              ),
            ),
          ],
          child: wrapSetupScreen(const SetupScreen()),
        ),
      );

      await tester.enterText(
        find.widgetWithText(TextField, 'Master Password'),
        'securepassword123',
      );
      await tester.enterText(
        find.widgetWithText(TextField, 'Confirm Password'),
        'securepassword123',
      );
      await tester.tap(find.text('Create Vault'));
      await tester.pumpAndSettle();

      expect(capturedPassword, equals('securepassword123'));
    });
  });
}
