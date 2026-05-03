import 'package:flutter_test/flutter_test.dart';
import 'package:soccer_assistant_coach/data/db/database.dart';

import 'helpers/fixtures.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Shift lifecycle', () {
    late AppDb db;

    setUp(() {
      db = AppDb.test();
    });

    tearDown(() async {
      await db.close();
    });

    test('incrementShiftDuration accumulates actualSeconds', () async {
      final ids = await seedTeam(db, createGame: true);
      final shiftId = await seedShift(db, gameId: ids.gameId!);

      await db.incrementShiftDuration(shiftId, 5);
      await db.incrementShiftDuration(shiftId, 3);

      final shift = await db.getShift(shiftId);
      expect(shift, isNotNull);
      expect(shift!.actualSeconds, 8);
    });

    test('incrementShiftDuration with non-positive seconds is a no-op', () async {
      final ids = await seedTeam(db, createGame: true);
      final shiftId = await seedShift(db, gameId: ids.gameId!);

      await db.incrementShiftDuration(shiftId, 0);
      await db.incrementShiftDuration(shiftId, -10);

      final shift = await db.getShift(shiftId);
      expect(shift!.actualSeconds, 0);
    });

    test('watchActiveShift returns the open-ended shift', () async {
      final ids = await seedTeam(db, createGame: true);
      // First shift, ended.
      await seedShift(
        db,
        gameId: ids.gameId!,
        startSeconds: 0,
        endSeconds: 300,
      );
      // Second shift, active.
      final activeId = await seedShift(
        db,
        gameId: ids.gameId!,
        startSeconds: 300,
      );

      final active = await db.watchActiveShift(ids.gameId!).first;
      expect(active, isNotNull);
      expect(active!.id, activeId);
    });

    test('watchActiveShift returns null when no shift is active', () async {
      final ids = await seedTeam(db, createGame: true);
      await seedShift(
        db,
        gameId: ids.gameId!,
        startSeconds: 0,
        endSeconds: 300,
      );

      final active = await db.watchActiveShift(ids.gameId!).first;
      expect(active, isNull);
    });

    test('watchGameShifts emits all shifts ordered by id', () async {
      final ids = await seedTeam(db, createGame: true);
      final s1 = await seedShift(db, gameId: ids.gameId!, startSeconds: 0);
      final s2 = await seedShift(db, gameId: ids.gameId!, startSeconds: 300);

      final shifts = await db.watchGameShifts(ids.gameId!).first;
      expect(shifts.map((s) => s.id), containsAll(<int>[s1, s2]));
    });
  });
}
