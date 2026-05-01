# MEMORY

This file tracks key decisions, conventions, and session learnings for the soccer-assistant-coach codebase. Keep under 200 lines; prune older entries to `LONGTERM_MEMORY.md`.

---

## Session: April 24, 2026 — Production readiness pass

Date: 2026-04-24

### What was done
Full pre-store audit and fixes to prepare the app for Apple App Store and Google Play Store submission.

### Changes made

| Change | Detail |
|--------|--------|
| Removed `assets/sounds/` from pubspec.yaml | Directory was empty; sound service uses `SystemSound`, not file assets |
| Added `ios/Runner/PrivacyInfo.xcprivacy` | Required by Apple for apps using `shared_preferences` (UserDefaults) and `path_provider` (file timestamps); prevents App Store rejection |
| Fixed `CFBundleName` in `Info.plist` | Changed from `soccer_assistant_coach` to `Soccer Assistant Coach` |
| Replaced `print()` with `debugPrint()` | In `database.dart` and `season_provider.dart` — no production log spam |
| `.gitignore` additions | `soccer_manager.db`, `*.db-journal`, `notes.txt`, `learnings.txt`, loose PNG/scripts, `android/key.properties`, keystore files |
| Moved `full_season_fixed_metrics.json` | Root → `test/fixtures/` |
| Fixed fixture path in `import_json_test.dart` | Updated to `test/fixtures/full_season_fixed_metrics.json` |
| Rewrote `test/database_migration_test.dart` | 5 real tests: fresh-install schema invariants + v17→v18 upgrade with data preservation |
| Added `AppDb.forTesting(super.executor)` constructor | Enables file-backed test databases for migration tests |
| Added `sqlite3: any` to dev_dependencies | Raw SQL seeding for pre-migration DB files in migration tests |
| Fixed `StopwatchCtrl` Timer leak | Added `ref.onDispose(() => _t?.cancel())` in `build()` — periodic timer was outliving its ProviderScope |
| Rewrote `game_screen_test.dart` | `navigateAway()` helper forces ProviderScope disposal before `_verifyInvariants`; removed `SharedPreferences.setMockInitialValues` (hung in fake-async zone) |
| Stripped diagnostic `debugPrint` statements | Removed ~40 logging calls from `game_screen.dart` and `game_scaffold.dart` added during hang investigation |

### Key learnings
- `_verifyInvariants()` in flutter_test runs **before** widget tree disposal — any timer pending at that point causes test failure
- `SharedPreferences.setMockInitialValues({})` registers a handler in the real async zone, causing `getInstance()` to hang inside flutter_test's fake-async zone — never call it in widget tests
- Riverpod `autoDispose` does NOT auto-cancel `Timer` objects held by a `Notifier`; must register `ref.onDispose(() => _t?.cancel())` explicitly in `build()`
- To test DB migrations: use raw `sqlite3` package to seed old schema files, then open with `AppDb.forTesting(NativeDatabase(file))` — opening via `AppDb` itself would trigger `onCreate` first

---

## Session: April 24, 2026 — Adopt .agents/ structure

Date: 2026-04-24

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
