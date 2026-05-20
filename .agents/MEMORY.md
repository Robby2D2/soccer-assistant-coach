# MEMORY

This file tracks key decisions, conventions, and session learnings for the soccer-assistant-coach codebase. Keep under 200 lines; prune older entries to `LONGTERM_MEMORY.md`.

---

## Session: May 20, 2026 — Android CI toolchain: fix Gradle OOM, Jetifier OOM, and deprecation warnings

Date: 2026-05-20

### What was done
Fixed three cascading CI failures: Gradle heap OOM silently killing the runner, Jetifier OOM on Flutter's ARM64 engine JARs, and all Android toolchain deprecation warnings (Gradle, AGP, Kotlin).

### Changes made

| Change | Detail |
|--------|--------|
| `android/gradle.properties` | Reduced `Xmx8G → Xmx2g`, `MaxMetaspaceSize=4G → 512m`; added `android.enableJetifier=false` |
| `android/gradle/wrapper/gradle-wrapper.properties` | Gradle 8.12 → 8.13 (minimum required by AGP 8.11.1) |
| `android/settings.gradle.kts` | AGP 8.9.1 → 8.11.1; Kotlin 2.1.0 → 2.2.20 |
| `android/app/build.gradle.kts` | Removed `id("kotlin-android")` plugin; removed `kotlinOptions {}` block |
| `android/build.gradle.kts` | Removed `KotlinCompile` import and `tasks.withType<KotlinCompile>` block |
| `.github/workflows/ci.yml` | Added `patrol build android` pre-build step; `target: default`; `timeout-minutes: 40` |

### Key learnings
- **Gradle heap OOM kills the runner silently**: `Xmx8G + MaxMetaspaceSize=4G` = 12 GB on a 7 GB GitHub runner → Linux OOM killer kills the process → no logs uploaded. Signature: step shows "in_progress" with no `completedAt`, no output. Fix: cap at `Xmx2g -XX:MaxMetaspaceSize=512m`.
- **`android.enableJetifier=true` OOM on Flutter projects**: Jetifier transforms Flutter's own already-AndroidX ARM64 engine JARs; even 2g heap can't handle `JetifyTransform` on these large JARs. Always set `android.enableJetifier=false` for Flutter projects — the engine is already AndroidX.
- **Gradle version lookup**: AGP 8.11.1 requires Gradle 8.13 minimum. Gradle 8.14.0 does NOT exist at the distribution URL (404). Let the AGP build error message tell you the actual minimum required, then use that version.
- **Flutter Built-in Kotlin migration**: Remove `id("kotlin-android")` from the app's plugins block — `dev.flutter.flutter-gradle-plugin` manages Kotlin internally. Remove `kotlinOptions {}` too (only valid when explicit kotlin-android plugin is present).
- **Kotlin 2.2 breaking changes**: `kotlinOptions {}` DSL removed (use `compilerOptions {}`); `JvmTarget.JVM_1_6` enum value removed (Kotlin 2.2 requires JVM 8+ minimum, so the old "raise 1.6 to 1.8" guard is moot — delete the block).

---

## Session: May 19, 2026 — Patrol E2E test fixes: all 11 tests now green

Date: 2026-05-19

### What was done
Fixed three previously-failing/excluded Patrol journey tests and updated CI to run all 11 tests.

### Changes made

| Change | Detail |
|--------|--------|
| `lib/data/db/database.dart` | SQL quoting fix: `"shift"` → `'shift'` in `getTeamMode` COALESCE query (double quotes = column name in SQLite, not string literal) |
| `patrol_test/json_import_test.dart` | Switched from `dart:io File` (absent on device) to `rootBundle.loadString()` for test fixture |
| `pubspec.yaml` | Declared `test/fixtures/full_season_fixed_metrics.json` as a Flutter asset so it bundles into the APK |
| `lib/features/home/home_screen.dart` | Guarded `game.currentShiftId!` null crash for in-progress games with no current shift yet |
| `patrol_test/shift_alarm_journey_test.dart` | Removed `setAttendance` call so `_ensureInitialShift` exits early → button stays "Start"; use `SettlePolicy.noSettle` + `Future.delayed` for timer-based alarm wait; clear SharedPreferences at test start |
| `.github/workflows/ci.yml` | Added all three previously-excluded tests to the stable CI subset (all 11 now run) |

