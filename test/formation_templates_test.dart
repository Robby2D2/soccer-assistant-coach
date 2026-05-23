import 'package:flutter_test/flutter_test.dart';
import 'package:soccer_assistant_coach/data/db/database.dart';

void main() {
  group('FormationTemplates default catalog', () {
    final templates = FormationTemplates.getTemplates();
    final byName = {for (final t in templates) t.name: t};

    test('all six 7v7/9v9 templates are present', () {
      expect(byName.containsKey('7v7 - 2-3-1'), isTrue);
      expect(byName.containsKey('7v7 - 3-2-1'), isTrue);
      expect(byName.containsKey('7v7 - 2-1-2-1'), isTrue);
      expect(byName.containsKey('9v9 - 3-2-3'), isTrue);
      expect(byName.containsKey('9v9 - 3-3-2'), isTrue);
      expect(byName.containsKey('9v9 - 2-3-3'), isTrue);
    });

    test('existing 5v5/11v11 templates are unchanged', () {
      expect(byName.containsKey('2-2-1'), isTrue);
      expect(byName.containsKey('4-4-2'), isTrue);
      expect(byName.containsKey('4-3-3'), isTrue);
      expect(byName.containsKey('4-2-3-1'), isTrue);
      expect(byName['2-2-1']!.playerCount, 6);
      expect(byName['4-4-2']!.playerCount, 11);
      expect(byName['4-3-3']!.playerCount, 11);
      expect(byName['4-2-3-1']!.playerCount, 11);
    });

    test('every template has consistent counts and a goalkeeper', () {
      for (final t in templates) {
        expect(
          t.positions.length,
          t.playerCount,
          reason: '${t.name} position count must equal playerCount',
        );
        expect(
          t.abbreviations.length,
          t.playerCount,
          reason: '${t.name} abbreviation count must equal playerCount',
        );
        expect(
          t.positions.first,
          'Goalkeeper',
          reason: '${t.name} should start with Goalkeeper',
        );
        expect(
          t.abbreviations.first,
          'GK',
          reason: '${t.name} should start with GK abbreviation',
        );
      }
    });

    test('7v7 templates have 7 players with the spec shape', () {
      // 7v7 - 2-3-1: 1 GK + 2 D + 3 M + 1 F
      final t231 = byName['7v7 - 2-3-1']!;
      expect(t231.playerCount, 7);
      expect(t231.abbreviations.where((a) => a.endsWith('B')).length, 2);
      expect(t231.abbreviations.where((a) => a.endsWith('M')).length, 3);
      expect(t231.abbreviations.where((a) => a == 'ST').length, 1);

      // 7v7 - 3-2-1: 1 GK + 3 D + 2 M + 1 F
      final t321 = byName['7v7 - 3-2-1']!;
      expect(t321.playerCount, 7);
      expect(t321.abbreviations.where((a) => a.endsWith('B')).length, 3);
      expect(t321.abbreviations.where((a) => a.endsWith('M')).length, 2);
      expect(t321.abbreviations.where((a) => a == 'ST').length, 1);

      // 7v7 - 2-1-2-1: 1 GK + 2 D + 1 DM + 2 AM + 1 F
      final t2121 = byName['7v7 - 2-1-2-1']!;
      expect(t2121.playerCount, 7);
      expect(t2121.abbreviations.where((a) => a.endsWith('B')).length, 2);
      expect(t2121.abbreviations.where((a) => a == 'DM').length, 1);
      expect(t2121.abbreviations.where((a) => a.endsWith('AM')).length, 2);
      expect(t2121.abbreviations.where((a) => a == 'ST').length, 1);
    });

    test('9v9 templates have 9 players with the spec shape', () {
      // 9v9 - 3-2-3: 1 GK + 3 D + 2 M + 3 F
      final t323 = byName['9v9 - 3-2-3']!;
      expect(t323.playerCount, 9);
      expect(t323.abbreviations.where((a) => a.endsWith('B')).length, 3);
      expect(t323.abbreviations.where((a) => a.endsWith('M')).length, 2);
      expect(t323.abbreviations.where((a) => a.endsWith('F')).length, 3);

      // 9v9 - 3-3-2: 1 GK + 3 D + 3 M + 2 F
      final t332 = byName['9v9 - 3-3-2']!;
      expect(t332.playerCount, 9);
      expect(t332.abbreviations.where((a) => a.endsWith('B')).length, 3);
      expect(t332.abbreviations.where((a) => a.endsWith('M')).length, 3);
      expect(t332.abbreviations.where((a) => a.endsWith('ST')).length, 2);

      // 9v9 - 2-3-3: 1 GK + 2 D + 3 M + 3 F
      final t233 = byName['9v9 - 2-3-3']!;
      expect(t233.playerCount, 9);
      expect(t233.abbreviations.where((a) => a.endsWith('B')).length, 2);
      expect(t233.abbreviations.where((a) => a.endsWith('M')).length, 3);
      expect(t233.abbreviations.where((a) => a.endsWith('F')).length, 3);
    });
  });
}
