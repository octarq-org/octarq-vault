# Task 014 — ChangePasswordNotifier: Test

**type:** test
**depends-on:** ["013"]

## BDD Scenarios Covered

```gherkin
Scenario: Successfully change master password
  When I enter current password "OldPass123!"
  And I enter new password "NewPass456!" and confirm "NewPass456!"
  And I tap "Change Password"
  Then the system verifies the current password against the stored verify blob
  And Argon2id derives a new 256-bit key from "NewPass456!" with a fresh salt
  And SQLCipher executes "PRAGMA rekey" with the new hex key
  And all asset_fields rows are re-encrypted with the new key
  And secure storage is updated with the new salt, key, and verify blob
  And a success message is shown
  And the vault remains unlocked

Scenario: Wrong current password rejected
  When I enter current password "WrongPass!"
  And I tap "Change Password"
  Then the current password is checked against the verify blob
  And the check fails before any database modification
  And an error "Incorrect current password" is shown
  And no data is modified

Scenario: PRAGMA rekey itself fails
  When PRAGMA rekey is executed with the new key
  And SQLCipher returns an error (e.g., disk full, IO error)
  Then the DB file remains encrypted under the original key
  And secure storage is NOT updated (no changes made yet)
  And the vault remains accessible with the original password

Scenario: Database re-keying fails midway — rollback
  Given the vault DB file has been backed up before the operation
  When PRAGMA rekey succeeds
  But re-encrypting asset_fields fails due to an unexpected error
  Then the backup DB file is restored over the damaged file
  And secure storage is NOT updated
  And the vault remains accessible with the original password
```

## Goal

Write unit tests for `ChangePasswordNotifier.changePassword()` with mocked `EncryptionService`, `DatabaseService`, and `SecureStorageService`.

## Test File to Create

- `test/providers/change_password_notifier_test.dart`

## Test Cases

1. **Successful change** — mock `encryptionService` to return the correct verify blob on decryption, mock `db.rekeyDatabase()` to succeed, mock `db.reEncryptAllFields()` to succeed, mock `storage.storeMasterKey()` to succeed. Call `changePassword("OldPass123!", "NewPass456!")`. Verify the notifier reaches a done/success state. Verify `storage.storeMasterKey(newKey, newSalt)` was called. Verify `storage.storeVerifyBlob(newBlob)` was called.

2. **Wrong current password** — mock `encryptionService.decryptBytes()` to throw (verify blob mismatch). Call `changePassword("WrongPass!", "NewPass456!")`. Verify `db.rekeyDatabase()` was NEVER called. Verify state has an error with message containing "Incorrect".

3. **PRAGMA rekey throws** — mock `db.rekeyDatabase()` to throw. Verify `db.reEncryptAllFields()` was NEVER called. Verify `storage.storeMasterKey()` was NEVER called. Verify state has an error.

4. **reEncryptAllFields throws — rollback triggered** — mock `db.rekeyDatabase()` to succeed and `db.reEncryptAllFields()` to throw. Verify that a DB backup restoration is attempted (or the error is surfaced without touching secure storage). Verify `storage.storeMasterKey()` was NEVER called.

## Verification

```bash
flutter test test/providers/change_password_notifier_test.dart
```

Expected: all tests fail (Red phase — `ChangePasswordNotifier` does not exist yet).
