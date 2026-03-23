# Task 005 — Attachment Detail Screen UI: Implementation

**type:** impl
**depends-on:** ["004"]

## BDD Scenarios Covered

Same as task-004 (Green phase).

## Goal

Add the Attachments section to `AssetDetailScreen` and the upload flow so tests from task-004 pass.

## Files to Modify

- `lib/views/asset_detail_screen.dart`
  - Import `attachments_provider.dart`, `attachment_service.dart`, `file_picker` package
  - Insert Attachments section **after** the Linked Assets block (after line ~378), before `SizedBox(height: 40)`
  - Section structure:
    - `Row { _SectionTitle(l10n.attachments), IconButton(Icons.attach_file) }` — `IconButton` triggers `_pickAndUpload()`
    - `if (kIsWeb) return hidden` — entire section hidden on web
    - `ref.watch(attachmentsProvider(widget.assetId)).when(...)` for list
    - Empty state: same `kSurfaceColor` card pattern as Linked Assets empty state
    - Non-empty: `_DetailCard` with `_AttachmentRow` widgets per attachment
  - Add private method `_pickAndUpload()`:
    - Calls `FilePicker.platform.pickFiles(withData: true)`
    - Calls `attachmentServiceProvider.saveAttachment(assetId, name, mimeType, bytes)`
    - Calls `databaseServiceProvider.insertAttachment(record)`
    - Calls `ref.invalidate(attachmentsProvider(assetId))`
  - Add private method `_deleteAttachment(AssetAttachment att)`:
    - Shows `AlertDialog` confirmation (same pattern as `_deleteAsset`)
    - On confirm: calls `attachmentServiceProvider.deleteAttachmentFile(att)`, then `databaseServiceProvider.deleteAttachment(att.id)`, then invalidates provider
  - Add private widget `_AttachmentRow` (at bottom of file):
    - Shows MIME icon, `att.name`, formatted size (e.g. `"${(att.size/1024).toStringAsFixed(1)} KB"`)
    - Download `IconButton`: calls `attachmentServiceProvider.loadAttachmentBytes(att)`, shows error snackbar on exception, opens file with `open_filex` or shares via `share_plus` on success
    - Delete `IconButton`: calls `_deleteAttachment(att)`

- `lib/l10n/app_en.arb` — add strings: `attachments`, `addAttachment`, `noAttachments`, `deleteAttachmentConfirmation`, `couldNotDecryptAttachment`
- `lib/l10n/app_zh.arb` — same keys in Chinese
- `lib/l10n/app_es.arb` — same keys in Spanish

## Verification

```bash
flutter test test/widgets/asset_detail_screen_test.dart
dart format --set-exit-if-changed lib/views/asset_detail_screen.dart
flutter analyze
```

Expected: all tests from task-004 pass (Green phase).
