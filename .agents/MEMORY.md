# MEMORY

This file tracks key decisions, conventions, and session learnings for the soccer-assistant-coach codebase. Keep under 200 lines; prune older entries to `LONGTERM_MEMORY.md`.

---

## Session: May 18, 2026 — iOS CI debugging: keychain hang fix and runner choice

Date: 2026-05-18

### What was done
Debugged and fixed a persistent hang in `flutter build ipa` on GitHub Actions macOS runners. All one-time setup steps (Match init, secrets, agreements) are now complete. Updated `.agents/memory/ios_setup.md` with current state.

### Changes made

| Change | Detail |
|--------|--------|
| `fastlane/Fastfile` `setup_signing` | Added `create_keychain` + passed `keychain_name`/`keychain_password` to `match` so the cert lands in a named, always-unlocked keychain |
| `.github/workflows/release-ios.yml` | Added `security set-key-partition-list` step before `flutter build ipa`; runner changed from `macos-latest` → `macos-14` → `macos-13` → back to `macos-14` |
| `ios/ExportOptions.plist` | Created for manual signing: `app-store` method, `DPS86D59PK`, profile `match AppStore com.useunix.soccerassistantcoach` |
| `Gemfile.lock` | Added `arm64-darwin-23` to PLATFORMS so bundler works on macOS CI runners |
| `.agents/memory/ios_setup.md` | Updated runner choice, Admin key requirement, and marked one-time steps complete |

### Key learnings

**Runner choice — use `macos-14`**
- `macos-13` (Intel): queue wait > 45 min in practice — not usable
- `macos-latest` / `macos-15`: 6-hour silent hangs during testing — avoid
- `macos-14` (Apple Silicon): picks up quickly, works correctly with the keychain fix

**Why `flutter build ipa` hung silently**
`flutter build ipa` invokes xcodebuild as a subprocess _outside_ of fastlane's session. When `match` installs the distribution cert into fastlane's ephemeral temp keychain, xcodebuild can't find it and waits indefinitely for a keychain prompt. Fix requires two things together:
1. `create_keychain(name: "build.keychain", default_keychain: true, unlock: true, timeout: 3600)` in `setup_signing` — creates a persistent named keychain that stays unlocked
2. `security set-key-partition-list -S apple-tool:,apple: -s -k buildpassword ~/Library/Keychains/build.keychain-db` — grants codesign direct access to the signing key with no UI prompts

**Use `flutter build ipa`, not fastlane `build_app`**
`fastlane build_app` (xcodebuild via fastlane) also hangs — same root cause, plus CocoaPods ruby environment conflicts when called from inside fastlane's `sh()`. `flutter build ipa --export-options-plist=ios/ExportOptions.plist` as a standalone workflow step avoids both issues.

**Pipeline structure**
```
setup_signing (fastlane) → Allow codesign access (security cmd) → flutter build ipa → fastlane ios release (upload only)
```

**Admin API key required**
App Store Connect API key must have **Admin** role. Developer role cannot create Distribution certificates — Match fails silently or with a misleading auth error.

**One-time steps now complete**
- Match certificates repo populated with dist cert + App Store provisioning profile
- All 6 GitHub secrets set
- Apple Developer Program and App Store Connect agreements accepted at both portals

---

## Session: May 4, 2026 — Play Store compliance + store listing assets

Date: 2026-05-04

### What was done
Removed the `USE_EXACT_ALARM` Android permission (restricted to alarm/calendar apps; Play Store rejected it). Generated Play Store listing assets. Documented the release process for agents and humans.

### Changes made

| Change | Detail |
|--------|--------|
| `android/app/src/main/AndroidManifest.xml` | Removed `USE_EXACT_ALARM`; kept `SCHEDULE_EXACT_ALARM` (user opt-in, allowed for any app). Existing fallback to inexact alarms in `notification_service.dart` handles the denied-permission case. |
| `store/assets/` | Added feature graphic (1024×500) + 2 phone, 2 tablet-7", 2 tablet-10" screenshots |
| `store/generate_assets.py` | Python/Pillow script to regenerate all store assets |
| `AGENTS.md` | Added "Publishing a Release" section (WSL + `bundle exec fastlane`) |
| `README.md` | Added "Publishing a Release" section with lane table and asset regen instructions |

### Key learnings
- **`USE_EXACT_ALARM`** is auto-granted but Play-Store-restricted to alarm/calendar apps. Any other app must use **`SCHEDULE_EXACT_ALARM`** (requires user opt-in) and handle the denied case with inexact fallback.
- **Fastlane must be run from WSL** via `bundle exec fastlane <lane>` — it is vendored in `vendor/bundle/ruby/3.2.0` and not accessible from PowerShell or Git Bash on this machine.
- WSL path to project: `/mnt/c/Users/rdane/Documents/Projects/soccer-assistant-coach`
- Store assets can be regenerated any time with `python -X utf8 store/generate_assets.py` (Pillow required, already installed).

---

## Session: May 3, 2026 — Patrol journey tests for major user flows

Date: 2026-05-03

