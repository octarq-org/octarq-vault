# Security Policy

## Reporting a Vulnerability

If you discover a security vulnerability in OctarqVault, please report it responsibly. **Do not disclose the issue publicly until we have had a chance to respond.**

Send a report to: **security@octarq.org**

Please include the following in your report:

- A clear description of the vulnerability and its potential impact
- Step-by-step instructions to reproduce the issue
- Any relevant code snippets, logs, or proof-of-concept material
- The version(s) of OctarqVault affected, if known

We will acknowledge receipt of your report within **72 hours** and aim to provide a resolution timeline as quickly as possible. We appreciate responsible disclosure and will credit researchers who report valid issues (unless you prefer to remain anonymous).

---

## Security Architecture

### Key Derivation

OctarqVault derives the vault encryption key from the user's master password using **Argon2id** with the following parameters:

| Parameter     | Value                         |
|---------------|-------------------------------|
| Algorithm     | Argon2id                      |
| Iterations    | 3                             |
| Memory        | 64 MB (65536 KiB)             |
| Parallelism   | 4                             |
| Output length | 256 bits (32 bytes)           |
| Salt          | Random 128-bit salt per vault |

The salt is generated once at vault creation and stored alongside the encrypted data. It is never reused across vaults.

### Field Encryption

Individual sensitive fields are encrypted using **AES-256-GCM**:

| Parameter           | Value                   |
|---------------------|-------------------------|
| Algorithm           | AES-256-GCM             |
| IV                  | Random 96-bit IV per field |
| Authentication tag  | 128-bit                 |

Each field receives its own randomly generated IV, ensuring that identical plaintext values produce distinct ciphertexts.

### Payload Encryption

Encrypted payloads are serialized in the following binary format:

```
[IV (12 bytes)] || [Ciphertext + 16-byte MAC]
```

The authentication tag is appended by the AES-GCM cipher and verified on decryption. Any tampering with the ciphertext or IV causes decryption to fail with an authentication error.

### Database

The local database is encrypted at rest using **SQLCipher** with AES-256. The database key is derived from the vault master key and is never stored in plaintext.

### Secure Storage

Platform-native secure storage is used to hold sensitive key material:

| Platform      | Mechanism                        |
|---------------|----------------------------------|
| iOS / macOS   | Keychain                         |
| Android       | Android Keystore                 |
| Web           | SharedPreferences fallback       |

The web fallback provides a best-effort security layer. Users requiring strong security guarantees should use native platform builds.

### Sync

Cloud sync uses **end-to-end encrypted snapshots** in the AVV2 format. Snapshots contain an embedded salt and are encrypted client-side before transmission. The sync provider (Google Drive, WebDAV, etc.) never receives plaintext data or encryption keys.

---

## Supported Versions

| Version        | Supported |
|----------------|-----------|
| Latest release | Yes       |
| Older releases | No        |

We only backport security fixes to the latest release. Users are encouraged to keep OctarqVault updated.

---

## Security Assumptions

OctarqVault's security model relies on the following assumptions:

- **Master password strength**: The security of the vault is directly tied to the strength of the master password. A weak or guessable password significantly reduces protection even with strong key derivation parameters. Users should choose a long, unique passphrase.
- **Device integrity**: OctarqVault assumes the device it runs on has not been compromised at the OS or firmware level. A rooted/jailbroken device or one with a malicious kernel module undermines all application-layer security guarantees.
- **Trusted build environment**: The application binary is assumed to have been built from unmodified source or distributed through a trusted channel. A tampered binary could exfiltrate keys before encryption occurs.
- **Secure memory**: The application relies on the OS to protect process memory from other processes. In shared or virtualized environments, memory isolation is assumed to be enforced by the host.
- **Platform secure storage**: The guarantees provided by Keychain, Android Keystore, and similar mechanisms are assumed to hold. Hardware-backed key storage (e.g., Secure Enclave, StrongBox) is used where available.

---

## Out of Scope

The following are **not** considered in-scope for this security policy:

- **Social engineering**: Attacks that rely on deceiving the user into revealing their master password or granting access.
- **Physical attacks**: Attacks requiring physical access to an unlocked device, or hardware-level attacks such as cold-boot or side-channel attacks.
- **Third-party dependencies**: Vulnerabilities in packages or libraries that OctarqVault depends on but does not control. Please report those directly to the relevant upstream maintainers.
- **Denial of service**: Issues that only affect availability without compromising data confidentiality or integrity.
- **Theoretical vulnerabilities**: Reports without a realistic attack scenario or reproducible proof of concept.
