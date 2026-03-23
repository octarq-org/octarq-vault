# Task 004 — Attachment Detail Screen UI: Test

**type:** test
**depends-on:** ["003"]

## BDD Scenarios Covered

```gherkin
Scenario: Upload attachment to asset
  When I tap the attach file button on the asset detail screen
  And I select a file "server_key.pem" (3.2 KB)
  Then the file is encrypted with AES-256-GCM before writing to disk
  And an AssetAttachment record is saved to the database
  And the attachment appears in the asset detail screen showing "server_key.pem" and "3.2 KB"
  And the oplog records an "upsert" entry for entity type "attachment"

Scenario: View attachment list in asset detail
  Given asset "My VPS" has 2 attachments: "server_key.pem" and "notes.txt"
  When I navigate to the asset detail screen
  Then I see an "Attachments" section with 2 items
  And each item shows the file name, size, and action icons

Scenario: Delete attachment
  Given asset "My VPS" has attachment "old_notes.txt"
  When I tap the delete icon on "old_notes.txt"
  And I confirm the deletion dialog
  Then the encrypted blob is deleted from disk
  And the AssetAttachment record is removed from the database
  And the oplog records a "delete" entry for entity type "attachment"
  And the attachment no longer appears in the list

Scenario: Corrupted attachment blob on download
  Given an attachment blob on disk has been corrupted (AES-GCM tag mismatch)
  When the user taps the download icon for that attachment
  Then AttachmentService.loadAttachmentBytes() throws a decryption error
  And the UI shows an error message "Could not decrypt attachment"
  And the attachment record in the database is preserved (not deleted)
```

## Goal

Write widget tests for the new Attachments section in `AssetDetailScreen`. Use mocked `attachmentsProvider`, `attachmentServiceProvider`, and `databaseServiceProvider`.

## Test File to Modify

- `test/widgets/asset_detail_screen_test.dart` (create if not exists)

## Test Cases

1. **Attachments section renders** — when `attachmentsProvider` returns 2 items, the screen shows an "Attachments" header, 2 `_AttachmentRow` widgets, each containing the correct `name` and formatted size text.

2. **Attach file button triggers file picker** — tapping the `IconButton(Icons.attach_file)` calls `FilePicker.platform.pickFiles(...)`. Use a mock/stub for `FilePicker`.

3. **Upload calls AttachmentService and DB** — after a file is picked, `attachmentServiceProvider.saveAttachment(...)` is called with correct `assetId`, `name`, `mimeType`, and `bytes`. Then `databaseServiceProvider.insertAttachment(...)` is called. Then `attachmentsProvider` is invalidated and the list refreshes.

4. **Delete shows confirmation dialog** — tapping the delete icon shows an `AlertDialog`. Cancelling does not call `deleteAttachmentFile`.

5. **Delete confirmed calls service and DB** — confirming the delete dialog calls `attachmentServiceProvider.deleteAttachmentFile(attachment)`, then `databaseServiceProvider.deleteAttachment(id)`, then invalidates `attachmentsProvider`.

6. **Corrupted blob shows snackbar** — when `attachmentServiceProvider.loadAttachmentBytes(attachment)` throws, a `SnackBar` with text containing "Could not decrypt" is shown. The attachment row remains in the list.

## Verification

```bash
flutter test test/widgets/asset_detail_screen_test.dart
```

Expected: all tests fail (Red phase — UI changes not yet implemented).
