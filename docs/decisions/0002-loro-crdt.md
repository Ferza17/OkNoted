# 0002 — Loro as the CRDT

- Status: Accepted
- Date: 2026-10-30

## Context
Devices can edit offline and meet later. We need automatic, conflict-free merging for rich text, block order, and the page hierarchy.

## Decision
Use **Loro** (native Rust) with the `LoroText`, `LoroTree`, `LoroMap`, and `LoroMovableList` containers.

## Alternatives considered
- yrs (Yjs) — no built-in movable tree; moving pages/blocks is harder.
- Automerge — mature, but heavier and without a built-in tree.
- Manual last-write-wins — loses data on concurrent edits.

## Consequences
- (+) Concurrently movable tree without cycles, a good fit for Notion-style pages.
- (+) Rich text with marks.
- (−) Younger ecosystem; the Loro version is pinned and upgrades must pass the convergence tests.
- (−) Storage format depends on the Loro version → keep `schema_version` and test migrations.
