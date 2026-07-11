# Shared UI Components — Soccer Assistant Coach

**Rule: one canonical widget per concept.** Before building any UI, check this inventory and
`lib/widgets/` for an existing component. If a widget close to what you need exists, **extend it**
(new parameter, variant flag) — never inline a near-duplicate. Reviewers treat an inlined variant
of a listed component as a required change.

When you add a shared widget or consolidate duplicates, add/update the row here in the same PR.

## Scaffolding & navigation

| Component | File | Use for |
|---|---|---|
| `TeamScaffold` + `TeamAppBar` | `lib/core/team_theme_manager.dart` | Every screen (see ARCHITECTURE.md → Scaffold/AppBar pattern). Never raw `Scaffold`/`AppBar`. |
| `GameScaffold` | `lib/core/game_scaffold.dart` | Game-scoped screens (resolves teamId from the game). |
| `StandardizedAppBarActions` / `CommonNavigationActions` | `lib/widgets/standardized_app_bar_actions.dart` | All app-bar action sets. The icon + kebab pairing is intentional — don't "fix" it. |
| `SidelineGameHeader` | `lib/widgets/game_header.dart` | Branded body-top header on **live** game screens (both modes). No AppBar on these screens. |
| `GameCompactTitle` | `lib/core/team_theme_manager.dart` | App-bar title on game **sub**-screens (edit, attendance, metrics). |
| `SidelineScreenHeader` / `SidelineHeaderBand` / `SidelineCrest` | `lib/widgets/sideline_header.dart` | Branded headers on non-game Sideline screens. |
| `SidelineTeamTabs` | `lib/widgets/sideline_team_tabs.dart` | Team-section tab bar. |

## Game display

| Component | File | Use for |
|---|---|---|
| `GameResultCard` | `lib/widgets/game_result_card.dart` | **The** game summary tile (icon, "vs Opponent", date pill, W/L/D score badge, LIVE/Archived pills). Used by the games list, team-landing "Most Recent Game", and the completed-game panel. Score uses an en-dash (`3–2`) — patrol asserts on it. |
| `SidelineHeroShiftCard`, `SidelineAlertBanner`, `SidelinePlayerShiftRow`, `SidelinePositionChip`, `SidelineNextOnChip` | `lib/widgets/sideline_widgets.dart` | Live-game shift UI. Also exports `teamColorsOf(context)`. |

## Team & player identity

| Component | File | Use for |
|---|---|---|
| `TeamBrandedHeader` | `lib/widgets/team_header.dart` | **Legacy, pre-Sideline** — gradient header on assign-players + end-game screens only. Don't adopt in new screens; replace with Sideline headers during the Teams/Roster restyle. |
| `TeamListPanel` | `lib/widgets/team_panels.dart` | **Legacy, pre-Sideline** — gradient team tile on the teams list only. Same restyle plan as above. (Six sibling variants were dead code, deleted 2026-07.) |
| `TeamFloatingActionButton`, `TeamFilledButton`, `TeamCard`, `TeamDivider`, `TeamGradientContainer`, `TeamBadge` | `lib/widgets/team_accent_widgets.dart` | Team-color-accented controls — use instead of manually theming Material ones. |
| `TeamLogoWidget` / `EditableTeamLogoWidget` | `lib/widgets/team_logo_widget.dart` | Team crests everywhere. |
| `TeamColorPicker` | `lib/widgets/team_color_picker.dart` | Team color selection. |
| `PlayerAvatar` | `lib/widgets/player_avatar.dart` | Player avatars everywhere. |
| `PlayerPanel` | `lib/widgets/player_panel.dart` | Player-scoped content panels. |

## Tokens & theming (never hardcode)

| Token | File | Use for |
|---|---|---|
| `SidelineColors`, `SidelineSpacing`, `SidelineRadius`, `sidelineTextTheme()`, `sidelineMono()` | `lib/core/sideline.dart` | Spacing/radius/palette; `sidelineMono()` for **all numerics** (tabular figures). |
| `TeamColors` ThemeExtension / `teamColorsOf(context)` | `lib/utils/team_theme.dart` | Team-derived shades on the active theme. |
| `TeamColorContrast.onColorFor()` | `lib/utils/` | Text/icon color over any team-colored surface (WCAG ≥ 4.5:1). |
