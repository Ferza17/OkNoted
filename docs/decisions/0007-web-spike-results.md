# 0007 — Web risk spike results (M1)

- Status: Accepted
- Date: 2026-10-30

## Context
Flutter Web + a Rust core compiled to WASM is the riskiest part of the stack (`tech-stack.md` §4). Before building features we had to prove, in the real web build, that we can (1) store data in SQLite on OPFS and keep it across reloads, (2) run Loro, and (3) connect two browser tabs through the relay and a WebRTC DataChannel.

The spike lives in `crates/ffi/src/api/spike.rs`, `crates/ffi/src/spike_db.rs`, `crates/ffi/src/spike_rtc.rs`, `crates/net-web/src/spike.rs`, `crates/relay`, and the Flutter screen `app/lib/features/spike/`. It was verified in headless Chrome against the release web build (`scripts/run-web.sh` flags), plus native unit tests and widget tests.

## Results

| Item | Result |
|---|---|
| SQLite in OPFS | ✅ 1,000 rows written, still present after a reload, 2,000 after a second write |
| Loro in WASM | ✅ create → edit → snapshot export → import → edit → update export/import merges (`Hello, WASM Loro!`) |
| Two tabs via relay + WebRTC | ✅ DataChannel `oknoted` opened, messages delivered both ways; relay logged only ids and byte sizes |

## Decision

**Where Rust runs on web.** flutter_rust_bridge runs plain functions on a Web Worker pool, `async fn` on the main thread (`spawn_local`), and `#[frb(sync)]` inline on the main thread. Its async futures need no `Send` on web. We rely on this:
- WebRTC and the relay WebSocket live on the **main thread** (async/sync functions): `RTCPeerConnection` does not exist in workers.
- SQLite lives on **one dedicated worker**: the OPFS sync-access-handle pool (`sqlite-wasm-vfs` `sahpool`) only installs in a `DedicatedWorkerGlobalScope`, its pool is owned per worker, and SQLite is compiled with `SQLITE_THREADSAFE=0`.

**Database actor.** A plain frb function (`spike_sqlite_init`) starts an actor with `spawn_local` on the worker that runs it; frb keeps pool workers alive, so the actor lives on. The actor installs `sahpool` as the default VFS and owns the only `rusqlite::Connection`. Every later call sends a boxed job over a `futures` channel and awaits a oneshot reply; cross-thread wakeups work because the build uses shared memory. `storage::wasm` (M6) keeps this shape.

**Libraries.** `rusqlite` 0.41 uses `sqlite-wasm-rs` 0.6 on `wasm32-unknown-unknown`, so the same rusqlite API serves native and web. OPFS comes from `sqlite-wasm-vfs` 0.3 (`sahpool`). `sqlite-wasm-rs` also offers SQLCipher / SQLite3MultipleCiphers builds — the candidate for M6's encryption at rest instead of a separate application-level layer.

**WebRTC.** Host candidates only (default `RTCPeerConnection` config, ADR 0006). ICE is not trickled: each side waits for gathering to finish (instant on a LAN) and sends one complete SDP, so signaling is exactly one offer and one answer and there is no candidate-before-description race. The newcomer to a room always offers, so offers never collide.

**Relay.** `crates/relay` implements `sync-protocol.md` §7 (join/signal/leave; peers/joined/left/signal; 16 KiB payload, 30 msg/s, 32 peers per room; in memory only). Message types live in `oknoted_core::signal` so relay and clients share them.

## Hazards found (must be handled before shipping web)

1. **One tab per profile owns the database.** A second tab of the same origin gets `NoModificationAllowedError` from `createSyncAccessHandle` while the first tab holds the pool. The web app needs a single active tab (Web Locks API leader election, other tabs show "open in another tab" or proxy through the leader) — decide in M6.
2. **frb `StreamSink` crosses tabs.** On web, frb's Dart side delivers stream events over `BroadcastChannel`s named with a per-page counter (`RustStreamSink__0`, …). Two same-origin tabs therefore receive each other's stream events. Observed in the spike (tab A showed tab B's events). Single-tab ownership (hazard 1) avoids it; otherwise report upstream and avoid `StreamSink` on web.
3. **Build requirements.** The web build needs nightly Rust with `rust-src` (frb builds `std` with atomics), `wasm-pack` 0.13.1 (newer needs Rust ≥ 1.91), clang with the wasm32 backend, and `CFLAGS_wasm32_unknown_unknown="-matomics -mbulk-memory"` so SQLite's C code matches the shared-memory build (`scripts/run-web.sh` sets it). Output is ~4 MB of WASM.
4. **Shared WASM memory limits some web APIs.** `crypto.getRandomValues` rejects views of shared memory; randomness on web must copy through a non-shared buffer (relevant for the `Rng` trait in M2).

## Deferred (spike shortcuts)
- Signaling payloads are plain JSON, not sealed with `HKDF(account_secret, "oknoted/v1/signal")` — M6, needs identity from M4.
- One peer connection per tab; errors cross the FFI boundary as plain strings, not the `code` + `message` type.
- Native WebRTC (`net-lan::webrtc`) is not part of the spike — M6.

## Alternatives considered
- Run SQLite on the main thread with an IndexedDB-backed VFS — works without a worker but loses OPFS durability/speed and blocks the UI on writes.
- Trickle ICE — faster connection setup on real networks, but needs candidate buffering; unnecessary for LAN host candidates.
- A JS-side SQLite (sqlite-wasm in JS) called from Dart — puts data access outside the Rust core, against golden rule 2.

## Consequences
- (+) All three web risks are retired; `storage`, `net-web` and `relay` keep the shapes proven here.
- (−) Web needs a single-tab policy and a heavier toolchain than native.
- (−) frb's web stream transport is a known multi-tab hazard to track.
