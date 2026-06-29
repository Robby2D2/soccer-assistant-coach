# Handoff: Sideline Design System — Live Game Screen

## Overview
"Sideline" is a refreshed visual design system for **Soccer Assistant Coach** (Flutter app).
It is built for sideline, glance-and-go use: high contrast for bright daylight, large touch
targets, and a single **team color** token that recolors the whole UI per team. This package
contains the design reference and the first screen applying it — the **Live Game screen**
(stopwatch, shifts, substitutions).

## About the Design Files
The file in this bundle (`Sideline System.dc.html`) is a **design reference created in HTML** —
a prototype showing the intended look and behavior. It is **not production code to copy**.
Your task is to **recreate these designs in the existing Flutter codebase** using its established
patterns: Material 3 `ColorScheme`, the `TeamTheme` / `teamThemeProvider` pipeline, and the
`TeamScaffold` / `GameScaffold` / `TeamAppBar` widgets described in the repo README. Map the
tokens below onto those structures rather than introducing a parallel styling system.

The HTML uses CSS `color-mix()` to derive the "strong" and "soft" team shades from the base
team color. In Dart, do the equivalent with `Color`/`HSLColor` math inside `TeamTheme`
(see Design Tokens → Team color derivation).

## Fidelity
**High-fidelity.** Final colors, typography, spacing, and radii are specified. Recreate the UI
to match, using Flutter widgets and your existing theme. Exact hex values, font sizes, and
spacing are given below.

---

## Design Tokens

### Neutral palette (constant across all teams)
| Token | Hex | Use |
|---|---|---|
| Ink | `#18211C` | Primary text, number badges, dark hero card |
| Muted | `#5A675F` | Secondary text, captions |
| Field (background) | `#F2F5EE` | App background (warm off-white) |
| Surface | `#FFFFFF` | Cards, rows |
| Hairline | `#E2E7DC` | Borders, dividers, progress track |

### Functional palette
| Token | Hex | Use |
|---|---|---|
| Whistle | `#F2A33B` | Shift/halftime alerts (amber) |
| Whistle text | `#9A6212` | Text on whistle-soft backgrounds |
| Whistle soft | `#FCEFD9` | Alert/"next on" backgrounds |

### Team color (the one token coaches set)
| Token | Default (Pitch Green) | Derivation |
|---|---|---|
| Team | `#1B8A47` | The coach-selected color |
| Team strong | `#146536` | `color-mix(team, black 30%)` — headers, on-soft text |
| Team soft | `#E4F2E8` | `color-mix(team 13%, white)` — tinted chips/fills |
| On-team | `#FFFFFF` | Text/icons on team color (pick via contrast check) |

Reference team presets used in the mockups:
- Pitch Green `#1B8A47` (default) · strong `#146536` · soft `#E4F2E8`
- Riverside Red `#D8442F` · strong `#A8301F` · soft `#FBE7E2`
- Lakeside Blue `#2563C9` · strong `#1A47A0` · soft `#E4EBFB`
- Coastal Teal `#0E8C8C` · strong `#0A6A6A` · soft `#DBF0F0`

**Team color derivation (Dart) — add to `lib/utils/team_theme.dart`:**
```dart
Color _strong(Color c) => Color.alphaBlend(Colors.black.withOpacity(0.30), c);
Color _soft(Color c)   => Color.alphaBlend(c.withOpacity(0.13), Colors.white);
// On-team: choose white or ink by luminance for readable contrast.
Color _onTeam(Color c) =>
    c.computeLuminance() > 0.55 ? const Color(0xFF18211C) : Colors.white;
```
Wire these into the generated `ColorScheme` so `colorScheme.primary` = team,
plus expose `strong`/`soft`/`onTeam` (e.g. as a `ThemeExtension<TeamColors>`).
Keep `TeamColorContrast.onColorFor` as the source of truth for foreground choice.

### Spacing scale (4px base)
`8, 12, 16, 20, 24, 32`. Screen horizontal padding: **16**. Card inner padding: **16–20**.

### Radius
| Name | Value | Use |
|---|---|---|
| pill | `999` | Status pills, "next on" chips, GK badge |
| card | `20–22` | Hero shift card |
| row/button | `14–16` | Player rows, buttons, score box |
| chip | `9–10` | Position chips (FWD/MID/DEF) |
| phone header bottom | `28` | Team header rounded bottom corners |

### Elevation / shadow
- Cards: `0 1px 3px rgba(20,40,28,0.10)`
- Hero shift card: `0 10px 24px rgba(20,40,28,0.20)`
- Primary button: `0 6px 16px <team @ 40% alpha>`

---

## Typography
Two families. Add both to `pubspec.yaml` fonts (or `google_fonts`).

1. **Hanken Grotesk** — everything you read (names, titles, labels, buttons).
2. **Spline Sans Mono** — all numerics: the game/shift clock, score, minutes played,
   jersey numbers, token captions. Use **tabular figures** so digits don't jitter as the
   clock ticks (`fontFeatures: [FontFeature.tabularFigures()]`).

| Role | Family | Size | Weight | Notes |
|---|---|---|---|---|
| Hero countdown | Spline Sans Mono | 76 | 700 | letter-spacing -0.02em, on ink card |
| Display / section title | Hanken Grotesk | 18–24 | 800 | "On the pitch", "Next on" |
| Team name (header) | Hanken Grotesk | 20 | 800 | white on team color |
| Player name | Hanken Grotesk | 16 | 700 | |
| Body | Hanken Grotesk | 17 | 500 | |
| Score | Spline Sans Mono | 22 | 700 | |
| Minutes played / shift clock | Spline Sans Mono | 16 | 700 | tabular |
| Label (SHIFT 4 OF 6) | Spline Sans Mono | 12–13 | 700 | uppercase, letter-spacing .10em, muted |
| Position chip | Hanken Grotesk | 12–14 | 700 | |

