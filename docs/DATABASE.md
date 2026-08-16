# MaybeLater — Database Specification

## Requirements

- SQLite
- migrations
- transactions
- indexes
- FTS5
- persistent processing state
- crash recovery
- duplicate detection

The database is the source of truth.

FTS is an index and must be rebuildable.

## Core Tables

### collections

```sql
CREATE TABLE collections (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL,
    description TEXT DEFAULT '',
    color TEXT DEFAULT '#7C3AED',
    icon TEXT DEFAULT 'folder',
    created_at INTEGER NOT NULL,
    updated_at INTEGER NOT NULL
);
```

### screenshots

```sql
CREATE TABLE screenshots (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    filepath TEXT NOT NULL UNIQUE,
    thumbnail_path TEXT,
    original_uri TEXT,
    filename TEXT DEFAULT '',
    ocr_text TEXT DEFAULT '',
    ai_labels TEXT DEFAULT '[]',
    manual_tags TEXT DEFAULT '[]',
    collection_id INTEGER,
    source TEXT DEFAULT 'import',
    created_at INTEGER NOT NULL,
    imported_at INTEGER NOT NULL,
    updated_at INTEGER NOT NULL,
    file_size INTEGER DEFAULT 0,
    width INTEGER DEFAULT 0,
    height INTEGER DEFAULT 0,
    content_hash TEXT,
    processing_status TEXT DEFAULT 'pending',
    processing_error TEXT DEFAULT '',
    is_deleted INTEGER DEFAULT 0,
    deleted_at INTEGER,
    is_favorite INTEGER DEFAULT 0,
    FOREIGN KEY (collection_id) REFERENCES collections(id)
);
```

Use a unique content hash when practical:

```sql
CREATE UNIQUE INDEX idx_screenshots_hash
ON screenshots(content_hash)
WHERE content_hash IS NOT NULL;
```

Useful indexes:

```sql
CREATE INDEX idx_screenshots_created
ON screenshots(created_at DESC);

CREATE INDEX idx_screenshots_collection
ON screenshots(collection_id);

CREATE INDEX idx_screenshots_deleted
ON screenshots(is_deleted);

CREATE INDEX idx_screenshots_status
ON screenshots(processing_status);
```

## Tags

Use a normalized tags table rather than relying only on JSON if autocomplete/usage counting needs efficient queries.

Suggested:

```sql
CREATE TABLE tags (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL UNIQUE,
    usage_count INTEGER NOT NULL DEFAULT 0
);

CREATE TABLE screenshot_tags (
    screenshot_id INTEGER NOT NULL,
    tag_id INTEGER NOT NULL,
    PRIMARY KEY (screenshot_id, tag_id),
    FOREIGN KEY (screenshot_id) REFERENCES screenshots(id) ON DELETE CASCADE,
    FOREIGN KEY (tag_id) REFERENCES tags(id) ON DELETE CASCADE
);
```

## Search History

```sql
CREATE TABLE search_history (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    query TEXT NOT NULL,
    searched_at INTEGER NOT NULL
);
```

Keep history bounded.

## Processing States

Use explicit states:

- pending
- copying
- thumbnailing
- hashing
- ocr
- labeling
- completed
- failed
- cancelled

## Persistent Import Jobs

If the import queue cannot be represented safely by screenshots alone, create an import_jobs table.

Suggested fields:

- id
- source_uri
- target_path
- status
- retry_count
- last_error
- created_at
- updated_at

The queue must survive app restarts.

## FTS5

```sql
CREATE VIRTUAL TABLE screenshots_fts USING fts5(
    ocr_text,
    ai_labels,
    manual_tags,
    content='screenshots',
    content_rowid='id',
    tokenize='unicode61'
);
```

Maintain FTS correctly on insert/update/delete.

Do not use LIKE as the primary search.

## Transactions

Use transactions for related state changes.

Batch inserts during large imports.

Never leave a screenshot record claiming completed if its required processing state was not actually completed.

## Migrations

Never drop and recreate the production database for schema changes.

Use numbered migrations.

Every migration must be testable.

## Integrity

Provide a way to:

- detect missing files
- detect missing thumbnails
- detect orphaned records
- recover stale jobs
- rebuild FTS

Do not silently delete user data during repair.
