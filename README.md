# OctarqVault · Personal Digital Asset Manager

[![中文](https://img.shields.io/badge/README-中文-2ea043)](README.zh-CN.md)

> **One-stop encrypted asset management for technical practitioners**

OctarqVault is a digital asset manager built for technical practitioners (developers, site operators, crypto users). It supports local encryption, offline-first design, dynamic fields, and expiry reminders.

- **Website**: [vault.octarq.org](https://vault.octarq.org)
- **Docs**: [vault.octarq.org/docs](https://vault.octarq.org/docs)

## Features
1. **All asset types**: Presets for domains, VPS, SSL certs, email, SaaS subscriptions, and service API keys.
2. **Layered encryption**: Master key derived from master password + salt via Argon2id; AES-256. Protected by device secure enclave (Keychain / Keystore) and local biometrics (Face ID / Touch ID). DB-level cipher storage with SQLCipher; critical fields wrapped with AES-256-GCM.
3. **Offline & local-first**: All data stays on device and runs independently.
4. **Smart reminders**: Local scheduler for system-level scheduled and expiry notifications.
5. **Export**: Full encrypted DB exported as JSON to clipboard for quick manual handoff across devices.

## Tech stack
* **Framework**: Flutter (v3.11+)
* **Routing**: `go_router`
* **State**: `flutter_riverpod`
* **Local DB**: `sqflite_sqlcipher` (AES-256 DB encryption)
* **Crypto**: `pointycastle` (AES-GCM), `dargon2_flutter` (Argon2id)
* **Secure storage**: `flutter_secure_storage`, `local_auth`
* **CodeGen**: `freezed`, `json_serializable`, `build_runner`

---

## Run locally

### Requirements
1. macOS (recommended) / Linux / Windows
2. Flutter SDK v3.11+
3. Xcode and Command Line Tools (for iOS)
4. Android Studio / Java 17+ (for Android)
5. CocoaPods (iOS dependencies)

### Build & run
1. **Clone**:
   ```bash
   git clone https://github.com/app/assetvault.git
   cd asset_vault
   ```

2. **Install dependencies**:
   ```bash
   flutter pub get
   ```

3. **Run code generation**:
   > Required for Freezed models and JSON serialization.
   ```bash
   dart run build_runner build --delete-conflicting-outputs
   ```

4. **(Optional) pre-commit hooks**  
   Pre-commit: `dart format`, `build_runner`, `flutter analyze`. Pre-push: `flutter test`.  
   ```bash
   pip install pre-commit
   pre-commit install && pre-commit install --hook-type pre-push
   ```

5. **Run on device/simulator**:
   ```bash
   flutter run -d ios
   flutter run -d android
   ```

### CI/CD
Github Actions runs on every PR/push (see `.github/workflows/ci.yml`):
- `flutter analyze`
- `flutter test`
- Android APK release build
- iOS (no codesign) build check

### Release builds

**macOS app:**
```bash
flutter build macos
```
Output: `build/macos/Build/Products/Release/asset-vault.app`

**Web (static):**
```bash
flutter build web
```
Output: `build/web/` — deploy to any static host (Vercel, NGINX, etc.)

## Roadmap
- [ ] Dark theme and richer Tags for Asset Form
- [ ] Optional backup via iCloud / WebDAV
- [ ] Better keyboard & mouse support on desktop (macOS / Windows)

## License
MIT License. All rights reserved.
