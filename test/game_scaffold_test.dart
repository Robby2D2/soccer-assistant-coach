import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:soccer_assistant_coach/core/game_scaffold.dart';
import 'package:soccer_assistant_coach/core/team_theme_manager.dart';
import 'package:soccer_assistant_coach/core/providers.dart';

void main() {
  group('GameScaffold', () {
    testWidgets('resolves team theme and shows body', (tester) async {
      final db = AppDb.test();
      // Create a team
      final teamId = await db.addTeam(TeamsCompanion.insert(name: 'Theme FC'));
      // Create a game linked to team
      final gameId = await db.addGame(GamesCompanion.insert(teamId: teamId));

      await tester.pumpWidget(
        ProviderScope(
          overrides: [dbProvider.overrideWithValue(db)],
          child: MaterialApp(
            home: GameScaffold(
              gameId: gameId,
              appBar: TeamAppBar(teamId: teamId, titleText: 'Game'),
              body: const Text('Body Content'),
            ),
          ),
        ),
      );
      // Wait for futures
      await tester.pumpAndSettle();
      expect(find.text('Body Content'), findsOneWidget);
      // TeamAppBar replaces titleText with team name when teamId present.
      expect(find.text('Theme FC'), findsOneWidget);
    });
  });
}
