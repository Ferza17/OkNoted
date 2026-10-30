//! M1 spike: two browser peers meet through the relay (`sync-protocol.md` §7) and
//! exchange text over a WebRTC DataChannel. One peer connection at a time. The
//! real `Transport` replaces this in M6.

use std::cell::RefCell;
use std::future::Future;
use std::rc::Rc;

use oknoted_core::signal::{ClientMessage, RelayMessage};
use serde::{Deserialize, Serialize};
use wasm_bindgen::closure::Closure;
use wasm_bindgen::{JsCast, JsValue};
use wasm_bindgen_futures::{JsFuture, spawn_local};
use web_sys::{
    MessageEvent, RtcDataChannel, RtcDataChannelEvent, RtcPeerConnection,
    RtcPeerConnectionIceEvent, RtcSdpType, RtcSessionDescriptionInit, WebSocket,
};

/// Progress of a [`Session`], reported in order.
#[derive(Debug, Clone, PartialEq, Eq)]
pub enum Event {
    /// Joined the room under session id `me`.
    Joined { me: String },
    /// Another peer joined the room.
    PeerJoined { peer: String },
    /// A peer left the room.
    PeerLeft { peer: String },
    /// The DataChannel to `peer` is open.
    Connected { peer: String },
    /// Text received over the DataChannel.
    Message { text: String },
    /// The relay connection or the DataChannel closed.
    Closed,
    /// Something failed; `message` never contains payload data.
    Error { message: String },
}

/// Peer-to-peer payload inside relay `signal` messages. ICE is not trickled: each
/// side waits for host candidates to be gathered and sends one complete SDP.
// shortcut: sent as clear JSON, not sealed with the account-derived key; seal it in M6 (sync-protocol.md §7).
#[derive(Serialize, Deserialize)]
#[serde(tag = "kind", rename_all = "lowercase")]
enum Signal {
    Offer { sdp: String },
    Answer { sdp: String },
}

/// A spike session: relay WebSocket plus at most one peer connection.
#[derive(Clone)]
pub struct Session(Rc<Inner>);

struct Inner {
    ws: WebSocket,
    me: String,
    on_event: Box<dyn Fn(Event)>,
    peer: RefCell<Option<(String, RtcPeerConnection)>>,
    channel: RefCell<Option<RtcDataChannel>>,
}

impl Session {
    /// Connects to `relay_url`, joins `room`, and opens a DataChannel to the first
    /// peer already there (the newcomer always offers, so offers never collide).
    pub fn connect(
        relay_url: &str,
        room: &str,
        on_event: impl Fn(Event) + 'static,
    ) -> Result<Self, JsValue> {
        let ws = WebSocket::new(relay_url)?;
        let session = Session(Rc::new(Inner {
            ws,
            me: session_id(),
            on_event: Box::new(on_event),
            peer: RefCell::default(),
            channel: RefCell::default(),
        }));

        let (s, room) = (session.clone(), room.to_owned());
        let on_open = Closure::<dyn FnMut()>::new(move || {
            s.relay(&ClientMessage::Join {
                room: room.clone(),
                peer: s.0.me.clone(),
            });
            s.emit(Event::Joined { me: s.0.me.clone() });
        });
        let s = session.clone();
        let on_message = Closure::<dyn FnMut(MessageEvent)>::new(move |event: MessageEvent| {
            match event
                .data()
                .as_string()
                .and_then(|text| serde_json::from_str(&text).ok())
            {
                Some(message) => s.on_relay(message),
                None => s.emit(Event::Error {
                    message: "unreadable relay message".into(),
                }),
            }
        });
        let s = session.clone();
        let on_close = Closure::<dyn FnMut()>::new(move || s.emit(Event::Closed));
        let ws = &session.0.ws;
        ws.set_onopen(Some(on_open.into_js_value().unchecked_ref()));
        ws.set_onmessage(Some(on_message.into_js_value().unchecked_ref()));
        ws.set_onclose(Some(on_close.into_js_value().unchecked_ref()));
        Ok(session)
    }

    /// Sends `text` over the open DataChannel.
    pub fn send(&self, text: &str) -> Result<(), JsValue> {
        match self.0.channel.borrow().as_ref() {
            Some(channel) => channel.send_with_str(text),
            None => Err(JsValue::from_str("no open DataChannel yet")),
        }
    }

    /// Closes the peer connection and leaves the relay.
    pub fn close(&self) {
        if let Some((_, pc)) = self.0.peer.borrow_mut().take() {
            pc.close();
        }
        self.relay(&ClientMessage::Leave);
        let _ = self.0.ws.close();
    }

    fn emit(&self, event: Event) {
        (self.0.on_event)(event);
    }

    fn relay(&self, message: &ClientMessage) {
        if let Ok(text) = serde_json::to_string(message) {
            let _ = self.0.ws.send_with_str(&text);
        }
    }

    fn on_relay(&self, message: RelayMessage) {
        match message {
            RelayMessage::Peers { peers } => {
                if let Some(peer) = peers.into_iter().next() {
                    let s = self.clone();
                    self.run(async move { s.offer(peer).await });
                }
            }
            RelayMessage::Joined { peer } => self.emit(Event::PeerJoined { peer }),
            RelayMessage::Left { peer } => {
                let gone = self.0.peer.borrow_mut().take_if(|(id, _)| *id == peer);
                if let Some((_, pc)) = gone {
                    pc.close();
                }
                self.emit(Event::PeerLeft { peer });
            }
            RelayMessage::Signal { from, payload } => {
                match serde_json::from_str::<Signal>(&payload) {
                    Ok(signal) => {
                        let s = self.clone();
                        self.run(async move { s.on_signal(from, signal).await });
                    }
                    Err(_) => self.emit(Event::Error {
                        message: "unreadable signal".into(),
                    }),
                }
            }
        }
    }

