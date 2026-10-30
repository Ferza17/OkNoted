# Security Policy

OkNoted handles private notes, seed phrases, and device keys, so we take security reports seriously.
The threat model and key handling are described in [docs/security.md](docs/security.md).

## Supported versions

OkNoted is in early development (pre-1.0). Only the latest `main` branch receives security fixes.

## Reporting a vulnerability

**Please do not open a public issue.** Report privately through GitHub:
[Report a vulnerability](https://github.com/Ferza17/OkNoted/security/advisories/new).

Include affected component (core, storage, sync/network, relay, app), steps to reproduce, and impact.
Never include real seed phrases, keys, or personal notes in a report.

We aim to acknowledge reports within 7 days and to agree on a disclosure date with you once a fix is
available.

## Scope

In scope: anything that lets an attacker read or modify notes, impersonate a device, recover keys,
or make the relay learn or store user data. Out of scope: attacks that require an already
compromised, unlocked device.
