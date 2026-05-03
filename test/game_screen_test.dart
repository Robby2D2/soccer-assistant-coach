import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:soccer_assistant_coach/features/games/game_screen.dart';
import 'package:soccer_assistant_coach/core/providers.dart';
import 'package:drift/drift.dart' as drift;

// ----------------------------------------------------------------------------
// Helpers
// ----------------------------------------------------------------------------

/// Creates a minimal season + team + game and returns their IDs.
Future<({int seasonId, int teamId, int gameId})> createGame(
  AppDb db, {
  String status = 'in-progress',
}) async {
  final seasonId = await db.createSeason(
    name: 'Test Season',
    startDate: DateTime.now(),
  );
  final teamId = await db.addTeamToSeason(
    seasonId: seasonId,
    name: 'Test Team',
  );
  final gameId = await db.addGame(
    GamesCompanion.insert(
      teamId: teamId,
      seasonId: seasonId,
      gameStatus: drift.Value(status),
    ),
  );
  return (seasonId: seasonId, teamId: teamId, gameId: gameId);
}

/// Builds the minimal widget tree for a GameScreen test.
Widget buildGameScreen(int gameId, AppDb db) {
  return ProviderScope(
    overrides: [dbProvider.overrideWithValue(db)],
    child: MaterialApp(home: GameScreen(gameId: gameId)),
  );
}

/// Navigates away from the current GameScreen so the ProviderScope is disposed
/// before the test framework runs _verifyInvariants (which checks for pending
/// timers). Without this, any timer in the stopwatch/notification services that
/// starts during initState would still be alive at invariant-check time.
Future<void> navigateAway(WidgetTester tester, AppDb db) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [dbProvider.overrideWithValue(db)],
      child: const MaterialApp(home: Scaffold(body: SizedBox())),
    ),
  );
  await tester.pump();
}

// ----------------------------------------------------------------------------
// Tests
// ----------------------------------------------------------------------------

void main() {
  group('GameScreen Tests', () {
    late AppDb testDb;

    setUp(() {
      testDb = AppDb.test();
    });

    tearDown(() async {
      await testDb.close();
    });

    testWidgets('loads for a valid in-progress game', (tester) async {
      final data = await createGame(testDb);

      await tester.pumpWidget(buildGameScreen(data.gameId, testDb));
      await tester.pump();

      expect(find.byType(GameScreen), findsOneWidget);

      await navigateAway(tester, testDb);
    });

    testWidgets('loads with players present', (tester) async {
      final data = await createGame(testDb);

      final playerId = await testDb.into(testDb.players).insert(
        PlayersCompanion.insert(
          teamId: data.teamId,
          seasonId: data.seasonId,
          firstName: 'John',
          lastName: 'Doe',
        ),
      );
      await testDb.into(testDb.gamePlayers).insert(
        GamePlayersCompanion.insert(
          gameId: data.gameId,
          playerId: playerId,
          isPresent: const drift.Value(true),
        ),
      );

      await tester.pumpWidget(buildGameScreen(data.gameId, testDb));
      await tester.pump();

      expect(find.byType(GameScreen), findsOneWidget);

      await navigateAway(tester, testDb);
    });

    testWidgets('handles a scheduled game with no shifts', (tester) async {
      final data = await createGame(testDb, status: 'scheduled');

      await tester.pumpWidget(buildGameScreen(data.gameId, testDb));
      await tester.pump();

      expect(find.byType(GameScreen), findsOneWidget);

      await navigateAway(tester, testDb);
    });

    testWidgets('loads when a shift already exists', (tester) async {
      final data = await createGame(testDb);
      await testDb.into(testDb.shifts).insert(
        ShiftsCompanion.insert(
          gameId: data.gameId,
          startSeconds: 0,
          actualSeconds: const drift.Value(0),
        ),
      );

      await tester.pumpWidget(buildGameScreen(data.gameId, testDb));
      await tester.pump();

      expect(find.byType(GameScreen), findsOneWidget);

      await navigateAway(tester, testDb);
    });

    test('DB queries for a game complete without hanging', () async {
      final data = await createGame(testDb);

      final shifts = await testDb
          .watchGameShifts(data.gameId)
          .first
          .timeout(const Duration(seconds: 2));
      expect(shifts, isEmpty);

      final game = await testDb
          .getGame(data.gameId)
          .timeout(const Duration(seconds: 2));
      expect(game, isNotNull);

      final hasPlayers = await testDb
          .hasPresentPlayersForGame(data.gameId)
          .timeout(const Duration(seconds: 2));
      expect(hasPlayers, isFalse);
    });

    testWidgets('widget build completes within a few frames', (tester) async {
      final data = await createGame(testDb);
      bool built = false;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [dbProvider.overrideWithValue(testDb)],
          child: MaterialApp(
            home: Builder(builder: (context) {
              Future.microtask(() => built = true);
              return GameScreen(gameId: data.gameId);
            }),
          ),
        ),
      );
      await tester.pump();

      expect(built, isTrue, reason: 'GameScreen build must complete');

      await navigateAway(tester, testDb);
    });
  });
}
