import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:soccer_assistant_coach/core/team_theme_manager.dart';
import 'package:soccer_assistant_coach/core/providers.dart';

void main() {
  group('TeamAppBar', () {
    testWidgets('renders fallback title when no teamId', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(appBar: TeamAppBar(titleText: 'Games')),
          ),
        ),
      );
      await tester.pump();
      expect(find.text('Games'), findsOneWidget);
    });

    testWidgets('renders team name when teamId provided', (tester) async {
      final db = AppDb.test();
      // Create a default season for testing
      final seasonId = await db.createSeason(
        name: 'Test Season',
        startDate: DateTime.now(),
      );
      final teamId = await db.addTeamToSeason(
        seasonId: seasonId,
        name: 'Test FC',
      );
      await tester.pumpWidget(
        ProviderScope(
          overrides: [dbProvider.overrideWithValue(db)],
          child: MaterialApp(
            home: Scaffold(
              appBar: TeamAppBar(teamId: teamId, titleText: 'Ignored'),
            ),
          ),
        ),
      );
      // Wait for future builders (team theme + team fetch) to resolve.
      await tester.pumpAndSettle();
      expect(find.text('Test FC'), findsOneWidget);
    });
  });
}
