import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../widgets/team_color_picker.dart';

/// Utility functions related to color contrast and accessibility.
class TeamColorContrast {
  TeamColorContrast._();

  /// Returns a text/icon color (black or white) that has adequate contrast
  /// with the provided [background]. Uses luminance heuristic plus a fallback
  /// contrast ratio calculation to guard against mid-tone edge cases.
  static Color onColorFor(Color background) {
    // First pass luminance threshold
    final luminance = background.computeLuminance();
    final candidate = luminance > 0.5 ? Colors.black : Colors.white;

    // Verify contrast ratio ~ WCAG AA for normal text (4.5:1). If it fails,
    // fall back to the opposite color even if luminance suggested otherwise.
    if (_contrastRatio(background, candidate) < 4.5) {
      return candidate == Colors.black ? Colors.white : Colors.black;
    }
    return candidate;
  }

  /// Calculate contrast ratio between two colors per WCAG definition.
  static double _contrastRatio(Color a, Color b) {
    final l1 = a.computeLuminance();
    final l2 = b.computeLuminance();
    final brightest = math.max(l1, l2);
    final darkest = math.min(l1, l2);
    return (brightest + 0.05) / (darkest + 0.05);
  }
}

/// Team-derived colors for the Sideline design system, exposed on the active
/// [ThemeData] as a [ThemeExtension] so widgets can read the strong / soft /
/// onTeam shades without re-deriving them.
///
/// `team` is the coach-selected color (== `colorScheme.primary`). The shades
/// are derived per the handoff spec (README → Design Tokens → Team color
/// derivation):
///   strong = color-mix(team, black 30%)   → headers, on-soft text
///   soft   = color-mix(team 13%, white)   → tinted chips / fills
///   onTeam = white or ink by contrast     → text/icons on team color
@immutable
class TeamColors extends ThemeExtension<TeamColors> {
  final Color team;
  final Color strong;
  final Color soft;
  final Color onTeam;

  const TeamColors({
    required this.team,
    required this.strong,
    required this.soft,
    required this.onTeam,
  });

  /// Derive the full set from the single coach-selected [team] color.
  factory TeamColors.fromSeed(Color team) => TeamColors(
    team: team,
    strong: _strong(team),
    soft: _soft(team),
    onTeam: _onTeam(team),
  );

  // color-mix(team, black 30%)
  static Color _strong(Color c) =>
      Color.alphaBlend(Colors.black.withOpacity(0.30), c);

  // color-mix(team 13%, white)
  static Color _soft(Color c) =>
      Color.alphaBlend(c.withOpacity(0.13), Colors.white);

  // White or ink by luminance for readable contrast. TeamColorContrast stays
  // the source of truth for foreground choice.
  static Color _onTeam(Color c) => TeamColorContrast.onColorFor(c);

  @override
  TeamColors copyWith({
    Color? team,
    Color? strong,
    Color? soft,
    Color? onTeam,
  }) => TeamColors(
    team: team ?? this.team,
    strong: strong ?? this.strong,
    soft: soft ?? this.soft,
    onTeam: onTeam ?? this.onTeam,
  );

  @override
  TeamColors lerp(ThemeExtension<TeamColors>? other, double t) {
    if (other is! TeamColors) return this;
    return TeamColors(
      team: Color.lerp(team, other.team, t)!,
      strong: Color.lerp(strong, other.strong, t)!,
      soft: Color.lerp(soft, other.soft, t)!,
      onTeam: Color.lerp(onTeam, other.onTeam, t)!,
    );
  }
}

class TeamTheme {
  final Color primaryColor;
  final Color secondaryColor;
  final Color tertiaryColor;
  final bool isDarkMode;

  const TeamTheme({
    required this.primaryColor,
    required this.secondaryColor,
    required this.tertiaryColor,
    this.isDarkMode = false,
  });

  /// Create team theme from hex color strings
  factory TeamTheme.fromHexStrings({
    String? color1,
    String? color2,
    String? color3,
    bool isDarkMode = false,
  }) {
    return TeamTheme(
      primaryColor: ColorHelper.hexToColor(color1) ?? Colors.blue,
      secondaryColor: ColorHelper.hexToColor(color2) ?? Colors.green,
      tertiaryColor: ColorHelper.hexToColor(color3) ?? Colors.orange,
      isDarkMode: isDarkMode,
    );
  }

