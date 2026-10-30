# Contributing to OkNoted

Thanks for helping! OkNoted is local-first: no server ever stores user data. Please read
[CLAUDE.md](CLAUDE.md) (the golden rules apply to humans too) and the relevant documents in
[`docs/`](docs/) before making a change.

## Getting started

Set up your environment with [docs/development.md](docs/development.md), then:

```bash
cargo test --workspace
./scripts/codegen.sh
cd app && flutter run -d linux   # or macos / windows
./scripts/run-web.sh             # web
```

## Before opening a pull request

```bash
cargo fmt --all
cargo clippy --workspace --all-targets -- -D warnings
cargo test --workspace
cargo check -p oknoted-core --target wasm32-unknown-unknown
cargo deny check
cd app && dart analyze && flutter test   # if Dart changed
```

- If you changed `crates/ffi/src/api/**`, run `./scripts/codegen.sh` and commit the generated output.
- If you changed behavior, the sync protocol, or the schema, update `docs/` (protocol changes bump
  `PROTOCOL_VERSION`; schema changes are a new migration file).
- New architectural decisions get an ADR in `docs/decisions/`.

## Conventions

- Everything in the repository is in English. UI text goes through `app/lib/l10n/*.arb` (EN and ID).
- Commits follow [Conventional Commits](https://www.conventionalcommits.org/):
  `feat(core): ...`, `fix(app): ...`, `docs: ...`.
- One pull request = one coherent change. Follow the milestone order in [docs/roadmap.md](docs/roadmap.md).
- Never log note content, seed phrases, or keys.

## Reporting bugs and security issues

Bugs: open a GitHub issue. Security vulnerabilities: **do not** open a public issue; see
[SECURITY.md](SECURITY.md).

By participating you agree to the [Code of Conduct](CODE_OF_CONDUCT.md).
