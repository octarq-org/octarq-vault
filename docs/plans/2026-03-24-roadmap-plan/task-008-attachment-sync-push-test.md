# Task 008 — Attachment Sync Push: Test

**type:** test
**depends-on:** ["003"]

## BDD Scenarios Covered

```gherkin
Scenario: Attachment blob syncs to Google Drive after push
  Given asset "My VPS" has attachment "server_key.pem" that has not been uploaded
  And Google Drive sync is configured
  When I trigger a sync push
  Then the encrypted blob bytes are uploaded to Google Drive under "octarq_attachments/"
  And the attachment is marked as synced

Scenario: Partial attachment sync does not block vault sync
  Given one attachment blob fails to upload due to network error
  When a sync push is triggered
  Then the vault snapshot (assets, relations, types) is uploaded successfully
  And the failed attachment is silently skipped (logged in debug mode only)
  And the sync status shown to the user reflects success
  And the sync is not marked as failed
```

## Goal

Write unit tests for the attachment blob upload loop in `AssetsNotifier` (the sync push path).

## Test File to Modify

- `test/providers/assets_provider_test.dart` — add new test group `"attachment sync push"`

## Test Cases

1. **Uploads missing blob on push** — mock `AttachmentService.attachmentExists()` returning `false`, mock `AttachmentService.loadEncryptedBytes()` returning dummy bytes, mock `GoogleDriveService.uploadAttachment()`. After `assetsProvider.notifier.pushSync()`, verify `uploadAttachment` was called once with the correct `AssetAttachment` and bytes.

2. **Does not upload already-present blob** — mock `attachmentExists()` returning `true`. Verify `uploadAttachment` is NOT called.

3. **Upload failure does not fail push** — mock `uploadAttachment()` throwing a network exception. Verify the overall push does not throw and sync status is `success`.

4. **WebDAV push also uploads attachments** — same as test 1 but with `WebdavService` mock and WebDAV sync method configured.

## Verification

```bash
flutter test test/providers/assets_provider_test.dart --name "attachment sync push"
```

Expected: all tests fail (Red phase — upload loop not yet in `AssetsNotifier`).
