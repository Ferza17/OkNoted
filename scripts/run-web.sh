#!/usr/bin/env bash
# Build crates/ffi to WASM (into app/web/pkg) and run the web app with the
# COOP/COEP headers that SharedArrayBuffer (WASM threads, OPFS) requires.
set -euo pipefail
cd "$(dirname "$0")/../app"
# frb builds WASM with shared memory; SQLite's C code (sqlite-wasm-rs) must match it.
export CFLAGS_wasm32_unknown_unknown="-matomics -mbulk-memory"
flutter_rust_bridge_codegen build-web --rust-root ../crates/ffi --release
flutter run -d chrome \
  --web-header=Cross-Origin-Opener-Policy=same-origin \
  --web-header=Cross-Origin-Embedder-Policy=require-corp \
  "$@"
