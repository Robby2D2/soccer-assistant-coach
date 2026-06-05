import 'package:flutter_test/flutter_test.dart';
import 'package:soccer_assistant_coach/data/db/database.dart';

import 'helpers/fixtures.dart';

// Widget-level rendering of AssignPlayersScreen is covered by the Patrol E2E
// suite (`integration_test/shift_alarm_journey_test.dart`). Driving the
// screen here would require pumping a tree with active Drift stream
// subscriptions, which leaves Timers pending past the test framework's
// invariant check — see .agents/MEMORY.md for the previous incident.

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Substitution DB rules', () {
    late AppDb db;

    setUp(() {
      db = AppDb.test();
    });

    tearDown(() async {
      await db.close();
    });

    test('setPlayerPosition inserts a new assignment', () async {
      final ids = await seedTeam(db, createGame: true);
      final playerId = await seedPlayer(
        db,
        teamId: ids.teamId,
        seasonId: ids.seasonId,
        firstName: 'Alex',
        lastName: 'Striker',
      );
      final shiftId = await seedShift(db, gameId: ids.gameId!);

      await db.setPlayerPosition(
        shiftId: shiftId,
        playerId: playerId,
        position: 'CENTER_FORWARD',
      );

      final assigns = await db.watchAssignments(shiftId).first;
      expect(assigns, hasLength(1));
      expect(assigns.single.playerId, playerId);
      expect(assigns.single.position, 'CENTER_FORWARD');
    });

    test('setPlayerPosition replaces an existing assignment', () async {
      final ids = await seedTeam(db, createGame: true);
      final playerId = await seedPlayer(
        db,
        teamId: ids.teamId,
        seasonId: ids.seasonId,
        firstName: 'Sam',
        lastName: 'Versatile',
      );
      final shiftId = await seedShift(db, gameId: ids.gameId!);

      await db.setPlayerPosition(
        shiftId: shiftId,
        playerId: playerId,
        position: 'GOALIE',
      );
      await db.setPlayerPosition(
        shiftId: shiftId,
        playerId: playerId,
        position: 'LEFT_DEFENSE',
      );

      final assigns = await db.watchAssignments(shiftId).first;
      expect(
        assigns,
        hasLength(1),
        reason: 'Reassigning a player must not duplicate the row',
      );
      expect(assigns.single.position, 'LEFT_DEFENSE');
    });

    test('marking a player absent clears their shift assignments', () async {
      final ids = await seedTeam(db, createGame: true);
      final playerId = await seedPlayer(
        db,
        teamId: ids.teamId,
        seasonId: ids.seasonId,
        firstName: 'Avery',
        lastName: 'Outed',
      );
      final shiftId = await seedShift(db, gameId: ids.gameId!);

      await db.setAttendance(
        gameId: ids.gameId!,
        playerId: playerId,
        isPresent: true,
      );
      await db.setPlayerPosition(
        shiftId: shiftId,
        playerId: playerId,
        position: 'GOALIE',
      );
      expect((await db.watchAssignments(shiftId).first), hasLength(1));

      // Marking absent should remove all of this player's assignments
      // for shifts in this game (per AttendanceQueries.setAttendance).
      await db.setAttendance(
        gameId: ids.gameId!,
        playerId: playerId,
        isPresent: false,
      );

      final after = await db.watchAssignments(shiftId).first;
      expect(after, isEmpty);
    });

    test(
      'multiple players can occupy distinct positions on the same shift',
      () async {
        final ids = await seedTeam(db, createGame: true);
        final goalie = await seedPlayer(
          db,
          teamId: ids.teamId,
          seasonId: ids.seasonId,
          firstName: 'G',
          lastName: 'Keeper',
        );
        final forward = await seedPlayer(
          db,
          teamId: ids.teamId,
          seasonId: ids.seasonId,
          firstName: 'F',
          lastName: 'Striker',
        );
        final shiftId = await seedShift(db, gameId: ids.gameId!);

        await db.setPlayerPosition(
          shiftId: shiftId,
          playerId: goalie,
          position: 'GOALIE',
        );
        await db.setPlayerPosition(
          shiftId: shiftId,
          playerId: forward,
          position: 'CENTER_FORWARD',
        );

        final assigns = await db.watchAssignments(shiftId).first;
        expect(assigns, hasLength(2));
        final byPlayer = {for (final a in assigns) a.playerId: a.position};
        expect(byPlayer[goalie], 'GOALIE');
        expect(byPlayer[forward], 'CENTER_FORWARD');
      },
    );

    test(
      'attendance gates which players show up in present-player lookups',
      () async {
        final ids = await seedTeam(db, createGame: true);
        final present = await seedPlayer(
          db,
          teamId: ids.teamId,
          seasonId: ids.seasonId,
          firstName: 'Pat',
          lastName: 'Present',
        );
        final absent = await seedPlayer(
          db,
          teamId: ids.teamId,
          seasonId: ids.seasonId,
          firstName: 'Aiden',
          lastName: 'Absent',
        );
        await db.setAttendance(
          gameId: ids.gameId!,
          playerId: present,
          isPresent: true,
        );
        await db.setAttendance(
          gameId: ids.gameId!,
          playerId: absent,
          isPresent: false,
        );

        final players = await db.presentPlayersForGame(ids.gameId!, ids.teamId);
        final names = players.map((p) => p.firstName).toSet();
        expect(names, contains('Pat'));
        expect(names, isNot(contains('Aiden')));
        expect(await db.hasPresentPlayersForGame(ids.gameId!), isTrue);
      },
    );

    test(
      'hasPresentPlayersForGame is false when nobody has been marked present',
      () async {
        final ids = await seedTeam(db, createGame: true);
        final p = await seedPlayer(
          db,
          teamId: ids.teamId,
          seasonId: ids.seasonId,
          firstName: 'Only',
          lastName: 'One',
        );
        await db.setAttendance(
          gameId: ids.gameId!,
          playerId: p,
          isPresent: false,
        );
        expect(await db.hasPresentPlayersForGame(ids.gameId!), isFalse);
      },
    );

    test('jersey number round-trips through the DB', () async {
      final ids = await seedTeam(db, createGame: true);
      final playerId = await seedPlayer(
        db,
        teamId: ids.teamId,
        seasonId: ids.seasonId,
        firstName: 'Jamie',
        lastName: 'Kit',
        jerseyNumber: 7,
      );

      final player = await db.getPlayer(playerId);
      expect(player, isNotNull);
      expect(player!.jerseyNumber, 7);
    });

    test('player with no jersey number has null jerseyNumber', () async {
      final ids = await seedTeam(db, createGame: true);
      final playerId = await seedPlayer(
        db,
        teamId: ids.teamId,
        seasonId: ids.seasonId,
        firstName: 'Robin',
        lastName: 'Nonum',
      );

      final player = await db.getPlayer(playerId);
      expect(player, isNotNull);
      expect(player!.jerseyNumber, isNull);
    });
  });
}
