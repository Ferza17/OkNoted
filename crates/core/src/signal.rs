//! Relay signaling messages (`docs/sync-protocol.md` §7), shared by the relay and its clients.
//!
//! `payload` is opaque to the relay: clients seal it with an account-derived key.

use serde::{Deserialize, Serialize};

/// Maximum `payload` size in bytes.
pub const MAX_PAYLOAD_BYTES: usize = 16 * 1024;
/// Maximum messages per second a single connection may send.
pub const MAX_MESSAGES_PER_SECOND: u32 = 30;
/// Maximum peers in one room.
pub const MAX_PEERS_PER_ROOM: usize = 32;

/// Message sent by a client to the relay.
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
#[serde(tag = "type", rename_all = "lowercase")]
pub enum ClientMessage {
    /// Join `room` (the hex `account_tag`) as session id `peer`.
    Join {
        /// Room to join.
        room: String,
        /// Random session id of the sender.
        peer: String,
    },
    /// Forward a sealed payload to `to` in the same room.
    Signal {
        /// Recipient session id.
        to: String,
        /// Sealed signaling payload.
        payload: String,
    },
    /// Leave the room.
    Leave,
}

/// Message sent by the relay to a client.
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
#[serde(tag = "type", rename_all = "lowercase")]
pub enum RelayMessage {
    /// Peers already in the room, sent right after `join`.
    Peers {
        /// Session ids of the other peers.
        peers: Vec<String>,
    },
    /// A peer joined the room.
    Joined {
        /// Session id of the new peer.
        peer: String,
    },
    /// A peer left the room.
    Left {
        /// Session id of the peer that left.
        peer: String,
    },
    /// A sealed payload from `from`.
    Signal {
        /// Sender session id.
        from: String,
        /// Sealed signaling payload.
        payload: String,
    },
}

#[cfg(test)]
mod tests {
    use super::*;
    use serde_json::json;

    #[test]
    fn wire_format_matches_spec() {
        let join = ClientMessage::Join { room: "ab".into(), peer: "p1".into() };
        assert_eq!(serde_json::to_value(&join).unwrap(), json!({"type": "join", "room": "ab", "peer": "p1"}));
        let leave: ClientMessage = serde_json::from_value(json!({"type": "leave"})).unwrap();
        assert_eq!(leave, ClientMessage::Leave);
        let signal = RelayMessage::Signal { from: "p1".into(), payload: "x".into() };
        assert_eq!(serde_json::to_value(&signal).unwrap(), json!({"type": "signal", "from": "p1", "payload": "x"}));
    }
}
