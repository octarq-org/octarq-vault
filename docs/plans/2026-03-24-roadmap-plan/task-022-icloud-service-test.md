# Task 022 — iCloud Drive Service: Test

**type:** test
**depends-on:** ["021"]

## BDD Scenarios Covered

```gherkin
Scenario: First-time backup to iCloud Drive
  Given no vault file exists in the iCloud ubiquity container
  When I make any change to an asset
  And automatic sync triggers
  Then the encrypted AVV3 snapshot is written to the iCloud Drive ubiquity container
  And the file appears in Files.app under "OctarqVault"

Scenario: Restore from iCloud Drive on new device
  Given a vault snapshot exists in the iCloud Drive ubiquity container
  When I install OctarqVault on a new device and tap "Restore from iCloud"
  Then the app downloads the snapshot from the ubiquity container
  And prompts for the master password
  And decrypts and imports all assets on successful authentication

Scenario: Conflict between local and iCloud versions
  Given device A and device B both have the vault open
  When device A modifies asset "My VPS" at timestamp T1
  And device B modifies the same asset at timestamp T2 > T1
  And both devices sync
  Then the LWW merge selects device B's version (newer updatedAt)
  And no data loss occurs

Scenario: iCloud Drive unavailable (no internet or iCloud disabled)
  Given the user's iCloud account is not signed in
  When iCloud Drive sync is selected in Settings
  Then an informational message explains that iCloud Drive requires an Apple ID
  And the sync setting falls back gracefully without crashing
```

## Goal

Write unit tests for the rewritten `icloud_sync_service_io.dart` using a mock `ICloudStorage` interface. Tests must run on macOS (can use the `check-macos` CI job).

## Test File to Create

- `test/services/icloud_sync_service_test.dart`

## Test Cases

1. **backup() calls ICloudStorage.upload()** — mock `ICloudStorage.upload()`. Call `backup(encryptedBytes)`. Verify `upload` was called with filename `"octarq_vault.enc"` and the correct bytes.

2. **restore() calls ICloudStorage.download()** — mock `ICloudStorage.download()` returning bytes. Call `restore()`. Verify the returned bytes match.

3. **restore() returns null when no file in container** — mock `ICloudStorage.download()` throwing "file not found". Verify `restore()` returns `null`.

4. **hasBackup() returns false when container empty** — mock `ICloudStorage.gather()` returning empty list. Verify `hasBackup()` returns `false`.

5. **iCloud unavailable returns false from isSupported** — when `ICloudStorage` constructor or `gather()` throws (e.g., entitlement not configured), `ICloudSyncService.isSupported` returns `false` without crashing.

6. **backupAttachment() calls upload with correct path** — mock `ICloudStorage.upload()`. Call `backupAttachment(attachment, encBytes)`. Verify upload called with filename matching `attachment.encFileName`.

## Verification

```bash
flutter test test/services/icloud_sync_service_test.dart
```

Expected: all tests fail (Red phase — service not yet rewritten with `ICloudStorage`).
