import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:soccer_assistant_coach/features/games/game_screen.dart';
import 'package:soccer_assistant_coach/core/providers.dart';
import 'package:drift/drift.dart' as drift;

/// Simple test to verify GameScreen can be created without hanging
void main() {
  testWidgets('GameScreen simple instantiation test',
      (WidgetTester tester) async {
    final testDb = AppDb.test();

    final seasonId = await testDb.createSeason(
      name: 'Test Season',
      startDate: DateTime.now(),
    );

    final teamId = await testDb.addTeamToSeason(
      seasonId: seasonId,
      name: 'Test Team',
    );

    final gameId = await testDb.addGame(
      GamesCompanion.insert(
        teamId: teamId,
        seasonId: seasonId,
        opponent: drift.Value('Opponent'),
        gameStatus: drift.Value('scheduled'),
      ),
    );

    // Try to just create the widget tree with a short timeout
    await tester.runAsync(() async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            dbProvider.overrideWithValue(testDb),
          ],
          child: MaterialApp(
            home: GameScreen(gameId: gameId),
          ),
        ),
      ).timeout(
        const Duration(seconds: 2),
        onTimeout: () {
          fail('pumpWidget timed out - GameScreen initState is blocking');
        },
      );

      // Try one pump with timeout
      await tester.pump(Duration.zero).timeout(
        const Duration(seconds: 2),
        onTimeout: () {
          fail('pump() timed out - GameScreen build is blocking');
        },
      );
    });

    expect(find.byType(GameScreen), findsOneWidget);

    await testDb.close();
  }, timeout: const Timeout(Duration(seconds: 10)));
}
