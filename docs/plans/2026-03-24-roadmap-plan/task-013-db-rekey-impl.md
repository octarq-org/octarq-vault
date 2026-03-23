# Task 013 — DatabaseService rekeyDatabase: Implementation

**type:** impl
**depends-on:** ["012"]

## BDD Scenarios Covered

Same as task-012 (Green phase).

## Goal

Add `rekeyDatabase` and `reEncryptAllFields` methods to `DatabaseService` so tests from task-012 pass.

## Files to Modify

- `lib/services/database_service.dart`

  **New method: `rekeyDatabase(Uint8List newKey)`**
  - Execute `PRAGMA wal_checkpoint(TRUNCATE)` to flush WAL first
  - Execute `PRAGMA rekey = '<newHexKey>'` on the open database
  - Propagates any SQLCipher exception to the caller

  **New method: `reEncryptAllFields(EncryptionService oldEnc, EncryptionService newEnc)`**
  - Read all rows from `asset_fields` table
  - Inside a single DB transaction (`db.transaction(...)`):
    - For each row: decrypt `value_enc`/`iv` with `oldEnc.decryptField()`; re-encrypt with `newEnc.encryptField()`; update the row
  - If the transaction throws, SQLite rolls it back automatically

## Verification

```bash
flutter test test/services/database_service_rekey_test.dart
flutter analyze
```

Expected: all tests from task-012 pass (Green phase).