### What was done
Added four new Patrol E2E journey tests covering the major user flows that the original alarm-focused suite didn't reach: team creation, player substitution, manual shift advancement, and starting a new season from a previous season's roster.

### Changes made

| Change | Detail |
|--------|--------|
| `patrol_test/team_management_journey_test.dart` | Home → Manage Teams → Create Team dialog → assert team appears in active season |
| `patrol_test/substitution_journey_test.dart` | Pushes the production GoRouter into `/game/:id/assign/:shiftId`, picks a position via dropdown, asserts the `player_shifts` row landed |
| `patrol_test/shift_management_journey_test.dart` | Two queued shifts → tap "Next Shift" → confirm "Start next shift early?" dialog → assert `games.currentShiftId` advances |
| `patrol_test/season_clone_journey_test.dart` | Manage Seasons → Create New Season with a previous-season team checked → assert new season + cloned roster |
| `patrol_test/README.md` | Added the four new tests to the coverage table |
| `.agents/TESTING.md` | Same coverage update in the testing guide |
| `.agents/ARCHITECTURE.md` | Added two decision rows: Patrol substitution coverage uses the deep-link route, and the journey suite always ends with a DB assertion |
| `README.md` | New "End-to-End Tests (Patrol)" section listing every journey + how to invoke `patrol test` |

