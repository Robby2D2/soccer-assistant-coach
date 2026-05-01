# End-to-End Tests (Patrol)

This directory holds the [Patrol](https://patrol.leancode.co) integration
tests for Soccer Assistant Coach. They run on real Android emulators and
iOS simulators and exercise the full app — routing, providers, database,
notifications, and platform plugins.

The fast/cheap layer of testing lives in [`test/`](../test/). Use that for
DB rules, controllers, and pure-Dart logic. Patrol is reserved for flows
that only make sense on a real platform (notifications, permissions,
end-to-end UI journeys).

---

## One-time setup

Patrol requires a system-level CLI:

```bash
dart pub global activate patrol_cli
patrol doctor
```

`patrol doctor` reports any missing toolchain pieces (Android SDK / Xcode).
Re-run it after fixing any reported issues until it is fully green.

### iOS (Mac required)

The Xcode project needs a `RunnerUITests` target that builds
[`ios/RunnerUITests/RunnerUITests.m`](../ios/RunnerUITests/RunnerUITests.m)
and links the `patrol` CocoaPod. From a Mac:

```bash
cd ios
patrol bootstrap --no-android
pod install
```

`patrol bootstrap` mutates the Xcode project (`Runner.xcodeproj`) and adds
the test target. Commit the resulting changes.

### Android

Native config is already in place
([`android/app/build.gradle.kts`](../android/app/build.gradle.kts) +
[`android/app/src/androidTest/`](../android/app/src/androidTest/)). No
extra setup needed beyond `patrol_cli` and a running emulator.

---

## Running

```bash
# Whole suite, current device
patrol test

# A single test file
patrol test -t patrol_test/smoke_test.dart

# Pick a device (after `flutter devices`)
patrol test -d emulator-5554
patrol test -d "iPhone 15"
```

CI examples live at <https://patrol.leancode.co/ci/overview>.

---

## What's covered

| File | Flow |
|------|------|
| `smoke_test.dart` | App boots, navigates from Home → Settings |
| `settings_test.dart` | Toggling shift/halftime alarms persists across nav |
| `shift_alarm_journey_test.dart` | Seeded 3-second shift triggers the shift-end SnackBar; user acknowledges |
| `halftime_journey_test.dart` | Seeded 6-second half advances `currentHalf` (traditional mode) |
| `notifications_test.dart` | Notification permission flow + countdown plumbing on a real device |
| `json_import_test.dart` | `AppDb.importDatabase` against the seeded fixture, run on-device |

The shift/halftime journeys deliberately use the team's
**configurable shift / half length** (`shift_length_seconds`,
`half_duration_seconds`) rather than a debug fast-forward hook, so the
tests exercise the same path production users do.

---

## Test isolation

[`helpers/app_harness.dart`](helpers/app_harness.dart) exposes two
helpers: `initApp()` runs the same platform glue as `lib/main.dart`
(timezones, notifications, system UI), and `appUnderTest({AppDb? db})`
builds the production `SoccerApp` wrapped in a `ProviderScope`. Pass
`AppDb.test()` so each test starts from a clean in-memory database and
can't leak data into the user's real install.
