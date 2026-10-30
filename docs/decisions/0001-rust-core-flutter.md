# 0001 — Rust core + Flutter for all platforms

- Status: Accepted
- Date: 2026-10-30

## Context
The app must run on Android, iOS, Windows, macOS, Linux, and Web, and is developed by a small open source team. Sync and crypto logic must be identical on every platform and free of memory-safety bugs.

## Decision
- All logic (model, CRDT, sync, crypto, storage) is written in Rust.
- The UI for every platform is written in Flutter.
- They are connected with flutter_rust_bridge v2 (FFI on native, WASM on web).

## Alternatives considered
- Tauri + web UI — Tauri's mobile story is less mature than Flutter's.
- Pure Dart — sync/crypto in Dart is slower and cannot be reused by the relay.
- Kotlin Multiplatform — web & desktop support is less mature for this use case.

## Consequences
- (+) One logic layer, tested once, memory-safe.
- (+) One UI codebase.
- (−) More complex builds (cargo-ndk, WASM, codegen).
- (−) Flutter Web + Rust WASM is the riskiest area → validated in milestone M1.
