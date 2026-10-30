# 0006 — Web sync via WebRTC + signaling relay

- Status: Accepted
- Date: 2026-10-30

## Context
Browsers cannot do mDNS, open server sockets, or connect to `ws://` LAN addresses from an HTTPS page (mixed content). The web version must still sync with other devices on the LAN.

## Decision
- The web uses a WebRTC DataChannel for sync data.
- Peer introduction (offer/answer/ICE) goes through a WebSocket relay that only forwards encrypted messages (sealed with an account-derived key).
- Native clients also implement WebRTC (`net-lan::webrtc`) so they can act as peers for web clients.
- By default ICE uses only host candidates (LAN). STUN/TURN is optional.

## Alternatives considered
- Web only views data through a desktop device acting as a local HTTP server — blocked by HTTPS/mixed content and certificates.
- No sync on web — greatly reduces the value of the web version.

## Consequences
- (+) Data stays peer-to-peer and end-to-end encrypted.
- (−) The web needs a reachable relay (public or self-hosted).
- (−) Adds a fairly large native WebRTC dependency.
