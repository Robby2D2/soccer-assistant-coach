# Production Readiness — April 2026 Pre-Store Audit

## Session: April 24, 2026

### What was done
Full pre-store audit and fixes to prepare the app for Apple App Store and Google Play Store submission.

### Changes made

| Change | Detail |
|--------|--------|
| Removed `assets/sounds/` from pubspec.yaml | Directory was empty; sound service uses `SystemSound`, not file assets |
| Added `ios/Runner/PrivacyInfo.xcprivacy` | Required by Apple for apps using `shared_preferences` (UserDefaults) and `path_provider` (file timestamps); prevents App Store rejection |
| Fixed `CFBundleName` in `Info.plist` | Changed from `soccer_assistant_coach` to `Soccer Assistant Coach` |
| Replaced `print()` with `debugPrint()` | In `database.dart` and `season_provider.dart` — no production log spam |
| `.gitignore` additions | `soccer_manager.db`, `*.db-journal`, `notes.txt`, `learnings.txt`, loose PNG/scripts, keystore files |
| Moved `full_season_fixed_metrics.json` | Root → `test/fixtures/` |
| Rewrote `test/database_migration_test.dart` | 5 real tests: fresh-install schema invariants + v17→v18 upgrade with data preservation |
| Added `AppDb.forTesting(super.executor)` | Enables file-backed test DBs for migration tests |
| Fixed `StopwatchCtrl` Timer leak | Added `ref.onDispose(() => _t?.cancel())` in `build()` |

### Key learnings
- `_verifyInvariants()` in flutter_test runs **before** widget tree disposal — any pending timer causes test failure
- `SharedPreferences.setMockInitialValues({})` registers a handler in the real async zone, causing `getInstance()` to hang inside flutter_test's fake-async zone — never call it in widget tests
- Riverpod `autoDispose` does NOT auto-cancel `Timer` objects held by a `Notifier`; must register `ref.onDispose(() => _t?.cancel())` explicitly in `build()`
- To test DB migrations: use raw `sqlite3` package to seed old schema files, then open with `AppDb.forTesting(NativeDatabase(file))` — opening via `AppDb` itself would trigger `onCreate` first
