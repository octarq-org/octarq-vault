# Task 017 — Change Password UI: Implementation

**type:** impl
**depends-on:** ["016"]

## BDD Scenarios Covered

Same as task-016 (Green phase).

## Goal

Add the Change Password entry point to `SettingsScreen` and implement the dialog.

## Files to Modify

- `lib/views/settings_screen.dart`
  - In the Security section (after the biometric toggle `ListTile`), add a new `ListTile`:
    - Icon: `Icons.lock_reset_outlined`
    - Title: `l10n.changeMasterPassword`
    - Trailing chevron
    - `onTap`: calls `_showChangePasswordDialog(context)`
  - Add private method `_showChangePasswordDialog(BuildContext context)` that opens a `showModalBottomSheet` or `showDialog` containing `_ChangePasswordForm`

- `lib/views/settings_screen.dart` (or a new `lib/views/change_password_sheet.dart`)
  - **Widget `_ChangePasswordForm`** (stateful):
    - Three `TextFormField` widgets: current password, new password, confirm new password (all obscured)
    - Password strength indicator for new password — reuse or reference the logic from `lib/views/setup_screen.dart` (≥12 chars requirement)
    - Inline validation: mismatch between new and confirm shows "Passwords do not match"
    - Submit button: disabled when validation fails or state is `AsyncLoading`
    - On submit: calls `ref.read(changePasswordProvider.notifier).changePassword(current, newPwd)`
    - On success: shows `SnackBar`, pops dialog
    - On error: shows error text inside the dialog

- `lib/l10n/app_en.arb` — add: `changeMasterPassword`, `currentPassword`, `newPassword`, `confirmNewPassword`, `passwordChangedSuccess`, `passwordChangeFailed`, `passwordsDoNotMatch`
- `lib/l10n/app_zh.arb` — same keys in Chinese
- `lib/l10n/app_es.arb` — same keys in Spanish

## Verification

```bash
flutter test test/widgets/change_password_ui_test.dart
dart format --set-exit-if-changed lib/views/settings_screen.dart
flutter analyze
```

Expected: all tests from task-016 pass (Green phase).
