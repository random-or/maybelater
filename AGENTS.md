# MaybeLater — Agent Operating Instructions

## Mission

Build MaybeLater as a production-quality, privacy-first, offline Flutter Android application.

Core product:

REAL SCREENSHOT
→ LOCAL OCR
→ SQLITE
→ FTS5
→ FAST SEARCH
→ CORRECT SCREENSHOT

The primary success criterion is that a user can import thousands of screenshots, search for remembered text, and find the correct screenshot quickly.

## Non-Negotiable Rules

1. Read this file before changing code.
2. Read `docs/ROADMAP.md` before starting work.
3. Read the relevant documentation for the current phase.
4. Never invent requirements.
5. Never invent package APIs. Inspect installed versions/APIs first.
6. Never create fake OCR, fake search, fake progress, fake AI labels, or fake data.
7. No cloud services, accounts, analytics, telemetry, advertising SDKs, or remote AI APIs.
8. Do not modify unrelated features.
9. Do not rewrite working code without a concrete reason.
10. Keep database access out of widgets.
11. Keep business logic out of widgets.
12. Use Riverpod for application state.
13. Use SQLite FTS5 for primary screenshot search.
14. Do not use `LIKE '%query%'` as the primary search implementation.
15. Imports must be persistent, resumable, and recoverable.
16. One failed screenshot must never stop the whole import.
17. Never load thousands of full-resolution images into memory.
18. Use thumbnails for gallery views.
19. Never claim a feature works unless it was actually implemented and verified.
20. Run formatting, analyzer, and relevant tests after changes.
21. Do not start future roadmap phases without explicit instruction.
22. Preserve user data. Never silently delete or overwrite screenshots.
23. Prefer the smallest correct implementation over speculative architecture.
24. If an assumption materially affects architecture, record it in `docs/DECISIONS.md`.

## Workflow

Before coding:

1. Inspect the repository.
2. Inspect Flutter/Dart versions.
3. Inspect Android configuration.
4. Read `docs/ROADMAP.md`.
5. Read documentation relevant to the current phase.
6. Inspect existing implementation.
7. State the exact scope you will implement.
8. Implement only that scope.
9. Run `dart format .`.
10. Run `flutter analyze`.
11. Run relevant tests.
12. Fix failures.
13. Update `docs/ROADMAP.md`.
14. Report exactly what changed, what was verified, and what remains.

## Scope Control

Only work on the first incomplete roadmap phase unless the user explicitly names another phase.

If something is ambiguous:

- inspect existing docs first
- inspect existing code second
- make the smallest reasonable decision
- record important decisions
- do not invent unrelated features

If a dependency/API is uncertain, inspect the installed package or official documentation instead of guessing.

## Completion Standard

A phase is not complete because files exist.

A phase is complete only when:

- implementation exists
- code compiles
- analyzer is clean or known issues are explicitly reported
- relevant tests pass
- behavior has been verified as far as the environment allows
- roadmap status is updated

## Current Phase

Read `docs/ROADMAP.md`. The roadmap is the source of truth for implementation order.
