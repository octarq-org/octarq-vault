import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'router/app_router.dart';

void main() {
  runApp(const ProviderScope(child: AssetVaultApp()));
}

class AssetVaultApp extends ConsumerWidget {
  const AssetVaultApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return Shortcuts(
      shortcuts: <LogicalKeySet, Intent>{
        LogicalKeySet(Platform.isMacOS ? LogicalKeyboardKey.meta : LogicalKeyboardKey.control, LogicalKeyboardKey.keyN): const AddAssetIntent(),
      },
      child: Actions(
        actions: <Type, Action<Intent>>{
          AddAssetIntent: CallbackAction<AddAssetIntent>(
            onInvoke: (AddAssetIntent intent) {
              router.go('/add-asset');
              return null;
            },
          ),
        },
        child: MaterialApp.router(
          title: 'AssetVault',
          debugShowCheckedModeBanner: false,
          themeMode: ThemeMode.dark,
          darkTheme: ThemeData.dark().copyWith(
            colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.deepPurple,
              brightness: Brightness.dark,
            ),
            appBarTheme: const AppBarTheme(
              centerTitle: true,
              elevation: 0,
            ),
            cardTheme: CardThemeData(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            inputDecorationTheme: InputDecorationTheme(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              filled: true,
            ),
          ),
          routerConfig: router,
        ),
      ),
    );
  }
}

class AddAssetIntent extends Intent {
  const AddAssetIntent();
  static const String id = 'AddAssetIntent';
}