### Key learnings
- **SQLite double-quote quirk**: `"shift"` in a SQL string literal position is parsed as an identifier (column name), not a string. Always use single quotes for string literals in raw SQL.
- **Patrol on real device — `pumpAndSettle` timeout not honored**: In integration test mode, `pumpAndSettle(timeout: ...)` may not respect the timeout. Use `SettlePolicy.noSettle` for taps when `Timer.periodic` is running; use `Future.delayed` for real wall-clock waits (not `pump()` loops).
- **SharedPreferences persists across Patrol test runs**: In-memory DB always creates IDs from 1 — stale `timer_started_at_1` causes `_restore()` to auto-start the timer. Always `await prefs.clear()` at test start.
- **`_ensureInitialShift` changes button text**: If any player is marked present, GameScreen auto-creates an initial shift on mount, making the button read "Resume" instead of "Start". Tests that tap "Start" by text must not seed present attendance.
- **Use PowerShell tool, not Bash, for Windows commands**: Bash tool runs `/usr/bin/bash` (Unix) and exits 127 for `flutter`, `patrol`, `fvm`, etc. Always use PowerShell tool for Windows-native dev commands.

---

## Session: May 18, 2026 — CSV roster import upgrade (issue #6)

Date: 2026-05-18

### What was done
Upgraded the roster import screen to support file upload in addition to paste-in text, and replaced blind INSERTs with upsert diff logic (add/update/archive) plus a confirmation dialog. Also documented the `gh` CLI path required for Claude Code tools.

### Changes made

| Change | Detail |
|--------|--------|
| `lib/utils/roster_diff.dart` | New utility: `diffRoster()` computes add/update/archive sets by matching on normalized firstName+lastName |
| `lib/features/players/roster_import_screen.dart` | Added file picker button; both file and paste paths feed the same diff+confirm+execute flow; fixed `Scaffold` → `TeamScaffold` |
| `lib/l10n/app_{en,es,fr}.arb` | Added 8 new localization strings for the new UI |
| `test/roster_csv_import_test.dart` | 7 unit tests covering all diff cases |
| `patrol_test/roster_import_journey_test.dart` | E2E: paste CSV → confirm dialog → DB assertions for add/update/archive |
| `AGENTS.md` | Documented `gh` CLI path: `C:\Program Files\GitHub CLI\gh.exe` |
| `.claude/commands/fix-issue.md` | New `/fix-issue` skill for automated issue → PR workflow |

### Key learnings
- **`gh` is not in the sandboxed PATH** — must invoke as `& "C:\Program Files\GitHub CLI\gh.exe"` from PowerShell tools; `gh` bare, `wsl bash -c "gh ..."`, etc. do not work.
- **Patrol E2E cannot drive the OS file picker** — test the paste-text path instead; it exercises the same diff+confirm+write pipeline and is fully deterministic on an emulator.
- **`flutter gen-l10n` must be run after ARB edits** before `flutter analyze` will pass, as the generated `app_localizations_*.dart` files are what the compiler sees.
- **Generated l10n files are tracked in this repo** (`lib/l10n/app_localizations*.dart`) — commit them alongside ARB changes or a fresh checkout won't compile.

---

## Session: May 18, 2026 — iOS CI debugging: keychain hang fix and runner choice

Date: 2026-05-18

### What was done
Debugged and fixed a persistent hang in `flutter build ipa` on GitHub Actions macOS runners. All one-time setup steps (Match init, secrets, agreements) are now complete. Updated `.agents/memory/ios_setup.md` with current state.

### Changes made

| Change | Detail |
|--------|--------|
| `fastlane/Fastfile` `setup_signing` | Added `create_keychain` + passed `keychain_name`/`keychain_password` to `match` so the cert lands in a named, always-unlocked keychain |
| `.github/workflows/release-ios.yml` | Added `security set-key-partition-list` step before `flutter build ipa`; runner changed from `macos-latest` → `macos-14` → `macos-13` → back to `macos-14` |
| `ios/ExportOptions.plist` | Created for manual signing: `app-store` method, `DPS86D59PK`, profile `match AppStore com.useunix.soccerassistantcoach` |
| `Gemfile.lock` | Added `arm64-darwin-23` to PLATFORMS so bundler works on macOS CI runners |
| `.agents/memory/ios_setup.md` | Updated runner choice, Admin key requirement, and marked one-time steps complete |

### Key learnings

**Runner choice — use `macos-14`**
- `macos-13` (Intel): queue wait > 45 min in practice — not usable
- `macos-latest` / `macos-15`: 6-hour silent hangs during testing — avoid
- `macos-14` (Apple Silicon): picks up quickly, works correctly with the keychain fix

**Why `flutter build ipa` hung silently**
`flutter build ipa` invokes xcodebuild as a subprocess _outside_ of fastlane's session. When `match` installs the distribution cert into fastlane's ephemeral temp keychain, xcodebuild can't find it and waits indefinitely for a keychain prompt. Fix requires two things together:
1. `create_keychain(name: "build.keychain", default_keychain: true, unlock: true, timeout: 3600)` in `setup_signing` — creates a persistent named keychain that stays unlocked
2. `security set-key-partition-list -S apple-tool:,apple: -s -k buildpassword ~/Library/Keychains/build.keychain-db` — grants codesign direct access to the signing key with no UI prompts

