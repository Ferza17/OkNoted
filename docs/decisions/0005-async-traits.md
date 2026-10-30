# 0005 — Async trait pattern across native & WASM

- Status: Accepted
- Date: 2026-10-30

## Context
`core` defines the `Storage` and `Transport` traits, implemented on native (tokio, multi-threaded, needs `Send`) and on WASM (single-threaded; web-sys types are not `Send`).

## Decision
- Use `async fn` in traits (stable Rust) with a conditional bound alias:

```rust
#[cfg(not(target_arch = "wasm32"))]
pub trait MaybeSend: Send {}
#[cfg(not(target_arch = "wasm32"))]
impl<T: Send> MaybeSend for T {}

#[cfg(target_arch = "wasm32")]
pub trait MaybeSend {}
#[cfg(target_arch = "wasm32")]
impl<T> MaybeSend for T {}
```

- I/O traits are written as `-> impl Future<Output = ...> + MaybeSend` with `Self: MaybeSend + MaybeSync`.
- The engine uses generics rather than trait objects (`dyn Storage`), avoiding object-safety issues.
- `core` never spawns tasks; if needed it accepts a `Spawner` trait.

## Alternatives considered
- `async_trait` with `?Send` everywhere — easy, but allocates a `Box` per call and loses `Send` on native.
- Two separate trait sets — duplicated logic.

## Consequences
- (+) One engine codebase for both targets, with no extra allocations.
- (−) Slightly longer trait signatures; follow the example in `crates/core/src/storage.rs`.
