# CLAUDE.md — NoteSync

Primary guide for coding agents. Read this file first, then the documents in `docs/` that are relevant to your task.

## What this project is

NoteSync is a Notion-like note-taking app that is **open source**, **local-first**, and requires **no login to any server**.
Data lives only on the user's devices. Devices belonging to the same account **sync automatically when they are on the same local network (LAN)**.

- Platforms: Android, iOS, Windows, macOS, Linux, Web — **one Flutter app** in `app/`.
- Logic: **one Rust core** in `crates/`, called from Flutter via **flutter_rust_bridge v2** (FFI on native, WASM on web).
- Status: **greenfield**. Follow the milestone order in `docs/roadmap.md`.

## Golden rules (never break these)

1. **No server stores user data.** `crates/relay` only forwards WebRTC signaling messages that are already encrypted (sealed). The relay must not have a database.
2. **All business logic lives in Rust.** Dart is only for UI, navigation, and view state. Do not write sync, CRDT, crypto, or data-query logic in Dart.
3. **`crates/core` must be platform-agnostic** and must compile to `wasm32-unknown-unknown`. Forbidden in `core`: `tokio`, `std::fs`, `std::net`, `std::thread`, `rusqlite`. I/O happens only through the `Storage`, `Transport`, `Clock`, and `Rng` traits.
4. **The CRDT (Loro) is the source of truth.** SQLite tables other than `docs` / `doc_updates` / `blobs` are derived indexes that must be rebuildable from the CRDT at any time.
5. **Never log note content, seed phrases, or keys.** Log only IDs, sizes, durations, and statuses.
6. **Sync protocol changes** must update `docs/sync-protocol.md` and bump `PROTOCOL_VERSION`. SQLite schema changes must be a new migration file (never edit an existing migration).
7. **`unsafe` is forbidden** in `core`, `storage`, `net-*`, and `relay` (`#![forbid(unsafe_code)]`). The only exception is `ffi`, where codegen may require it.
8. **Never edit generated code**: `app/lib/src/rust/**` and `crates/ffi/src/frb_generated.rs`. Change the source, then run codegen.

## Repository map

```
crates/core       model, CRDT (Loro), identity, crypto, sync engine, I/O traits
crates/storage    Storage implementations: rusqlite (native) & sqlite-wasm-rs (web)
crates/net-lan    native Transport: mDNS discovery, QUIC, WebRTC (for web peers)
crates/net-web    web Transport: WebRTC via web-sys + signaling client
crates/ffi        public API for Dart (flutter_rust_bridge); wires all crates together
crates/relay      signaling server (axum), separate binary
app/              Flutter app for all platforms
docs/             architecture, protocol, security, roadmap, ADRs
deploy/relay      relay Dockerfile
scripts/          build & codegen scripts
```

Full details: `docs/folder-structure.md`.

## Commands

| Purpose | Command |
|---|---|
| Build & test all crates | `cargo test --workspace` |
| Rust lint (must be clean) | `cargo clippy --workspace --all-targets -- -D warnings` |
| Format Rust | `cargo fmt --all` |
| Check core compiles to WASM | `cargo check -p notesync-core --target wasm32-unknown-unknown` |
| Dependency audit | `cargo deny check` |
| Generate Dart↔Rust bindings | `./scripts/codegen.sh` |
| Run desktop app | `cd app && flutter run -d macos` (or `windows` / `linux`) |
| Run web app | `./scripts/run-web.sh` |
| Flutter tests | `cd app && flutter test` |
| Dart analysis | `cd app && dart analyze` |
| Run relay locally | `cargo run -p notesync-relay` |

After changing anything in `crates/ffi/src/api/**`, you **must** run `./scripts/codegen.sh` before running the app.

## Conventions

**Language**
- Everything in the repository is in **English**: code, identifiers, comments, commit messages, and documentation.
- UI text goes through `app/lib/l10n/*.arb` (English and Indonesian), never hardcoded.

**Rust** (details: `crates/CLAUDE.md`)
- Library errors: `thiserror`; binary/test errors: `anyhow`.
- No `unwrap()` / `expect()` in production code, except for invariants explained in a comment.
- Logging via `tracing`. Every public item has a doc comment.

**Flutter** (details: `app/CLAUDE.md`)
- State: Riverpod. Routing: go_router. Feature-first structure in `lib/features/<feature>/`.

**Git**
- Conventional Commits: `feat(core): ...`, `fix(app): ...`, `docs: ...`, `refactor(storage): ...`.
- One PR = one coherent change.

## How the agent is expected to work

1. Read the relevant documents before writing code:
   - touching the data model or CRDT → `docs/data-model.md`
   - touching sync, networking, or the relay → `docs/sync-protocol.md`
   - touching keys, encryption, or pairing → `docs/security.md`
   - starting a new feature → `docs/roadmap.md`
2. For tasks spanning more than one crate, or changing the protocol/schema, **plan first** and list the files you will change.
3. Work in small steps. Write tests first for CRDT and sync logic.
4. Before declaring a task done, run the commands in *Definition of Done*.
5. When you make a new architectural decision, add an ADR in `docs/decisions/`.
6. If a task's instructions conflict with the golden rules, stop and ask.

## Definition of Done

- [ ] `cargo fmt --all` and `cargo clippy ... -D warnings` are clean
- [ ] `cargo test --workspace` passes
- [ ] `cargo check -p notesync-core --target wasm32-unknown-unknown` passes
- [ ] If Dart changed: `dart analyze` is clean and `flutter test` passes
- [ ] If the ffi API changed: codegen has been run and its output is committed
- [ ] Docs in `docs/` are updated if behavior, protocol, or schema changed

## Document index

| Document | Contents |
|---|---|
| `docs/architecture.md` | System overview, layers, data flow, glossary |
| `docs/data-model.md` | Entities, Loro document layout, SQLite schema |
| `docs/sync-protocol.md` | Discovery, handshake, sync messages, relay |
| `docs/security.md` | Threat model, key derivation, pairing |
| `docs/development.md` | Dev environment setup per platform |
| `docs/roadmap.md` | Milestones and acceptance criteria |
| `docs/tech-stack.md` | Technologies and rationale |
| `docs/folder-structure.md` | Full folder structure |
| `docs/decisions/` | Architecture Decision Records (ADRs) |