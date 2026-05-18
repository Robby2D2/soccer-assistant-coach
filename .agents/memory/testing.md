# Testing — E2E and Patrol

## Session: May 1, 2026 — Patrol 4.x upgrade and PATH setup

### What was done
Upgraded patrol from 3.x to 4.5.0 (compatible with patrol_cli 4.3.1), added patrol_cli to the Windows PATH, confirmed the smoke test passes in ~4 s, and migrated tests from `integration_test/` to `patrol_test/`.

### Changes made

| Change | Detail |
|--------|--------|
| `pubspec.yaml` | `patrol: ^3.15.2` → `^4.5.0`; removed `integration_test: sdk: flutter`; removed `test_path` override |
| Tests moved | `integration_test/` → `patrol_test/` (patrol 4.x default); avoids Windows absolute-path bug in bundle generator |
| `notifications_test.dart` | `$.native.grantPermissionWhenInUse()` → `$.platform.mobile.grantPermissionWhenInUse()` (patrol 4.x API) |
| All Patrol tests | Added `timeout: Duration(seconds: N)` to every `pumpAndSettle()` call — without it, always-open Drift streams cause ~19-minute hangs |
| Windows PATH | Added `%LOCALAPPDATA%\Pub\Cache\bin` to User PATH so `patrol` is callable from any terminal |

### Key learnings
- **patrol_cli 4.x Windows bug**: when `test_path` points outside `patrol_test/`, the CLI generates `import 'C:/Users/...'` with a drive letter — invalid Dart. Fix: use the default `patrol_test/` directory and omit `test_path`.
- **`pumpAndSettle()` without timeout hangs**: Drift `StreamProvider`s are always-open. Always pass `timeout: const Duration(seconds: 5)` (or 3 s for post-tap settles).
- **`patrol_test/test_bundle.dart` is generated** — delete it before re-running if stale.
- **`flutter clean` required** after moving test files — incremental compiler caches old source paths.

---

## Session: May 1, 2026 — Comprehensive E2E test coverage

### What was done
Added 7 new widget/DB test files in `test/` (36 new tests) plus a full Patrol integration suite covering flows that only make sense on a real device.

### Changes made

| Change | Detail |
|--------|--------|
| `test/alarm_settings_test.dart` | Model defaults, copyWith, JSON round-trip, fresh-container restore |
| `test/alert_service_test.dart` | Gates on `shiftsEnabled` / `halftimeEnabled`, double-trigger no-op, ack stops |
| `test/substitution_test.dart` | DB-level: insert, replace, attendance-driven removal, present-player filter |
| `test/team_config_test.dart` | Shift length / half duration getters, setters, defaults, mode round-trip |
| `test/shift_lifecycle_test.dart` | `incrementShiftDuration`, `watchActiveShift`, `watchGameShifts` |
| `test/game_lifecycle_test.dart` | Game completion, timer flips, JSON export/import round-trip |
| `test/stopwatch_ctrl_test.dart` | `setMeta` persistence + fresh-container `_restore` |
| Patrol suite | smoke, settings, shift alarm journey, halftime journey, notifications, json import |

### Key learnings
- **`stopwatchProvider` is `NotifierProvider.autoDispose.family`** — `container.read(provider.notifier)` does not keep the provider alive. Use `container.listen(provider, ...)` to hold it open.
- **`StopwatchCtrl.start()` / `pause()` / `reset()` cannot be unit-tested** — they call `NotificationService.cancelStopwatch`, which dereferences an uninitialized `late` field. Covered by Patrol E2E instead.
- **AssignPlayersScreen widget tests leave a Timer pending** — StreamBuilder + Drift stream holds onto a timer past `_verifyInvariants`. Coverage moved to DB-level tests + Patrol E2E.
- The shift/halftime alarm E2E tests use the team's configurable `shift_length_seconds` / `half_duration_seconds` (3 s / 6 s for tests) — exercises the same code path as production.

---

## Session: May 3, 2026 — Patrol journey tests for major user flows

### What was done
Added four Patrol journey tests covering team creation, substitution, shift advancement, and season cloning.

### Changes made

| Change | Detail |
|--------|--------|
| `patrol_test/team_management_journey_test.dart` | Home → Manage Teams → Create Team → assert in active season |
| `patrol_test/substitution_journey_test.dart` | Deep-links into `/game/:id/assign/:shiftId`, picks position, asserts DB row |
| `patrol_test/shift_management_journey_test.dart` | Two queued shifts → "Next Shift" → confirm dialog → assert `currentShiftId` advances |
| `patrol_test/season_clone_journey_test.dart` | Create New Season with previous-season team checked → assert cloned roster |

### Key learnings
- **`router.push('/game/$id/assign/$shiftId')` works directly inside Patrol** — harness already pumps `SoccerApp` with GoRouter.
- **`_handleStartNextShift` confirmation dialog** always appears on a fresh seeded game (zero elapsed time) — Patrol tests must dismiss it.
- **`cloneSelectedTeamsToSeason`** is what Create-New-Season calls; cloned team gets new ID, same name, duplicated roster.
- **Active-Games card filters on `startTime IS NOT NULL`** — seed `startTime: drift.Value(DateTime.now())` or the home card won't appear.
- Every journey test ends with a DB-level assertion to catch "tap succeeded but write was lost" regressions.
