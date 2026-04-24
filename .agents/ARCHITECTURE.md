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

### Contrast Safety

`TeamColorContrast.onColorFor(Color)` returns black or white to maintain ≥ 4.5:1 WCAG contrast against any team background. Always use this for text/icons rendered over team-colored surfaces.

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
