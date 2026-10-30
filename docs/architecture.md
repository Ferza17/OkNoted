# Architecture

## 1. Goals

| Goal | Design consequence |
|---|---|
| No server storing data | Data lives only on devices; peer-to-peer sync |
| No login | Account = cryptographic keypair derived from a seed phrase |
| Auto sync on LAN | mDNS discovery + direct device-to-device connections |
| Fully offline | All operations are local; network is only for sync |
| Concurrent edits without conflicts | CRDT (Loro) as the source of truth |
| One codebase | Flutter for UI on every platform, Rust for all logic |

### Non-goals (initial versions)

- Collaboration between **different accounts** (sharing a workspace with others).
- Sync over the internet (outside the LAN). The relay is only for web signaling, not for remote sync.
- Third-party plugins, AI, external service integrations.

## 2. Layers

```
┌──────────────────────────────────────────────────────┐
│ Flutter app (app/)                                   │
│  screens • widgets • Riverpod providers              │
└───────────────────────┬──────────────────────────────┘
                        │ flutter_rust_bridge (FFI / WASM)
┌───────────────────────▼──────────────────────────────┐
│ ffi (crates/ffi) — public API, wires dependencies    │
├──────────────────────────────────────────────────────┤
│ core (crates/core) — platform-agnostic               │
│  model • crdt • identity • crypto • sync • search    │
│  traits: Storage, Transport, Clock, Rng              │
├───────────────┬───────────────────┬──────────────────┤
│ storage       │ net-lan           │ net-web          │
│ SQLite native │ mDNS, QUIC,       │ WebRTC (web-sys) │
│ SQLite WASM   │ native WebRTC     │ signaling client │
└───────────────┴───────────────────┴────────┬─────────┘
                                             │ signaling (sealed)
                                   ┌─────────▼─────────┐
                                   │ relay (axum)      │
                                   └───────────────────┘
```

Implementation selection per platform (in `ffi`):

| Platform | Storage | Transport |
|---|---|---|
| Android, iOS, desktop | `storage::native` (rusqlite + SQLCipher) | `net-lan` (QUIC + native WebRTC) |
| Web | `storage::wasm` (SQLite WASM + OPFS) | `net-web` (WebRTC) |

## 3. Core components

| Module | Responsibility |
|---|---|
| `model` | Domain types: `Workspace`, `Page`, `Block`, `Database`, `View`, `Device` |
| `crdt` | Wraps `LoroDoc`: create/load documents, apply operations, export/import updates, version vectors |
| `identity` | Seed phrase → account keys; device keys; device certificates |
| `crypto` | AEAD for data & messages, sealed boxes for signaling, key derivation (HKDF) |
| `sync` | Sync engine: finds differing documents, sends/receives updates, per-peer status |
| `search` | Builds queries against the FTS index through the `Storage` trait |
| `backup` | Encrypted archive export/import, Markdown/JSON export |
| `index` | Updates derived tables (titles, tree, FTS) whenever a document changes |

## 4. Data flow

### 4.1 Local edit
```
User types
 → editor (Dart) produces block operations
 → ffi::page::apply_block_ops(page_id, ops)
 → core::crdt applies them to the page's LoroDoc
 → storage persists the update (doc_updates) + updates indexes
 → sync engine marks the document "dirty"
 → DocChanged event sent to Dart (origin = local)
 → if peers are connected: update is sent (see sync-protocol.md)
```

### 4.2 Update from another device
```
Transport receives an encrypted frame
 → sync engine decrypts & verifies the sender (device of the same account)
 → core::crdt imports the update into the LoroDoc
 → storage persists + updates indexes
 → DocChanged event (origin = remote) → UI updates the editor
```

### 4.3 Discovery & connection
```
Native: mDNS advertises _oknoted._udp with account_tag
 → other devices with the same account_tag try to connect (QUIC)
 → mutual-auth handshake (device certificate signed by the account key)
 → sync session

Web: connect to the relay (WSS), join room = account_tag
 → exchange offer/answer/ICE (sealed) with other native/web devices
 → WebRTC DataChannel (ICE host candidates = LAN path)
 → same handshake & sync session
```

## 5. Concurrency

- Native: one `tokio` runtime owned by `ffi`. Each active `LoroDoc` is owned by a single *actor* (task + channel), so no locks are held across awaits.
- Web: single-threaded, everything on the browser event loop.
- Native SQLite access: one write connection + a pool of read connections (WAL mode).

## 6. Errors & observability

- Domain errors from `core` are mapped in `ffi` to `{ code, message }`.
- `tracing` in every crate. In the app, users can export logs from settings for bug reports — without note content.

## 7. Glossary

| Term | Meaning |
|---|---|
| Account | Identity derived from a seed phrase; not registered on any server |
| Device | One app installation; has its own keypair certified by the account key |
| Workspace | The set of pages owned by one account |
| Document (doc) | One `LoroDoc`; the smallest unit of sync |
| Update | Binary Loro delta that is sent/stored |
| Version vector (VV) | Summary of the operations a document already contains |
| `account_tag` | Short public account identifier used for discovery (not a key) |
| Relay | WebRTC signaling server with no storage |
| Derived index | SQLite tables built from the CRDT for fast queries |
