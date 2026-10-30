# Roadmap

Work through the milestones in order. Each milestone has acceptance criteria that must be met before moving on. Tick items as they are completed.

## M0 — Repository foundation

- [ ] Cargo workspace with 6 empty crates that compile
- [ ] `rust-toolchain.toml`, `deny.toml`, `.gitignore`
- [ ] Empty Flutter app in `app/` with flutter_rust_bridge set up; a `greet()` function from Rust is shown on screen
- [ ] `scripts/codegen.sh`, `scripts/run-web.sh`
- [ ] CI: `rust.yml` (fmt, clippy, test, wasm check, deny) and `flutter.yml` (analyze, test)
- [ ] LICENSE, README, CONTRIBUTING, CODE_OF_CONDUCT, SECURITY

**Accepted when:** `greet()` runs on desktop **and** web; CI is green.

## M1 — Web risk spike (required before features)

- [ ] SQLite WASM + OPFS from Rust in Flutter Web: write & read 1,000 rows, persisted across reloads
- [ ] Loro runs in WASM: create a document, edit, export/import
- [ ] Two browser tabs connected via a local relay + WebRTC DataChannel, exchanging messages
- [ ] Record results & decisions in an ADR

**Accepted when:** all three work, or an ADR explains the alternative.

## M2 — Core & storage

- [ ] `Storage`, `Transport`, `Clock`, `Rng` traits + in-memory implementations (`test-util`)
- [ ] `crdt`: workspace & page documents per `data-model.md`
- [ ] `BlockOp` applied to Loro, with UTF-16 index conversion
- [ ] `storage::native` (rusqlite + SQLCipher) with migration V1
- [ ] Derived indexes + FTS5, index rebuild command
- [ ] Update compaction

**Accepted when:** the proptest "random operations on 3 replicas converge" passes; a full index rebuild yields the same content as the incremental index.

## M3 — Desktop editor (no sync)

- [ ] ffi API: workspace, page, block ops, `DocChanged` stream
- [ ] Sidebar page tree (create, rename, move, delete to trash)
- [ ] appflowy_editor block editor wired to Rust (paragraph, heading, list, to-do, code, quote, divider)
- [ ] Title & content search
- [ ] l10n EN/ID, light/dark theme

**Accepted when:** a user can write notes, close the app, reopen it, and everything is intact.

## M4 — Identity & native LAN sync

- [ ] Onboarding: create account (seed phrase) & restore
- [ ] `DeviceCert`, Noise XX handshake
- [ ] mDNS discovery + QUIC
- [ ] Sync engine per `sync-protocol.md` (summary, request, update, ack, live mode)
- [ ] Devices screen: per-peer sync status

**Accepted when:** two desktops on the same LAN, edited offline concurrently, converge within 5 seconds of connecting.

## M5 — Mobile

- [ ] Android: permissions, multicast lock, build via cargo-ndk
- [ ] iOS: Local Network & Bonjour permissions, sync while the app is active
- [ ] QR pairing (scan from mobile)
- [ ] Mobile layout

**Accepted when:** a phone and a laptop sync both ways on home Wi-Fi.

## M6 — Web

- [ ] `storage::wasm` with application-level encryption
- [ ] `net-web` + production relay (rate limits, size limits)
- [ ] Native WebRTC (`net-lan::webrtc`) so web ↔ native can sync
- [ ] Relay Dockerfile, static web deployment

**Accepted when:** a browser tab and a desktop sync on the same LAN via the relay.

## M7 — Databases (Notion-style)

- [ ] Columns: text, number, select, multi-select, date, checkbox, url
- [ ] Table view (filter, sort) and kanban
- [ ] Calendar view

## M8 — 1.0 release

- [ ] Image attachments (blob sync)
- [ ] Automatic encrypted backups + Markdown/JSON export
- [ ] Device revocation
- [ ] Release pipeline for all platforms, F-Droid
- [ ] Light external security review

## After 1.0 (ideas)

- Sharing a workspace with other accounts
- Sync through a folder (Syncthing/USB drive) as an alternative path
- Account rotation
- Page templates, import from Notion/Markdown
