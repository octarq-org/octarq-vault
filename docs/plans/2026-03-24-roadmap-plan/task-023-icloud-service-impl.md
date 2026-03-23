# Task 023 — iCloud Drive Service: Implementation

**type:** impl
**depends-on:** ["022"]

## BDD Scenarios Covered

Same as task-022 (Green phase).

## Goal

Rewrite `lib/services/icloud_sync_service_io.dart` to use the `icloud_storage` package's ubiquity container API instead of `getApplicationDocumentsDirectory()`. The public API surface (`backup`, `restore`, `hasBackup`, `backupAttachment`, `restoreAttachment`, `attachmentBackupExists`, `deleteAttachmentBackup`) must remain unchanged so callers in `AssetsNotifier` require no modifications.

## Files to Modify

- `lib/services/icloud_sync_service_io.dart` — rewrite internal file path resolution:

  Replace `_vaultFile()` which calls `getApplicationDocumentsDirectory()` with a function that:
  1. Calls `ICloudStorage.gather(containerId: 'iCloud.org.octarq.vault', ...)` to check availability
  2. Uses `ICloudStorage.upload()` for `backup()` and `ICloudStorage.download()` for `restore()`
  3. Maps `_attachmentsDir()` to the ubiquity container's `octarq_attachments/` subdirectory
  4. Adds an `isSupported` getter that tries `ICloudStorage` initialization and returns `false` on any exception (entitlement missing, iCloud not signed in)

- The `ICloudSyncService` wrapper class in `lib/services/icloud_sync_service.dart` should expose `isSupported` so `AssetsNotifier` can skip iCloud sync gracefully when unavailable.

- `lib/services/icloud_sync_service_stub.dart` — no changes needed (web/non-iOS stub remains as-is).

## Verification

```bash
flutter test test/services/icloud_sync_service_test.dart
flutter analyze
flutter build ios --no-codesign
```

Expected: all tests from task-022 pass (Green phase). iOS build must succeed without entitlement errors.
