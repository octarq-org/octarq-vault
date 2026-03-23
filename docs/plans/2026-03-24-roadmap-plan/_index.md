# OctarqVault Roadmap Implementation Plan

**Source Design:** `docs/plans/2026-03-24-roadmap-design/`
**Date:** 2026-03-24
**Features:** Attachment UI + Sync (R1), Change Master Password (R2), Open Source Community (R3), iCloud Drive Active Sync (R4)

---

## Goal

Implement all four roadmap features using a test-first (Red-Green) workflow. Each feature has test tasks that must pass in "Red" (failing) state before their paired implementation tasks turn them "Green".

## Constraints

- No code generation side-effects: always run `dart run build_runner build --delete-conflicting-outputs` after editing `@freezed` models
- Web platform: all attachment code paths must be guarded with `kIsWeb` — `AttachmentServiceStub` throws `UnsupportedError`
- iCloud Drive (R4) requires manual Apple Developer Portal configuration before implementation — Task 021 documents the prerequisite
- Rollback safety: Change Password operation uses a DB file backup; never touches `SecureStorageService` before `PRAGMA rekey` + field re-encryption succeed

---

## Execution Plan

```yaml
tasks:
  - id: "001"
    subject: "Add file_picker dependency"
    slug: "add-file-picker-dep"
    type: "setup"
    depends-on: []

  - id: "002"
    subject: "Attachments provider — test"
    slug: "attachments-provider-test"
    type: "test"
    depends-on: ["001"]

  - id: "003"
    subject: "Attachments provider — impl"
    slug: "attachments-provider-impl"
    type: "impl"
    depends-on: ["002"]

  - id: "004"
    subject: "Attachment detail screen UI — test"
    slug: "attachment-detail-ui-test"
    type: "test"
    depends-on: ["003"]

  - id: "005"
    subject: "Attachment detail screen UI — impl"
    slug: "attachment-detail-ui-impl"
    type: "impl"
    depends-on: ["004"]

  - id: "006"
    subject: "Attachment web platform guard — test"
    slug: "attachment-web-guard-test"
    type: "test"
    depends-on: ["003"]

  - id: "007"
    subject: "Attachment web platform guard — impl"
    slug: "attachment-web-guard-impl"
    type: "impl"
    depends-on: ["005", "006"]

  - id: "008"
    subject: "Attachment sync push — test"
    slug: "attachment-sync-push-test"
    type: "test"
    depends-on: ["003"]

  - id: "009"
    subject: "Attachment sync push — impl"
    slug: "attachment-sync-push-impl"
    type: "impl"
    depends-on: ["008"]

  - id: "010"
    subject: "Attachment sync pull — test"
    slug: "attachment-sync-pull-test"
    type: "test"
    depends-on: ["003"]

  - id: "011"
    subject: "Attachment sync pull — impl"
    slug: "attachment-sync-pull-impl"
    type: "impl"
    depends-on: ["010"]

  - id: "012"
    subject: "DatabaseService rekeyDatabase — test"
    slug: "db-rekey-test"
    type: "test"
    depends-on: []

  - id: "013"
    subject: "DatabaseService rekeyDatabase — impl"
    slug: "db-rekey-impl"
    type: "impl"
    depends-on: ["012"]

  - id: "014"
    subject: "ChangePasswordNotifier — test"
    slug: "change-password-notifier-test"
    type: "test"
    depends-on: ["013"]

  - id: "015"
    subject: "ChangePasswordNotifier — impl"
    slug: "change-password-notifier-impl"
    type: "impl"
    depends-on: ["014"]

  - id: "016"
    subject: "Change password UI — test"
    slug: "change-password-ui-test"
    type: "test"
    depends-on: ["015"]

  - id: "017"
    subject: "Change password UI — impl"
    slug: "change-password-ui-impl"
    type: "impl"
    depends-on: ["016"]

  - id: "018"
    subject: "CONTRIBUTING.md and README link fix"
    slug: "contributing-md"
    type: "setup"
    depends-on: []

  - id: "019"
    subject: "GitHub issue templates"
    slug: "github-issue-templates"
    type: "setup"
    depends-on: []

  - id: "020"
    subject: "CI macOS test job"
    slug: "ci-macos-job"
    type: "impl"
    depends-on: []

  - id: "021"
    subject: "iCloud entitlements and dependency setup"
    slug: "icloud-entitlements-setup"
    type: "setup"
    depends-on: []

  - id: "022"
    subject: "iCloud Drive service — test"
    slug: "icloud-service-test"
    type: "test"
    depends-on: ["021"]

  - id: "023"
    subject: "iCloud Drive service — impl"
    slug: "icloud-service-impl"
    type: "impl"
    depends-on: ["022"]
```

---

## Task File References

