# Testing Guide — Soccer Assistant Coach

The project uses a **two-layer** test stack:

| Layer | Location | Speed | Run with | Use for |
|---|---|---|---|---|
| Widget / DB | `test/` | < 2 s each | `flutter test` | DB rules, controllers, models, screens that don't subscribe to Drift streams |
| Patrol E2E | `patrol_test/` | seconds–minutes | `patrol test` (Android emulator / iOS simulator) | Real notification firing, permissions, full UI journeys (shift alarm, halftime, JSON import) |

See [`patrol_test/README.md`](../patrol_test/README.md) for Patrol setup. Use in-memory databases (`AppDb.test()`) at both layers — never hit the on-disk `soccer_manager.db`.

> **patrol_cli install:** `dart pub global activate patrol_cli` — the binary lands in `%LOCALAPPDATA%\Pub\Cache\bin` which must be on PATH. Run once per machine.

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

## Existing Tests

Browse `test/` and `patrol_test/` directly — file names describe what each covers (e.g.
`shift_lifecycle_test.dart`, `roster_import_journey_test.dart`). Before writing a new test, find
the closest existing one and match its patterns.

- Shared widget/DB fixture helpers: `test/helpers/fixtures.dart` (`seedTeam`, `seedPlayer`, `seedShift`).
- Patrol harness: `patrol_test/helpers/app_harness.dart` (`appUnderTest(db:)`, overflow-error
  filter, screenshot boundary); every journey seeds `AppDb.test()` and ends with a DB-level
  assertion so a lost write fails the test.

---

## CI screenshots of a fix (UI-changing PRs)

For PRs that change UI, a journey test can snapshot the fixed screen so the qa-reviewer agent can
attach it to the GitHub issue — a human sees the actual change before merging.

Patrol 4.5.0 has **no** screenshot API, and a final-frame capture is the wrong screen for most of our
tests (they assert via the DB *after* the screen pops). So capture deliberately, mid-test, with the
helper `patrol_test/helpers/screenshot.dart`:

```dart
import 'helpers/screenshot.dart';
// ... drive to and assert the fixed UI ...
await captureScreenshot($, 'import-confirmation'); // fixed UI is on screen here
// ... then continue (taps that pop the screen, DB assertions, etc.)
```

`captureScreenshot` renders the live widget tree (`RenderRepaintBoundary.toImage` via the boundary in
`helpers/app_harness.dart`) to `files/screenshots/<name>.png` in the app's support dir. The patrol gate
(`.github/workflows/patrol-gate.yml`) pulls these with `run-as` and uploads them as artifacts; the
qa-reviewer agent embeds them in the issue via the public `ci-screenshots` branch.

Guidance:
- Call it **before** any pop/navigation away from the fixed screen.
- Name it for what it shows; capture only the screen(s) that demonstrate the change (one or two).
- It's best-effort — a capture failure never fails the test.
- Captures are headless `swiftshader` pixel_6 frames: a visual sanity check, not pixel-perfect.

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
