//! In-memory rooms: who is connected where. Nothing is persisted.

use std::collections::HashMap;
use std::time::{Duration, Instant};

use oknoted_core::signal::{MAX_MESSAGES_PER_SECOND, MAX_PEERS_PER_ROOM, RelayMessage};
use tokio::sync::mpsc;

/// Outgoing queue of one connection (serialized [`RelayMessage`]s).
pub type Outbox = mpsc::Sender<String>;

/// Why a `join` was refused.
#[derive(Debug, PartialEq, Eq)]
pub enum JoinError {
    /// The room already holds [`MAX_PEERS_PER_ROOM`] peers.
    RoomFull,
    /// Another connection already uses this session id in the room.
    PeerTaken,
}

/// All rooms, keyed by room id, then by peer session id.
#[derive(Default)]
pub struct Rooms(HashMap<String, HashMap<String, Outbox>>);

impl Rooms {
    /// Adds `peer` to `room`, tells the others, and returns the peers already there.
    pub fn join(
        &mut self,
        room: &str,
        peer: &str,
        outbox: Outbox,
    ) -> Result<Vec<String>, JoinError> {
        let members = self.0.entry(room.to_owned()).or_default();
        if members.contains_key(peer) {
            return Err(JoinError::PeerTaken);
        }
        if members.len() >= MAX_PEERS_PER_ROOM {
            return Err(JoinError::RoomFull);
        }
        let existing: Vec<String> = members.keys().cloned().collect();
        broadcast(
            members,
            &RelayMessage::Joined {
                peer: peer.to_owned(),
            },
        );
        members.insert(peer.to_owned(), outbox);
        Ok(existing)
    }

    /// Removes `peer` from `room`, tells the others, and drops the room when empty.
    pub fn leave(&mut self, room: &str, peer: &str) {
        let Some(members) = self.0.get_mut(room) else {
            return;
        };
        if members.remove(peer).is_none() {
            return;
        }
        broadcast(
            members,
            &RelayMessage::Left {
                peer: peer.to_owned(),
            },
        );
        if members.is_empty() {
            self.0.remove(room);
        }
    }

    /// Forwards `payload` from `from` to `to`, only within the same room.
    pub fn signal(&self, room: &str, from: &str, to: &str, payload: String) {
        if let Some(target) = self.0.get(room).and_then(|m| m.get(to)) {
            send(
                target,
                &RelayMessage::Signal {
                    from: from.to_owned(),
                    payload,
                },
            );
        }
    }
}

fn broadcast(members: &HashMap<String, Outbox>, msg: &RelayMessage) {
    for outbox in members.values() {
        send(outbox, msg);
    }
}

/// Queues `msg`; a slow client whose queue is full simply misses it (signaling is retried by WebRTC).
pub fn send(outbox: &Outbox, msg: &RelayMessage) {
    if let Ok(text) = serde_json::to_string(msg) {
        let _ = outbox.try_send(text);
    }
}

/// Fixed one-second window limiter for [`MAX_MESSAGES_PER_SECOND`].
pub struct RateLimit {
    window_start: Instant,
    count: u32,
}

impl RateLimit {
    /// Starts a fresh window at `now`.
    pub fn new(now: Instant) -> Self {
        Self {
            window_start: now,
            count: 0,
        }
    }

    /// Records one message at `now`; returns `false` once the limit is exceeded.
    pub fn allow(&mut self, now: Instant) -> bool {
        if now.duration_since(self.window_start) >= Duration::from_secs(1) {
            self.window_start = now;
            self.count = 0;
        }
        self.count += 1;
        self.count <= MAX_MESSAGES_PER_SECOND
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    fn outbox() -> (Outbox, mpsc::Receiver<String>) {
        mpsc::channel(64)
    }

    #[test]
    fn join_reports_existing_peers_and_notifies_them() {
        let mut rooms = Rooms::default();
        let (a, mut a_rx) = outbox();
        let (b, _b_rx) = outbox();
        assert_eq!(rooms.join("r", "a", a), Ok(vec![]));
        assert_eq!(rooms.join("r", "b", b), Ok(vec!["a".to_owned()]));
        assert_eq!(a_rx.try_recv().unwrap(), r#"{"type":"joined","peer":"b"}"#);
    }

    #[test]
    fn signal_stays_inside_the_room() {
        let mut rooms = Rooms::default();
        let (a, _a_rx) = outbox();
        let (b, mut b_rx) = outbox();
        let (c, mut c_rx) = outbox();
        rooms.join("r1", "a", a).unwrap();
        rooms.join("r1", "b", b).unwrap();
        rooms.join("r2", "c", c).unwrap();
        rooms.signal("r1", "a", "b", "hi".into());
        rooms.signal("r1", "a", "c", "nope".into());
        assert_eq!(
            b_rx.try_recv().unwrap(),
            r#"{"type":"signal","from":"a","payload":"hi"}"#
        );
        assert!(c_rx.try_recv().is_err());
    }

    #[test]
    fn room_limits_and_cleanup() {
        let mut rooms = Rooms::default();
        let mut keep = Vec::new();
        for i in 0..MAX_PEERS_PER_ROOM {
            let (tx, rx) = outbox();
            keep.push(rx);
            rooms.join("r", &i.to_string(), tx).unwrap();
        }
        assert_eq!(
            rooms.join("r", "extra", outbox().0),
            Err(JoinError::RoomFull)
        );
        assert_eq!(rooms.join("r", "0", outbox().0), Err(JoinError::PeerTaken));
        for i in 0..MAX_PEERS_PER_ROOM {
            rooms.leave("r", &i.to_string());
        }
        assert!(rooms.0.is_empty());
    }

    #[test]
    fn rate_limit_resets_each_second() {
        let start = Instant::now();
        let mut limit = RateLimit::new(start);
        assert!((0..MAX_MESSAGES_PER_SECOND).all(|_| limit.allow(start)));
        assert!(!limit.allow(start));
        assert!(limit.allow(start + Duration::from_secs(1)));
    }
}
