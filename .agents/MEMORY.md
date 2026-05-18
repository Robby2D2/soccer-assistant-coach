# MEMORY

This file tracks key decisions, conventions, and session learnings for the soccer-assistant-coach codebase. Keep under 200 lines; prune older entries to `LONGTERM_MEMORY.md`.

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

## Session: May 3, 2026 — Patrol journey tests for major user flows

Date: 2026-05-03

### What was done
Added four new Patrol E2E journey tests covering the major user flows that the original alarm-focused suite didn't reach: team creation, player substitution, manual shift advancement, and starting a new season from a previous season's roster.

### Changes made

| Change | Detail |
|--------|--------|
| `patrol_test/team_management_journey_test.dart` | Home → Manage Teams → Create Team dialog → assert team appears in active season |
| `patrol_test/substitution_journey_test.dart` | Pushes the production GoRouter into `/game/:id/assign/:shiftId`, picks a position via dropdown, asserts the `player_shifts` row landed |
| `patrol_test/shift_management_journey_test.dart` | Two queued shifts → tap "Next Shift" → confirm "Start next shift early?" dialog → assert `games.currentShiftId` advances |
| `patrol_test/season_clone_journey_test.dart` | Manage Seasons → Create New Season with a previous-season team checked → assert new season + cloned roster |
| `patrol_test/README.md` | Added the four new tests to the coverage table |
| `.agents/TESTING.md` | Same coverage update in the testing guide |
| `.agents/ARCHITECTURE.md` | Added two decision rows: Patrol substitution coverage uses the deep-link route, and the journey suite always ends with a DB assertion |
| `README.md` | New "End-to-End Tests (Patrol)" section listing every journey + how to invoke `patrol test` |

### Key learnings
- **Substitution UI is fragmented across two screens** (`AssignPlayersScreen` route + the inline lineup builder used by the live game screen). Driving the deep-link route is much more deterministic for Patrol than driving the live game screen's auto-rotation/lineup-builder UI, and exercises the same `setPlayerPosition` code path.
- **`router.push('/game/$id/assign/$shiftId')` works directly inside a Patrol test** because the harness already pumps `SoccerApp` (which uses `MaterialApp.router(routerConfig: router)`) — no separate `Navigator.of(context)` lookup needed.
- **The `_handleStartNextShift` confirmation dialog** appears whenever there's still time on the current shift, so a Patrol test that seeds a fresh game (zero elapsed time) will always need to dismiss "Start next shift early?" before the shift actually advances.
- **`cloneSelectedTeamsToSeason` is what the Create-New-Season dialog calls** when the user checks at least one existing team. The cloned team gets a new ID with the same name, and the player roster is duplicated into the new `seasonId'.
- Every journey test ends with a DB-level assertion (`getAllTeams`, `watchAssignments`, `getGame`, `watchTeams(seasonId:)`, raw player select). This catches "tap succeeded but write was lost" regressions that pure UI assertions miss.
- **Active-Games card on Home filters on `startTime IS NOT NULL`** (`watchActiveGames` in `database.dart`). Any Patrol test that drives navigation via the home dashboard's "vs <opponent>" card MUST seed `startTime: drift.Value(DateTime.now())` on the game — the schema column is nullable with no default. Caught when `shift_management_journey_test.dart` initially failed at the home-card lookup; the same fix was retro-applied to the older `shift_alarm_journey_test.dart` and `halftime_journey_test.dart` to unblock their first step. (Those two have additional pre-existing downstream issues — likely the `for ... pump(seconds:1)` loop not advancing the wall-clock-based `StopwatchCtrl` timer on a real device — out of scope for this session.)

### Verified on emulator (emulator-5554, Android API 36)
- `smoke_test.dart` ✅
- `team_management_journey_test.dart` ✅
- `substitution_journey_test.dart` ✅
- `shift_management_journey_test.dart` ✅
- `season_clone_journey_test.dart` ✅

---

<!-- Older entries moved to .agents/memory/testing.md and .agents/memory/production_readiness.md -->
