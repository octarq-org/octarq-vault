# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**OctarqVault** is a cross-platform, offline-first, E2EE personal asset manager built with Flutter. SQLCipher (AES-256) + Argon2id key derivation.

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

### Auth — `lib/providers/auth_provider.dart`

State machine: `initializing → unsetup → locked → unlocked`. A verification blob (`OCTARQ_VAULT_VERIFY_V1` AES-encrypted) is stored in secure storage to detect wrong passwords before opening SQLCipher. `AssetsNotifier` listens to `authProvider` and auto-loads/clears state on transitions.

### Key providers (`lib/providers/`)

- `auth_provider` — auth lifecycle
- `assets_provider` — asset CRUD + sync orchestration; on **web**, no SQLite: reads/writes an encrypted `VaultSnapshot` blob via `WebVaultStorage` (IndexedDB)
- `asset_types_provider`, `relations_provider` / `relation_providers` — types and asset-to-asset relations
- `sync_conflicts_provider` — surfaces `AssetConflict` pairs for UI resolution
- `auto_lock_provider` — inactivity timer
- `service_providers` — singleton service instances

### Key services (`lib/services/`)

- `database_service.dart` — SQLCipher DB schema v4; tables: `assets`, `asset_fields`, `tags`, `asset_tags`, `reminders`, `asset_types`, `asset_relations`, `op_log`, `asset_attachments`
- `e2ee_sync_service.dart` — `VaultSnapshot` pack/unpack, LWW merge by `updatedAt`, conflict detection
- `attachment_service.dart` — encrypted blobs on disk (`<ApplicationSupport>/octarq_attachments/<uuid>.enc`); metadata only in DB; conditional import (native only)
- `encryption_service.dart` — AES-256-GCM + Argon2id
- `secure_storage_service.dart` — Keychain/Keystore for key, salt, verify blob
- `google_drive_service.dart`, `webdav_service.dart`, `icloud_sync_service.dart` — sync backends

### Sync: AVV3 + Delta

Wire format: `[magic(4)] [salt_len(2)] [salt] [type(1)=0x00 full|0x01 delta] [IV(12)] [Ciphertext+MAC]`

`VaultSnapshot` has `payloadType` (`'full'`/`'delta'`), `baseSeq`, `opLog`, `attachmentManifest`. Delta payloads carry only oplog entries since `baseSeq`. Soft deletes use `TombstoneRegistry` (LWW: `deletedAt > updatedAt` wins; pruned after 30 days).

### Platform Divergence

Conditional imports resolve `_io` / `_web` / `_stub` variants for: `attachment_service`, `icloud_sync_service`, `local_file_sync_service`, `platform_utils`, `web_vault_storage`, `google_sign_in_button`.

### i18n

`lib/l10n/` — English, Simplified Chinese, Spanish. Add new strings to all ARB files; `flutter pub get` regenerates `app_localizations*.dart`.
