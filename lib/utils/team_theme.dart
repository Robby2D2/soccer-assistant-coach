import 'package:flutter/material.dart';
import '../widgets/team_color_picker.dart';

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

  /// Generate ColorScheme based on team colors
  ColorScheme get colorScheme {
    if (isDarkMode) {
      return ColorScheme.fromSeed(
        seedColor: primaryColor,
        brightness: Brightness.dark,
      ).copyWith(secondary: secondaryColor, tertiary: tertiaryColor);
    } else {
      return ColorScheme.fromSeed(
        seedColor: primaryColor,
        brightness: Brightness.light,
      ).copyWith(secondary: secondaryColor, tertiary: tertiaryColor);
    }
  }

  /// Generate ThemeData based on team colors
  ThemeData get themeData {
    return ThemeData(
      colorScheme: colorScheme,
      useMaterial3: true,
      appBarTheme: AppBarTheme(
        backgroundColor: colorScheme.primaryContainer,
        foregroundColor: colorScheme.onPrimaryContainer,
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
  Color _getContrastColor(Color backgroundColor) {
    return backgroundColor.computeLuminance() > 0.5
        ? Colors.black
        : Colors.white;
  }

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
