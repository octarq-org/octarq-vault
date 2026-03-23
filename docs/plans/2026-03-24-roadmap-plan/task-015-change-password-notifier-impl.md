# Task 015 — ChangePasswordNotifier: Implementation

**type:** impl
**depends-on:** ["014"]

## BDD Scenarios Covered

Same as task-014 (Green phase).

## Goal

Create `lib/providers/change_password_notifier.dart` implementing the 6-step atomic password change operation.

## Files to Create

- `lib/providers/change_password_notifier.dart` — new file

  **Class:** `ChangePasswordNotifier extends AsyncNotifier<void>`

  **Method: `changePassword(String current, String newPwd)`**

  Implements the sequence from the design doc `docs/plans/2026-03-24-roadmap-design/architecture.md` (D2):

  - Step 1: Verify current password via verify blob (decrypt with current `EncryptionService` key). Throw/error if wrong.
  - Step 2: Derive new key via `EncryptionService.deriveKey(newPwd, newSalt)` — in memory only; keep both old and new `EncryptionService` instances available until Step 6.
  - Step 3: Backup DB file path to a temp location (using `dart:io` `File.copy()`). Then call `db.rekeyDatabase(newKey)`. If this throws, the DB is still under the old key — propagate error, no rollback needed.
  - Step 4: Call `db.reEncryptAllFields(oldEnc, newEnc)`. If this throws, restore DB from backup (copy temp file back over DB path). Re-throw error.
  - Step 5: Call `storage.storeVerifyBlob(newBlob)` and `storage.storeMasterKey(newKey, newSalt)`.
  - Step 6: Update live `EncryptionService.masterKey` and `EncryptionService.salt` in the singleton (`ref.read(encryptionServiceProvider)`).
  - On success: emit `AsyncData(null)`, clean up temp backup file.

  **Provider:**
  ```
  final changePasswordProvider = AsyncNotifierProvider<ChangePasswordNotifier, void>(...)
  ```

## Verification

```bash
flutter test test/providers/change_password_notifier_test.dart
flutter analyze
```

Expected: all tests from task-014 pass (Green phase).
