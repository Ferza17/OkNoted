# Data Model

The source of truth is the CRDT documents (Loro). SQLite stores CRDT updates and derived indexes for fast queries.

## 1. Entities

| Entity | Stored as | Notes |
|---|---|---|
| Workspace | `workspace` document (one per account) | Page tree, workspace name, device list |
| Page | `page` document (one per page) | Page properties + block content |
| Block | part of a `page` document | Paragraph, heading, list, to-do, code, quote, image, divider, callout |
| Database | `page` document with `kind = database` | Column schema + rows (each row is a page) |
| View | part of a database document | Table, kanban, calendar; filter & sort |
| Blob | `blobs` table (not CRDT) | File attachments, content-addressed by hash |

Why one document per page: sync and loading can happen per page, documents stay small, and unopened pages don't need to be loaded into memory.

## 2. IDs

| Type | Format |
|---|---|
| `DocId`, `PageId` | UUID v7 (time-ordered) |
| `BlockId` | UUID v7 |
| `DeviceId` | 32-byte Ed25519 device public key |
| `AccountId` | 32-byte Ed25519 account public key |
| `BlobId` | BLAKE3 content hash (32 bytes) |

## 3. Loro document layout

### 3.1 `workspace` document

```
root (LoroMap)
├── schema_version: i64
├── name: String
├── tree: LoroTree              # page hierarchy (movable tree)
│     node.meta (LoroMap):
│       page_id: String
│       title_cache: String     # copy of the title for the sidebar
│       icon: String?
│       deleted_at: i64?        # soft delete (trash)
└── devices: LoroMap<device_id_hex, LoroMap>
      name: String
      platform: String          # android | ios | macos | windows | linux | web
      added_at: i64
      revoked: bool
```

`LoroTree` is used because it supports concurrent moves without creating cycles.

### 3.2 `page` document

```
root (LoroMap)
├── schema_version: i64
├── kind: "page" | "database"
├── props: LoroMap
│     title: LoroText
│     icon: String?
│     cover: BlobId?
│     created_at: i64
│     updated_at: i64
│     cells: LoroMap<column_id, value>   # only when this page is a database row
├── blocks: LoroTree            # block order & nesting
│     node.meta (LoroMap):
│       id: String
│       type: String            # paragraph | heading | bulleted | numbered | todo | code | quote | image | divider | callout
│       text: LoroText          # rich text (marks: bold, italic, underline, strike, code, link)
│       attrs: LoroMap          # heading level, to-do checked, code language, image blob, etc.
└── database: LoroMap           # only when kind = database
      columns: LoroMovableList<LoroMap>
        id, name, type (text|number|select|multi_select|date|checkbox|url|relation), options
      rows: LoroMovableList<String>   # PageId of each row
      views: LoroMovableList<LoroMap>
        id, name, type (table|kanban|calendar), filter, sort, group_by, hidden_columns
```

Each row's property values are stored in that row's own page document under `props.cells`.

### 3.3 Schema evolution rules

- Bump `schema_version` when the layout changes incompatibly.
- The app must be able to read every older version and migrate when a document is opened.
- New fields are always optional. Never change the type of an existing container.

## 4. Block operations (Dart ↔ Rust contract)

The editor never touches the CRDT directly. It sends high-level operations:

```rust
pub enum BlockOp {
    Insert { parent: Option<BlockId>, after: Option<BlockId>, block: NewBlock },
    Delete { id: BlockId },
    Move   { id: BlockId, parent: Option<BlockId>, after: Option<BlockId> },
    SetType { id: BlockId, block_type: BlockType },
    SetAttr { id: BlockId, key: String, value: AttrValue },
    TextInsert { id: BlockId, index: u32, text: String, marks: Vec<Mark> },
    TextDelete { id: BlockId, index: u32, len: u32 },
    TextFormat { id: BlockId, index: u32, len: u32, mark: Mark, on: bool },
}
```

- Text indexes are in **UTF-16 code units** to match Dart strings. Conversion to Loro units happens in Rust.
- Rust sends back `DocChanged { doc_id, origin, ops: Vec<BlockOp> }` so the editor can apply remote changes incrementally.

## 5. SQLite schema

```sql
-- Source of truth (CRDT)
CREATE TABLE docs (
  doc_id        BLOB PRIMARY KEY,      -- UUID
  kind          TEXT NOT NULL,         -- workspace | page
  snapshot      BLOB,                  -- latest (compacted) Loro snapshot
  version       BLOB NOT NULL,         -- encoded version vector
  updated_at    INTEGER NOT NULL
);

CREATE TABLE doc_updates (
  doc_id        BLOB NOT NULL REFERENCES docs(doc_id),
  seq           INTEGER NOT NULL,      -- local sequence
  data          BLOB NOT NULL,         -- Loro update
  created_at    INTEGER NOT NULL,
  PRIMARY KEY (doc_id, seq)
);

CREATE TABLE blobs (
  blob_id       BLOB PRIMARY KEY,      -- BLAKE3
  mime          TEXT NOT NULL,
  size          INTEGER NOT NULL,
  data          BLOB NOT NULL
);

-- Derived indexes (may be dropped & rebuilt)
CREATE TABLE idx_pages (
  page_id       BLOB PRIMARY KEY,
  parent_id     BLOB,
  title         TEXT NOT NULL,
  icon          TEXT,
  kind          TEXT NOT NULL,
  sort_key      TEXT NOT NULL,
  deleted_at    INTEGER,
  updated_at    INTEGER NOT NULL
);

CREATE VIRTUAL TABLE idx_fts USING fts5(
  page_id UNINDEXED, title, body, tokenize = 'unicode61 remove_diacritics 2'
);

CREATE TABLE idx_cells (
  database_id   BLOB NOT NULL,
  row_id        BLOB NOT NULL,
  column_id     TEXT NOT NULL,
  value_text    TEXT,
  value_num     REAL,
  PRIMARY KEY (database_id, row_id, column_id)
);

-- Local to each device (not synced)
CREATE TABLE peers (
  device_id     BLOB PRIMARY KEY,
  last_seen     INTEGER,
  last_addr     TEXT
);

CREATE TABLE peer_doc_state (
  device_id     BLOB NOT NULL,
  doc_id        BLOB NOT NULL,
  version       BLOB NOT NULL,         -- last VV known to be held by the peer
  PRIMARY KEY (device_id, doc_id)
);

CREATE TABLE kv (
  key           TEXT PRIMARY KEY,
  value         BLOB NOT NULL          -- local settings
);
```

### Compaction

When a document's `doc_updates` exceed 200 rows or 1 MB, merge them into a new `snapshot` in `docs` and delete the old update rows, in a single transaction.

## 6. Blobs

- Attachments are stored locally and referenced from the CRDT by `BlobId`.
- During sync, a peer requests blobs that are referenced but missing (`BlobWant`); they are sent in 64 KB chunks.
- Blob size limit for the initial version: 25 MB.
