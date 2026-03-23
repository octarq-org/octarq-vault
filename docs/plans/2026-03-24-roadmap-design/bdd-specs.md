# BDD Specifications

## Feature: Attachment Management

```gherkin
Feature: Attachment Management
  As a vault user
  I want to attach encrypted files to my assets
  So that I can store related documents alongside credentials

  Background:
    Given the vault is unlocked
    And I am viewing asset "My VPS"

  Scenario: Upload attachment to asset
    When I tap the attach file button on the asset detail screen
    And I select a file "server_key.pem" (3.2 KB)
    Then the file is encrypted with AES-256-GCM before writing to disk
    And an AssetAttachment record is saved to the database
    And the attachment appears in the asset detail screen showing "server_key.pem" and "3.2 KB"
    And the oplog records an "upsert" entry for entity type "attachment"

  Scenario: View attachment list in asset detail
    Given asset "My VPS" has 2 attachments: "server_key.pem" and "notes.txt"
    When I navigate to the asset detail screen
    Then I see an "Attachments" section with 2 items
    And each item shows the file name, size, and action icons

  Scenario: Download and decrypt attachment
    Given asset "My VPS" has attachment "server_key.pem"
    When I tap the download icon on "server_key.pem"
    Then the encrypted blob is read from disk
    And decrypted with AES-256-GCM using the master key
    And the plaintext file is saved to the device's downloads folder

  Scenario: Delete attachment
    Given asset "My VPS" has attachment "old_notes.txt"
    When I tap the delete icon on "old_notes.txt"
    And I confirm the deletion dialog
    Then the encrypted blob is deleted from disk
    And the AssetAttachment record is removed from the database
    And the oplog records a "delete" entry for entity type "attachment"
    And the attachment no longer appears in the list

  Scenario: Attachment not available on web platform
    Given I am using the web version of OctarqVault
    When I navigate to any asset detail screen
    Then the Attachments section is not visible
    And no file picker option is shown

  Scenario: Attachment blob syncs to Google Drive after push
    Given asset "My VPS" has attachment "server_key.pem" that has not been uploaded
    And Google Drive sync is configured
    When I trigger a sync push
    Then the encrypted blob bytes are uploaded to Google Drive under "octarq_attachments/"
    And the attachment is marked as synced

  Scenario: Missing attachment blob downloaded after pull
    Given the remote snapshot contains an attachmentManifest entry for "server_key.pem"
    And the local device does not have "server_key.pem" on disk
    When a sync pull completes successfully
    Then the blob is downloaded from the remote backend
    And saved to disk via AttachmentService.saveEncryptedBytes()
    And the file is available for decryption without a re-sync

  Scenario: Partial attachment sync does not block vault sync
    Given one attachment blob fails to upload due to network error
    When a sync push is triggered
    Then the vault snapshot (assets, relations, types) is uploaded successfully
    And the failed attachment is silently skipped (logged in debug mode only)
    And the sync status shown to the user reflects success
    And the sync is not marked as failed

  Scenario: Corrupted attachment blob on download
    Given an attachment blob on disk has been corrupted (AES-GCM tag mismatch)
    When the user taps the download icon for that attachment
    Then AttachmentService.loadAttachmentBytes() throws a decryption error
    And the UI shows an error message "Could not decrypt attachment"
    And the attachment record in the database is preserved (not deleted)

  Scenario: Deleted local attachment is not re-downloaded from remote
    Given the user deleted attachment "old_notes.txt" locally
    And the remote attachmentManifest still contains "old_notes.txt"
    When a sync pull completes
    Then the blob is NOT re-downloaded
    And the deletion tombstone in op_log prevents resurrection
```

---

## Feature: Change Master Password

