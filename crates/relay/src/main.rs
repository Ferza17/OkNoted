//! OkNoted signaling relay (`docs/sync-protocol.md` §7). Forwards sealed WebRTC
//! signaling messages between peers in the same room; stores no user data.
#![forbid(unsafe_code)]

mod rooms;

use std::net::SocketAddr;
use std::sync::{Arc, Mutex};
use std::time::Instant;

use anyhow::Context;
use axum::Router;
use axum::extract::State;
use axum::extract::ws::{Message, WebSocket, WebSocketUpgrade};
use axum::response::Response;
use axum::routing::get;
use futures::{SinkExt, StreamExt};
use oknoted_core::signal::{ClientMessage, MAX_PAYLOAD_BYTES, RelayMessage};
use rooms::{RateLimit, Rooms};
use tokio::sync::mpsc;
use tracing::{debug, info};

/// Default listen address for local development.
const DEFAULT_LISTEN: &str = "127.0.0.1:8787";
/// Largest WebSocket message accepted: the payload plus room for the JSON envelope.
const MAX_MESSAGE_BYTES: usize = MAX_PAYLOAD_BYTES + 1024;
/// Longest accepted room or peer id.
const MAX_ID_LEN: usize = 64;

type SharedRooms = Arc<Mutex<Rooms>>;

#[tokio::main]
async fn main() -> anyhow::Result<()> {
    tracing_subscriber::fmt()
        .with_env_filter(
            tracing_subscriber::EnvFilter::try_from_default_env().unwrap_or_else(|_| "info".into()),
        )
        .init();
    let listen = parse_listen(std::env::args().skip(1))?;
    let app = Router::new()
        .route("/", get(upgrade))
        .with_state(SharedRooms::default());
    let listener = tokio::net::TcpListener::bind(listen)
        .await
        .with_context(|| format!("bind {listen}"))?;
    info!(%listen, "relay listening");
    axum::serve(listener, app).await?;
    Ok(())
}

/// Reads `--listen <addr>`, defaulting to [`DEFAULT_LISTEN`].
fn parse_listen(mut args: impl Iterator<Item = String>) -> anyhow::Result<SocketAddr> {
    let mut listen = DEFAULT_LISTEN.to_owned();
    while let Some(arg) = args.next() {
        match arg.as_str() {
            "--listen" => listen = args.next().context("--listen needs an address")?,
            other => {
                anyhow::bail!("unknown argument: {other} (usage: oknoted-relay [--listen <addr>])")
            }
        }
    }
    listen
        .parse()
        .with_context(|| format!("invalid address: {listen}"))
}

async fn upgrade(ws: WebSocketUpgrade, State(rooms): State<SharedRooms>) -> Response {
    ws.max_message_size(MAX_MESSAGE_BYTES)
        .on_upgrade(move |socket| connection(socket, rooms))
}

fn valid_id(id: &str) -> bool {
    !id.is_empty() && id.len() <= MAX_ID_LEN
}

/// Serves one client until it leaves, breaks a rule, or disconnects.
async fn connection(socket: WebSocket, rooms: SharedRooms) {
    let (mut sink, mut stream) = socket.split();
    let (outbox, mut queue) = mpsc::channel::<String>(64);
    let writer = tokio::spawn(async move {
        while let Some(text) = queue.recv().await {
            if sink.send(Message::Text(text.into())).await.is_err() {
                break;
            }
        }
    });

    let mut joined: Option<(String, String)> = None;
    let mut limit = RateLimit::new(Instant::now());
    while let Some(Ok(message)) = stream.next().await {
        let text = match message {
            Message::Text(text) => text,
            Message::Close(_) => break,
            _ => continue,
        };
        if !limit.allow(Instant::now()) {
            debug!("closing connection: rate limit exceeded");
            break;
        }
        let Ok(message) = serde_json::from_str::<ClientMessage>(text.as_str()) else {
            debug!(bytes = text.len(), "closing connection: invalid message");
            break;
        };
        match (message, &joined) {
            (ClientMessage::Join { room, peer }, None) if valid_id(&room) && valid_id(&peer) => {
                let Ok(peers) = lock(&rooms).join(&room, &peer, outbox.clone()) else {
                    break;
                };
                rooms::send(&outbox, &RelayMessage::Peers { peers });
                debug!(%room, %peer, "joined");
                joined = Some((room, peer));
            }
            (ClientMessage::Signal { to, payload }, Some((room, me)))
                if payload.len() <= MAX_PAYLOAD_BYTES =>
            {
                debug!(bytes = payload.len(), "forwarding signal");
                lock(&rooms).signal(room, me, &to, payload);
            }
            // Leave, a second join, a signal before join, or an oversized payload.
            _ => break,
        }
    }

    if let Some((room, peer)) = joined {
        lock(&rooms).leave(&room, &peer);
        debug!(%room, %peer, "left");
    }
    writer.abort();
}

fn lock(rooms: &SharedRooms) -> std::sync::MutexGuard<'_, Rooms> {
    // A poisoned lock only means another connection panicked mid-update; the map is still usable.
    rooms
        .lock()
        .unwrap_or_else(|poisoned| poisoned.into_inner())
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn parses_listen_flag() {
        let args = |v: &[&str]| {
            v.iter()
                .map(|s| s.to_string())
                .collect::<Vec<_>>()
                .into_iter()
        };
        assert_eq!(parse_listen(args(&[])).unwrap().to_string(), DEFAULT_LISTEN);
        assert_eq!(
            parse_listen(args(&["--listen", "0.0.0.0:9000"]))
                .unwrap()
                .port(),
            9000
        );
        assert!(parse_listen(args(&["--bogus"])).is_err());
    }
}
