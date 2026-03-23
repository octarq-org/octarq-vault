# Task 009 — Attachment Sync Push: Implementation

**type:** impl
**depends-on:** ["008"]

## BDD Scenarios Covered

Same as task-008 (Green phase).

## Goal

Inject the attachment blob upload loop into `AssetsNotifier`'s sync push path so tests from task-008 pass.

## Files to Modify

- `lib/providers/assets_provider.dart`
  - In the Google Drive push branch (after `driveService.syncToDrive(...)` succeeds), add a best-effort loop:
    - Get `allAttachments` from `db.getAllAttachments()`
    - For each attachment: if `!attachSvc.attachmentExists(att)`, call `driveService.uploadAttachment(att, encBytes)` wrapped in try/catch that logs and continues
  - In the WebDAV push branch (after `webDav.backup(...)` succeeds), same loop calling `webDav.uploadAttachment(att, encBytes)`
  - iCloud branch: no upload call (iCloud Drive is P2 — passive backup handles blobs via `backupAttachment` in `icloud_sync_service_io.dart`)
  - Import `attachmentServiceProvider` from `attachments_provider.dart`

## Verification

```bash
flutter test test/providers/assets_provider_test.dart --name "attachment sync push"
flutter test test/providers/assets_provider_test.dart
flutter analyze
```

Expected: all push tests from task-008 pass; no regressions in other provider tests.