```gherkin
Feature: Change Master Password
  As a security-conscious vault user
  I want to change my master password
  So that I can rotate credentials periodically or after a suspected compromise

  Background:
    Given the vault is unlocked with password "OldPass123!"

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

  Scenario: Wrong current password rejected
    Given I open the Change Password dialog
    When I enter current password "WrongPass!"
    And I tap "Change Password"
    Then the current password is checked against the verify blob
    And the check fails before any database modification
    And an error "Incorrect current password" is shown
    And no data is modified

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

  Scenario: PRAGMA rekey itself fails
    Given the DB is open under the current key
    When PRAGMA rekey is executed with the new key
    And SQLCipher returns an error (e.g., disk full, IO error)
    Then the DB file remains encrypted under the original key
    And secure storage is NOT updated (no changes made yet)
    And an error dialog informs the user
    And the vault remains accessible with the original password

  Scenario: Database re-keying fails midway — rollback
    Given the vault DB file has been backed up before the operation
    When PRAGMA rekey succeeds
    But re-encrypting asset_fields fails due to an unexpected error
    Then the backup DB file is restored over the damaged file
    And secure storage is NOT updated
    And an error dialog informs the user to try again
    And the vault remains accessible with the original password
```

---

## Feature: Open Source Community Files

```gherkin
Feature: Open Source Community Files
  As an open source contributor
  I want clear contribution guidelines and issue templates
  So that I can contribute effectively to OctarqVault

  Scenario: Bug report template has all required fields
    Given a contributor navigates to GitHub Issues > New Issue
    When they select "Bug Report"
    Then the template includes: Flutter/Dart version, OS/platform, steps to reproduce,
         expected behaviour, actual behaviour, and optional logs section

  Scenario: Feature request template is available
    Given a contributor navigates to GitHub Issues > New Issue
    When they select "Feature Request"
    Then the template includes: problem description, proposed solution,
         alternatives considered, and platform relevance

  Scenario: Blank issues are disabled
    Given a contributor navigates to GitHub Issues > New Issue
    Then they cannot open a blank issue without selecting a template

  Scenario: CONTRIBUTING.md covers all contributor needs
    Given a new contributor reads CONTRIBUTING.md
    Then they find: Flutter SDK setup steps, build_runner code generation step,
         pre-commit hook installation, conventional commits format,
         PR process, and security disclosure link to SECURITY.md

  Scenario: CI runs unit tests on macOS
    Given a PR is opened against main
    When the CI workflow runs
    Then a macOS job runs "flutter test" in parallel with the existing Ubuntu job
    And failures in macOS-specific code (SQLCipher, secure_storage) are caught
```

---

## Feature: iCloud Drive Active Sync

```gherkin
Feature: iCloud Drive Active Sync
  As an iOS/macOS user
  I want my vault to sync via iCloud Drive in real time
  So that changes on one device appear on other devices within minutes

  Background:
    Given I am using OctarqVault on iOS with iCloud Drive enabled
    And the app has the iCloud container entitlement "iCloud.org.octarq.vault"

  Scenario: First-time backup to iCloud Drive
    Given no vault file exists in the iCloud ubiquity container
    When I make any change to an asset
    And automatic sync triggers
    Then the encrypted AVV3 snapshot is written to the iCloud Drive ubiquity container
    And the file appears in Files.app under "OctarqVault"

  Scenario: Restore from iCloud Drive on new device
    Given a vault snapshot exists in the iCloud Drive ubiquity container
    When I install OctarqVault on a new device and tap "Restore from iCloud"
    Then the app downloads the snapshot from the ubiquity container
    And prompts for the master password
    And decrypts and imports all assets on successful authentication

  Scenario: Conflict between local and iCloud versions
    Given device A and device B both have the vault open
    When device A modifies asset "My VPS" at timestamp T1
    And device B modifies the same asset at timestamp T2 > T1
    And both devices sync
    Then the LWW merge selects device B's version (newer updatedAt)
    And no data loss occurs

  Scenario: iCloud Drive unavailable (no internet or iCloud disabled)
    Given the user's iCloud account is not signed in
    When iCloud Drive sync is selected in Settings
    Then an informational message explains that iCloud Drive requires an Apple ID
    And the sync setting falls back gracefully without crashing
```