- [Task 001: Add file_picker dependency](./task-001-add-file-picker-dep.md)
- [Task 002: Attachments provider — test](./task-002-attachments-provider-test.md)
- [Task 003: Attachments provider — impl](./task-003-attachments-provider-impl.md)
- [Task 004: Attachment detail screen UI — test](./task-004-attachment-detail-ui-test.md)
- [Task 005: Attachment detail screen UI — impl](./task-005-attachment-detail-ui-impl.md)
- [Task 006: Attachment web platform guard — test](./task-006-attachment-web-guard-test.md)
- [Task 007: Attachment web platform guard — impl](./task-007-attachment-web-guard-impl.md)
- [Task 008: Attachment sync push — test](./task-008-attachment-sync-push-test.md)
- [Task 009: Attachment sync push — impl](./task-009-attachment-sync-push-impl.md)
- [Task 010: Attachment sync pull — test](./task-010-attachment-sync-pull-test.md)
- [Task 011: Attachment sync pull — impl](./task-011-attachment-sync-pull-impl.md)
- [Task 012: DatabaseService rekeyDatabase — test](./task-012-db-rekey-test.md)
- [Task 013: DatabaseService rekeyDatabase — impl](./task-013-db-rekey-impl.md)
- [Task 014: ChangePasswordNotifier — test](./task-014-change-password-notifier-test.md)
- [Task 015: ChangePasswordNotifier — impl](./task-015-change-password-notifier-impl.md)
- [Task 016: Change password UI — test](./task-016-change-password-ui-test.md)
- [Task 017: Change password UI — impl](./task-017-change-password-ui-impl.md)
- [Task 018: CONTRIBUTING.md and README link fix](./task-018-contributing-md.md)
- [Task 019: GitHub issue templates](./task-019-github-issue-templates.md)
- [Task 020: CI macOS test job](./task-020-ci-macos-job.md)
- [Task 021: iCloud entitlements and dependency setup](./task-021-icloud-entitlements-setup.md)
- [Task 022: iCloud Drive service — test](./task-022-icloud-service-test.md)
- [Task 023: iCloud Drive service — impl](./task-023-icloud-service-impl.md)

---

## BDD Coverage

| BDD Scenario | Covered By |
|---|---|
| Upload attachment to asset | 004, 005 |
| View attachment list in asset detail | 002, 003, 004, 005 |
| Download and decrypt attachment | 004, 005 |
| Delete attachment | 004, 005 |
| Attachment not available on web | 006, 007 |
| Attachment blob syncs to Google Drive after push | 008, 009 |
| Missing attachment blob downloaded after pull | 010, 011 |
| Partial attachment sync does not block vault sync | 008, 009 |
| Corrupted attachment blob on download | 004, 005 |
| Deleted local attachment not re-downloaded | 010, 011 |
| Successfully change master password | 012, 013, 014, 015, 016, 017 |
| Wrong current password rejected | 014, 015 |
| New password too weak rejected | 016, 017 |
| New password confirmation mismatch | 016, 017 |
| PRAGMA rekey itself fails | 012, 013, 014, 015 |
| Database re-keying fails midway — rollback | 012, 013, 014, 015 |
| Bug report template has all required fields | 019 |
| Feature request template is available | 019 |
| Blank issues are disabled | 019 |
| CONTRIBUTING.md covers all contributor needs | 018 |
| CI runs unit tests on macOS | 020 |
| First-time backup to iCloud Drive | 021, 022, 023 |
| Restore from iCloud Drive on new device | 022, 023 |
| Conflict between local and iCloud versions | 022, 023 |
| iCloud Drive unavailable | 022, 023 |

All 25 BDD scenarios from `docs/plans/2026-03-24-roadmap-design/bdd-specs.md` are covered.

---

## Dependency Chain

```
[001] add-file-picker-dep
  └── [002] attachments-provider-test
        └── [003] attachments-provider-impl
              ├── [004] attachment-detail-ui-test
              │     └── [005] attachment-detail-ui-impl
              │           └── [007] attachment-web-guard-impl ←─ also depends on [006]
              ├── [006] attachment-web-guard-test
              │     └── [007] attachment-web-guard-impl
              ├── [008] attachment-sync-push-test
              │     └── [009] attachment-sync-push-impl
              └── [010] attachment-sync-pull-test
                    └── [011] attachment-sync-pull-impl

[012] db-rekey-test (independent)
  └── [013] db-rekey-impl
        └── [014] change-password-notifier-test
              └── [015] change-password-notifier-impl
                    └── [016] change-password-ui-test
                          └── [017] change-password-ui-impl

[018] contributing-md (independent, no deps)

[019] github-issue-templates (independent, no deps)

[020] ci-macos-job (independent, no deps)

[021] icloud-entitlements-setup (independent, requires manual Apple portal step)
  └── [022] icloud-service-test
        └── [023] icloud-service-impl
```

**Parallel execution opportunities:**
- R1 chain (001→003→004/006/008/010) and R2 chain (012→013→014) can run in parallel
- R3 tasks (018, 019, 020) are fully independent and can run at any time
- R4 chain must wait for manual Apple Developer Portal step (021) before 022/023
