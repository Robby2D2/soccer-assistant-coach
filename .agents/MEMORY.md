# MEMORY

This file tracks key decisions, conventions, and session learnings for the soccer-assistant-coach codebase. Keep under 200 lines; prune older entries to `LONGTERM_MEMORY.md`.

---

## Session: April 24, 2026 — Adopt .agents/ structure

### What was done
Reorganized project documentation to follow the `.agents/` directory convention.

### Changes made

| Change | Detail |
|--------|--------|
| Created `.agents/` directory | Now holds `ARCHITECTURE.md`, `TESTING.md`, `CODING.md`, `MEMORY.md` |
| Moved `ARCHITECTURE.md` | Root → `.agents/ARCHITECTURE.md`; removed stale link to deleted `memory/contrast_notes.md` |
| Moved `TEST.md` | Root → `.agents/TESTING.md`; renamed to match convention |
| Created `.agents/CODING.md` | Extracted coding principles and Flutter rules from old root `AGENTS.md` |
| Updated root `AGENTS.md` | Now an entry-point that references `.agents/` subdocs and includes Key Changes protocol |
| Updated root `CLAUDE.md` | Simplified to `@AGENTS.md` |
| Cleaned up `memory/MEMORY.md` | Removed stale entries for deleted files |

### Key conventions
- `.agents/MEMORY.md` — session-level task log (this file); prune to topic files in `.agents/memory/` when > 200 lines
- `.agents/LONGTERM_MEMORY.md` — table of contents linking to files in `.agents/memory/`
- `.agents/memory/<topic>.md` — individual long-term memory files by topic (theming, timer, etc.)
- `memory/` directory — feature-level implementation notes; indexed by `memory/MEMORY.md`
- Generated files (`*.g.dart`, `*.drift.dart`) must never be edited — always regenerate
- `AppDb.test()` for all test DB access — never touch `soccer_manager.db` in tests
