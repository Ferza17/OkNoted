//! M0 smoke-test API proving the Dart <-> Rust bridge works on every platform.

/// Returns a greeting for `name`. Shown on the app's first screen.
#[flutter_rust_bridge::frb(sync)]
pub fn greet(name: String) -> String {
    format!("Hello, {name}!")
}

/// Called once by `RustLib.init()` before any other API call.
#[flutter_rust_bridge::frb(init)]
pub fn init_app() {
    flutter_rust_bridge::setup_default_user_utils();
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn greet_formats_name() {
        assert_eq!(greet("OkNoted".into()), "Hello, OkNoted!");
    }
}
