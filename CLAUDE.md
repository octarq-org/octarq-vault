# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**OctarqVault** is a cross-platform, offline-first, end-to-end encrypted personal asset manager built with Flutter. It stores credentials, crypto wallets, certificates, and other sensitive assets using SQLCipher (AES-256) with Argon2id key derivation.

## Commands

```bash
# Install dependencies
flutter pub get

# Code generation (run after modifying models with @freezed/@JsonSerializable)
dart run build_runner build --delete-conflicting-outputs

# Format, lint, test
dart format --set-exit-if-changed .
flutter analyze
flutter test

# Run a single test file
flutter test test/path/to/test_file.dart

# Run on simulator/device
flutter run -d ios
flutter run -d android

# Release builds
flutter build macos
flutter build web
```

## Code Generation

Models in `lib/models/` use `freezed` and `json_serializable`. After editing any model annotated with `@freezed` or `@JsonSerializable`, always run:

```bash
dart run build_runner build --delete-conflicting-outputs
```

Generated files (`*.freezed.dart`, `*.g.dart`) are committed to the repo.

## Architecture

### State Management — Riverpod

All state lives in `lib/providers/`. Key providers:
- `auth_provider` — auth lifecycle: `unsetup → locked → unlocked`
- `assets_provider` — asset CRUD backed by `DatabaseService`
- `service_providers` — singleton instances of all services (DB, crypto, sync, notifications)

### Routing — go_router

`lib/router/app_router.dart` defines all routes. Auth state drives redirects:
- Unsetup → `/setup`
- Locked → `/lock`
- Unlocked → `/` (dashboard)

### Services (`lib/services/`)

| Service | Responsibility |
|---|---|
| `database_service.dart` | SQLCipher DB, all CRUD |
| `encryption_service.dart` | AES-256-GCM field-level encryption |
| `secure_storage_service.dart` | Keychain/Keystore for derived key |
| `e2ee_sync_service.dart` | Orchestrates E2EE sync across backends |
| `google_drive_service.dart` / `icloud_sync_service.dart` | Cloud sync backends |
| `notification_service.dart` | Local notifications for asset expiry |

### Models (`lib/models/`)

Core models are immutable (freezed):
- `Asset` — central entity with typed `fields`, `tags`, `reminders`
- `AssetType` — template defining field schema for an asset category
- `Field` — typed key-value with optional encryption flag

### Platform Divergence

Some files have platform-specific variants (e.g., `local_file_sync_io.dart` vs `local_file_sync_web.dart`, `google_sign_in_button_web.dart` vs `google_sign_in_button_stub.dart`). These are resolved via conditional imports.

### i18n

Translations are in `lib/l10n/` (English + Simplified Chinese). Running `flutter gen-l10n` (or `flutter pub get`) regenerates `lib/l10n/app_localizations*.dart`. Add new strings to both ARB files before using them.
