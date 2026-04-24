# Coding Standards — Soccer Assistant Coach

## Principles

- **KISS** — Keep solutions simple. Prefer the straightforward path; avoid clever code that requires explanation.
- **DRY** — Do not duplicate logic, UI patterns, or data access. Extract shared behavior into utilities or providers only when used in more than one place.
- No speculative features, no future-proofing abstractions, no extra configurability beyond what is asked.
- Match the existing code style. Read surrounding code before writing new code.

---

## Flutter / Dart Rules

- Do **not** use raw `Scaffold` or `AppBar` — use the established `TeamScaffold`/`GameScaffold` + `TeamAppBar` pattern (see [ARCHITECTURE.md](ARCHITECTURE.md)).
- Do **not** hardcode colors — use `Theme.of(context).colorScheme.*` and `TeamColorContrast.onColorFor()` for contrast safety.
- Do **not** edit generated files (`*.g.dart`, `*.drift.dart`) — regenerate them:
  ```
  flutter pub run build_runner build --delete-conflicting-outputs
  ```
- Do **not** touch the on-disk database in tests — use `AppDb.test()` (in-memory).
- Always use proper types; avoid `dynamic` or implicit `Object`.
- Use async/await patterns consistently.

---

## Documentation

- **Architecture and significant decisions** → [.agents/ARCHITECTURE.md](ARCHITECTURE.md).
- **Testing patterns and guidance** → [.agents/TESTING.md](TESTING.md).
- **Feature-level and long-term notes** → store as a topic-specific file in `.agents/memory/` and add a link in [.agents/LONGTERM_MEMORY.md](LONGTERM_MEMORY.md).
- Do not scatter documentation into ad-hoc comments when a dedicated doc file is more appropriate.

---

## Pull Request / Commit Hygiene

- Commits should be small and focused.
- Describe *why* in the commit message, not just *what*.
- Do not commit generated files if they can be regenerated cleanly from source.
