# Security

## 1. Threat model

| Attacker | What is protected | How |
|---|---|---|
| Others on the same Wi-Fi | Note content, account metadata | Channel encryption (Noise), mutual auth, rotating `account_tag` |
| Relay operator | Note content & signaling | The relay never receives data; signaling is sealed |
| Thief with a locked device | Local database | SQLCipher with the key in Keychain/Keystore |
| Lost old device | Future sync access | Device revocation (`revoked`) |
| Malicious dependency | Build integrity | `cargo-deny`, `cargo-audit`, committed lockfile |

Out of scope: rooted/jailbroken devices controlled by an attacker while unlocked; malware on the user's OS.

## 2. Keys

```
seed phrase (BIP39, 24 words, 256-bit entropy)
  └─ seed = BIP39 seed (PBKDF2, no passphrase by default)
       └─ account_secret = HKDF-SHA256(seed, info="notesync/v1/account")
            ├─ account_key (Ed25519)        = HKDF(account_secret, "notesync/v1/sign")
            ├─ account_tag (16 bytes)       = HKDF(account_secret, "notesync/v1/account-tag" [+ date])
            ├─ signal_key  (32 bytes)       = HKDF(account_secret, "notesync/v1/signal")
            └─ backup_key  (32 bytes)       = HKDF(account_secret, "notesync/v1/backup")

device_key (Ed25519)   = random per installation, never leaves the device
noise_static (X25519)  = random per installation
db_key (32 bytes)      = random per installation, kept in secure storage
```

### Device certificate

```rust
struct DeviceCert {
    account_id: [u8; 32],     // account_key public key
    device_id: [u8; 32],      // device_key public key
    device_name: String,
    issued_at: i64,
    signature: [u8; 64],      // account_key signature over the fields above
}
```

## 3. Key storage

| Platform | Location |
|---|---|
| iOS / macOS | Keychain (`flutter_secure_storage`) |
| Android | Android Keystore (`flutter_secure_storage`) |
| Windows | DPAPI / Credential Manager |
| Linux | libsecret; if unavailable, an encrypted file with a warning |
| Web | IndexedDB, wrapped with a non-exportable `CryptoKey` (WebCrypto). Users must be told that web security is weaker. |

Is `account_secret` stored on the device? **Yes**, in secure storage, because it is needed to certify new devices during pairing. The seed phrase itself is not stored; it is shown once during onboarding.

## 4. Onboarding & pairing

### New account
1. Generate a 24-word seed phrase, show it, and ask the user to confirm 3 random words.
2. Derive all keys, create the `device_key`, issue its own `DeviceCert`.
3. Create an empty `workspace` document.

### Adding a device (QR pairing)
1. The new device (B) creates a `device_key` and shows a QR code containing: `device_id`, an ephemeral X25519 key, device name, LAN address (if any).
2. The existing device (A) scans the QR code and shows a 6-digit verification code on both screens (derived from the transcript).
3. The user confirms the codes match on both screens.
4. A sends B, over the encrypted channel: `account_secret` and B's `DeviceCert`.
5. A adds B to `workspace.devices`. Sync starts.

Alternative: enter the seed phrase on the new device (for recovery when no old device is available).

### Revoking a device
- Set `devices[id].revoked = true` in the workspace document; other peers reject handshakes from that device.
- Limitation to explain to users: a revoked device still holds `account_secret` and any data already synced. For a full cut-off, the user must create a new account and migrate data ("account rotation" is on the roadmap).

## 5. Data at rest

- Native: the whole database is encrypted with SQLCipher using `db_key`.
- Web: SQLite WASM in OPFS without SQLCipher in the initial version; the `snapshot` and `data` columns are encrypted at the application level with ChaCha20-Poly1305 before being written.
- Backups: exported archives are encrypted with `backup_key` (XChaCha20-Poly1305), so they can be restored with only the seed phrase.

## 6. Rules for contributors

- Never implement crypto primitives yourself; use the RustCrypto / dalek / snow crates.
- All secrets are wrapped in `Zeroizing`, never printed in logs, never included in error messages.
- MAC/tag comparisons must be constant-time (already handled by the AEAD crates).
- Any change to `identity`, `crypto`, or the handshake must carry the `security` label on the PR and be reviewed by two people.
- Vulnerability reports: see `SECURITY.md`.
