# MaybeLater — Implementation Roadmap

## Status Legend

- NOT_STARTED
- IN_PROGRESS
- BLOCKED
- COMPLETE

Only work on the first incomplete phase unless the user explicitly selects another phase.

---

# Phase 0 — Foundation

Status: COMPLETE

- [x] Inspect repository/environment
- [x] Verify Flutter/Dart versions
- [x] Resolve stable compatible dependencies
- [x] Establish app structure
- [x] Configure theme
- [x] Configure routing
- [x] Configure Riverpod
- [x] Create basic app shell
- [x] Add analyzer/lint configuration
- [x] Verify clean build (Local verification blocker bypassed using GitHub Actions cloud-build workflow; successful physical-device verification)

---

# Phase 1 — Database

Status: IN_PROGRESS

- [x] SQLite initialization
- [x] Migration system
- [x] screenshots table
- [x] collections table
- [x] tags table
- [x] screenshot_tags table
- [x] search_history table
- [x] processing/import job persistence
- [x] indexes
- [x] DAO/repository layer
- [x] database tests (Written, but local execution blocked by IPC hang)

---

# Phase 2 — Real Import Foundation

Status: IN_PROGRESS

- [x] Android media/file selection
- [x] permission handling
- [x] app-managed thumbnail storage
- [x] image validation
- [x] MediaStore indexing (replacing file copying)
- [x] content hashing
- [x] thumbnail generation
- [x] persistent queue
- [x] bounded workers
- [x] duplicate handling
- [x] progress persistence
- [ ] index tests

Do not implement OCR yet unless required to verify pipeline boundaries.

---

# Phase 3 — OCR

Status: NOT_STARTED

- [ ] ML Kit OCR integration
- [ ] OCR worker
- [ ] persistence
- [ ] error handling
- [ ] retry
- [ ] stale-job recovery
- [ ] OCR tests
- [ ] real-device validation

---

# Phase 4 — FTS5 Search

Status: NOT_STARTED

- [ ] FTS5 table
- [ ] synchronization
- [ ] query normalization
- [ ] safe query construction
- [ ] ranking
- [ ] snippets
- [ ] highlighting
- [ ] search repository
- [ ] performance tests
- [ ] 10k dataset test

---

# Phase 5 — Gallery

Status: NOT_STARTED

- [ ] thumbnail grid
- [ ] lazy loading
- [ ] sorting
- [ ] favorites
- [ ] multi-select
- [ ] deletion
- [ ] selection toolbar
- [ ] performance validation

---

# Phase 6 — Search UI

Status: NOT_STARTED

- [ ] search screen
- [ ] debounced input
- [ ] recent searches
- [ ] result cards
- [ ] matched snippets
- [ ] highlighting
- [ ] empty state
- [ ] loading/error states
- [ ] filter foundation

---

# Phase 7 — Detail

Status: NOT_STARTED

- [ ] image viewer
- [ ] zoom
- [ ] OCR display
- [ ] copy OCR
- [ ] tags
- [ ] collections
- [ ] favorite
- [ ] share
- [ ] delete

---

# Phase 8 — Collections + Tags

Status: NOT_STARTED

- [ ] create collection
- [ ] edit collection
- [ ] delete collection safely
- [ ] assign screenshots
- [ ] create tags
- [ ] autocomplete
- [ ] tag usage counts
- [ ] bulk tagging

---

# Phase 9 — Cleaner + Trash

Status: NOT_STARTED

- [ ] cleaner queue
- [ ] swipe physics
- [ ] haptics
- [ ] keep/delete actions
- [ ] undo
- [ ] trash
- [ ] restore
- [ ] permanent deletion
- [ ] progress
- [ ] cleaner performance

---

# Phase 10 — Background Processing

Status: NOT_STARTED

- [ ] persistent processing
- [ ] Android background strategy
- [ ] foreground execution where required
- [ ] notification progress
- [ ] restart recovery
- [ ] cancellation
- [ ] retry
- [ ] low-storage handling

---

# Phase 11 — Hardening

Status: NOT_STARTED

- [ ] storage verification
- [ ] repair tool
- [ ] FTS rebuild
- [ ] missing-file detection
- [ ] orphan detection
- [ ] migration testing
- [ ] crash recovery testing
- [ ] 2k real screenshot test
- [ ] 10k dataset test
- [ ] airplane-mode test
- [ ] permission test
- [ ] low-memory testing
- [ ] low-storage testing
- [ ] accessibility pass
- [ ] UI polish
- [ ] release build

---

# Phase 12 — Release Readiness

Status: NOT_STARTED

- [ ] release configuration
- [ ] app icon
- [ ] privacy copy
- [ ] store metadata
- [ ] final real-device test
- [ ] no debug/fake data
- [ ] no unintended network dependency
- [ ] final analyzer/test pass

---

# Phase 13 — Backup / Restore

Status: NOT_STARTED

- [ ] portable local backup format
- [ ] preserve screenshots, OCR, tags, and collections
- [ ] export implementation
- [ ] restore implementation
