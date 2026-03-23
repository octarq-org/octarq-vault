# Task 001 — Add file_picker Dependency

**type:** setup
**depends-on:** []

## Goal

Add the `file_picker` package to `pubspec.yaml` so that attachment upload UI can use a native file selection dialog. Confirm no conflicts with existing dependencies.

## Files to Modify

- `pubspec.yaml` — add `file_picker: ^8.x.x` under `dependencies`
- `pubspec.lock` — regenerated automatically

## Steps

1. Check `pubspec.yaml` to confirm `file_picker` is not already present
2. Add `file_picker: ^8.x.x` under the `# Utilities` section in `pubspec.yaml`
3. Run `flutter pub get` to resolve and lock the dependency
4. Confirm `flutter analyze` passes with no new warnings

## Verification

```bash
flutter pub get
flutter analyze
grep "file_picker" pubspec.lock
```

Expected: `file_picker` appears in `pubspec.lock`, analyze reports no errors.
