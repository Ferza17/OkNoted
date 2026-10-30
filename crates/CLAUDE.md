# CLAUDE.md — Rust crates

Applies to all code in `crates/`. The rules in `/CLAUDE.md` still apply.

## Dependency graph (never break this)

```
core  ◄── storage
  ▲   ◄── net-lan
  │   ◄── net-web
  │   ◄── relay (signaling message types only)
  └────── ffi (wires core + storage + net-*)
```

- `core` depends on no other internal crate.
- `storage`, `net-lan`, and `net-web` do not depend on each other.
- Only `ffi` chooses concrete implementations.

## Crate names

| Folder | Package name |
|---|---|
| `crates/core` | `oknoted-core` |
| `crates/storage` | `oknoted-storage` |
| `crates/net-lan` | `oknoted-net-lan` |
| `crates/net-web` | `oknoted-net-web` |
| `crates/ffi` | `oknoted-ffi` |
| `crates/relay` | `oknoted-relay` |

Shared dependencies are declared once in `[workspace.dependencies]` in the root `Cargo.toml` and referenced with `dep = { workspace = true }`.

## Compilation targets

| Crate | native | wasm32-unknown-unknown |
|---|---|---|
| core | ✅ | ✅ required |
| storage | ✅ (`native.rs`) | ✅ (`wasm.rs`) |
| net-lan | ✅ | ❌ |
| net-web | ❌ | ✅ |
| ffi | ✅ | ✅ |
| relay | ✅ | ❌ |

Use `#[cfg(target_arch = "wasm32")]` / `#[cfg(not(target_arch = "wasm32"))]` only in `storage`, `ffi`, and the `lib.rs` of the net crates.

## Async

- `core` defines **runtime-agnostic** async traits. Never use `tokio::spawn` in `core`; accept a `Spawner` parameter if needed.
- Native uses `tokio` (multi-threaded). Web uses `wasm-bindgen-futures`.
- The cross-target trait pattern is defined in `docs/decisions/0005-async-traits.md`. Follow that ADR; do not invent a new pattern.

## Errors

- Each crate has an `error.rs` with an `Error` enum (thiserror) and `pub type Result<T> = std::result::Result<T, Error>;`.
- Errors returned to Dart are converted in `ffi` into a simple type (`code` + `message`). Never expose raw internal errors.
- Error messages must never contain note content or key material.

## Code style

- `#![forbid(unsafe_code)]` in every crate except `ffi`.
- `#![warn(missing_docs)]` in `core`.
- IDs are newtypes: `PageId(Uuid)`, `DeviceId([u8; 32])`, `DocId(Uuid)`. Never pass raw `String`s as IDs.
- Secrets are wrapped in `zeroize::Zeroizing` and never implement a `Debug` that prints their contents.
- Wire serialization: `postcard`. Export/backup: `serde_json`.
- Time and randomness only through the `Clock` and `Rng` traits in `core`, so tests are deterministic.

## Testing

- Unit tests live in the same module (`#[cfg(test)]`).
- Integration tests live in `crates/<crate>/tests/`.
- CRDT & sync: use `proptest` to simulate many peers with random message ordering, duplicated messages, and dropped messages. Core property: **all peers converge to the same state**.
- `core` provides `MemoryStorage`, `MemoryTransport`, `FixedClock`, and `SeededRng` behind the `test-util` feature.
- Snapshot tests (`insta`) for export formats and protocol message encoding.

## ffi (flutter_rust_bridge)

- Only functions in `crates/ffi/src/api/**` are exposed to Dart.
- Types crossing the FFI boundary must be plain data (structs/enums). Never expose Loro types or internal handles.
- Continuous events (sync status, document changes) are sent through `StreamSink`.
- Heavy operations (import, index rebuild) must be async so the UI never freezes.
- After changes: run `./scripts/codegen.sh` and commit the output.

## relay

- No persistent storage. State lives only in memory with a TTL.
- Per-connection rate limits and message size limits are mandatory (see `docs/sync-protocol.md` §7).
- The relay can never read payloads: they are sealed by clients.
