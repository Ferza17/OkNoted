# Tech Stack

A Notion-like, open source, **local-first** note-taking app with no server login.
Devices of the same account sync automatically over the local network (LAN).

Target platforms: **Android, iOS, Windows, macOS, Linux, Web** — all from **one Flutter codebase** + **one Rust core**.

---

## 1. Architecture summary

```
┌─────────────────────────────────────────────┐
│ Flutter UI (mobile, desktop, web)           │
│  editor • sidebar • database • devices      │
└──────────────────┬──────────────────────────┘
                   │ flutter_rust_bridge (FFI / WASM)
┌──────────────────▼──────────────────────────┐
│ Rust Core                                   │
│  model • CRDT (Loro) • identity • crypto    │
│  sync protocol • search • backup            │
├──────────────┬──────────────┬───────────────┤
│ Storage      │ Network LAN  │ Network Web   │
│ SQLite       │ mDNS + QUIC  │ WebRTC        │
└──────────────┴──────────────┴───────┬───────┘
                                      │ signaling only
                          ┌───────────▼─────────┐
                          │ Rust Relay (axum)   │
                          │ stores no data      │
                          └─────────────────────┘
```

---

## 2. Core choices

| Layer | Technology | Rationale |
|---|---|---|
| Core | **Rust** | Memory safety, performance, one logic for all platforms |
| Web relay | **Rust** | Lightweight signaling server, self-hostable |
| Database | **SQLite** | Local storage on every device |
| Mobile | **Flutter + Rust** | Android & iOS |
| Web | **Flutter Web** | Rust core compiled to WASM |
| Desktop | **Flutter Desktop** | Windows, macOS, Linux |

---

## 3. Supporting technologies

### 3.1 Flutter ↔ Rust bridge
| Need | Choice | Rationale |
|---|---|---|
| Dart ↔ Rust bindings | **flutter_rust_bridge v2** | Generated bindings, supports native (FFI) and web (WASM), async, streams |
| Building Rust inside Flutter | **cargokit** (bundled with frb) | Builds Rust automatically during `flutter build` |
| Android builds | **cargo-ndk** | Cross-compiles to Android ABIs |

### 3.2 CRDT (conflict-free merging) — **most important**
| Option | Notes |
|---|---|
| **Loro** (chosen) | Written in Rust, has *rich text* and a *movable tree* — fits a Notion-style block/page structure |
| yrs (Yjs in Rust) | Alternative, large Yjs ecosystem |
| Automerge | Alternative, mature, somewhat heavier |

> Without a CRDT, two devices editing the same page offline would overwrite each other.

### 3.3 Block editor (Flutter)
| Option | Notes |
|---|---|
| **appflowy_editor** (chosen) | Open source block editor used by AppFlowy, already Notion-style |
| super_editor | Alternative, very flexible |

> Needs an adapter layer: editor operations ⇄ Loro CRDT operations.

### 3.4 Networking
| Need | Choice | Notes |
|---|---|---|
| Async runtime | **tokio** | De facto Rust standard |
| LAN discovery | **mdns-sd** | Finds other devices on the same network |
| Native ↔ native transport | **quinn (QUIC)** | Fast, built-in encryption & multiplexing |
| Web ↔ anyone transport | **WebRTC** (`web-sys` in WASM) | Browsers cannot do mDNS or open sockets |
| **Native WebRTC** | **webrtc-rs** or **str0m** | ⚠️ Often forgotten: lets native devices sync with the web version |
| Relay / signaling | **axum** + WebSocket | Only introduces peers; data stays P2P on the LAN |

> Note: an HTTPS web page **cannot** connect to `ws://192.168.x.x` (blocked as *mixed content*). That is why the web path must use WebRTC.

### 3.5 Identity & security (replacing login)
| Need | Choice |
|---|---|
| Account & device identity | **ed25519-dalek** (keypairs) |
| Account recovery seed phrase | **bip39** |
| Sync channel encryption | **snow** (Noise Protocol) |
| Data encryption | **chacha20poly1305** |
| Database encryption at rest | **SQLCipher** (`bundled-sqlcipher` feature of rusqlite) |
| On-device key storage | **flutter_secure_storage** (Keychain/Keystore) |
| Device pairing | QR code: **mobile_scanner** + **qr_flutter** |

### 3.6 Database & data
| Need | Choice |
|---|---|
| Native SQLite | **rusqlite** (`bundled`) |
| Web SQLite | **sqlite-wasm-rs** + OPFS (prototype early) |
| Schema migrations | **rusqlite_migration** |
| Full-text search | **SQLite FTS5** |
| Serialization | **serde** + **postcard** (wire) + **serde_json** (export) |
| Unique IDs | **uuid** v7 |
| Content hashing | **blake3** |

### 3.7 Flutter (UI side)
| Need | Choice |
|---|---|
| State management | **Riverpod** |
| Routing | **go_router** |
| Localization | **flutter_localizations** + **intl** (EN & ID) |
| Lint | **flutter_lints** / **very_good_analysis** |

### 3.8 Quality & observability
| Need | Choice |
|---|---|
| Error handling | **thiserror** (libraries), **anyhow** (binaries) |
| Logging | **tracing** + **tracing-subscriber** |
| Rust tests | `cargo test`, **proptest** (randomized CRDT/sync tests), **insta** (snapshots) |
| Flutter tests | `flutter test`, `integration_test` |
| Rust lint | **clippy**, **rustfmt** |
| Dependency audit | **cargo-deny**, **cargo-audit** |

### 3.9 Build, release & distribution
| Need | Choice |
|---|---|
| CI/CD | **GitHub Actions** (per-platform matrix) |
| Relay deployment | **Docker** + docker-compose |
| Web hosting | Static hosting (GitHub Pages / Cloudflare Pages) |
| Desktop releases | GitHub Releases (`.msi`, `.dmg`, `.AppImage`) |
| Android releases | Play Store + **F-Droid** (important for the open source community) |
| iOS releases | App Store (requires an Apple Developer account) |

### 3.10 Platform permissions (don't forget)
| Platform | What to configure |
|---|---|
| iOS | `NSLocalNetworkUsageDescription`, `NSBonjourServices` in `Info.plist` |
| Android | `INTERNET`, `ACCESS_WIFI_STATE`, `CHANGE_WIFI_MULTICAST_STATE` (multicast lock for mDNS) |
| macOS | `network.client` & `network.server` entitlements |
| Web | COOP/COEP headers when WASM needs threads (SharedArrayBuffer) |

### 3.11 Open source project
| Need | Choice |
|---|---|
| License | **AGPL-3.0** (prevents closed forks) or **MIT/Apache-2.0** (more permissive) |
| Community docs | README, CONTRIBUTING, CODE_OF_CONDUCT, SECURITY |
| Protocol spec | `docs/sync-protocol.md` so others can build clients |

---

## 4. Risks to watch

1. **Flutter Web + Rust WASM** is the riskiest part — prototype it first (SQLite WASM + WebRTC).
2. **Flutter Web initial download size** is large; fine for an app, not for SEO.
3. **iOS does not allow free background sync** — sync happens while the app is open.
4. **Public/office Wi-Fi** often blocks device-to-device traffic (*client isolation*).
5. **No server = no backup** — provide automatic backup/export from the first version.
