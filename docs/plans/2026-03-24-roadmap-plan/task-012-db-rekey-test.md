# Task 012 — DatabaseService rekeyDatabase: Test

**type:** test
**depends-on:** []

## BDD Scenarios Covered

```gherkin
Scenario: Successfully change master password
  Given I navigate to Settings > Security > Change Master Password
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

Scenario: Database re-keying fails midway — rollback
  Given the vault DB file has been backed up before the operation
  When PRAGMA rekey succeeds
  But re-encrypting asset_fields fails due to an unexpected error
  Then the backup DB file is restored over the damaged file
  And secure storage is NOT updated
  And an error dialog informs the user to try again
  And the vault remains accessible with the original password

Scenario: PRAGMA rekey itself fails
  Given the DB is open under the current key
  When PRAGMA rekey is executed with the new key
  And SQLCipher returns an error (e.g., disk full, IO error)
  Then the DB file remains encrypted under the original key
  And secure storage is NOT updated (no changes made yet)
  And an error dialog informs the user
  And the vault remains accessible with the original password
```

## Goal

Write unit tests for the new `DatabaseService.rekeyDatabase(Uint8List newKey)` method and `DatabaseService.reEncryptAllFields(EncryptionService oldEnc, EncryptionService newEnc)` method. These are pure DB-layer operations and do not depend on UI.

## Test File to Create

- `test/services/database_service_rekey_test.dart`

## Test Cases

1. **rekeyDatabase executes PRAGMA rekey** — open a real in-memory (or temp) SQLCipher DB, call `rekeyDatabase(newKey)`. Verify the DB can be re-opened with `newKey` and NOT with the old key.

2. **reEncryptAllFields re-encrypts all rows** — insert 3 `asset_fields` rows encrypted with `oldEncService`. Call `reEncryptAllFields(oldEnc, newEnc)`. For each row, decrypt with `newEncService` and verify the plaintext matches the original values.

3. **reEncryptAllFields is transactional** — mock the underlying `txn.update()` call to throw on the 2nd row. Verify the transaction is rolled back (row 1 is NOT updated, row 3 is NOT updated), and the original ciphertext is preserved.

4. **PRAGMA rekey failure propagates** — mock `db.execute("PRAGMA rekey...")` to throw. Verify the exception propagates to the caller without touching secure storage.

## Verification

```bash
flutter test test/services/database_service_rekey_test.dart
```

Expected: tests fail (Red phase — methods do not exist yet).
