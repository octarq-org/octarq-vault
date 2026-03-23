# Task 006 — Attachment Web Platform Guard: Test

**type:** test
**depends-on:** ["003"]

## BDD Scenario Covered

```gherkin
Scenario: Attachment not available on web platform
  Given I am using the web version of OctarqVault
  When I navigate to any asset detail screen
  Then the Attachments section is not visible
  And no file picker option is shown
```

## Goal

Write a widget test that verifies the Attachments section and file picker button are completely absent when running on web.

## Test File

- `test/widgets/asset_detail_screen_web_test.dart` (new)

## Test Cases

1. **Attachments section hidden on web** — render `AssetDetailScreen` with `kIsWeb = true` (override via test environment or use `debugDefaultTargetPlatformOverride`). Assert that no widget with key `attachmentsSectionKey` or text matching "Attachments" is found.

2. **No file picker button on web** — assert `Icons.attach_file` is not present in the widget tree.

3. **`attachmentsProvider` returns empty on web** — unit test (not widget test): call `attachmentsProvider` in a `ProviderContainer` in web mode, verify it returns `[]` without touching `DatabaseService`.

## Verification

```bash
flutter test test/widgets/asset_detail_screen_web_test.dart
```

Expected: tests fail (Red phase — web guard not yet implemented).
