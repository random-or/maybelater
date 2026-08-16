# MaybeLater Agent Documentation

This directory contains the persistent engineering context for the MaybeLater project.

## Files

- `../AGENTS.md` — permanent instructions for coding agents
- `PRODUCT.md` — product requirements
- `ARCHITECTURE.md` — technical architecture
- `DATABASE.md` — SQLite/FTS5 specification
- `IMPORT_PIPELINE.md` — import and processing system
- `SEARCH.md` — search engine requirements
- `UI.md` — visual and interaction requirements
- `TESTING.md` — testing strategy
- `ROADMAP.md` — implementation source of truth
- `DECISIONS.md` — accepted architectural decisions
- `PHASE_PROMPTS.md` — one-at-a-time prompts for the coding agent

## How to use

1. Put these files in the project root.
2. Start the agent.
3. Tell it to read `AGENTS.md` and `docs/ROADMAP.md`.
4. Use one phase prompt from `PHASE_PROMPTS.md`.
5. Let the agent implement only that phase.
6. Verify the result.
7. Move to the next phase.

Do not give the agent the entire project as one giant implementation request.
