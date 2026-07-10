# Sideline Design System — rollout notes (June 2026)

Foundation and Live Game application of the "Sideline" design system
(`design-system/design_handoff_sideline/README.md`). The durable architecture (tokens,
`TeamColors` ThemeExtension, component list) is documented in
[`.agents/ARCHITECTURE.md`](../ARCHITECTURE.md) → "Sideline design system". This file holds the
extra context that doc doesn't.

## Design source

- The live design lives in the claude.ai/design project `4def67a5-f261-40c8-8862-a8447aef9aee`
  ("Design system for soccer coach"). It's a regular PROJECT type, so it does **not** show in
  `DesignSync.list_projects` — read it via `get_project` / `list_files` / `get_file`.
- Working style with Rob: he iterates visually and pastes screenshots; translate those to Flutter
  against the Sideline tokens.

## Live Game screen — decisions made (don't relitigate)

- **Keep the horizontal `PageView` shift-planning view.** Do not rebuild into the vertical
  on-pitch list from the handoff.
- **No "Next on · least time" section** — Rob chose planning view + max players visible instead.
  `SidelinePlayerShiftRow` / `SidelineNextOnChip` exist in `sideline_widgets.dart` but are unused.
- Play/pause lives in the hero card top-right (`SidelineHeroShiftCard.action` slot); countdown
  shrunk 76→60; `_ShiftsList` fills an `Expanded` (no fixed height).
- **`_ShiftActionBar`** (sticky bottom bar) replaces the old "Next Shift" button. Label follows the
  viewed pager page: active shift → "See Next Shift"; upcoming → "Start Shift"; past → "Back to
  Current Shift". Wiring: `_ShiftsList.onShiftViewed` → `_viewedShiftId` (`ValueNotifier`) →
  `ValueListenableBuilder`.
- **`SidelineGameHeader`** (`lib/widgets/game_header.dart`) replaced `TeamAppBar` on Live Game: a
  full-bleed team-colored band rendered as the first body child (not the `appBar` slot), filling
  behind the status bar via `SafeArea(bottom: false)`. Wraps in
  `AnnotatedRegion<SystemUiOverlayStyle>` choosing icon brightness from band luminance.
- Known cruft: a dead `Offstage` duplicate-buttons block remains in `game_screen.dart` (harmless,
  cleanup candidate).

## Gotchas

- **`TeamColors` is the app's single ThemeExtension** and `applyTo` must set `extensions:` outright.
  Spreading `base.extensions.values` passes `flutter analyze` but the stricter test front-end
  rejects the inferred `ThemeExtension<ThemeExtension<dynamic>>` type.
- **Render all numerics with `sidelineMono()`** (tabular figures) so clocks don't jitter.
- **Team color staleness:** `teamThemeProvider` is a non-autoDispose `FutureProvider` that caches
  the team. After editing team colors, call `invalidateTeamTheme(ref, teamId)` (done in the team
  editor's Save handler). A reactive `StreamProvider` + `db.watchTeam` was tried first but a drift
  stream leaves a pending timer when a short-lived test widget tree disposes ("A Timer is still
  pending").

## Data available for a future on-pitch / next-on view

- `db.playedSecondsByPlayer(gameId)` — per-player seconds (least-time sort).
- `db.presentPlayersForGame(gameId, teamId)`; `db.getAssignments(shiftId)` — on-pitch + positions.
- Bench = present − on-pitch.

## Rollout status (as of 2026-06-28)

Global theme (fonts + neutrals) re-skins every screen. Live Game hero card, alert banner, branded
header, and action bar are live. Metrics playtime bars use team color + `sidelineMono`.
Teams/Roster deeper per-screen styling is still open — get user direction/screenshots before
sprawling.
