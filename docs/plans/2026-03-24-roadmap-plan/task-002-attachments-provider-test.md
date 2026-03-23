# Task 002 — Attachments Provider: Test

**type:** test
**depends-on:** ["001"]

## BDD Scenarios Covered

```gherkin
Scenario: View attachment list in asset detail
  Given asset "My VPS" has 2 attachments: "server_key.pem" and "notes.txt"
  When I navigate to the asset detail screen
  Then I see an "Attachments" section with 2 items
  And each item shows the file name, size, and action icons

Scenario: Attachment not available on web platform
  Given I am using the web version of OctarqVault
  When I navigate to any asset detail screen
  Then the Attachments section is not visible
  And no file picker option is shown
```

## Goal

Write unit tests for the new `attachmentsProvider` (FutureProvider.family) and `attachmentServiceProvider` before implementing them. Tests should use mocked `DatabaseService` and `EncryptionService`.

## Test File to Create

- `test/providers/attachments_provider_test.dart`

## Test Cases

1. **Returns list from DB** — given a mocked `DatabaseService.getAttachmentsForAsset(assetId)` returning 2 `AssetAttachment` records, `attachmentsProvider(assetId)` emits a list with 2 items with correct `name` and `size` fields.

2. **Returns empty list on web** — when `kIsWeb` is true (use `testWidgets` with `debugDefaultTargetPlatformOverride` or a `kIsWebOverride` mechanism), `attachmentsProvider` returns `[]` without calling `DatabaseService`.

3. **Opens DB if not open** — when `DatabaseService.isOpen` is false, the provider calls `ensureOpen(key)` before querying, using `EncryptionService.masterKey` from the injected provider.

4. **`attachmentServiceProvider` returns `AttachmentService` singleton** — the provider creates an `AttachmentService` instance wrapping the `EncryptionService` from `encryptionServiceProvider`.

## Verification

```bash
flutter test test/providers/attachments_provider_test.dart
```

Expected: all tests fail with "not implemented" or import errors (Red phase — implementations do not exist yet).
