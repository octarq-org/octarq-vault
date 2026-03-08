import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/auth_provider.dart';
import '../views/splash_screen.dart';
import '../views/setup_screen.dart';
import '../views/lock_screen.dart';
import '../views/dashboard_screen.dart';

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
      ),
    ],
  );
});
