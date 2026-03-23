# Task 021 — iCloud Drive: Entitlements and Dependency Setup

**type:** setup
**depends-on:** []

## BDD Scenario Covered

```gherkin
Scenario: First-time backup to iCloud Drive
  Given no vault file exists in the iCloud ubiquity container
  When I make any change to an asset
  And automatic sync triggers
  Then the encrypted AVV3 snapshot is written to the iCloud Drive ubiquity container
  And the file appears in Files.app under "OctarqVault"
```

## Goal

Prepare the entitlements, pubspec dependency, and Apple Developer Portal prerequisites for iCloud Drive active sync. This task is mostly configuration — no business logic changes.

## ⚠️ Manual Prerequisite (Cannot Be Automated)

Before writing any code:
1. Log into **Apple Developer Portal** → Certificates, Identifiers & Profiles → Identifiers
2. Select the `org.octarq.vault` App ID
3. Enable **iCloud** capability
4. Create iCloud Container: `iCloud.org.octarq.vault`
5. Regenerate the iOS and macOS provisioning profiles
6. Download and install the updated profiles in Xcode

**Only proceed to the file changes below after the portal steps are complete.**

## Files to Modify

**`pubspec.yaml`** — add under `dependencies`:
```yaml
icloud_storage: ^2.x.x
```

**`ios/Runner/Runner.entitlements`** — add:
```xml
<key>com.apple.developer.icloud-container-identifiers</key>
<array><string>iCloud.org.octarq.vault</string></array>
<key>com.apple.developer.icloud-services</key>
<array><string>CloudDocuments</string></array>
```

**`macos/Runner/Release.entitlements`** — same iCloud keys as above

**`macos/Runner/DebugProfile.entitlements`** — same iCloud keys (needed for debug builds)

## Verification

```bash
flutter pub get
grep "icloud_storage" pubspec.lock
flutter analyze
flutter build ios --no-codesign   # must not error on entitlements
```

Manual: confirm Xcode shows iCloud capability enabled without warnings in the Signing & Capabilities tab.
