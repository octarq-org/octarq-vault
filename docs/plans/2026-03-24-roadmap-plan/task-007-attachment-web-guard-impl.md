# Task 007 — Attachment Web Platform Guard: Implementation

**type:** impl
**depends-on:** ["005", "006"]

## BDD Scenario Covered

Same as task-006 (Green phase).

## Goal

Ensure that all attachment UI code paths are guarded with `kIsWeb` so the web build never reaches `AttachmentServiceStub` (which throws `UnsupportedError`).

## Files to Modify

- `lib/views/asset_detail_screen.dart` — wrap entire Attachments section in `if (!kIsWeb)` block (this should already be in task-005, but this task verifies and finalises the guard)
- `lib/providers/attachments_provider.dart` — confirm the early `if (kIsWeb) return []` guard is the first line of the provider body

## Verification

```bash
flutter test test/widgets/asset_detail_screen_web_test.dart
flutter build web
```

Expected: web guard tests pass; `flutter build web` succeeds with no import errors from `attachment_service_io.dart`.
