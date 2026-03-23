# Task 019 — GitHub Issue Templates

**type:** setup
**depends-on:** []

## BDD Scenarios Covered

```gherkin
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
```

## Goal

Create GitHub Issues templates to standardise bug reports and feature requests.

## Files to Create

**`.github/ISSUE_TEMPLATE/bug_report.yml`**

Required fields:
- `platform` (dropdown): Android / iOS / macOS / Web / Windows / Linux
- `app_version` (input, required): e.g. "1.4.0+1"
- `flutter_version` (input, required): output of `flutter --version`
- `sync_method` (dropdown, optional): None / WebDAV / Google Drive / iCloud / Local File
- `steps_to_reproduce` (textarea, required): numbered steps
- `expected_behavior` (textarea, required)
- `actual_behavior` (textarea, required)
- `crash_log` (textarea, optional)

Auto-assign label: `bug`

**`.github/ISSUE_TEMPLATE/feature_request.yml`**

Required fields:
- `feature_area` (dropdown): Sync / Encryption / UI / Asset Types / Import-Export / Notifications / Platform Support / Other
- `problem_statement` (textarea, required): "What problem does this solve?"
- `proposed_solution` (textarea, required)
- `alternatives_considered` (textarea, optional)
- `platform_relevance` (checkboxes): Android / iOS / macOS / Web / Windows / Linux / All
- `security_implications` (dropdown): Yes / No / Unsure

Auto-assign label: `enhancement`

**`.github/ISSUE_TEMPLATE/config.yml`**

- `blank_issues_enabled: false`
- Contact links section pointing to SECURITY.md for security issues

## Verification

Manual checklist:
- [ ] `.github/ISSUE_TEMPLATE/bug_report.yml` is valid YAML
- [ ] `.github/ISSUE_TEMPLATE/feature_request.yml` is valid YAML
- [ ] `.github/ISSUE_TEMPLATE/config.yml` sets `blank_issues_enabled: false`

```bash
# Validate YAML syntax
python3 -c "import yaml; yaml.safe_load(open('.github/ISSUE_TEMPLATE/bug_report.yml'))" && echo "bug_report.yml OK"
python3 -c "import yaml; yaml.safe_load(open('.github/ISSUE_TEMPLATE/feature_request.yml'))" && echo "feature_request.yml OK"
python3 -c "import yaml; yaml.safe_load(open('.github/ISSUE_TEMPLATE/config.yml'))" && echo "config.yml OK"
```
