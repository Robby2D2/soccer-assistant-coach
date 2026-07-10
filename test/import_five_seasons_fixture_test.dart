import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:soccer_assistant_coach/data/db/database.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('import five_seasons_real_madrid_barcelona.json into in-memory DB', () async {
    final db = AppDb.test();
    try {
      final file = File('test/fixtures/five_seasons_real_madrid_barcelona.json');
      expect(
        await file.exists(),
        isTrue,
        reason: 'fixture must exist at test/fixtures/five_seasons_real_madrid_barcelona.json',
      );

      final jsonData = await file.readAsString();

      final result = await db.importDatabase(jsonData);

      expect(result, isTrue, reason: 'Import should complete without errors');

      final teams = await db.getAllTeams();
      expect(teams, hasLength(10), reason: '2 clubs x 5 seasons');

      final games = await db.select(db.games).get();
      expect(games, hasLength(60), reason: '6 games per club per season');
    } finally {
      await db.close();
    }
  }, timeout: Timeout(Duration(minutes: 2)));
}
