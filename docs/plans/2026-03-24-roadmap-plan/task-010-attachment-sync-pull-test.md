# Task 010 — Attachment Sync Pull: Test

**type:** test
**depends-on:** ["003"]

## BDD Scenarios Covered

```gherkin
Scenario: Missing attachment blob downloaded after pull
  Given the remote snapshot contains an attachmentManifest entry for "server_key.pem"
  And the local device does not have "server_key.pem" on disk
  When a sync pull completes successfully
  Then the blob is downloaded from the remote backend
  And saved to disk via AttachmentService.saveEncryptedBytes()
  And the file is available for decryption without a re-sync

Scenario: Deleted local attachment is not re-downloaded from remote
  Given the user deleted attachment "old_notes.txt" locally
  And the remote attachmentManifest still contains "old_notes.txt"
  When a sync pull completes
  Then the blob is NOT re-downloaded
  And the deletion tombstone in op_log prevents resurrection
```

## Goal

Write unit tests for the attachment blob download loop in `AssetsNotifier`'s pull path.

## Test File to Modify

- `test/providers/assets_provider_test.dart` — add new test group `"attachment sync pull"`

## Test Cases

1. **Downloads missing blob after pull** — mock a remote `VaultSnapshot` with `attachmentManifest` containing one `AssetAttachment`. Mock `AttachmentService.attachmentExists()` returning `false`. Mock `GoogleDriveService.downloadAttachment()` returning dummy encrypted bytes. After pull, verify `attachmentService.saveEncryptedBytes()` was called with the correct attachment and bytes.

2. **Does not download already-present blob** — mock `attachmentExists()` returning `true`. Verify `downloadAttachment` is NOT called.

3. **Null download result is handled gracefully** — mock `downloadAttachment()` returning `null` (blob not on remote yet). Verify no exception is thrown and `saveEncryptedBytes` is NOT called.

4. **Download failure does not fail pull** — mock `downloadAttachment()` throwing. Verify pull does not throw.

5. **Deleted attachment not re-downloaded** — mock a remote manifest containing `AssetAttachment` with id `X`. Also mock the local op_log having a "delete" entry for entity `X` with a tombstone. Verify `downloadAttachment` is NOT called for that attachment.

## Verification

```bash
flutter test test/providers/assets_provider_test.dart --name "attachment sync pull"
```

Expected: all tests fail (Red phase).
