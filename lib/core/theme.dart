import 'package:flutter/material.dart';
import 'sideline.dart';
import '../utils/team_theme.dart';

// Sideline default team color (Pitch Green) — the brand seed and the fallback
// team color for screens not scoped to a specific team.
const _brandSeed = Color(0xFF1B8A47);

ThemeData appTheme = _makeTheme(Brightness.light);
ThemeData appDarkTheme = _makeTheme(Brightness.dark);

ThemeData _makeTheme(Brightness brightness) {
  final isLight = brightness == Brightness.light;
  final scheme = ColorScheme.fromSeed(
    seedColor: _brandSeed,
    brightness: brightness,
  ).copyWith(
    // Sideline light neutrals: warm off-white field + white surfaces + hairline
    // borders. Dark mode keeps the seed-generated scheme.
    surface: isLight ? SidelineColors.surface : null,
    onSurface: isLight ? SidelineColors.ink : null,
    outlineVariant: isLight ? SidelineColors.hairline : null,
  );
  final textTheme = sidelineTextTheme(
    (brightness == Brightness.dark
            ? Typography.material2021().white
            : Typography.material2021().black)
        .apply(bodyColor: scheme.onSurface, displayColor: scheme.onSurface),
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    brightness: brightness,
    scaffoldBackgroundColor: isLight ? SidelineColors.field : null,
    extensions: <ThemeExtension<dynamic>>[TeamColors.fromSeed(_brandSeed)],
    textTheme: textTheme,
    visualDensity: VisualDensity.standard,
    splashFactory: InkSparkle.splashFactory,
    appBarTheme: AppBarTheme(
      backgroundColor: scheme.surface,
      foregroundColor: scheme.onSurface,
      elevation: 0,
      centerTitle: false,
      scrolledUnderElevation: 2,
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: isLight ? SidelineColors.surface : scheme.surfaceContainerHighest,
    ),
    listTileTheme: ListTileThemeData(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      iconColor: scheme.onSurfaceVariant,
      textColor: scheme.onSurface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      tileColor: scheme.surface,
      selectedTileColor: scheme.secondaryContainer,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: scheme.surfaceContainerHighest,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: scheme.outlineVariant),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: scheme.primary, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    ),
    chipTheme: ChipThemeData(
      shape: StadiumBorder(side: BorderSide(color: scheme.outlineVariant)),
      labelStyle: TextStyle(color: scheme.onSurface),
      backgroundColor: scheme.surfaceContainerHigh,
      selectedColor: scheme.secondaryContainer,
    ),
    dividerTheme: DividerThemeData(color: scheme.outlineVariant, thickness: 1),
    dialogTheme: DialogThemeData(
      backgroundColor: scheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
    ),
  );
}
