# MaybeLater — Phase Prompts

Use these prompts one at a time in Antigravity/AI coding agents.

Do not paste all phase prompts into one request.

---

## Phase 0 Prompt

Read `AGENTS.md`, `docs/ROADMAP.md`, and `docs/ARCHITECTURE.md`.

We are starting MaybeLater from the current repository state.

Do not implement future phases.

First inspect:

- repository structure
- Flutter version
- Dart version
- Android configuration
- current dependencies
- existing code

Then implement Phase 0 only.

Establish the project foundation, theme, routing, Riverpod setup, and basic app shell.

Before finishing:

- run `dart format .`
- run `flutter analyze`
- run `flutter test`
- fix issues

Update `docs/ROADMAP.md` only after verification.

Report:
1. files changed
2. what was implemented
3. commands/tests run
4. remaining issues

Do not claim completion if the build is broken.

---

## Phase 1 Prompt

Read:

- `AGENTS.md`
- `docs/ROADMAP.md`
- `docs/DATABASE.md`
- existing database code

Implement Phase 1 only.

Build the real SQLite database foundation with migrations, models, DAOs/repositories, indexes, and tests.

Do not implement OCR, search UI, cleaner, or unrelated future features.

Use transactions and safe parameterized queries.

Run formatting, analyzer, and relevant tests.

Update the roadmap only after verification.

Report exact verification results.

---

## Phase 2 Prompt

Read:

- `AGENTS.md`
- `docs/ROADMAP.md`
- `docs/IMPORT_PIPELINE.md`
- `docs/DATABASE.md`
- existing implementation

Implement Phase 2 only.

Build the real screenshot import foundation:

- media/file selection
- correct Android permission/media handling
- app-managed storage
- image validation
- copying
- hashing
- thumbnails
- persistent import jobs
- bounded workers
- duplicate handling
- progress persistence

Do not add OCR yet unless needed to keep the pipeline boundaries correct.

Do not fake processing.

Test interruption and duplicate behavior.

Run formatting, analyzer, and tests.

Update roadmap only after verification.

---

## Phase 3 Prompt

Read:

- `AGENTS.md`
- `docs/ROADMAP.md`
- `docs/IMPORT_PIPELINE.md`
- existing implementation

Implement Phase 3 only.

Add real on-device ML Kit OCR.

Do not invent OCR output.

Integrate OCR into the persistent processing pipeline.

A single OCR failure must not stop unrelated jobs.

Implement retry/recovery.

Run analyzer and tests.

Validate on real screenshots if available.

Update roadmap only after verification.

---

## Phase 4 Prompt

Read:

- `AGENTS.md`
- `docs/ROADMAP.md`
- `docs/DATABASE.md`
- `docs/SEARCH.md`
- existing database/OCR implementation

Implement Phase 4 only.

Build the real SQLite FTS5 search engine.

Implement:

- FTS table
- synchronization
- safe query normalization
- ranking
- snippets
- highlighting data
- search repository
- tests

Do not build the search UI yet unless required for verification.

Do not use LIKE as the primary search.

Benchmark using 1k/5k/10k metadata datasets.

Update roadmap only after verification.

---

## Phase 5 Prompt

Read:

- `AGENTS.md`
- `docs/ROADMAP.md`
- `docs/UI.md`
- existing gallery/data implementation

Implement Phase 5 only.

Build the real gallery using local thumbnails.

Requirements:

- lazy loading
- 3-column default
- sorting
- favorites
- multi-select
- deletion
- selection toolbar

Do not load full-resolution images into the grid.

Test with a large dataset.

Run analyzer/tests.

Update roadmap only after verification.

---

## Phase 6 Prompt

Read:

- `AGENTS.md`
- `docs/ROADMAP.md`
- `docs/SEARCH.md`
- `docs/UI.md`
- existing search engine

Implement Phase 6 only.

Build the search UI on top of the existing real FTS5 search engine.

Requirements:

- debounced search
- recent searches
- result cards
- snippets
- matched-term highlighting
- empty state
- loading/error states

Do not replace the search engine with mock logic.

Run analyzer/tests.

Update roadmap only after verification.

---

## Phase 7 Prompt

Read:

- `AGENTS.md`
- `docs/ROADMAP.md`
- `docs/UI.md`
- existing screenshot model/repository

Implement Phase 7 only.

Build the screenshot detail screen:

- image viewer
- zoom
- OCR
- copy OCR
- tags
- collection
- favorite
- share
- delete

Use real database data.

No placeholder screenshot data.

Run analyzer/tests.

Update roadmap only after verification.

---

## Phase 8 Prompt

Read:

- `AGENTS.md`
- `docs/ROADMAP.md`
- `docs/DATABASE.md`
- `docs/UI.md`

Implement Phase 8 only.

Build collections and tags.

Deleting a collection must not delete screenshots.

Tags must support autocomplete and usage counts.

Use real persistence.

Run analyzer/tests.

Update roadmap only after verification.

---

## Phase 9 Prompt

Read:

- `AGENTS.md`
- `docs/ROADMAP.md`
- `docs/UI.md`
- existing screenshot/trash implementation

Implement Phase 9 only.

Build Cleaner and recoverable Trash.

Cleaner:

- left swipe = trash
- right swipe = keep
- haptics
- card physics
- small preload stack
- OCR snippet
- progress

Never permanently delete during a normal swipe.

Implement undo/restore.

Run analyzer/tests.

Update roadmap only after verification.

---

## Phase 10 Prompt

Read:

- `AGENTS.md`
- `docs/ROADMAP.md`
- `docs/IMPORT_PIPELINE.md`

Implement Phase 10 only.

Harden long-running processing for Android.

Implement the appropriate persistent/background strategy for the actual Android constraints.

Requirements:

- progress notification where needed
- restart recovery
- cancellation
- retry
- low-storage handling

Do not claim background execution that Android does not permit.

Test app kill/restart behavior.

Run analyzer/tests.

Update roadmap only after verification.

---

## Phase 11 Prompt

Read:

- `AGENTS.md`
- `docs/ROADMAP.md`
- `docs/TESTING.md`
- all relevant architecture docs

Implement Phase 11 only.

Harden the complete application.

Focus on:

- crash recovery
- missing files
- orphan records
- FTS rebuild
- storage verification
- low memory
- low storage
- permissions
- large datasets
- airplane mode
- accessibility
- performance
- UI polish

Do not add new product features.

Run the full test/analyzer suite.

Update roadmap only after verification.

---

## Phase 12 Prompt

Read:

- `AGENTS.md`
- `docs/ROADMAP.md`
- `docs/TESTING.md`
- `docs/PRODUCT.md`

Implement Phase 12 only.

Prepare the app for a release build.

Do not add new features.

Verify:

- release configuration
- app icon
- privacy copy
- store metadata
- real-device workflow
- no fake/debug data
- no unintended network dependency
- final analyzer/test pass

Only mark complete when verified.
