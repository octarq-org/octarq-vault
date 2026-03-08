import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/auth_provider.dart';
import '../views/splash_screen.dart';
import '../views/setup_screen.dart';
import '../views/lock_screen.dart';
import '../views/dashboard_screen.dart';
import '../views/asset_form_screen.dart';
import '../views/asset_detail_screen.dart';
import '../views/settings_screen.dart';
import '../views/webdav_settings_screen.dart';
import '../views/asset_type_manager_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);

  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      final isSplash = state.matchedLocation == '/splash';
      final isSetup = state.matchedLocation == '/setup';
      final isLock = state.matchedLocation == '/lock';

      switch (authState) {
        case AuthState.initializing:
          return isSplash ? null : '/splash';
        case AuthState.unsetup:
          return isSetup ? null : '/setup';
        case AuthState.locked:
          return isLock ? null : '/lock';
        case AuthState.unlocked:
          if (isSplash || isSetup || isLock) return '/';
          return null;
      }
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/setup',
        builder: (context, state) => const SetupScreen(),
      ),
      GoRoute(
        path: '/lock',
        builder: (context, state) => const LockScreen(),
      ),
      GoRoute(
        path: '/',
        builder: (context, state) => const DashboardScreen(),
        routes: [
          GoRoute(
            path: 'add-asset',
            builder: (context, state) => const AssetFormScreen(),
          ),
          GoRoute(
            path: 'asset/:id',
            builder: (context, state) {
              final id = state.pathParameters['id']!;
              return AssetDetailScreen(assetId: id);
            },
          ),
          GoRoute(
            path: 'settings',
            builder: (context, state) => const SettingsScreen(),
            routes: [
              GoRoute(
                path: 'webdav',
                builder: (context, state) => const WebDavSettingsScreen(),
              ),
              GoRoute(
                path: 'asset-types',
                builder: (context, state) => const AssetTypeManagerScreen(),
              ),
              GoRoute(
                path: 'asset-types/add',
                builder: (context, state) => const AssetTypeFormScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
});
