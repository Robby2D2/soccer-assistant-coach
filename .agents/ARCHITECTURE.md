# Architecture — Soccer Assistant Coach

This document captures significant architectural decisions and patterns. Update it when making decisions that are not obvious from reading the code.

---

## High-Level Structure

```
lib/
  main.dart               # Entry point, ProviderScope root
  app.dart                # MaterialApp + router setup
  core/
    theme.dart            # Base Material 3 theme (no team context)
    team_theme_manager.dart  # teamThemeProvider (Riverpod)
    game_scaffold.dart    # GameScaffold widget
    providers.dart        # Shared global providers (dbProvider, etc.)
    router.dart           # go_router configuration
    season_provider.dart  # Active season provider
    positions.dart        # Position constants
  features/
    games/                # Game lifecycle screens + DB services
    teams/                # Team CRUD + color picker
    players/              # Player management
    seasons/              # Season management
    formations/           # Formation editor
    settings/             # App settings
    home/                 # Dashboard
    startup/              # Initialization logic
    debug/                # Debug-only screens
  data/
    db/                   # Drift database definition + DAOs
    services/             # Business logic services
  utils/                  # Shared utilities (TeamColorContrast, etc.)
  widgets/                # Shared reusable widgets
  l10n/                   # ARB localization files
```

---

## Database

- **ORM:** Drift (type-safe SQLite wrapper with code generation).
- **Location:** `lib/data/db/`
- **Singleton access:** `dbProvider` (Riverpod `Provider`).
- **Test isolation:** `AppDb.test()` creates an in-memory database.
- Migrations are versioned inside `AppDb`; see `database_migration_test.dart` for regression coverage.

---

## State Management

Riverpod v3 throughout.

- Global providers: `lib/core/providers.dart`
- Feature providers: co-located with the feature (e.g., `lib/features/games/`)
- Prefer `StreamProvider` or `AsyncNotifierProvider` over one-shot futures so the UI reacts to DB changes automatically.
- `dbProvider` is the root dependency; all data providers depend on it.

---

## Theming Pipeline

Team colors propagate through the widget tree via a layered system:

1. **Base theme** — `lib/core/theme.dart` (Material 3, brand seed). Used when no team is active.
2. **Team theme** — `TeamTheme` in `lib/utils/team_theme.dart`. Generates a `ColorScheme` from a team's primary color.
3. **Provider** — `teamThemeProvider` in `lib/core/team_theme_manager.dart` exposes the current team theme.
4. **Scaffolds** — `TeamScaffold` and `GameScaffold` apply the team theme to their subtree.

### Sideline design system

The "Sideline" design system (`design-system/design_handoff_sideline/`) layers on top of the above:

- **Tokens** — `lib/core/sideline.dart`: `SidelineColors` (neutral + whistle palettes), `SidelineSpacing`, `SidelineRadius`, and typography helpers `sidelineTextTheme()` (Hanken Grotesk) / `sidelineMono()` (Spline Sans Mono, tabular figures — use for all numerics). Light mode in `theme.dart` adopts these neutrals; dark mode keeps the seed scheme.
- **`TeamColors` ThemeExtension** — `lib/utils/team_theme.dart`: exposes team-derived `team`/`strong`/`soft`/`onTeam` shades on the active `ThemeData`. Read via `Theme.of(context).extension<TeamColors>()` or `teamColorsOf(context)` (in `lib/widgets/sideline_widgets.dart`). It is the **only** ThemeExtension in the app; `applyTo` sets it outright (do not spread `base.extensions` — the test front-end rejects the inferred type).
- **Components** — `lib/widgets/sideline_widgets.dart`: `SidelineHeroShiftCard`, `SidelineAlertBanner`, `SidelinePlayerShiftRow`, `SidelinePositionChip`, `SidelineNextOnChip`. The hero card + alert banner are live on the Live Game screen; the row/chip widgets exist but the rest of the Live Game layout (branded header, vertical pitch list, next-on wrap, bottom Next-Shift bar) and the Teams/Roster/Metrics rollout are still pending.

### Contrast Safety

`TeamColorContrast.onColorFor(Color)` returns black or white to maintain ≥ 4.5:1 WCAG contrast against any team background. Always use this for text/icons rendered over team-colored surfaces. (`TeamColors.onTeam` is derived from it.)

