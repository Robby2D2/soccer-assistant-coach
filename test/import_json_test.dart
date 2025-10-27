import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:soccer_assistant_coach/data/db/database.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('import full_season_fixed_metrics.json into in-memory DB', () async {
    final db = AppDb.test();
    try {
      final file = File('full_season_fixed_metrics.json');
      expect(await file.exists(), isTrue, reason: 'JSON file must exist at repository root');

      final jsonData = await file.readAsString();

      final result = await db.importDatabase(jsonData);

      // Print result for visibility in logs
      print('import result: $result');

      expect(result, isTrue, reason: 'Import should complete without errors');
    } finally {
      await db.close();
    }
  }, timeout: Timeout(Duration(minutes: 2)));
}
