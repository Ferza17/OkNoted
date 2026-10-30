#!/usr/bin/env bash
# Generate Dart <-> Rust bindings from crates/ffi/src/api/** (config: app/flutter_rust_bridge.yaml).
set -euo pipefail
cd "$(dirname "$0")/../app"
flutter_rust_bridge_codegen generate "$@"
# frb formats with the 2021 style; reformat so `cargo fmt --check` (edition 2024) stays clean.
cargo fmt -p oknoted-ffi