Minimum readable body size on the sideline: **16**. Don't go below it.

---

## Screens / Views

### Live Game screen
**Purpose:** During a match the coach watches the shift countdown, sees who's on with how
many minutes each has played (playtime fairness), sees who's next on (least time first),
and taps **Next Shift** to rotate. Maps to `GameScreen` / `TraditionalGameScreen` wrapped in
`GameScaffold(gameId: ...)`.

**Layout (top → bottom):**
1. **Team header** — full-bleed `colorScheme.primary` band, rounded bottom (28). Contains the
   status row (time · LIVE · battery), then a row of: crest badge (44, white rounded square,
   team-colored initial) + team name + "vs Opponent", and a score box (translucent white,
   score in mono + "2ND HALF" label). This is the `TeamAppBar` region — extend it to carry
   the score/period, or place a `TeamBrandedHeader` here.
2. **Hero shift card** — ink (`#18211C`) card, radius 22, margin `-14` top so it overlaps the
   header, padding 20. Row: "SHIFT 4 OF 6" label (left) + "⚖ Even rotation" pill (right,
   toggleable). Center: giant mono countdown `03:12` + "until next shift". Then a progress bar
   (track `rgba(255,255,255,.14)`, fill = team color, width = shift elapsed %). Footer row:
   "Game 31:08" · "Shift 4:48 / 8:00" in muted mono.
3. **Alert banner** (conditional) — whistle-soft bg, 1px whistle border, radius 14, a pulsing
   amber dot + "Shift ending soon — get <names> ready". Show when countdown < threshold; ties
   to the existing shift-alarm SnackBar/notification.
4. **On the pitch** — title + "7 players" count. List of player rows: surface card, 1px
   hairline, radius 14, padding ~11. Each row = number badge (40, ink, mono) + name +
   playtime bar (track hairline, fill team color, width = minutes/total) + position chip +
   minutes (mono, right-aligned, fixed width). GK chip is ink pill; outfield chips are
   team-soft bg / team-strong text.
5. **Next on · least time** — title + a wrap of pill chips: number circle + name + minutes.
   The two lowest-minute players are highlighted (whistle-soft bg, whistle border) to nudge
   fair rotation; others are plain surface chips.
6. **Bottom action bar** — sticky, field-colored. A 56×56 outlined **Pause** button (two ink
   bars) + a flex-1 56-tall **Next Shift** primary button (team color, white text, → glyph,
   team-tinted shadow). This is the primary glance-and-go action; keep it dominant.

**Component → existing-widget mapping:**
- Header → `TeamAppBar` (+ score/period in its `title`) inside `GameScaffold`.
- Player row → new `PlayerShiftRow` widget; derive chip colors from `colorScheme` + team
  soft/strong extension, never hard-coded.
- Next Shift button → `FilledButton` styled with `colorScheme.primary`; 56 min height.
- Alert → reuse the shift-alarm trigger; render as an inline banner (this design) in addition
  to / instead of the SnackBar.

## Interactions & Behavior
- **Next Shift** tap → advances `currentShiftId`, reassigns positions, resets shift countdown,
  recomputes minutes. (Existing substitution/shift pipeline.)
- **Countdown** ticks every second (tabular figures prevent width jitter). At the warning
  threshold the alert banner appears and the shift-end alarm fires.
- **Pause** → pauses game + shift timers.
- **Even rotation pill** → reflects the auto-rotation setting; tappable to toggle.
- Team color change anywhere re-themes this screen live via `teamThemeProvider` (already in
  place) — verify the new `strong`/`soft`/`onTeam` extension rebuilds with it.
- Animation: the LIVE dot and alert dot pulse opacity 1 → .35 → 1 over ~1.4s
  (`AnimationController`, repeat reverse).

## State Management
Existing Riverpod + Drift (`AppDb`) stack. Needs: current game (`gameId` → team), current
shift index + total, per-player minutes played, on-pitch vs bench split, shift countdown
seconds, alert threshold, even-rotation flag. No new data sources — surface what the game/shift
providers already compute.

## Assets
No raster assets. Crests are letter badges (team initial on a rounded square). Icons are simple
shapes/glyphs (chevron, →, pause bars, dots) — use your icon set or `Icon`s. Fonts: Hanken
Grotesk + Spline Sans Mono (both on Google Fonts).

## Files
- `Sideline System.dc.html` — the full design reference (open in a browser). Three frames:
  **(1)** the design system (palette, team theming, type, radius/spacing, component kit),
  **(2)** the Live Game screen at full size (default green),
  **(3)** the same screen recolored for three teams (red/blue/teal) — proof the theming holds.

## Suggested implementation order
1. Add fonts; extend `TeamTheme` to emit `strong`/`soft`/`onTeam` (ThemeExtension) from the
   team color using the derivation above.
2. Update the neutral side of `lib/core/theme.dart` to the Sideline neutrals (field/surface/
   ink/hairline) and whistle alert colors.
3. Rebuild `TeamAppBar` header to the new spec (crest + name + score/period, rounded bottom).
4. Build `PlayerShiftRow` + the hero shift card; assemble the Live Game screen in
   `GameScreen` via `GameScaffold`.
5. Add the inline alert banner tied to the shift-alarm threshold.
6. Roll the same tokens/widgets out to Teams, Roster, and Metrics screens next.
