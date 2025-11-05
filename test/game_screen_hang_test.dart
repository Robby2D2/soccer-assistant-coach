import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:soccer_assistant_coach/features/games/game_screen.dart';
import 'package:soccer_assistant_coach/core/providers.dart';
import 'package:drift/drift.dart' as drift;

/// Tests for GameScreen initialization and disposal issues
/// 
/// This test was created to diagnose a hanging issue when navigating to GameScreen.
/// The issue turned out to be in the dispose() method where NotificationService
/// was being initialized during cleanup, which failed in test environments.
void main() {
  group('GameScreen Lifecycle Tests', () {
    testWidgets('GameScreen should load and dispose without errors',
        (WidgetTester tester) async {
      final testDb = AppDb.test();

      // Create minimal test data
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
          opponent: drift.Value('Opponent Team'),
          gameStatus: drift.Value('scheduled'),
        ),
      );

      // Create and render the widget
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            dbProvider.overrideWithValue(testDb),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: GameScreen(gameId: gameId),
            ),
          ),
        ),
      );

      // Allow initial frame to render
      await tester.pump();

      // Verify the widget was created
      expect(find.byType(GameScreen), findsOneWidget);

      // Now dispose the widget by navigating away
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            dbProvider.overrideWithValue(testDb),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: Text('Different screen'),
            ),
          ),
        ),
      );

      // Allow disposal to complete
      await tester.pump();

      // Verify the GameScreen was properly disposed
      expect(find.byType(GameScreen), findsNothing);
      expect(find.text('Different screen'), findsOneWidget);

      await testDb.close();
    });

    testWidgets('GameScreen should handle rapid navigation without hanging',
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

      // Navigate to GameScreen multiple times quickly
      for (int i = 0; i < 3; i++) {
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              dbProvider.overrideWithValue(testDb),
            ],
            child: MaterialApp(
              home: Scaffold(
                body: GameScreen(gameId: gameId),
              ),
            ),
          ),
        );

        await tester.pump();

        // Navigate away
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              dbProvider.overrideWithValue(testDb),
            ],
            child: const MaterialApp(
              home: Scaffold(
                body: Text('Away'),
              ),
            ),
          ),
        );

        await tester.pump();
      }

      await testDb.close();
    });
  });
}