**Use `flutter build ipa`, not fastlane `build_app`**
`fastlane build_app` (xcodebuild via fastlane) also hangs — same root cause, plus CocoaPods ruby environment conflicts when called from inside fastlane's `sh()`. `flutter build ipa --export-options-plist=ios/ExportOptions.plist` as a standalone workflow step avoids both issues.

**Pipeline structure**
```
setup_signing (fastlane) → Allow codesign access (security cmd) → flutter build ipa → fastlane ios release (upload only)
```

**Admin API key required**
App Store Connect API key must have **Admin** role. Developer role cannot create Distribution certificates — Match fails silently or with a misleading auth error.

**One-time steps now complete**
- Match certificates repo populated with dist cert + App Store provisioning profile
- All 6 GitHub secrets set
- Apple Developer Program and App Store Connect agreements accepted at both portals

---

## Session: May 18, 2026 — App Store submission tooling

Date: 2026-05-18

### What was done
Set up the full App Store submission pipeline: iOS screenshots, App Store metadata, Fastlane deliver lanes, and verified the GitHub Pages privacy policy URL is live.

### Changes made

| Change | Detail |
|--------|--------|
| `store/generate_assets.py` | Added `out_dir` param to screenshot functions; added iOS screenshot generation for iPhone 6.9" (1320×2868) and 6.7" (1290×2796) |
| `fastlane/screenshots/en-US/` | 4 iOS screenshots generated: `iphone69_01_teams`, `iphone69_02_lineup`, `iphone67_01_teams`, `iphone67_02_lineup` |
| `fastlane/metadata/en-US/` | Created all required App Store text files: name, subtitle, description, keywords, release_notes, support_url, privacy_url |
| `fastlane/Fastfile` | Added `ios metadata` lane (upload metadata + screenshots, no submit) and `ios submit` lane (metadata + submit for review) |
| `AGENTS.md` | Updated available lanes summary with the two new iOS lanes |

### Key learnings
- **App Store submission is fully automated** via `bundle exec fastlane ios submit` (from WSL) — selects latest TestFlight build and submits for review
- **Metadata-only updates** use `bundle exec fastlane ios metadata` (no submission)
- **Privacy policy** is already live at `https://robby2d2.github.io/soccer-assistant-coach/privacy-policy` via existing `docs/` GitHub Pages setup
- **Screenshot naming for deliver**: Fastlane's `upload_to_app_store` detects device size from filename; use `iphone69` and `iphone67` prefixes for 6.9" and 6.7" iPhone displays
- **Submission answer**: export compliance `false` (standard HTTPS only), IDFA `false` (no ad tracking)

---

## Session: May 4, 2026 — Play Store compliance + store listing assets

Date: 2026-05-04

### What was done
Removed the `USE_EXACT_ALARM` Android permission (restricted to alarm/calendar apps; Play Store rejected it). Generated Play Store listing assets. Documented the release process for agents and humans.

### Changes made

| Change | Detail |
|--------|--------|
| `android/app/src/main/AndroidManifest.xml` | Removed `USE_EXACT_ALARM`; kept `SCHEDULE_EXACT_ALARM` (user opt-in, allowed for any app). Existing fallback to inexact alarms in `notification_service.dart` handles the denied-permission case. |
| `store/assets/` | Added feature graphic (1024×500) + 2 phone, 2 tablet-7", 2 tablet-10" screenshots |
| `store/generate_assets.py` | Python/Pillow script to regenerate all store assets |
| `AGENTS.md` | Added "Publishing a Release" section (WSL + `bundle exec fastlane`) |
| `README.md` | Added "Publishing a Release" section with lane table and asset regen instructions |

### Key learnings
- **`USE_EXACT_ALARM`** is auto-granted but Play-Store-restricted to alarm/calendar apps. Any other app must use **`SCHEDULE_EXACT_ALARM`** (requires user opt-in) and handle the denied case with inexact fallback.
- **Fastlane must be run from WSL** via `bundle exec fastlane <lane>` — it is vendored in `vendor/bundle/ruby/3.2.0` and not accessible from PowerShell or Git Bash on this machine.
- WSL path to project: `/mnt/c/Users/rdane/Documents/Projects/soccer-assistant-coach`
- Store assets can be regenerated any time with `python -X utf8 store/generate_assets.py` (Pillow required, already installed).

---

<!-- Older entries moved to .agents/memory/testing.md and .agents/memory/production_readiness.md -->
