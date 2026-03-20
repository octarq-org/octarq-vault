# OctarqVault · Personal Digital Asset Manager

[![中文](https://img.shields.io/badge/README-中文-2ea043)](README.zh-CN.md)
[![Security](https://img.shields.io/badge/security-responsible%20disclosure-blue)](SECURITY.md)

> **One-stop encrypted asset management for technical practitioners**

OctarqVault is a digital asset manager built for technical practitioners (developers, site operators, crypto users). It supports local encryption, offline-first design, dynamic fields, and expiry reminders.

- **Website**: [vault.octarq.org](https://vault.octarq.org)
- **Docs**: [vault.octarq.org/docs](https://vault.octarq.org/docs)

## Features
1. **All asset types**: Presets for domains, VPS, SSL certs, email, SaaS subscriptions, and service API keys.
2. **Layered encryption**: Master key derived from master password + salt via Argon2id; AES-256. Protected by device secure enclave (Keychain / Keystore) and local biometrics (Face ID / Touch ID). DB-level cipher storage with SQLCipher; critical fields wrapped with AES-256-GCM.
3. **Offline & local-first**: All data stays on device and runs independently.
4. **Smart reminders**: Local scheduler for system-level scheduled and expiry notifications.
5. **Export & sync**: Clipboard export; **E2EE `.enc` snapshot** — WebDAV (mobile/desktop), **Google Drive** + **local file** (Web, Chromium File System API or download fallback).
6. **i18n**: English / 中文.

## Tech stack
* **Framework**: Flutter (v3.11+)
* **Routing**: `go_router`
* **State**: `flutter_riverpod`
* **Local DB**: `sqflite_sqlcipher` (AES-256 DB encryption)
* **Crypto**: `pointycastle` (AES-GCM), `dargon2_flutter` (Argon2id)
* **Secure storage**: `flutter_secure_storage`, `local_auth`
* **CodeGen**: `freezed`, `json_serializable`, `build_runner`

## Architecture

**Encryption Flow:**
```
Master Password + Salt (128-bit random)
        │
        ▼ Argon2id (iter=3, mem=64MB, par=4)
   Master Key (256-bit)
        │
   ┌────┴────────────────────────┐
   │                             │
   ▼                             ▼
SQLCipher DB Key           Field Encryption
(AES-256)                  AES-256-GCM
                           IV: random 96-bit
                           Tag: 128-bit
                           Stored: {valueEnc, iv}
```

**Sync Flow (E2EE Snapshot):**
```
Local Vault State
        │
        ▼ packSnapshotToCiphertext()
  JSON Snapshot → AES-256-GCM encrypt
        │
  AVV2 Payload: [magic(4)] [salt_len(2)] [salt] [IV(12)] [Ciphertext+MAC]
        │
   ┌────┼────────────┐
   ▼    ▼            ▼
WebDAV  Google Drive  Local File
        │
   (on restore) unpackCiphertextToSnapshot()
        │
        ▼ LWW merge by updatedAt (tombstone-aware)
   Merged Local State
```

**Key Derivation Parameters:**

| Parameter | Value |
|-----------|-------|
| Algorithm | Argon2id |
| Iterations (t) | 3 |
| Memory (m) | 65536 KiB (64 MB) |
| Parallelism (p) | 4 |
| Output length | 32 bytes (256-bit) |
| Salt length | 16 bytes (128-bit, random per vault) |

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
   git clone https://github.com/Jungley8/octarq-vault.git
   cd octarq-vault
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
Github Actions on every PR/push (`.github/workflows/ci.yml`): `dart format`, `flutter analyze`, `flutter test`, **`flutter build web`** (smoke).

**Releases**: tag → optional Cloudflare Pages deploy + artifacts; see `docs/web-deploy.md`.

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

## Self-Hosting

### WebDAV CORS Proxy (for Web client)

Browsers enforce CORS. If your WebDAV server doesn't support CORS, front it with an nginx proxy:

```nginx
location / {
    proxy_pass http://your-webdav-server:5005;
    add_header 'Access-Control-Allow-Origin' 'https://your-app-domain.com' always;
    add_header 'Access-Control-Allow-Methods' 'GET, POST, PUT, DELETE, OPTIONS, PROPFIND, MKCOL, COPY, MOVE' always;
    add_header 'Access-Control-Allow-Headers' 'Authorization, Content-Type, Depth, If-Match, If-None-Match, Lock-Token, Overwrite, Timeout, Destination' always;
    add_header 'Access-Control-Allow-Credentials' 'true' always;
    if ($request_method = OPTIONS) { return 204; }
}
```

See [CONTRIBUTING.md](CONTRIBUTING.md) for the full nginx server block and Google Cloud Console OAuth setup.

## License
MIT License. All rights reserved.
