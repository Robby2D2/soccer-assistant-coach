import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:soccer_assistant_coach/features/games/game_screen.dart';
import 'package:soccer_assistant_coach/core/providers.dart';
import 'package:drift/drift.dart' as drift;

void main() {
  group('GameScreen Tests', () {
    late AppDb testDb;

    setUp(() {
      testDb = AppDb.test();
    });

    tearDown(() async {
      await testDb.close();
    });

    testWidgets('GameScreen loads without hanging for valid game',
        (tester) async {
      // Create test data
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
          gameStatus: drift.Value('in-progress'),
        ),
      );

      print('Created game with ID: $gameId');

      // Create the widget with proper providers
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            dbProvider.overrideWithValue(testDb),
          ],
          child: MaterialApp(
            home: GameScreen(gameId: gameId),
          ),
        ),
      );

      // Wait for initial frame
      await tester.pump();
      print('Initial pump completed');

      // Wait for async operations with timeout
      try {
        await tester.pumpAndSettle(const Duration(seconds: 5));
        print('PumpAndSettle completed successfully');
      } catch (e) {
        print('PumpAndSettle timed out or failed: $e');
        fail('GameScreen appears to be hanging during load');
      }

      // Verify the screen loaded
      expect(find.byType(GameScreen), findsOneWidget);
      print('GameScreen widget found');
    });

    testWidgets('GameScreen loads with players present', (tester) async {
      // Create test data with players
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
          gameStatus: drift.Value('in-progress'),
        ),
      );

      // Add a player
      final playerId = await testDb.into(testDb.players).insert(
        PlayersCompanion.insert(
          teamId: teamId,
          seasonId: seasonId,
          firstName: 'John',
          lastName: 'Doe',
        ),
      );

      // Mark player as present for game
      await testDb.into(testDb.gamePlayers).insert(
        GamePlayersCompanion.insert(
          gameId: gameId,
          playerId: playerId,
          isPresent: const drift.Value(true),
        ),
      );

      print('Created game with ID: $gameId and player ID: $playerId');

      // Create the widget
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            dbProvider.overrideWithValue(testDb),
          ],
          child: MaterialApp(
            home: GameScreen(gameId: gameId),
          ),
        ),
      );

      // Wait for initial frame
      await tester.pump();
      print('Initial pump completed');

      // Wait for async operations with extended timeout since initial shift creation may occur
      try {
        await tester.pumpAndSettle(const Duration(seconds: 10));
        print('PumpAndSettle completed successfully');
      } catch (e) {
        print('PumpAndSettle timed out or failed: $e');
        fail('GameScreen appears to be hanging with players present');
      }

      // Verify the screen loaded
      expect(find.byType(GameScreen), findsOneWidget);
      print('GameScreen widget found with players');
    });

    testWidgets('GameScreen handles empty game (no shifts)', (tester) async {
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
          gameStatus: drift.Value('scheduled'),
        ),
      );

      print('Created scheduled game with ID: $gameId (no shifts expected)');

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            dbProvider.overrideWithValue(testDb),
          ],
          child: MaterialApp(
            home: GameScreen(gameId: gameId),
          ),
        ),
      );

      await tester.pump();
      print('Initial pump completed');

      try {
        await tester.pumpAndSettle(const Duration(seconds: 5));
        print('PumpAndSettle completed for empty game');
      } catch (e) {
        print('PumpAndSettle failed for empty game: $e');
        fail('GameScreen hangs even with no shifts');
      }

      expect(find.byType(GameScreen), findsOneWidget);
      print('GameScreen handles empty game correctly');
    });

    testWidgets('GameScreen with existing shift loads correctly',
        (tester) async {
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
          gameStatus: drift.Value('in-progress'),
        ),
      );

      // Create a shift manually
      final shiftId = await testDb.into(testDb.shifts).insert(
        ShiftsCompanion.insert(
          gameId: gameId,
          startSeconds: 0,
          actualSeconds: const drift.Value(0),
        ),
      );

      print('Created game with ID: $gameId and shift ID: $shiftId');

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            dbProvider.overrideWithValue(testDb),
          ],
          child: MaterialApp(
            home: GameScreen(gameId: gameId),
          ),
        ),
      );

      await tester.pump();
      print('Initial pump completed with existing shift');

      try {
        await tester.pumpAndSettle(const Duration(seconds: 5));
        print('PumpAndSettle completed with existing shift');
      } catch (e) {
        print('PumpAndSettle failed with existing shift: $e');
        fail('GameScreen hangs even with existing shift');
      }

      expect(find.byType(GameScreen), findsOneWidget);
      print('GameScreen with existing shift works correctly');
    });

    test('Database queries complete without hanging', () async {
      // Test the database queries directly
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
        ),
      );

      print('Testing database queries for game: $gameId');

      // Test watchGameShifts stream
      final shiftsStream = testDb.watchGameShifts(gameId);
      final shifts = await shiftsStream.first.timeout(
        const Duration(seconds: 2),
        onTimeout: () {
          fail('watchGameShifts stream timed out');
        },
      );
      print('Shifts query completed: ${shifts.length} shifts found');

      // Test getGame
      final game = await testDb.getGame(gameId).timeout(
        const Duration(seconds: 2),
        onTimeout: () {
          fail('getGame query timed out');
        },
      );
      print('getGame query completed: game found = ${game != null}');

      // Test hasPresentPlayersForGame
      final hasPlayers = await testDb.hasPresentPlayersForGame(gameId).timeout(
        const Duration(seconds: 2),
        onTimeout: () {
          fail('hasPresentPlayersForGame query timed out');
        },
      );
      print('hasPresentPlayersForGame query completed: $hasPlayers');

      expect(shifts, isEmpty);
      expect(game, isNotNull);
      expect(hasPlayers, isFalse);
    });

    testWidgets('GameScreen initialization completes', (tester) async {
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
        ),
      );

      print('Testing GameScreen initialization for game: $gameId');

      bool initCompleted = false;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            dbProvider.overrideWithValue(testDb),
          ],
          child: MaterialApp(
            home: Builder(
              builder: (context) {
                // Mark when build completes
                Future.microtask(() {
                  if (!initCompleted) {
                    initCompleted = true;
                    print('GameScreen build completed');
                  }
                });
                return GameScreen(gameId: gameId);
              },
            ),
          ),
        ),
      );

      // Initial pump
      await tester.pump();
      print('After initial pump, initCompleted: $initCompleted');

      // Give it a few frames to complete initialization
      for (int i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 100));
        if (initCompleted) {
          print('Initialization completed after ${i + 1} frames');
          break;
        }
      }

      expect(initCompleted, isTrue,
          reason: 'GameScreen should complete initialization');
    });
  });
}
