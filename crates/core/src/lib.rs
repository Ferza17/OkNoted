//! OkNoted core: model, CRDT, identity, crypto, and sync engine.
//!
//! Platform-agnostic: must compile to `wasm32-unknown-unknown`. All I/O goes
//! through the `Storage`, `Transport`, `Clock`, and `Rng` traits (added in M2).
#![forbid(unsafe_code)]
#![warn(missing_docs)]
