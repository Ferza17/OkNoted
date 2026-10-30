# 0003 — One Loro document per page

- Status: Accepted
- Date: 2026-10-30

## Context
A workspace can contain thousands of pages. Loading the whole workspace as one CRDT document would be slow and memory-hungry, especially on mobile and web.

## Decision
- One `workspace` document per account (page tree, device list).
- One `page` document per page (properties + blocks + database data).

## Alternatives considered
- One document for the whole workspace — simple, but does not scale.
- One document per block — too many documents, high sync overhead.

## Consequences
- (+) Pages load on demand; sync happens per page.
- (−) The page title is stored twice (in the page and as `title_cache` in the tree) → both must be updated together; the source of truth is `props.title` in the page.
- (−) Cross-page operations (e.g. moving a block to another page) are not atomic.
