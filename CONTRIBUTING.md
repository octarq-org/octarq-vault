# Contributing to OctarqVault

Thank you for your interest in contributing to OctarqVault! This guide covers everything you need to get a local development environment running and submit a pull request.

---

## Dev Setup

### Requirements

- **Flutter SDK** ≥ 3.11 — [flutter.dev/docs/get-started](https://flutter.dev/docs/get-started)
- **Dart** 3.11.1+

### Getting started

```bash
git clone https://github.com/octarq/asset-vault.git
cd asset-vault
flutter pub get
```

### Code generation

Models use `freezed` and `json_serializable`. Run the code generator after cloning (and after any model changes):

```bash
dart run build_runner build --delete-conflicting-outputs
```

### Pre-commit hooks

Install and enable pre-commit hooks to enforce linting, formatting, and code generation automatically:

```bash
pip install pre-commit
pre-commit install
pre-commit install --hook-type pre-push
```

---

## Platform-Specific Setup

### iOS / macOS

Xcode is required. Install CocoaPods and run `pod install` before building:

```bash
gem install cocoapods
cd ios && pod install
```

For macOS, run `cd macos && pod install` instead.

### Android

Android Studio (or a standalone JDK 17+) is required.

**Google Services configuration (for Google Drive sync):**

1. Go to the [Firebase Console](https://console.firebase.google.com) or [Google Cloud Console](https://console.cloud.google.com) and create or select your project.
2. Download `google-services.json` from the project settings.
3. Place the file at `android/app/google-services.json`.
4. This file is gitignored — **never commit it**.
5. For CI, set the `GOOGLE_SERVICES_JSON` secret to the base64-encoded contents of the file. The CI workflow decodes it before building.

If you do not need Google Drive sync, you can skip this step.

### Web

Flutter web support is enabled by default. No additional setup is required to run `flutter run -d chrome`.

**WebDAV and CORS:** When using the WebDAV sync provider from a browser, the WebDAV server must be configured to return appropriate CORS headers. Below is an example nginx reverse-proxy configuration:

```nginx
server {
    listen 443 ssl;
    server_name webdav-proxy.example.com;
    # SSL config here ...

    location / {
        # Proxy to your WebDAV server
        proxy_pass http://your-webdav-server:5005;

        # CORS headers for OctarqVault web client
        add_header 'Access-Control-Allow-Origin' 'https://vault.octarq.org' always;
        add_header 'Access-Control-Allow-Methods' 'GET, POST, PUT, DELETE, OPTIONS, PROPFIND, MKCOL, COPY, MOVE' always;
        add_header 'Access-Control-Allow-Headers' 'Authorization, Content-Type, Depth, If-Match, If-None-Match, Lock-Token, Overwrite, Timeout, Destination' always;
        add_header 'Access-Control-Allow-Credentials' 'true' always;

        if ($request_method = OPTIONS) {
            return 204;
        }
    }
}
```

> **Note:** Replace the `Access-Control-Allow-Origin` value with your actual app origin (or `*` for testing only). The `PROPFIND`, `MKCOL`, `COPY`, and `MOVE` methods are required for the WebDAV protocol.

### Windows / Linux

No additional tooling is required beyond Flutter desktop support. Keyboard shortcuts are defined in `lib/main.dart` and implemented as `SingleActivator` shortcuts:

| Shortcut           | Action              |
|--------------------|---------------------|
| Cmd/Ctrl + N       | New asset           |
| Cmd/Ctrl + ,       | Open settings       |
| Cmd/Ctrl + F       | Focus search        |
| Cmd/Ctrl + L       | Lock vault          |

These shortcuts have been verified on macOS. If you encounter issues on Windows or Linux, please open an issue with details about your environment.

---

## Build & Run

Common commands are available via `make` (see the `Makefile` for the full list):

```bash
make test         # Run all tests
make lint         # Analyze + format check
make gen          # Run build_runner codegen
make build-web    # Build web output
make build-macos  # Build macOS app
```

---

## Code Generation

Models use `freezed` + `json_serializable`. After changing any model file (any `.dart` file annotated with `@freezed`), regenerate the derived files:

```bash
dart run build_runner build --delete-conflicting-outputs
```

The pre-commit hook runs this automatically before each commit, so you will not accidentally commit stale generated files.

---

## Running Tests

```bash
flutter test

# With coverage report:
flutter test --coverage
```

---

## Commit Convention

This project follows [Conventional Commits](https://www.conventionalcommits.org/). Each commit message must start with one of the following types:

`feat`, `fix`, `perf`, `refactor`, `docs`, `test`, `style`, `ci`, `chore`, `build`, `revert`

**Examples:**

```
feat: add conflict resolution UI for LWW sync ties
fix: prevent tombstoned assets from reappearing after sync
docs: add WebDAV CORS proxy setup guide
```

The pre-push hook enforces this format.

---

## Pull Requests

- Keep PRs focused: **one feature or fix per PR**.
- Run `flutter test` and `flutter analyze` locally before submitting.
- Update `CHANGELOG.md` if your change is user-visible.
- Reference any related issue in the PR description (e.g., `Closes #42`).

---

## i18n (Internationalization)

OctarqVault supports English, Simplified Chinese, and Spanish. When adding any user-visible string, add it to **all three** ARB files before using it in code:
- `lib/l10n/app_en.arb`
- `lib/l10n/app_zh.arb`
- `lib/l10n/app_es.arb`

After editing ARB files, run `flutter pub get` to regenerate `lib/l10n/app_localizations*.dart`. Do not add strings to only one ARB file — the analyzer will catch missing translations.

---

## Platform-Specific Code

Services that diverge by platform use conditional imports with three variants:

| Suffix | Platform | Example |
|--------|----------|---------|
| `_io.dart` | iOS / macOS / Android / desktop | `attachment_service_io.dart` |
| `_web.dart` | Flutter Web | `attachment_service_web.dart` (or stub) |
| `_stub.dart` | Throws `UnsupportedError` | fallback for unsupported platforms |

The platform-neutral file (e.g., `attachment_service.dart`) exports the correct variant via `export ... if (dart.library.io) '..._io.dart' if (dart.library.html) '..._stub.dart'`. Follow this pattern when adding any service that has platform-specific behavior.

---

## Security Disclosure

**Do not open a public GitHub issue for security vulnerabilities.** Use the private disclosure process described in [SECURITY.md](./SECURITY.md). This ensures vulnerabilities can be assessed and patched before public disclosure.

---

## Google Cloud Console Setup (OAuth for Google Drive Sync)

If you are working on the Google Drive sync feature, you will need to configure an OAuth 2.0 client:

1. Go to [console.cloud.google.com](https://console.cloud.google.com) → **APIs & Services** → **Credentials**.
2. Click **Create Credentials** → **OAuth 2.0 Client ID**.
3. Select **Web application** as the application type.
4. Under **Authorized JavaScript origins**, add: `https://your-app-domain.com`
5. Under **Authorized redirect URIs**, add: `https://your-app-domain.com`
6. In the **API Library**, search for and enable the **Google Drive API**.
7. The required OAuth scope is: `https://www.googleapis.com/auth/drive.appdata`
8. Copy the generated **Client ID** and:
   - Add it as `GOOGLE_CLIENT_ID` in your CI secrets.
   - Pass it at build time for local development: `--dart-define=GOOGLE_CLIENT_ID=<your-client-id>`