  /// Create team theme from Team database model
  factory TeamTheme.fromTeam(dynamic team, {bool isDarkMode = false}) {
    return TeamTheme.fromHexStrings(
      color1: team.primaryColor1,
      color2: team.primaryColor2,
      color3: team.primaryColor3,
      isDarkMode: isDarkMode,
    );
  }

  /// Generate a [ColorScheme] from the team colors at the requested brightness.
  ColorScheme colorSchemeFor(Brightness brightness) {
    return ColorScheme.fromSeed(
      seedColor: primaryColor,
      brightness: brightness,
    ).copyWith(secondary: secondaryColor, tertiary: tertiaryColor);
  }

  /// Generate ColorScheme based on team colors, honoring [isDarkMode].
  ColorScheme get colorScheme =>
      colorSchemeFor(isDarkMode ? Brightness.dark : Brightness.light);

  /// Layer the team colors onto an existing [base] theme, preserving the base
  /// theme's brightness, scaffold background, and component styling so a
  /// team-scoped subtree stays consistent with the system light/dark mode.
  ThemeData applyTo(ThemeData base) {
    final scheme = colorSchemeFor(base.brightness);
    return base.copyWith(
      colorScheme: scheme,
      // Expose the team-derived Sideline shades so descendants can read them
      // via Theme.of(context).extension<TeamColors>(). TeamColors is the only
      // extension in the app, so we set it outright — overriding the base
      // theme's default TeamColors with this team's derived shades.
      extensions: <ThemeExtension<dynamic>>[
        TeamColors.fromSeed(primaryColor),
      ],
      appBarTheme: base.appBarTheme.copyWith(
        backgroundColor: scheme.primaryContainer,
        foregroundColor: scheme.onPrimaryContainer,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: _getContrastColor(primaryColor),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  /// Generate standalone ThemeData based on team colors.
  ///
  /// Prefer [applyTo] so the surrounding base theme (and its brightness) is
  /// preserved; this getter builds a theme from scratch at [isDarkMode].
  ThemeData get themeData {
    return applyTo(
      ThemeData(
        useMaterial3: true,
        brightness: isDarkMode ? Brightness.dark : Brightness.light,
      ),
    );
  }

  /// Get team colors as a list
  List<Color> get colors => [primaryColor, secondaryColor, tertiaryColor];

  /// Create gradient from team colors
  LinearGradient get primaryGradient => LinearGradient(
    colors: [primaryColor, secondaryColor],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Create gradient with all three colors
  LinearGradient get fullGradient => LinearGradient(
    colors: colors,
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Get contrast color for text readability
  Color _getContrastColor(Color backgroundColor) =>
      TeamColorContrast.onColorFor(backgroundColor);

  /// Apply team theme to specific widgets
  BoxDecoration get primaryContainerDecoration => BoxDecoration(
    gradient: primaryGradient,
    borderRadius: BorderRadius.circular(16),
  );

  BoxDecoration get cardDecoration => BoxDecoration(
    color: colorScheme.surface,
    borderRadius: BorderRadius.circular(16),
    border: Border.all(color: primaryColor.withOpacity(0.2), width: 1),
  );

  /// Team-themed elevated button style
  ButtonStyle get elevatedButtonStyle => ElevatedButton.styleFrom(
    backgroundColor: primaryColor,
    foregroundColor: _getContrastColor(primaryColor),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
  );

  /// Team-themed floating action button style
  FloatingActionButtonThemeData get fabTheme => FloatingActionButtonThemeData(
    backgroundColor: secondaryColor,
    foregroundColor: _getContrastColor(secondaryColor),
  );
}

/// Widget that applies team theme to its child
class TeamThemedWidget extends StatelessWidget {
  final Widget child;
  final TeamTheme? teamTheme;

  const TeamThemedWidget({super.key, required this.child, this.teamTheme});

  @override
  Widget build(BuildContext context) {
    if (teamTheme == null) {
      return child;
    }

    return Theme(data: teamTheme!.themeData, child: child);
  }
}

/// Container with team gradient background
class TeamGradientContainer extends StatelessWidget {
  final Widget child;
  final TeamTheme teamTheme;
  final BorderRadius? borderRadius;
  final EdgeInsets? padding;

  const TeamGradientContainer({
    super.key,
    required this.child,
    required this.teamTheme,
    this.borderRadius,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: teamTheme.fullGradient,
        borderRadius: borderRadius ?? BorderRadius.circular(16),
      ),
      padding: padding,
      child: child,
    );
  }
}
