//! M1 web risk spike: SQLite in OPFS, Loro in WASM, and WebRTC between tabs
//! (see ADR 0007). Replaced by the real APIs from M2 on.
//!
//! On web, frb runs plain functions on a Web Worker, `async` functions on the
//! main thread, and `sync` functions inline on the main thread. Each function's
//! kind below is chosen for the thread it needs.

use loro::{ExportMode, LoroDoc};

use crate::frb_generated::StreamSink;
use crate::spike_db;

/// Starts the database. Keep it a plain function: on web it must run on a Web Worker.
pub fn spike_sqlite_init() -> Result<(), String> {
    spike_db::init()
}

/// Inserts `rows` rows and returns the total row count.
pub async fn spike_sqlite_insert(rows: u32) -> Result<u64, String> {
    spike_db::run(move |conn| spike_db::insert_rows(conn, rows)).await
}

/// Reads every row back and returns how many there are.
pub async fn spike_sqlite_count() -> Result<u64, String> {
    spike_db::run(spike_db::read_rows).await
}

/// Creates a Loro document, edits it, exports a snapshot, imports it into a second
/// document, edits that one, syncs the update back, and returns the merged text.
#[flutter_rust_bridge::frb(sync)]
pub fn spike_loro_roundtrip() -> Result<String, String> {
    let original = LoroDoc::new();
    let text = original.get_text("page");
    text.insert(0, "Hello Loro").map_err(|e| e.to_string())?;
    text.insert(5, ", WASM").map_err(|e| e.to_string())?;
    original.commit();

    let snapshot = original
        .export(ExportMode::Snapshot)
        .map_err(|e| e.to_string())?;
    let copy = LoroDoc::new();
    copy.import(&snapshot).map_err(|e| e.to_string())?;
    let copy_text = copy.get_text("page");
    copy_text
        .insert(copy_text.len_unicode(), "!")
        .map_err(|e| e.to_string())?;
    copy.commit();

    let update = copy
        .export(ExportMode::updates(&original.oplog_vv()))
        .map_err(|e| e.to_string())?;
    original.import(&update).map_err(|e| e.to_string())?;
    let (merged, other) = (original.get_text("page").to_string(), copy_text.to_string());
    if merged != other {
        return Err("documents diverged after import".into());
    }
    Ok(merged)
}

/// WebRTC spike progress, streamed to Dart.
pub enum SpikeRtcEvent {
    /// Joined the room as `me`.
    Joined { me: String },
    /// Another peer joined.
    PeerJoined { peer: String },
    /// A peer left.
    PeerLeft { peer: String },
    /// DataChannel to `peer` is open.
    Connected { peer: String },
    /// Text received from the peer.
    Message { text: String },
    /// Relay connection or DataChannel closed.
    Closed,
    /// Something failed.
    Error { message: String },
}

/// Joins `room` on the relay at `relay_url` and streams progress into `events`.
/// Async so that on web it runs on the main thread, where `RTCPeerConnection` exists.
pub async fn spike_webrtc_connect(
    relay_url: String,
    room: String,
    events: StreamSink<SpikeRtcEvent>,
) -> Result<(), String> {
    crate::spike_rtc::connect(&relay_url, &room, events)
}

/// Sends `text` to the connected peer.
#[flutter_rust_bridge::frb(sync)]
pub fn spike_webrtc_send(text: String) -> Result<(), String> {
    crate::spike_rtc::send(&text)
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn loro_roundtrip_merges() {
        assert_eq!(spike_loro_roundtrip().unwrap(), "Hello, WASM Loro!");
    }
}
