import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dargon2_flutter/dargon2_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'l10n/app_localizations.dart';
import 'providers/locale_provider.dart';
import 'router/app_router.dart';
import 'providers/auto_lock_provider.dart';
import 'providers/auth_provider.dart';
import 'utils/auto_lock.dart';
import 'utils/web_visibility_listener.dart';

// ─── Design Tokens ──────────────────────────────────────────────────────────
const kPrimaryGreen = Color(0xFF00C896);
const kBgColor = Color(0xFF14161F); // deepest bg
const kSurfaceColor = Color(0xFF1E2130); // card / sidebar
const kBorderColor = Color(0xFF2B2E3E); // subtle divider
const kTextMuted = Color(0xFF7B8099);

/// Official site (landing) and docs. Used in Settings and README.
const kWebsiteUrl = 'https://vault.octarq.org';
const kDocsUrl = 'https://vault.octarq.org/docs';
// ─────────────────────────────────────────────────────────────────────────────

Future<void> main() async {
  DArgon2Flutter.init();
  if (kIsWeb) {
    const clientId = String.fromEnvironment(
      'GOOGLE_CLIENT_ID',
      defaultValue: 'YOUR_WEB_CLIENT_ID.apps.googleusercontent.com',
    );
    if (clientId.isNotEmpty && !clientId.startsWith('YOUR_')) {
      await GoogleSignIn.instance.initialize(clientId: clientId);
    }
  }
  runApp(const ProviderScope(child: OctarqVaultApp()));
}

class OctarqVaultApp extends ConsumerStatefulWidget {
  const OctarqVaultApp({super.key});

  @override
  ConsumerState<OctarqVaultApp> createState() => _OctarqVaultAppState();
}

class _OctarqVaultAppState extends ConsumerState<OctarqVaultApp>
    with WidgetsBindingObserver {
  DateTime? _pausedAt;

  void _maybeLockAfterBackgroundInterval() {
    if (_pausedAt == null) return;
    final paused = _pausedAt!;
    _pausedAt = null;
    if (!mounted) return;
    if (ref.read(authProvider) != AuthState.unlocked) return;
    final waitMinutes = ref.read(autoLockMinutesProvider);
    if (shouldLockAfterBackground(
      pausedAt: paused,
      now: DateTime.now(),
      limitMinutes: waitMinutes,
    )) {
      ref.read(authProvider.notifier).lock();
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (kIsWeb) {
      listenWebDocumentVisibility(
        onBecameHidden: () {
          _pausedAt = DateTime.now();
        },
        onBecameVisible: _maybeLockAfterBackgroundInterval,
      );
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _pausedAt = DateTime.now();
    } else if (state == AppLifecycleState.resumed) {
      _maybeLockAfterBackgroundInterval();
    }
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);

    final modKey = defaultTargetPlatform == TargetPlatform.macOS
        ? LogicalKeyboardKey.meta
        : LogicalKeyboardKey.control;

    return Shortcuts(
      shortcuts: <LogicalKeySet, Intent>{
        LogicalKeySet(modKey, LogicalKeyboardKey.keyN): const AddAssetIntent(),
        LogicalKeySet(modKey, LogicalKeyboardKey.comma):
            const OpenSettingsIntent(),
        LogicalKeySet(modKey, LogicalKeyboardKey.keyF):
            const FocusSearchIntent(),
        LogicalKeySet(modKey, LogicalKeyboardKey.keyL): const LockVaultIntent(),
      },
      child: Actions(
        actions: <Type, Action<Intent>>{
          AddAssetIntent: CallbackAction<AddAssetIntent>(
            onInvoke: (intent) {
              router.go('/add-asset');
              return null;
            },
          ),
          OpenSettingsIntent: CallbackAction<OpenSettingsIntent>(
            onInvoke: (intent) {
              router.go('/settings');
              return null;
            },
          ),
          FocusSearchIntent: CallbackAction<FocusSearchIntent>(
            onInvoke: (intent) {
              router.go('/all-assets');
              return null;
            },
          ),
          LockVaultIntent: CallbackAction<LockVaultIntent>(
            onInvoke: (intent) {
              router.go('/lock');
              return null;
            },
          ),
        },
        child: MaterialApp.router(
          title: 'OctarqVault', // app name, keep for system
          debugShowCheckedModeBanner: false,
          themeMode: ThemeMode.dark,
          darkTheme: _buildDarkTheme(),
          routerConfig: router,
          locale: ref.watch(localeProvider),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
        ),
      ),
    );
  }
}

ThemeData _buildDarkTheme() {
  final base = ThemeData.dark(useMaterial3: true);
  final textTheme = GoogleFonts.interTextTheme(
    base.textTheme,
  ).apply(bodyColor: Colors.white, displayColor: Colors.white);

  return base.copyWith(
    textTheme: textTheme,
    scaffoldBackgroundColor: kBgColor,
    colorScheme: const ColorScheme.dark(
      primary: kPrimaryGreen,
      secondary: kPrimaryGreen,
      surface: kSurfaceColor,
      onPrimary: Colors.black,
      onSurface: Colors.white,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: kBgColor,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: GoogleFonts.inter(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: Colors.white,
      ),
      iconTheme: const IconThemeData(color: Colors.white),
    ),
    cardTheme: CardThemeData(
      color: kSurfaceColor,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: kBorderColor),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: kSurfaceColor,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: kBorderColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: kBorderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: kPrimaryGreen, width: 1.5),
      ),
      labelStyle: const TextStyle(color: kTextMuted),
      hintStyle: const TextStyle(color: kTextMuted),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    ),
    dividerColor: kBorderColor,
    dividerTheme: const DividerThemeData(color: kBorderColor, thickness: 1),
    chipTheme: ChipThemeData(
      backgroundColor: kSurfaceColor,
      side: const BorderSide(color: kBorderColor),
      labelStyle: const TextStyle(fontSize: 12, color: Colors.white),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: kPrimaryGreen,
        foregroundColor: Colors.black,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        textStyle: GoogleFonts.inter(fontWeight: FontWeight.w600),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: kPrimaryGreen),
    ),
    listTileTheme: const ListTileThemeData(
      textColor: Colors.white,
      iconColor: kTextMuted,
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: kPrimaryGreen,
      foregroundColor: Colors.black,
    ),
    dropdownMenuTheme: DropdownMenuThemeData(
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: kSurfaceColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: kBorderColor),
        ),
      ),
    ),
  );
}

class AddAssetIntent extends Intent {
  const AddAssetIntent();
  static const String id = 'AddAssetIntent';
}

class OpenSettingsIntent extends Intent {
  const OpenSettingsIntent();
}

class FocusSearchIntent extends Intent {
  const FocusSearchIntent();
}

class LockVaultIntent extends Intent {
  const LockVaultIntent();
}
