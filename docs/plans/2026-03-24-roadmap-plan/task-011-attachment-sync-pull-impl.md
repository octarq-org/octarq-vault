# Task 011 — Attachment Sync Pull: Implementation

**type:** impl
**depends-on:** ["010"]

## BDD Scenarios Covered

Same as task-010 (Green phase).

## Goal

Inject the attachment blob download loop into `AssetsNotifier`'s sync pull path so tests from task-010 pass.

## Files to Modify

- `lib/providers/assets_provider.dart`
  - After `replaceFromSnapshot(mergedSnapshot)` in the pull path, add a best-effort download loop:
    - For each `AssetAttachment att` in `mergedSnapshot.attachmentManifest`:
      - Check local op_log tombstone: if a "delete" entry for `att.id` exists, skip (do NOT re-download)
      - If `!attachSvc.attachmentExists(att)`, call `backend.downloadAttachment(att)`
      - If result is not null, call `attachSvc.saveEncryptedBytes(att, bytes)`
      - Wrap in try/catch that logs and continues
  - The tombstone check requires calling `db.getOpLogSince(0)` filtered by `entityType == attachment && op == delete && entityId == att.id`. Or simpler: query `db.getAttachmentTombstones()` (may need a new `DatabaseService` helper — see note)

**Note:** If `DatabaseService` does not have a method to query deletion tombstones for attachments, add `getDeletedAttachmentIds()` returning `Set<String>` of attachment IDs with a "delete" op_log entry. This is a small addition to `database_service.dart`.

## Verification

```bash
flutter test test/providers/assets_provider_test.dart --name "attachment sync pull"
flutter test test/providers/assets_provider_test.dart
flutter analyze
```

Expected: all pull tests from task-010 pass; no regressions in other provider tests.
