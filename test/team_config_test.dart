import 'package:flutter_test/flutter_test.dart';
import 'package:soccer_assistant_coach/data/db/database.dart';

import 'helpers/fixtures.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Team configuration', () {
    late AppDb db;

    setUp(() {
      db = AppDb.test();
    });

    tearDown(() async {
      await db.close();
    });

    test('default shift length is 5 minutes (300s)', () async {
      final ids = await seedTeam(db); // no override
      expect(await db.getTeamShiftLengthSeconds(ids.teamId), 300);
    });

    test('default half duration is 20 minutes (1200s)', () async {
      final ids = await seedTeam(db);
      expect(await db.getTeamHalfDurationSeconds(ids.teamId), 1200);
    });

    test('custom shift length is honored', () async {
      final ids = await seedTeam(db, shiftLengthSeconds: 90);
      expect(await db.getTeamShiftLengthSeconds(ids.teamId), 90);
    });

    test('setTeamShiftLengthSeconds(0) falls back to default', () async {
      final ids = await seedTeam(db);
      await db.setTeamShiftLengthSeconds(ids.teamId, 0);
      expect(await db.getTeamShiftLengthSeconds(ids.teamId), 300);
    });

    test('setTeamShiftLengthSeconds persists a positive value', () async {
      final ids = await seedTeam(db);
      await db.setTeamShiftLengthSeconds(ids.teamId, 45);
      expect(await db.getTeamShiftLengthSeconds(ids.teamId), 45);
    });

    test('setTeamHalfDurationSeconds persists a positive value', () async {
      final ids = await seedTeam(db);
      await db.setTeamHalfDurationSeconds(ids.teamId, 600);
      expect(await db.getTeamHalfDurationSeconds(ids.teamId), 600);
    });

    test('teamMode round-trips between shift and traditional', () async {
      final ids = await seedTeam(db); // defaults to "shift"
      expect(await db.getTeamMode(ids.teamId), 'shift');
      await db.setTeamMode(ids.teamId, 'traditional');
      expect(await db.getTeamMode(ids.teamId), 'traditional');
    });
  });
}
