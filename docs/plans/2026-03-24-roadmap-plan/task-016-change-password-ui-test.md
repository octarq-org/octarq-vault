# Task 016 — Change Password UI: Test

**type:** test
**depends-on:** ["015"]

## BDD Scenarios Covered

```gherkin
Scenario: New password too weak is rejected
  Given I open the Change Password dialog
  When I enter current password "OldPass123!"
  And I enter new password "weak"
  Then the password strength indicator shows "Too weak"
  And the "Change Password" button remains disabled

Scenario: New password confirmation mismatch
  Given I open the Change Password dialog
  When I enter new password "NewPass456!" and confirm "DifferentPass!"
  Then an inline error "Passwords do not match" is shown
  And the "Change Password" button remains disabled
```

## Goal

Write widget tests for the Change Password UI (the dialog or bottom sheet in `SettingsScreen`).

## Test File

- `test/widgets/change_password_ui_test.dart` (new)

## Test Cases

1. **Settings shows Change Password tile** — render `SettingsScreen`. Assert that a `ListTile` with text "Change Master Password" (or matching l10n key) exists in the Security section.

2. **Tapping tile opens dialog** — tap the "Change Master Password" tile. Assert a dialog with three password fields is shown (current, new, confirm).

3. **Weak new password disables button** — enter "OldPass123!" in current, "abc" in new password. Assert the submit button is disabled and strength indicator shows a weak indicator (same component as `SetupScreen`).

4. **Password mismatch disables button and shows error** — enter valid current and new password, but "WrongConfirm" in confirm. Assert button is disabled and error text containing "do not match" is visible.

5. **Valid inputs enable button** — enter all three valid, matching passwords (≥12 chars). Assert button is enabled.

6. **Loading state shown during change** — mock `changePasswordProvider` to emit `AsyncLoading`. Assert a `CircularProgressIndicator` is shown and the button is disabled.

7. **Success shows SnackBar and closes dialog** — mock `changePasswordProvider.changePassword()` to complete successfully. Assert the dialog closes and a `SnackBar` with success text is shown.

8. **Error shows message in dialog** — mock `changePasswordProvider.changePassword()` to throw. Assert error text appears in the dialog and the dialog stays open.

## Verification

```bash
flutter test test/widgets/change_password_ui_test.dart
```

Expected: all tests fail (Red phase — UI does not exist yet).
