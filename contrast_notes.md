# Contrast Improvements

Date: 2025-10-17

## Summary
Implemented a contrast-aware coloring strategy to ensure dynamic team colors remain readable across the app.

## Key Changes
- Added `TeamColorContrast.onColorFor(Color)` in `team_theme.dart` (with WCAG ratio fallback) to pick black/white text for any background.
- Updated `TeamTheme` internal contrast helper to use the new utility.
- Enhanced Home Screen active game gradient cards:
  - Text, subtext, status chips, half/shift pill, and live timer now use contrast-calculated on-colors instead of assuming white.
- Added optional `fallbackTextColor` to `_LiveGameTimer` for contrast when embedded over custom backgrounds.
- Updated Game Screen app bar header to apply subtle shadow and contrast-aware coloring for opponent and date/time text when using team primary color.
- Improved `TeamColorPicker`:
  - Responds to updated initial colors via `didUpdateWidget` (fixing issue where saved team colors were not appearing when editing).
  - Uses the new contrast utility for the edit icon overlay.

## Rationale
Previously, some combinations (e.g., very light team primary color) produced low contrast (nearly white-on-white) especially in the Home Active Games timer and chips. The new approach ensures at least a ~4.5:1 contrast (heuristic) between background and text using a luminance guess plus ratio verification.

## Future Improvements
- Consider caching contrast results for performance if many dynamic paints occur (currently trivial cost).
- Expand contrast selection to allow dynamic tone adjustment (not only black/white) for brand consistency while still passing contrast (e.g., shifting toward nearest accessible tone of the same hue).
- Add automated golden/widget tests validating contrast decisions for a matrix of colors.
- Evaluate contrast in dark mode themes once implemented (current logic supports both, but broader QA recommended).

## Testing
- Ran `flutter analyze` (no new errors; only two pre-existing style infos).
- Manual visual verification recommended across: very light (#F5F5F5), very dark (#101010), saturated (#FF0000, #00AEEF), and mid-tone colors.

## Notes
If any remaining areas show poor readability (e.g., secondary widgets or panels not yet migrated), search for direct uses of `teamPrimaryColor` and wrap text/icon colors with `TeamColorContrast.onColorFor(backgroundColor)`.
