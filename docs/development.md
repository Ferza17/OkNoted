# Development Setup

## 1. Prerequisites

| Tool | Minimum version | Notes |
|---|---|---|
| Rust | latest stable (pinned in `rust-toolchain.toml`) | via `rustup` |
| Flutter | latest stable | stable channel |
| flutter_rust_bridge_codegen | v2 | `cargo install flutter_rust_bridge_codegen` |
| cargo-deny | latest | `cargo install cargo-deny` |
| Docker | optional | to run the relay |

Additional Rust targets:

```bash
rustup target add wasm32-unknown-unknown
# Android
rustup target add aarch64-linux-android armv7-linux-androideabi x86_64-linux-android
cargo install cargo-ndk
# iOS (macOS only)
rustup target add aarch64-apple-ios aarch64-apple-ios-sim
```

## 2. Per platform

| Platform | Additional requirements |
|---|---|
| macOS / iOS | Xcode, CocoaPods |
| Android | Android Studio, NDK (version per `app/android/app/build.gradle`), set `ANDROID_NDK_HOME` |
| Windows | Visual Studio Build Tools (C++ workload) |
| Linux | `clang cmake ninja-build pkg-config libgtk-3-dev libsecret-1-dev` |
| Web | Chrome; `wasm-pack` is not needed (handled by frb) |

## 3. First run

```bash
git clone <repo> oknoted && cd oknoted
cargo build --workspace
./scripts/codegen.sh
cd app
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter run -d macos     # or windows / linux
```

## 4. Web

The web build needs these headers so SQLite WASM (OPFS) and threads work:

```
Cross-Origin-Opener-Policy: same-origin
Cross-Origin-Embedder-Policy: require-corp
```

`./scripts/run-web.sh` builds the WASM and runs `flutter run -d chrome` with the headers above.

To test web sync, run a local relay:

```bash
cargo run -p oknoted-relay -- --listen 127.0.0.1:8787
```

## 5. Testing sync between devices

- Two desktop instances on one machine: run them with different data directories,
  `OKNOTED_DATA_DIR=/tmp/a flutter run -d macos` and `OKNOTED_DATA_DIR=/tmp/b ...`.
- Automated tests without networking: `cargo test -p oknoted-core --features test-util sync::`.
- Android emulators often don't forward multicast. Use physical devices on the same Wi-Fi to test mDNS.

## 6. Scripts

| Script | Purpose |
|---|---|
| `scripts/codegen.sh` | Generate Dart ↔ Rust bindings |
| `scripts/run-web.sh` | Build WASM + run web dev with COOP/COEP headers |
| `scripts/build-web.sh` | Production web build into `app/build/web` |
| `scripts/build-android.sh` | Build Rust for all ABIs + APK |

## 7. Environment variables

| Variable | Purpose |
|---|---|
| `OKNOTED_DATA_DIR` | Override the database location (dev) |
| `RUST_LOG` | Log level, e.g. `oknoted_core=debug,oknoted_net_lan=trace` |
| `OKNOTED_RELAY_URL` | Relay URL for web builds (default: local relay in debug) |

## 8. Troubleshooting

| Symptom | Fix |
|---|---|
| "symbol not found" after changing the API | Run `./scripts/codegen.sh`, then do a full rebuild |
| Devices don't discover each other | Check firewall (UDP 5353 & the QUIC port), router client isolation, Local Network permission (iOS) |
| Web: `SharedArrayBuffer is not defined` | COOP/COEP headers are missing |
| Android Rust build fails | Make sure `ANDROID_NDK_HOME` and `cargo-ndk` are installed |
