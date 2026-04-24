# Testing Guide — Soccer Assistant Coach

All tests live in `test/`. Run the full suite with:
```
flutter test
```

Tests should be fast (< 2 s each). Use in-memory databases — never hit the on-disk `soccer_manager.db`.

---

## Test Database Setup

```dart
final db = AppDb.test(); // in-memory SQLite, disposed automatically
```

Insert minimal fixture data:
```dart
final teamId = await db.addTeam(TeamsCompanion.insert(name: 'Demo FC'));
final gameId = await db.addGame(GamesCompanion.insert(teamId: Value(teamId), ...));
```

---

## Widget Test Template

```dart
testWidgets('description of expected behavior', (tester) async {
  final db = AppDb.test();

  // Insert fixtures
  final teamId = await db.addTeam(TeamsCompanion.insert(name: 'Test FC'));

  await tester.pumpWidget(
    ProviderScope(
      overrides: [dbProvider.overrideWithValue(db)],
      child: MaterialApp(
        home: YourWidget(teamId: teamId),
      ),
    ),
  );

  await tester.pumpAndSettle(); // let async providers resolve

  expect(find.text('Test FC'), findsOneWidget);
});
```

---

## What to Test

| Area | Approach |
|---|---|
| Widget rendering | `pumpWidget` + `find.*` assertions |
| DB reads/writes | `AppDb.test()` + direct await on db methods |
| Provider state | `ProviderScope` overrides |
| Navigation | Wrap in `MaterialApp.router` with `GoRouter` |
| Theme/contrast | Read `Theme.of(context).colorScheme` from a captured context |

---

## Existing Test Files

| File | Covers |
|---|---|
| `team_app_bar_test.dart` | `TeamAppBar` fallback title and team-name rendering |
| `game_scaffold_test.dart` | `GameScaffold` resolves `teamId` from `gameId` |
| `game_screen_test.dart` | Game screen integration |
| `game_screen_hang_test.dart` | Regression: game screen no longer hangs |
| `game_screen_simple_test.dart` | Lightweight game screen smoke test |
| `import_json_test.dart` | JSON season import round-trip |
| `database_migration_test.dart` | DB schema migration integrity |
| `widget_test.dart` | Basic app smoke test |

---

## Guidelines

- **Every new feature or bug fix must include or update a test.** If a fix is trivial (typo, copy), a test is still preferred.
- Prefer narrow unit/widget tests over broad integration tests.
- Do not use `flutter_test` mocking for the database — use `AppDb.test()` instead (real SQL behavior catches issues mocks miss).
- Use `tester.pumpAndSettle()` when the widget tree has async operations (DB lookups, provider futures).
- For color/contrast assertions, derive the expected value from `TeamTheme` logic rather than hardcoding hex strings.
- Snapshot/golden tests are acceptable for complex layout widgets; store goldens in `test/goldens/`.

---

## Linting and Analysis

Before marking any task complete:
```
flutter analyze
flutter test
```

Fix all errors. Address warnings unless there is a documented reason not to.
