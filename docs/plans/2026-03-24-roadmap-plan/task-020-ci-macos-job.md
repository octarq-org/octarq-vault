# Task 020 — CI: macOS Native Test Job

**type:** impl
**depends-on:** []

## BDD Scenario Covered

```gherkin
Scenario: CI runs unit tests on macOS
  Given a PR is opened against main
  When the CI workflow runs
  Then a macOS job runs "flutter test" in parallel with the existing Ubuntu job
  And failures in macOS-specific code (SQLCipher, secure_storage) are caught
```

## Goal

Add a `check-macos` parallel job to `.github/workflows/ci.yml` that runs the full unit test suite on `macos-latest`.

## Files to Modify

- `.github/workflows/ci.yml` — add a new `check-macos` job alongside the existing `check` job

  New job `check-macos`:
  - `runs-on: macos-latest`
  - Steps: `actions/checkout@v4`, `subosito/flutter-action@v2` (stable, cache: true), `flutter pub get`, `dart run build_runner build --delete-conflicting-outputs`, `flutter test`
  - Does NOT include `dart format` or `flutter analyze` (already covered by the Ubuntu job)
  - Does NOT include `flutter build macos --debug` (avoids code-signing complexity in CI; the release workflow already handles macOS release builds on tag push)

## Verification

```bash
# Validate YAML syntax locally
python3 -c "import yaml; yaml.safe_load(open('.github/workflows/ci.yml'))" && echo "ci.yml OK"
```

After pushing to a PR branch:
- [ ] GitHub Actions shows two parallel jobs: `check` (ubuntu) and `check-macos` (macos)
- [ ] Both jobs must pass for the PR to be mergeable
