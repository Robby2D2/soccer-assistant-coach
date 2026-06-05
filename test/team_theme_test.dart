import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:soccer_assistant_coach/core/providers.dart';
import 'package:soccer_assistant_coach/core/team_theme_manager.dart';
import 'package:soccer_assistant_coach/utils/team_theme.dart';

void main() {
  group('TeamTheme brightness awareness', () {
    final team = TeamTheme.fromHexStrings(color1: '#2E7D32');

    test('colorSchemeFor builds a light scheme for Brightness.light', () {
      expect(team.colorSchemeFor(Brightness.light).brightness, Brightness.light);
    });

    test('colorSchemeFor builds a dark scheme for Brightness.dark', () {
      expect(team.colorSchemeFor(Brightness.dark).brightness, Brightness.dark);
    });

    test('applyTo preserves the base theme brightness', () {
      final darkBase = ThemeData(brightness: Brightness.dark);
      final applied = team.applyTo(darkBase);
      expect(applied.brightness, Brightness.dark);
      expect(applied.colorScheme.brightness, Brightness.dark);

      final lightBase = ThemeData(brightness: Brightness.light);
      final appliedLight = team.applyTo(lightBase);
      expect(appliedLight.brightness, Brightness.light);
      expect(appliedLight.colorScheme.brightness, Brightness.light);
    });
  });

  group('TeamThemeScope follows the inherited (system) brightness', () {
    testWidgets(
      'team-scoped scaffold stays dark under a dark base theme',
      (tester) async {
        final db = AppDb.test();
        final seasonId = await db.createSeason(
          name: 'Test Season',
          startDate: DateTime.now(),
        );
        final teamId = await db.addTeamToSeason(
          seasonId: seasonId,
          name: 'Dark FC',
          primaryColor1: '#2E7D32',
        );

        late ThemeData scopedTheme;
        await tester.pumpWidget(
          ProviderScope(
            overrides: [dbProvider.overrideWithValue(db)],
            child: MaterialApp(
              theme: ThemeData(brightness: Brightness.light),
              darkTheme: ThemeData(brightness: Brightness.dark),
              themeMode: ThemeMode.dark,
              home: TeamThemeScope(
                teamId: teamId,
                child: Builder(
                  builder: (context) {
                    scopedTheme = Theme.of(context);
                    return const Scaffold(body: SizedBox.shrink());
                  },
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Regression: before the fix the team theme was always light, so a
        // dark-mode device showed a light scaffold under team-scoped screens.
        expect(scopedTheme.brightness, Brightness.dark);
        expect(scopedTheme.colorScheme.brightness, Brightness.dark);
      },
    );

    testWidgets(
      'team-scoped scaffold stays light under a light base theme',
      (tester) async {
        final db = AppDb.test();
        final seasonId = await db.createSeason(
          name: 'Test Season',
          startDate: DateTime.now(),
        );
        final teamId = await db.addTeamToSeason(
          seasonId: seasonId,
          name: 'Light FC',
          primaryColor1: '#2E7D32',
        );

        late ThemeData scopedTheme;
        await tester.pumpWidget(
          ProviderScope(
            overrides: [dbProvider.overrideWithValue(db)],
            child: MaterialApp(
              theme: ThemeData(brightness: Brightness.light),
              darkTheme: ThemeData(brightness: Brightness.dark),
              themeMode: ThemeMode.light,
              home: TeamThemeScope(
                teamId: teamId,
                child: Builder(
                  builder: (context) {
                    scopedTheme = Theme.of(context);
                    return const Scaffold(body: SizedBox.shrink());
                  },
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(scopedTheme.brightness, Brightness.light);
        expect(scopedTheme.colorScheme.brightness, Brightness.light);
      },
    );
  });
}
