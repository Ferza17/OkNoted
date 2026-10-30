# Architecture Decision Records

Every important architectural decision is recorded here so agents and contributors know *why* something was chosen.

## Adding an ADR

1. Copy `template.md` to `NNNN-short-title.md` (next number).
2. Fill in every section. Initial status: `Proposed`.
3. Once approved, change the status to `Accepted`. A superseded ADR gets the status `Superseded by NNNN`; never delete it.

## Index

| No | Title | Status |
|---|---|---|
| 0001 | Rust core + Flutter for all platforms | Accepted |
| 0002 | Loro as the CRDT | Accepted |
| 0003 | One Loro document per page | Accepted |
| 0004 | Seed-phrase identity, no account server | Accepted |
| 0005 | Async trait pattern across native & WASM | Accepted |
| 0006 | Web sync via WebRTC + signaling relay | Accepted |
| 0007 | Web risk spike results (M1) | Accepted |
