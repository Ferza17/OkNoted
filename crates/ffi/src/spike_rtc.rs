//! M1 spike: WebRTC session glue behind `api::spike` (kept outside `api` so frb
//! does not expose it). Web only; native returns an error until M6.

#[cfg(target_arch = "wasm32")]
mod imp {
    use std::cell::RefCell;

    use oknoted_net_web::spike::{Event, Session};

    use crate::api::spike::SpikeRtcEvent;
    use crate::frb_generated::StreamSink;

    thread_local! {
        // `Session` holds JS objects, so it stays on the main thread that created it.
        static SESSION: RefCell<Option<Session>> = const { RefCell::new(None) };
    }

    pub fn connect(
        relay_url: &str,
        room: &str,
        events: StreamSink<SpikeRtcEvent>,
    ) -> Result<(), String> {
        let session = Session::connect(relay_url, room, move |event| {
            let _ = events.add(match event {
                Event::Joined { me } => SpikeRtcEvent::Joined { me },
                Event::PeerJoined { peer } => SpikeRtcEvent::PeerJoined { peer },
                Event::PeerLeft { peer } => SpikeRtcEvent::PeerLeft { peer },
                Event::Connected { peer } => SpikeRtcEvent::Connected { peer },
                Event::Message { text } => SpikeRtcEvent::Message { text },
                Event::Closed => SpikeRtcEvent::Closed,
                Event::Error { message } => SpikeRtcEvent::Error { message },
            });
        })
        .map_err(|e| format!("{e:?}"))?;
        if let Some(old) = SESSION.replace(Some(session)) {
            old.close();
        }
        Ok(())
    }

    pub fn send(text: &str) -> Result<(), String> {
        SESSION.with_borrow(|session| match session {
            Some(session) => session.send(text).map_err(|e| format!("{e:?}")),
            None => Err("not connected".into()),
        })
    }
}

#[cfg(not(target_arch = "wasm32"))]
mod imp {
    use crate::api::spike::SpikeRtcEvent;
    use crate::frb_generated::StreamSink;

    const WEB_ONLY: &str = "the WebRTC spike runs on web only (native WebRTC arrives in M6)";

    pub fn connect(
        _relay_url: &str,
        _room: &str,
        _events: StreamSink<SpikeRtcEvent>,
    ) -> Result<(), String> {
        Err(WEB_ONLY.into())
    }

    pub fn send(_text: &str) -> Result<(), String> {
        Err(WEB_ONLY.into())
    }
}

pub use imp::{connect, send};
