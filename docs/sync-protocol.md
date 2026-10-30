# Sync Protocol

`PROTOCOL_VERSION = 1`

This specification is open so other clients can be implemented. Every change must bump `PROTOCOL_VERSION` and update this document.

## 1. Principles

- Only devices of the **same account** may sync.
- All traffic is encrypted and mutually authenticated.
- Sync is **idempotent**: receiving the same update twice does not change the result (guaranteed by the CRDT).
- There is no "master" device. All peers are equal.

## 2. Discovery (native)

mDNS service: `_notesync._udp.local.`

TXT record:

| Key | Contents |
|---|---|
| `v` | `PROTOCOL_VERSION` |
| `t` | `account_tag` (hex, 16 bytes) |
| `d` | first 8 bytes of the `DeviceId` (hex), to avoid connecting to itself |
| `p` | QUIC port |

`account_tag = HKDF(account_secret, info = "notesync/v1/account-tag")[0..16]`.
The tag rotates daily (`info` is suffixed with the UTC date `YYYY-MM-DD`) so devices are not easily tracked on public networks; peers accept today's and yesterday's tag.

Connection rule: when two peers discover each other, the peer with the smaller `DeviceId` (byte comparison) initiates, to avoid duplicate connections.

## 3. Transport

| Path | Technology | Used by |
|---|---|---|
| Native ↔ native | QUIC (quinn), one bidirectional stream per session | desktop, mobile |
| Web ↔ anyone | WebRTC DataChannel `notesync`, ordered, reliable | web, and native when the peer is web |

On top of any transport, the protocol uses **frames**:

```
u32 (big-endian) length | encrypted payload
```

Maximum frame size: 1 MiB. Larger data is chunked (blobs in 64 KiB pieces).

## 4. Handshake

Uses Noise `XX` (`Noise_XX_25519_ChaChaPoly_BLAKE2s`) via the `snow` crate, inside QUIC/DataChannel. The handshake payload contains:

```rust
struct Hello {
    protocol_version: u16,
    device_id: [u8; 32],            // Ed25519 device public key
    device_cert: DeviceCert,        // signed by the account key (see security.md)
    noise_static_sig: [u8; 64],     // device key signature over the Noise static key
    app_version: String,
}
```

The receiver verifies:
1. `protocol_version` is supported; otherwise close with error 409.
2. `device_cert.account_id` equals the local account.
3. The certificate signature is valid and the device is not in the `revoked` list.
4. `noise_static_sig` is valid, binding the Noise key to `device_id`.

After the handshake, all frames are encrypted with the Noise session keys.

## 5. Messages

Serialized with `postcard`.

```rust
enum Message {
    // Summary of all documents held
    Summary { docs: Vec<(DocId, VersionVector)> },

    // Request updates for a document since a given version
    Request { doc_id: DocId, since: VersionVector },

    // Send a Loro update
    Update { doc_id: DocId, kind: DocKind, data: Vec<u8> },

    // Confirm the latest version after import
    Ack { doc_id: DocId, version: VersionVector },

    // Blobs
    BlobWant { ids: Vec<BlobId> },
    BlobChunk { id: BlobId, offset: u64, total: u64, data: Vec<u8> },

    Ping,
    Pong,
    Bye { reason: ByeReason },
    Error { code: u16, message: String },
}
```

## 6. Session flow

```
A                                   B
│── Hello (Noise handshake) ───────►│
│◄────────────── Hello ─────────────│
│── Summary ───────────────────────►│
│◄─────────────────────── Summary ──│
│  (each side compares VVs)         │
│── Request(doc, since) ───────────►│   for docs where B is newer
│◄──────────── Update(doc, delta) ──│
│── Ack(doc, version) ─────────────►│
│        ... live mode ...          │
│── Update (on every local edit) ──►│   debounced 300 ms per document
│◄─────────────────────────── Ack ──│
│── Ping (every 15 s) ─────────────►│
```

Rules:
- A document missing on one side is treated as `since = empty VV`.
- The `workspace` document is synced first, because it holds the page tree and the revoked-device list.
- After `Ack`, store the peer's VV in `peer_doc_state` so the next session can send deltas immediately.
- If no `Pong` arrives within 45 seconds, the session is considered dead.

## 7. Relay (signaling for web)

The relay is a WebSocket server (`wss://`) that **only** forwards messages between clients in the same room.

### Client → relay messages

```json
{ "type": "join",   "room": "<account_tag hex>", "peer": "<random session id>" }
{ "type": "signal", "to": "<peer>", "payload": "<base64 sealed box>" }
{ "type": "leave" }
```

### Relay → client messages

```json
{ "type": "peers",  "peers": ["<peer>", ...] }
{ "type": "joined", "peer": "<peer>" }
{ "type": "left",   "peer": "<peer>" }
{ "type": "signal", "from": "<peer>", "payload": "<base64>" }
```

- `payload` holds the WebRTC offer/answer/ICE candidates, sealed with an account-derived key (`HKDF(account_secret, "notesync/v1/signal")`, XChaCha20-Poly1305). The relay cannot read it.
- Limits: payload max 16 KiB, 30 messages/second per connection, 32 peers per room; empty rooms are removed.
- The relay writes nothing to disk and never logs `payload` contents.
- ICE: by default only **host candidates** (LAN). Users may enable STUN/TURN in settings; data remains end-to-end encrypted.

Once the DataChannel is open, the handshake and message flow are the same as §4–§6.

## 8. Versioning & compatibility

- Different major protocol version → reject the connection and show "please update the app".
- New fields are added as optional fields/variants; receivers ignore unknown variants and reply `Error { code: 400 }`.

## 9. Error codes

| Code | Meaning |
|---|---|
| 400 | Unknown / invalid message |
| 401 | Authentication failed |
| 403 | Device revoked |
| 409 | Incompatible protocol version |
| 413 | Frame too large |
| 500 | Internal error |