    async fn offer(&self, peer: String) -> Result<(), JsValue> {
        let pc = self.new_peer(&peer)?;
        self.watch_channel(pc.create_data_channel("oknoted"), peer.clone());
        let offer = JsFuture::from(pc.create_offer()).await?;
        let sdp = local_sdp(&pc, offer.unchecked_ref()).await?;
        self.signal(&peer, &Signal::Offer { sdp });
        Ok(())
    }

    async fn on_signal(&self, from: String, signal: Signal) -> Result<(), JsValue> {
        match signal {
            Signal::Offer { sdp } => {
                let pc = self.new_peer(&from)?;
                let (s, peer) = (self.clone(), from.clone());
                let on_channel = Closure::<dyn FnMut(RtcDataChannelEvent)>::new(
                    move |event: RtcDataChannelEvent| {
                        s.watch_channel(event.channel(), peer.clone());
                    },
                );
                pc.set_ondatachannel(Some(on_channel.into_js_value().unchecked_ref()));
                JsFuture::from(pc.set_remote_description(&description(RtcSdpType::Offer, &sdp)))
                    .await?;
                let answer = JsFuture::from(pc.create_answer()).await?;
                let sdp = local_sdp(&pc, answer.unchecked_ref()).await?;
                self.signal(&from, &Signal::Answer { sdp });
            }
            Signal::Answer { sdp } => {
                let pc = self
                    .0
                    .peer
                    .borrow()
                    .as_ref()
                    .filter(|(id, _)| *id == from)
                    .map(|(_, pc)| pc.clone());
                let pc = pc.ok_or_else(|| JsValue::from_str("answer from an unknown peer"))?;
                JsFuture::from(pc.set_remote_description(&description(RtcSdpType::Answer, &sdp)))
                    .await?;
            }
        }
        Ok(())
    }

    /// Creates the peer connection for `peer`, replacing any previous one.
    /// The default configuration has no ICE servers: host (LAN) candidates only, per ADR 0006.
    fn new_peer(&self, peer: &str) -> Result<RtcPeerConnection, JsValue> {
        let pc = RtcPeerConnection::new()?;
        if let Some((_, old)) = self.0.peer.replace(Some((peer.to_owned(), pc.clone()))) {
            old.close();
        }
        Ok(pc)
    }

    fn watch_channel(&self, channel: RtcDataChannel, peer: String) {
        let s = self.clone();
        let on_open =
            Closure::<dyn FnMut()>::new(move || s.emit(Event::Connected { peer: peer.clone() }));
        let s = self.clone();
        let on_message = Closure::<dyn FnMut(MessageEvent)>::new(move |event: MessageEvent| {
            if let Some(text) = event.data().as_string() {
                s.emit(Event::Message { text });
            }
        });
        let s = self.clone();
        let on_close = Closure::<dyn FnMut()>::new(move || s.emit(Event::Closed));
        channel.set_onopen(Some(on_open.into_js_value().unchecked_ref()));
        channel.set_onmessage(Some(on_message.into_js_value().unchecked_ref()));
        channel.set_onclose(Some(on_close.into_js_value().unchecked_ref()));
        *self.0.channel.borrow_mut() = Some(channel);
    }

    fn signal(&self, to: &str, signal: &Signal) {
        if let Ok(payload) = serde_json::to_string(signal) {
            self.relay(&ClientMessage::Signal {
                to: to.to_owned(),
                payload,
            });
        }
    }

    /// Runs `task` on this thread, reporting a failure as [`Event::Error`].
    fn run(&self, task: impl Future<Output = Result<(), JsValue>> + 'static) {
        let s = self.clone();
        spawn_local(async move {
            if let Err(error) = task.await {
                s.emit(Event::Error {
                    message: format!("{error:?}"),
                });
            }
        });
    }
}

fn description(kind: RtcSdpType, sdp: &str) -> RtcSessionDescriptionInit {
    let description = RtcSessionDescriptionInit::new(kind);
    description.set_sdp(sdp);
    description
}

/// Applies `description` locally, waits until ICE gathering completes, and returns
/// the final SDP with every host candidate in it.
async fn local_sdp(
    pc: &RtcPeerConnection,
    description: &RtcSessionDescriptionInit,
) -> Result<String, JsValue> {
    let gathered = js_sys::Promise::new(&mut |resolve, _reject| {
        let on_candidate = Closure::<dyn FnMut(RtcPeerConnectionIceEvent)>::new(
            move |event: RtcPeerConnectionIceEvent| {
                // A `null` candidate marks the end of gathering.
                if event.candidate().is_none() {
                    let _ = resolve.call0(&JsValue::NULL);
                }
            },
        );
        pc.set_onicecandidate(Some(on_candidate.into_js_value().unchecked_ref()));
    });
    JsFuture::from(pc.set_local_description(description)).await?;
    JsFuture::from(gathered).await?;
    pc.local_description()
        .map(|d| d.sdp())
        .ok_or_else(|| JsValue::from_str("no local description"))
}

/// Random relay session id. It only needs to be unique, not secret: payloads are sealed.
// `crypto.getRandomValues` rejects views of shared WASM memory, which frb's threaded build uses.
fn session_id() -> String {
    format!(
        "{:013x}",
        (js_sys::Math::random() * (1u64 << 52) as f64) as u64
    )
}
