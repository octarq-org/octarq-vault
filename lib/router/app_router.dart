import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../l10n/app_localizations.dart';
import '../providers/auth_provider.dart';
import '../providers/assets_provider.dart';
import '../views/splash_screen.dart';
import '../views/setup_screen.dart';
import '../views/lock_screen.dart';
import '../views/main_layout_screen.dart';
import '../views/dashboard_screen.dart';
import '../views/asset_list_screen.dart';
import '../views/asset_form_screen.dart';
import '../views/asset_detail_screen.dart';
import '../views/settings_screen.dart';
import '../views/webdav_settings_screen.dart';
import '../views/sync_conflicts_screen.dart';
import '../views/asset_type_manager_screen.dart';
import '../views/tag_manager_screen.dart';

final rootNavigatorKey = GlobalKey<NavigatorState>();
final shellNavigatorKey = GlobalKey<NavigatorState>();

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);

  return GoRouter(
    navigatorKey: rootNavigatorKey,
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
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/setup',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const SetupScreen(),
      ),
      GoRoute(
        path: '/lock',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const LockScreen(),
      ),
      ShellRoute(
        navigatorKey: shellNavigatorKey,
        builder: (context, state, child) => MainLayoutScreen(child: child),
        routes: [
          GoRoute(
            path: '/',
            parentNavigatorKey: shellNavigatorKey,
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: DashboardScreen()),
          ),
          GoRoute(
            path: '/all-assets',
            parentNavigatorKey: shellNavigatorKey,
            pageBuilder: (context, state) {
              final filterExpiring =
                  state.uri.queryParameters['filter'] == 'expiring-soon';
              return NoTransitionPage(
                child: AssetListScreen(filterExpiringSoon: filterExpiring),
              );
            },
          ),
          GoRoute(
            path: '/category/:id',
            parentNavigatorKey: shellNavigatorKey,
            pageBuilder: (context, state) {
              final id = state.pathParameters['id']!;
              return NoTransitionPage(child: AssetListScreen(filterTypeId: id));
            },
          ),
          GoRoute(
            path: '/add-asset',
            parentNavigatorKey: shellNavigatorKey,
            pageBuilder: (context, state) {
              final typeId = state.uri.queryParameters['type'];
              return NoTransitionPage(
                child: AssetFormScreen(defaultTypeId: typeId),
              );
            },
          ),
          GoRoute(
            path: '/asset/:id',
            parentNavigatorKey: shellNavigatorKey,
            pageBuilder: (context, state) {
              final id = state.pathParameters['id']!;
              return NoTransitionPage(child: AssetDetailScreen(assetId: id));
            },
          ),
          GoRoute(
            path: '/edit-asset/:id',
            parentNavigatorKey: shellNavigatorKey,
            pageBuilder: (context, state) {
              final id = state.pathParameters['id']!;
              return NoTransitionPage(child: _EditAssetWrapper(assetId: id));
            },
          ),
          GoRoute(
            path: '/settings',
            parentNavigatorKey: shellNavigatorKey,
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: SettingsScreen()),
            routes: [
              GoRoute(
                path: 'webdav',
                parentNavigatorKey: shellNavigatorKey,
                pageBuilder: (context, state) =>
                    const NoTransitionPage(child: WebDavSettingsScreen()),
              ),
              GoRoute(
                path: 'asset-types',
                parentNavigatorKey: shellNavigatorKey,
                pageBuilder: (context, state) =>
                    const NoTransitionPage(child: AssetTypeManagerScreen()),
              ),
              GoRoute(
                path: 'asset-types/add',
                parentNavigatorKey: shellNavigatorKey,
                pageBuilder: (context, state) =>
                    const NoTransitionPage(child: AssetTypeFormScreen()),
              ),
              GoRoute(
                path: 'tags',
                parentNavigatorKey: shellNavigatorKey,
                pageBuilder: (context, state) =>
                    const NoTransitionPage(child: TagManagerScreen()),
              ),
              GoRoute(
                path: 'sync-conflicts',
                parentNavigatorKey: shellNavigatorKey,
                pageBuilder: (context, state) =>
                    const NoTransitionPage(child: SyncConflictsScreen()),
              ),
            ],
          ),
        ],
      ),
    ],
  );
});

class _EditAssetWrapper extends ConsumerWidget {
  final String assetId;
  const _EditAssetWrapper({required this.assetId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final assets = ref.watch(assetsProvider);
    final asset = assets.where((a) => a.id == assetId).firstOrNull;
    if (asset == null) {
      return Scaffold(
        body: Center(child: Text(AppLocalizations.of(context)!.assetNotFound)),
      );
    }
    return AssetFormScreen(editingAsset: asset);
  }
}
