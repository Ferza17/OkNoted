# 0004 — Seed-phrase identity, no account server

- Status: Accepted
- Date: 2026-10-30

## Context
The app must not have a login server, but it needs an "account" concept so that only devices owned by the same person can sync.

## Decision
- Account = keys derived from a 24-word BIP39 seed phrase.
- Each device has its own key with a certificate signed by the account key.
- New devices are added via QR pairing or by entering the seed phrase.
Details: `docs/security.md`.

## Alternatives considered
- Password + account server — violates the no-server principle.
- Pairing only, no account — no recovery path if every device is lost.

## Consequences
- (+) No server, no personal data such as email.
- (+) Recovery needs only the seed phrase + a backup.
- (−) Losing the seed phrase and all devices = permanent data loss. The UI must stress this.
- (−) Revoking a device does not erase the secrets already on it.
