# Task 018 — CONTRIBUTING.md and README Link Fix

**type:** setup
**depends-on:** []

## BDD Scenario Covered

```gherkin
Scenario: CONTRIBUTING.md covers all contributor needs
  Given a new contributor reads CONTRIBUTING.md
  Then they find: Flutter SDK setup steps, build_runner code generation step,
       pre-commit hook installation, conventional commits format,
       PR process, and security disclosure link to SECURITY.md
```

## Goal

Create `CONTRIBUTING.md` at the repo root and update the existing `README.md` link that currently points to a non-existent file.

## Files to Create / Modify

**Create `CONTRIBUTING.md`** at repo root with the following sections:

1. **Prerequisites** — Flutter SDK ≥3.11, Dart SDK ^3.11.1, Xcode (iOS/macOS), Android Studio (Android), CocoaPods (iOS)
2. **Setup** — `git clone`, `flutter pub get`, `dart run build_runner build --delete-conflicting-outputs`
3. **Pre-commit Hooks** — `pip install pre-commit && pre-commit install && pre-commit install --hook-type pre-push`. List what hooks do: `dart format`, `build_runner`, `flutter analyze` (pre-commit); `flutter test` (pre-push)
4. **Code Generation** — explain that `*.freezed.dart` and `*.g.dart` are committed; must run `build_runner` after editing any `@freezed`/`@JsonSerializable` model
5. **Code Style** — `dart format` enforced by CI; no manual formatting changes
6. **Commit Convention** — Conventional Commits (`feat:`, `fix:`, `chore:`, `docs:`, `test:`, `refactor:`). Reference `.pre-commit-config.yaml` for the commit-msg hook
7. **i18n** — add new strings to all three ARB files (`app_en.arb`, `app_zh.arb`, `app_es.arb`) before using them
8. **PR Process** — branch from `main`; CI must pass (format, analyze, test, web smoke build); PRs should be focused
9. **Platform-Specific Code** — explain the conditional import pattern (`_io` / `_web` / `_stub`) for new platform-diverging services
10. **Security Disclosure** — private disclosure only, no public issues for vulnerabilities; link to `SECURITY.md`

**Modify `README.md`** — update the `CONTRIBUTING.md` link (in the Self-Hosting or footer section) from a dead link to `./CONTRIBUTING.md`

## Verification

Manual checklist:
- [ ] `CONTRIBUTING.md` exists at repo root
- [ ] All 10 sections are present
- [ ] `README.md` link to CONTRIBUTING.md resolves correctly (not 404)
- [ ] `dart format --set-exit-if-changed CONTRIBUTING.md` — N/A (markdown file)
- [ ] `flutter analyze` still passes (no new Dart files modified)

```bash
flutter analyze
grep "CONTRIBUTING" README.md
```
