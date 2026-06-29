import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Sideline design-system tokens.
///
/// The neutral and functional palettes are constant across every team. The one
/// token coaches set is the *team color*; its derived shades (strong / soft /
/// onTeam) live in `TeamColors` (lib/utils/team_theme.dart) so they can be
/// resolved from the active [Theme] via a [ThemeExtension].
///
/// See `design-system/design_handoff_sideline/README.md` for the source spec.
class SidelineColors {
  SidelineColors._();

  // Neutral palette (constant across all teams).
  /// Primary text, number badges, dark hero card.
  static const Color ink = Color(0xFF18211C);

  /// Secondary text, captions.
  static const Color muted = Color(0xFF5A675F);

  /// App background (warm off-white).
  static const Color field = Color(0xFFF2F5EE);

  /// Cards, rows.
  static const Color surface = Color(0xFFFFFFFF);

  /// Borders, dividers, progress track.
  static const Color hairline = Color(0xFFE2E7DC);

  // Functional palette.
  /// Shift / halftime alerts (amber).
  static const Color whistle = Color(0xFFF2A33B);

  /// Text on whistle-soft backgrounds.
  static const Color whistleText = Color(0xFF9A6212);

  /// Alert / "next on" backgrounds.
  static const Color whistleSoft = Color(0xFFFCEFD9);
}

/// Spacing scale (4px base). Screen horizontal padding is [screen]; card inner
/// padding is [md]–[lg].
class SidelineSpacing {
  SidelineSpacing._();

  static const double xs = 8;
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 20;
  static const double xl = 24;
  static const double xxl = 32;

  /// Screen horizontal padding.
  static const double screen = 16;
}

/// Corner radii.
class SidelineRadius {
  SidelineRadius._();

  /// Status pills, "next on" chips, GK badge.
  static const double pill = 999;

  /// Hero shift card.
  static const double card = 22;

  /// Player rows, buttons, score box.
  static const double row = 14;

  /// Position chips (FWD / MID / DEF).
  static const double chip = 10;

  /// Team header rounded bottom corners.
  static const double headerBottom = 28;
}

/// Hanken Grotesk text theme — everything you read (names, titles, labels,
/// buttons). Pass the platform [base] so colours/sizes carry through.
TextTheme sidelineTextTheme(TextTheme base) =>
    GoogleFonts.hankenGroteskTextTheme(base);

/// Spline Sans Mono with tabular figures for all numerics: the game / shift
/// clock, score, minutes played, jersey numbers, token captions. Tabular
/// figures keep digit width stable so the clock does not jitter as it ticks.
TextStyle sidelineMono({
  double? fontSize,
  FontWeight? fontWeight,
  Color? color,
  double? letterSpacing,
  double? height,
}) => GoogleFonts.splineSansMono(
  fontSize: fontSize,
  fontWeight: fontWeight,
  color: color,
  letterSpacing: letterSpacing,
  height: height,
  fontFeatures: const [FontFeature.tabularFigures()],
);
