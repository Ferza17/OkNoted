# OkNoted

A Notion-like note-taking app that is **open source**, **local-first**, and requires **no login to any server**.
Your notes live only on your devices and sync automatically between your own devices when they are on the same local network.

> Status: early development. See the [roadmap](docs/roadmap.md).

## Planned features

- Block editor: headings, lists, to-dos, code, quotes, images
- Databases: table, kanban, calendar
- Automatic peer-to-peer LAN sync, end-to-end encrypted
- No email/password account: just a seed phrase
- Android, iOS, Windows, macOS, Linux, and Web

## Technology

Rust (core, sync, relay) · SQLite · Loro CRDT · Flutter (all platforms) · flutter_rust_bridge.
Details: [docs/tech-stack.md](docs/tech-stack.md).

## Documentation

| Document | Contents |
|---|---|
| [Architecture](docs/architecture.md) | System overview and data flow |
| [Data model](docs/data-model.md) | CRDT document structure and SQLite schema |
| [Sync protocol](docs/sync-protocol.md) | Open sync specification |
| [Security](docs/security.md) | Keys, encryption, device pairing |
| [Development setup](docs/development.md) | How to run the project |
| [Architecture decisions](docs/decisions/) | ADRs |

For coding agents: start with [CLAUDE.md](CLAUDE.md).

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) and the [Code of Conduct](CODE_OF_CONDUCT.md).
Security reports: [SECURITY.md](SECURITY.md).

## License

Licensed under either of [Apache License 2.0](LICENSE-APACHE) or [MIT license](LICENSE-MIT), at your option.

Unless you explicitly state otherwise, any contribution you submit for inclusion in this project, as defined in the Apache-2.0 license, is dual licensed as above, without any additional terms or conditions.
