//! Web `Transport`: WebRTC via web-sys plus the relay signaling client (full version in M6).
#![forbid(unsafe_code)]

#[cfg(target_arch = "wasm32")]
pub mod spike;