### Key learnings
- **Substitution UI is fragmented across two screens** (`AssignPlayersScreen` route + the inline lineup builder used by the live game screen). Driving the deep-link route is much more deterministic for Patrol than driving the live game screen's auto-rotation/lineup-builder UI, and exercises the same `setPlayerPosition` code path.
- **`router.push('/game/$id/assign/$shiftId')` works directly inside a Patrol test** because the harness already pumps `SoccerApp` (which uses `MaterialApp.router(routerConfig: router)`) — no separate `Navigator.of(context)` lookup needed.
- **The `_handleStartNextShift` confirmation dialog** appears whenever there's still time on the current shift, so a Patrol test that seeds a fresh game (zero elapsed time) will always need to dismiss "Start next shift early?" before the shift actually advances.
- **`cloneSelectedTeamsToSeason` is what the Create-New-Season dialog calls** when the user checks at least one existing team. The cloned team gets a new ID with the same name, and the player roster is duplicated into the new `seasonId'.
- Every journey test ends with a DB-level assertion (`getAllTeams`, `watchAssignments`, `getGame`, `watchTeams(seasonId:)`, raw player select). This catches "tap succeeded but write was lost" regressions that pure UI assertions miss.
- **Active-Games card on Home filters on `startTime IS NOT NULL`** (`watchActiveGames` in `database.dart`). Any Patrol test that drives navigation via the home dashboard's "vs <opponent>" card MUST seed `startTime: drift.Value(DateTime.now())` on the game — the schema column is nullable with no default. Caught when `shift_management_journey_test.dart` initially failed at the home-card lookup; the same fix was retro-applied to the older `shift_alarm_journey_test.dart` and `halftime_journey_test.dart` to unblock their first step. (Those two have additional pre-existing downstream issues — likely the `for ... pump(seconds:1)` loop not advancing the wall-clock-based `StopwatchCtrl` timer on a real device — out of scope for this session.)

### Verified on emulator (emulator-5554, Android API 36)
- `smoke_test.dart` ✅
- `team_management_journey_test.dart` ✅
- `substitution_journey_test.dart` ✅
- `shift_management_journey_test.dart` ✅
- `season_clone_journey_test.dart` ✅

---

## Session: May 1, 2026 — Patrol 4.x upgrade and PATH setup

Date: 2026-05-01

### What was done
Upgraded patrol from 3.x to 4.5.0 (compatible with patrol_cli 4.3.1), added patrol_cli to the Windows PATH, confirmed the smoke test passes in ~4 s, and migrated tests from `integration_test/` to `patrol_test/`.

### Changes made

| Change | Detail |
|--------|--------|
| `pubspec.yaml` | `patrol: ^3.15.2` → `^4.5.0`; removed `integration_test: sdk: flutter` (no longer needed); removed `test_path: integration_test` override |
| Tests moved | `integration_test/` → `patrol_test/` (patrol 4.x default); avoids Windows absolute-path bug in bundle generator |
| `notifications_test.dart` | `$.native.grantPermissionWhenInUse()` → `$.platform.mobile.grantPermissionWhenInUse()` (patrol 4.x API) |
| All Patrol tests | Added `timeout: Duration(seconds: N)` to every `pumpAndSettle()` call — without it, always-open Drift streams cause ~19-minute hangs |
| Windows PATH | Added `%LOCALAPPDATA%\Pub\Cache\bin` to User PATH so `patrol` is callable from any terminal |
| `.agents/TESTING.md` | Updated directory references from `integration_test/` to `patrol_test/`; added patrol_cli install note |
| `.agents/ARCHITECTURE.md` | Added two decision rows for `pumpAndSettle` timeout requirement and Windows `patrol_test/` placement |
| `patrol_test/README.md` | Fixed stale `-t integration_test/` run example |

### Key learnings
- **patrol_cli 4.x Windows bug**: when `test_path` in `pubspec.yaml` points outside `patrol_test/`, the CLI generates `import 'C:/Users/...'` with a drive letter — invalid Dart. Fix: use the default `patrol_test/` directory and omit `test_path`.
- **`pumpAndSettle()` without timeout hangs**: Drift `StreamProvider`s are always-open; `pumpAndSettle` never settles. Always pass `timeout: const Duration(seconds: 5)` (or 3 s for post-tap settles).
- **`patrol_test/test_bundle.dart` is generated** — delete it before re-running if it's stale; patrol regenerates it on the next `patrol test` invocation.
- **`flutter clean` required** after moving test files — the incremental compiler caches old source paths in depfiles and fails even after the files are gone.

---

## Session: May 1, 2026 — Comprehensive E2E test coverage

Date: 2026-05-01

### What was done
Added a layered automated test stack: 7 new widget/DB test files in `test/` (36 new tests) plus a full Patrol integration suite in `integration_test/` covering the flows that only make sense on a real device.

### Changes made

| Change | Detail |
|--------|--------|
| `pubspec.yaml` | Added `patrol: ^3.15.2` and `integration_test` (sdk: flutter) to dev_dependencies; added `patrol:` config block with Android package + iOS bundle id |
| `test/helpers/fixtures.dart` | Shared `seedTeam` / `seedPlayer` / `seedShift` helpers |
| `test/alarm_settings_test.dart` | Model defaults, copyWith, JSON round-trip, fresh-container restore |
| `test/alert_service_test.dart` | Gates on `shiftsEnabled` / `halftimeEnabled`, double-trigger no-op, ack stops |
| `test/substitution_test.dart` | DB-level: insert, replace, attendance-driven removal, present-player filter |
| `test/team_config_test.dart` | Shift length / half duration getters, setters, defaults, mode round-trip |
| `test/shift_lifecycle_test.dart` | `incrementShiftDuration`, `watchActiveShift`, `watchGameShifts` |
| `test/game_lifecycle_test.dart` | Game completion, timer flips, JSON export/import round-trip |
| `test/stopwatch_ctrl_test.dart` | `setMeta` persistence + fresh-container `_restore` |
| `integration_test/smoke_test.dart` | App boots, nav to Settings |
| `integration_test/settings_test.dart` | Toggling shift/halftime alarms persists |
| `integration_test/shift_alarm_journey_test.dart` | Seeded 3-second shift fires alarm SnackBar |
| `integration_test/halftime_journey_test.dart` | Seeded 6-second half advances `currentHalf` |
| `integration_test/notifications_test.dart` | Notification plumbing + permission grant via Patrol native |
| `integration_test/json_import_test.dart` | On-device `AppDb.importDatabase` |
| `integration_test/helpers/app_harness.dart` | `initApp()` + `appUnderTest({AppDb? db})` for in-memory isolation |
| `integration_test/README.md` | Patrol setup + run instructions for both platforms |
| `android/app/build.gradle.kts` | `PatrolJUnitRunner` + orchestrator + `clearPackageData` |
| `android/app/src/androidTest/.../MainActivityTest.java` | Parameterized JUnit shim that enumerates Dart tests |
| `ios/RunnerUITests/RunnerUITests.m` | iOS Patrol runner stub (Xcode target wiring still requires `patrol bootstrap` on a Mac) |
| `.agents/TESTING.md` + `.agents/ARCHITECTURE.md` | Documented the two-layer stack |

### Key learnings
- **`stopwatchProvider` is `NotifierProvider.autoDispose.family`** — `container.read(provider.notifier)` does *not* keep the provider alive. Subsequent calls on the captured controller throw "Cannot use the Ref ... after it has been disposed". Fix: `container.listen<int>(provider, (_, _) {})` to hold the listener open, then `read` the notifier.
- **`StopwatchCtrl.start()` / `pause()` / `reset()` cannot be unit-tested** — they all call `NotificationService.cancelStopwatch`, which dereferences `FlutterLocalNotificationsPlatform.instance` (a `late` field that never gets initialized in the unit-test environment). LateInitializationError. These paths are exercised by the Patrol E2E suite instead.
- **AssignPlayersScreen widget tests leave a Timer pending** even after `pumpWidget(SizedBox)` — the StreamBuilder + Drift stream subscription combo holds onto a timer past `_verifyInvariants`. Equivalent coverage moved to DB-level tests (`presentPlayersForGame`, `hasPresentPlayersForGame`) plus Patrol E2E.
- **Patrol tests must use a real `ProviderScope` override**, not `bootstrapApp` returning `Widget` — the existing `Override` type from riverpod 3.0.3 is **not** in the public `show` list, so the harness exposes a typed `appUnderTest({AppDb? db})` helper instead of letting tests pass arbitrary overrides.
- The shift / halftime alarm E2E tests use the team's **configurable** `shift_length_seconds` / `half_duration_seconds` (set to 3 s / 6 s for tests) rather than a debug fast-forward hook — this exercises the same code path production users run.

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