---

## Routing

`go_router` (`lib/core/router.dart`). All named routes are defined there. Feature screens are navigated to via `context.go(...)` / `context.push(...)` using named routes.

---

## Scaffold / AppBar Pattern

Established to prevent repeated boilerplate and ensure consistent theming across all screens.

| Use case | Widget combination |
|---|---|
| Team-scoped screen | `TeamScaffold(teamId:) + TeamAppBar(teamId:, titleText:)` |
| Global screen | `TeamScaffold(appBar: TeamAppBar(titleText:))` |
| Game-scoped screen | `GameScaffold(gameId:) + TeamAppBar(teamId: null, titleText:)` |

`GameScaffold` resolves `teamId` from the game record internally, eliminating repeated `FutureBuilder` boilerplate in game screens.

Do **not** use raw `Scaffold` or `AppBar` in new screens.

---

## JSON Import

Season data can be imported from a JSON file. The import pipeline:
1. Reads the file via `file_picker`.
2. Parses JSON with `json_serializable`-generated models.
3. Creates a default season if none exists, and applies `seasonId` fallbacks to players and teams.
4. Writes records via `AppDb` DAOs.

Integration test: `test/import_json_test.dart`.

---

## Significant Decisions Log

| Date | Decision | Rationale |
|---|---|---|
| 2025-10 | Introduced `TeamScaffold`/`GameScaffold`/`TeamAppBar` | Eliminate duplicated gradient/header logic across ~10 screens |
| 2025-10 | `TeamColorContrast.onColorFor` utility | Light team colors caused near-white-on-white text in live game cards |
| 2025 | `AppDb.test()` in-memory test helper | Real SQL behavior in tests caught issues that mocks missed |
| 2025 | Default season creation on JSON import | Prevented foreign-key failures when importing legacy data without a season |
| 2026-04 | `AppDb.forTesting(super.executor)` constructor | Allows file-backed NativeDatabase in migration tests so the test can seed a pre-migration schema file and open it via Drift to trigger migration |
| 2026-04 | `ref.onDispose(() => _t?.cancel())` in `StopwatchCtrl.build()` | autoDispose does not auto-cancel Dart `Timer` objects; must be registered explicitly or the timer outlives the ProviderScope |
| 2026-04 | `ios/Runner/PrivacyInfo.xcprivacy` | Apple requires a "required reason" manifest for any use of UserDefaults (`shared_preferences`) and file timestamps (`path_provider`) |
| 2026-05 | Two-layer test stack (widget tests in `test/`, Patrol E2E in `patrol_test/`) | Widget tests are fast and run on `flutter test` for DB/controller logic; Patrol covers real notification/permission/UI flows that need a device. Avoids putting platform-only behavior into the unit tier |
| 2026-05 | Patrol shift/halftime journey tests use team-configurable `shift_length_seconds` / `half_duration_seconds` | Lets E2E exercise the same code path production users run, instead of adding a debug fast-forward hook to the controller |
| 2026-05 | Patrol E2E tests live in `patrol_test/` (patrol 4.x default), not `integration_test/` | patrol_cli 4.x has a Windows bug where `test_path` pointing outside `patrol_test/` generates absolute drive-letter imports that Dart can't parse. Using the default directory avoids this entirely. |
| 2026-05 | `pumpAndSettle(timeout: Duration(seconds: N))` required in all Patrol tests | Without a timeout, `pumpAndSettle` spins for ~19 minutes on always-open Drift streams. Cap initial loads at 5 s and post-tap settles at 3 s. |
| 2026-05 | Substitution Patrol coverage drives the production GoRouter (`/game/:id/assign/:shiftId`) directly | The newer in-game lineup builder is harder to drive deterministically from Patrol; pushing the production deep-link route exercises the same `setPlayerPosition` write path without depending on the live game screen's auto-rotation behavior. |
| 2026-05 | Patrol journey tests for team creation, substitution, shift advancement, and season cloning | Closes the major-user-journey gap left by the original alarm-only Patrol suite. Every journey seeds `AppDb.test()` and ends with a DB assertion so the test fails if the UI write didn't reach storage. |
| 2026-05 | `android.enableJetifier=false` in `gradle.properties` | Flutter's engine JARs are already AndroidX; Jetifier runs `JetifyTransform` on them unnecessarily, causing Java heap OOM even at 2g. Safe to disable permanently for Flutter projects. |
| 2026-05 | Flutter Built-in Kotlin: removed `id("kotlin-android")` from app plugins | `dev.flutter.flutter-gradle-plugin` manages Kotlin compilation internally since Flutter 3.x. Explicit `kotlin-android` is redundant and blocks independent Kotlin version upgrades. Also removed `kotlinOptions {}` (removed in Kotlin 2.2) and the root `tasks.withType<KotlinCompile>` block (Kotlin 2.2 requires JVM 8+ minimum, so the 1.6→1.8 guard is moot). `compileOptions` must be `VERSION_17` — Kotlin 2.2 defaults jvmTarget to the JDK version (17 in CI), causing "Inconsistent JVM Target Compatibility" if Java stays at 1.8. |
| 2026-05 | Android toolchain: Gradle 8.13, AGP 8.11.1, Kotlin 2.2.20 | Minimum versions required to clear Flutter 3.44+ deprecation warnings. Gradle 8.14.0 does not exist at the distribution URL — use 8.13 (AGP 8.11.1's stated minimum). |
| 2026-05 | Patrol halftime test navigates back before `db.close()` teardown | `_TraditionalGameScreenState._startTimer()` creates a `Timer.periodic` that writes to Drift's executor every 5 s. If the timer outlives the test body, new writes arrive while `db.close()` tries to drain the queue → hang. Fix: `router.pop()` + `Future.delayed(600ms)` triggers `dispose()` which calls `_gameTimer?.cancel()` before the teardown runs. |
| 2026-05 | First-run onboarding via contextual empty states (issue #10) | Replaced bare "No Active Season" text on home screen with a `_OnboardingWelcomeCard` (3-step sequence). Added `_OnboardingNoTeamsCard` when season exists but no teams. Updated empty-state descriptions on Teams/Players/Games screens to include next-step hints. All copy in l10n ARB files. Onboarding disappears automatically once data exists — no dismiss logic needed. Covered by `patrol_test/onboarding_journey_test.dart` (empty DB → asserts no-teams card appears). |
| 2026-06 | Roster count summary bar on Players screen (issue #28) | Added `_RosterCountSummary` widget as first child of a `Column` wrapping the player `ListView`. Shows "N players · M active" derived inline from the existing stream — no extra DB query. Only shown when roster is non-empty (empty-state path returns before the `Column`). |
| 2026-07 | No `CrossAxisAlignment.stretch` in unbounded-height contexts (issue #39) | `_gameCard`'s stretch-Row inside a `SingleChildScrollView` failed layout (`!hasSize`) on every frame — blanking the `/team/:id` body in production and hanging `pumpAndSettle` (and thus the patrol gate) forever. Fix: wrap the Row in `IntrinsicHeight`. Guarded by `test/team_detail_screen_render_test.dart`, which pumps the real screen so `flutter test` catches per-frame layout exceptions without an emulator. |
| 2026-07 | Patrol gate captures device logcat per shard | A hung shard produces zero patrol output (no "Total:" line), leaving nothing to diagnose. `run_and_capture.sh` backgrounds `adb logcat` for the whole run; `patrol-gate.yml` uploads `logcat-<n>` artifacts `if: always()` so they survive timeout-cancelled jobs. |
| 2026-07 | Widget tests over Drift-stream screens: `tester.runAsync` + durationed pump before `db.close()` | Drift work needs real async (`runAsync`); `pumpAndSettle` never settles on open Drift streams; and drift's stream-cache `Timer.run` (scheduled on unsubscribe) must fire under the fake clock — pump **with a duration** after disposing the widget, or `await db.close()` deadlocks. |
| 2026-07 | `.agents/COMPONENTS.md` inventory + pr-reviewer static gate before qa-reviewer | Duplicate game-summary tiles shipped because no doc named the canonical widget and the QA review ran bundled with the slow patrol gate. Inventory gives dev + reviewers a checkable source of truth; the split review bounces reuse violations in minutes without burning a 20–40 min emulator run. |
