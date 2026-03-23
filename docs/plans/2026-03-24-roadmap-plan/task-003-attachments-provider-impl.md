# Task 003 — Attachments Provider: Implementation

**type:** impl
**depends-on:** ["002"]

## BDD Scenarios Covered

Same as task-002 (Green phase).

## Goal

Create `attachmentsProvider` and `attachmentServiceProvider` so that the tests from task-002 pass.

## Files to Create / Modify

- `lib/providers/attachments_provider.dart` — **new file**
  - `attachmentsProvider`: `FutureProvider.family<List<AssetAttachment>, String>` modelled after `assetRelationsProvider` in `lib/providers/relation_providers.dart:37-55`
  - Returns `[]` immediately when `kIsWeb`
  - Calls `dbSvc.ensureOpen(key)` if `!dbSvc.isOpen` before querying
  - Returns `dbSvc.getAttachmentsForAsset(assetId)`

- `lib/providers/service_providers.dart` — **add `attachmentServiceProvider`** at end of file
  - Import `attachment_service.dart` (conditional export)
  - `Provider<AttachmentService>` wrapping `EncryptionService` from `encryptionServiceProvider`

## Verification

```bash
flutter test test/providers/attachments_provider_test.dart
flutter analyze
```

Expected: all tests from task-002 now pass (Green phase).
