# MEMORY

This file tracks key decisions, conventions, and session learnings for the soccer-assistant-coach codebase. Keep under 200 lines; prune older entries to `LONGTERM_MEMORY.md`.

---

## Session: June 7, 2026 — QA agent attaches emulator screenshots to UI-changing PRs

Date: 2026-06-07

### What was done
Journey tests can now capture a screenshot **of the actual fix**, which the qa-reviewer agent attaches
to the GitHub issue so a human can eyeball the change before merging.

- **`patrol_test/helpers/app_harness.dart`** — `appUnderTest()` is wrapped in a keyed
  `RepaintBoundary` (`screenshotBoundaryKey`) above `SoccerApp`, so the whole UI incl. dialogs/snackbars
  is capturable.
- **`patrol_test/helpers/screenshot.dart`** (new) — `captureScreenshot($, '<name>')` renders the live
  tree (`RenderRepaintBoundary.toImage`) to `files/screenshots/<name>.png` in the app support dir.
  Best-effort: failures never fail the test.
- **`patrol-gate.yml`** — after `patrol test`, pulls those PNGs with `adb exec-out run-as <pkg> cat`
  (debuggable APK ⇒ no root/storage perms) and uploads them as a per-shard `screenshot-<job-index>`
  artifact. Test's real exit code is preserved (`set +e` … `exit $status`) so a red test still fails.
- **`developer.md` Step 7** — for UI changes, the developer agent must call `captureScreenshot` at the
  point the fixed UI is on screen, **before any pop** (most journey tests assert via DB after the screen
  pops, so the final frame is the wrong screen).
- **`qa-reviewer.md` Step 4.6** — for PRs touching `lib/**/*.dart` (excl. generated), downloads the
  artifacts, pushes every PNG to a public **`ci-screenshots` orphan branch** under `pr-<n>/<sha>/`, and
  posts a `<!-- qa-agent:screenshots -->` issue comment embedding them as inline
  `raw.githubusercontent.com` images. This is the QA agent's **only** sanctioned push (assets, never code).

### Key learnings
- **Patrol 4.5.0 has no screenshot API** (verified in the pub cache) and patrol_cli doesn't collect
  integration_test screenshots → use Flutter's own `RenderRepaintBoundary.toImage`, which is pure Dart,
  headless-safe, and NOT the flaky Android surface-conversion path.
- **Final-frame capture is structurally wrong here:** journey tests deliberately end away from the fix
  (e.g. `roster_import_journey_test.dart` pops then asserts via DB). The screenshot must be taken
  mid-test, by the test, at the assertion point. That's why this reversed the original "no Dart changes"
  plan.
- Repo is **public** → branch files get no-auth raw URLs that render inline in comments. Private repo
  would NOT render (would need an image host / release assets).
- `<sha>` in the asset path keeps each review's raw URLs unique so GitHub's ~5-min raw cache never
  serves a stale image.
- App package id: `com.useunix.soccerassistantcoach`; pulled from `files/screenshots` via `run-as`.
- Status: written, **not yet exercised on a real PR** — verify capture → run-as pull → artifact →
  branch push → inline render on the next UI PR.

---

## Session: June 5, 2026 — Move the /fix-issue agent pipeline to the cloud (GitHub Actions)

Date: 2026-06-05

### What was done
Migrated the entire `/fix-issue` agent pipeline off the developer's Windows PC to run **headless on GitHub-hosted Linux runners**. The agents are no longer Windows/PowerShell/WSL-bound; the local Windows Task Scheduler job is retired.

### Changes made

| Change | Detail |
|--------|--------|
| `.github/workflows/fix-issue.yml` | **New.** Cron + manual `workflow_dispatch` job that runs `claude /fix-issue` headless via `anthropics/claude-code-action` on `ubuntu-latest`. Has a `concurrency` group so sweeps never overlap. |
| `.github/workflows/patrol-gate.yml` | **New.** The required patrol gate: boots a headless Android emulator **on the runner** (`reactivecircus/android-emulator-runner`) and runs the patrol journeys. **Sharded** — one matrix job per `patrol_test/*.dart` file (`fail-fast: false`) so the documented Patrol-4.x between-tests hang is isolated to one shard instead of wedging the whole gate. Takes a `ref` input. |
| `.claude/commands/fix-issue.md` + all 5 `.claude/agents/*.md` | De-Windowed: bare `gh` (PATH + `GH_TOKEN`) instead of `C:\Program Files\GitHub CLI\gh.exe`, bash heredocs (`--body "$(cat <<'EOF'…EOF)"`) instead of PowerShell `@'…'@` here-strings. `tools:` lists dropped `PowerShell`. |
| `qa-reviewer.md` | No longer boots a local emulator. It **dispatches `patrol-gate.yml`** against the PR branch (`gh workflow run … --ref <head>`), polls `gh run watch --exit-status`, and gates on the conclusion. |
| `release-manager.md` | **No more WSL/fastlane.** Dispatches `patrol-gate.yml` against `main`, then bumps `pubspec.yaml` itself, commits, and pushes a `vX.Y.Z` tag. The tag push triggers the existing `release.yml`/`release-ios.yml`. Eliminates the WSL silent-push credential-manager bug entirely. |
| `AGENTS.md` | GitHub CLI section now documents the CI (bare `gh`/bash) path as primary, Windows/PowerShell as the local-human path. Publishing section notes the automated release is just a tag push; WSL fastlane is the manual path. |
| `scripts/fix-issue-daily.ps1`, `scripts/install-fix-issue-task.ps1` | Marked **DEPRECATED** (kept as local fallback). The Windows scheduled task `SoccerAssistantCoach-FixIssueDaily` should be unregistered. |

### Key learnings / required setup before this runs
- **`GITHUB_TOKEN` cannot trigger other workflows.** Pushes/tags the agents make must use a **fine-grained PAT** stored as `secrets.BOT_TOKEN` (scopes: contents, pull-requests, issues, workflows RW) so `ci.yml`/`release.yml`/`release-ios.yml` actually fire. `fix-issue.yml` checks out with `BOT_TOKEN`.
- **Claude auth:** repo secret `ANTHROPIC_API_KEY` (pay-per-use) or `CLAUDE_CODE_OAUTH_TOKEN` (subscription seat).
- The patrol emulator now runs **inside GitHub's runner**, not on any of the user's machines.
- Status: code/workflows written; **secrets not yet added and the pipeline not yet test-run** — verify per the plan (auth smoke test → patrol-in-cloud → dev path cascade → release path) before disabling the local task.

---

## Session: June 5, 2026 — Add CPO agent as the first issue gate + define product OKRs

Date: 2026-06-05

### What was done
Added a **CPO (Chief Product Officer)** agent that sits in front of the product-manager in the `/fix-issue` pipeline. It is the first agent to see a brand-new issue and decides — against the product OKRs **and** mission fit — whether the issue is worth fixing at all before any PM/dev effort is spent. **All mission-fit/closing authority was moved out of the PM and into the CPO**, narrowing the PM to a pure spec-writer for already-greenlit issues.

### Changes made

| Change | Detail |
|--------|--------|
| `.agents/OKRS.md` | **New.** Source-of-truth product OKRs (O1 effortless lineups/subs, O2 reliability, O3 fast onboarding, O4 low cognitive load), each with measurable KRs. The CPO's rubric; also a reference for PM success metrics. |
| `.claude/agents/cpo.md` | **New.** CPO agent. Reads `.agents/OKRS.md`, evaluates an issue, then either posts `<!-- cpo-agent:greenlit -->` (hands to PM) or `<!-- cpo-agent:declined -->` + labels `wont-fix` + closes as not planned. Lightweight gate — no specs, no codebase spelunking. Conservative: when on the fence, greenlight. |
| `.claude/commands/fix-issue.md` | Wired CPO into orchestrator: new **CPO (new)** triage bucket (fires when an issue has no `cpo-agent` marker and no `pm-agent:spec`/`pm-agent:question` marker); **PM (new)** now gated behind a `cpo-agent:greenlit` comment; DONE check moved first so `wont-fix`/closed issues are skipped; added `wont-fix` label setup, CPO dispatch template, parallelism note, and marker list entries. Retired the `pm-agent:closed` marker (now legacy/non-blocking). |
| `.claude/agents/product-manager.md` | **Narrowed to a pure spec-writer.** Removed outcome D + Step 6 (close-as-not-planned) and the `pm-agent:closed` flow; the PM now assumes mission fit is settled by the CPO and only writes specs (A) or asks spec-blocking clarifying questions (B). It no longer judges mission fit or closes any issue. Now also reads `.agents/memory/pm_conventions.md` in Step 1. |
| `.agents/memory/cpo_decisions.md`, `.agents/memory/pm_conventions.md` | **New — per-agent decision memory** for the two judgment agents (anti-drift). CPO: standing greenlight/decline principles + precedent. PM: terminology table, spec structure, OKR-aligned metrics, out-of-scope boundaries. Two-layer design: GitHub label/comment trail is the authoritative self-truing record; these curated files hold distilled rationale. **Agents read but never write them** (they ingest untrusted issue text → no repo-file writes; avoids prompt-injection + poisoning). CPO Step 2 now queries `--label wont-fix` for live precedent. |
| `AGENTS.md`, `.agents/LONGTERM_MEMORY.md` | Added "Key Changes" step 5 (distill CPO/PM patterns into the memory files during upkeep — human is the only writer) and indexed both files. |

### Follow-up fixes (same day — first live run of the CPO/PM pipeline)
The first `/fix-issue` run through the new pipeline (issue #18 → CPO greenlit → PM spec → dev PR #19) surfaced a class of shell errors. Root cause + fixes:

| Change | Detail |
|--------|--------|
| `.claude/agents/cpo.md`, `product-manager.md` (frontmatter) | **Root cause: CPO and PM were the only agents missing the `PowerShell` tool** — they had `Bash` only, so the PowerShell-syntax `gh` commands (`&` call operator, `@'…'@` here-strings, `$null`) were run through `/usr/bin/bash`, which can't parse them (`syntax error near unexpected token '&'`). Added `PowerShell` to both, plus a "Tooling — use PowerShell, never Bash, for gh/git" section. This is the same lesson as the `feedback_shell_tools` rule, now enforced per-agent. |
| All 5 agents + `AGENTS.md` | **Safe comment posting:** standardized on the `gh ... --body @'…'@` here-string form (CPO/PM previously improvised `--body '…'`, which doubled apostrophes → `user''s`). Added a canonical "Posting comments safely" note to `AGENTS.md`. |
| All 5 agents + `fix-issue.md` + `AGENTS.md` | **Error-handling protocol (halt + flag for a human):** canonical "Agent Error Handling" section in `AGENTS.md`; each agent halts on an *unrecoverable* failure (auth/network, push rejected, infra), posts a `<!-- *-agent:error -->` comment, and returns a `BLOCKED:` line instead of faking success. Orchestrator gained a **BLOCKED** triage bucket (issues + PRs) that skips for human attention. Benign control-flow (label exists, empty list, own-code test failures) is explicitly NOT a halt. |

### Key learnings
- **Every agent that runs `gh`/git/flutter MUST have `PowerShell` in its `tools:` list and use the PowerShell tool, not Bash.** The Bash tool (`/usr/bin/bash`) cannot parse PowerShell syntax; wrapping in `powershell -Command "…"` from Bash just adds a second layer of quote mangling. This bit the CPO/PM because they were defined with `Bash` only.
- **Post comment bodies via `@'…'@` here-strings**, never inline `--body '…'` — inline single-quoting doubles apostrophes and breaks on `$`/backticks/markdown.
- **Pipeline order is now CPO → PM → dev → QA → release.** Clean separation of concerns: the **CPO** owns "should we care?" (mission fit + OKR worth) and is the *only* agent that closes issues for fit; the **PM** owns "what exactly do we build?" (spec only). Narrowing the PM's context to spec-writing should yield more reliable specs.
- **State machine is marker-driven.** New markers `<!-- cpo-agent:greenlit -->` / `<!-- cpo-agent:declined -->` must stay stable. The CPO (new) trigger requires no `cpo-agent` marker and no active PM marker (`pm-agent:spec`/`pm-agent:question`); legacy in-flight PM issues bypass the gate. `pm-agent:closed` is retired but treated as non-blocking, so a reopened legacy PM-closed issue routes back to the CPO for a fresh decision.
- **CPO closes declined issues as not planned + `wont-fix`** so the DONE bucket skips them; a human reopen routes back to CPO (new), and the CPO is instructed never to re-decline a reopened issue.

---

## Session: May 25, 2026 — QA fix: add Patrol onboarding journey test (issue #10)

Date: 2026-05-25

### What was done
QA reviewer flagged a false comment in `test/onboarding_empty_state_test.dart` claiming existing Patrol tests covered the onboarding wiring. Added the actual Patrol journey test and corrected the comment.

### Changes made

| Change | Detail |
|--------|--------|
| `patrol_test/onboarding_journey_test.dart` | New Patrol E2E test: seeds `AppDb.test()` with no data, pumps the full app via `appUnderTest(db: db)`, asserts 'You're almost ready!' card appears; DB assertion confirms zero teams exist |
| `test/onboarding_empty_state_test.dart` | Corrected the header comment: removed false claim that existing Patrol tests covered the onboarding wiring; replaced with accurate pointer to new test file |

### Key learnings
- **Empty DB → "has season, no teams" state**: `_ensureActiveSeason` runs via `Future.microtask()` so after `pumpAndSettle(5s)` the auto-created season exists but no teams → home screen shows `_OnboardingNoTeamsCard`. The "no season" state is too transient to reliably test.
- **False test comments are blocking**: QA will reject PRs with comments that claim automated coverage exists when it doesn't. Always add the real test rather than leaving a placeholder comment.

---

## Session: May 24, 2026 — Onboarding empty-state guidance (issue #10)

Date: 2026-05-24

### What was done
Added first-run onboarding guidance so new coaches know what to do when they first open the app.

### Changes made

| Change | Detail |
|--------|--------|
| `lib/features/home/home_screen.dart` | When no season exists, shows `_OnboardingWelcomeCard` (3-step sequence + "Create your first season" button) instead of bare icon + text; when season exists but 0 teams, shows `_OnboardingNoTeamsCard` (next-step hint + "Manage Teams" button) instead of the Quick Actions grid |
| `lib/features/teams/teams_screen.dart` | Empty-state description now uses `noTeamsYetDescriptionOnboarding` which includes the step sequence hint |
| `lib/features/players/players_screen.dart` | Empty-state uses `noPlayersYetDescriptionOnboarding` with roster + next-step hint |
| `lib/features/games/games_screen.dart` | Empty-state uses `noGamesYetDescriptionOnboarding` with scheduling context |
| `lib/l10n/app_{en,es,fr}.arb` | Added 11 new onboarding l10n strings |
| `test/onboarding_empty_state_test.dart` | 5 l10n-level widget tests verifying onboarding strings |

### Key learnings
- **Drift StreamBuilder screens can't be widget-tested directly**: Screens with always-open Drift streams leave pending `FakeAsync` timers. Test l10n strings in isolation or test the components that don't use Drift streams. The `substitution_test.dart` comment documents this pattern.
- **Onboarding should disappear automatically**: Since empty states are conditional on data being absent, they satisfy the acceptance criterion "only shown when the relevant list is empty" without any dismiss logic.
- **`_ensureActiveSeason` in `season_provider.dart` creates a season automatically on first launch**: The "no season" home screen state is transient (auto-resolved on first frame). The primary first-run UX that a coach actually sees is "has season but no teams."

---

## Session: May 22, 2026 — v1.0.7 release: fastlane bump push silent failure + Fastfile :release lane never built AAB

Date: 2026-05-22

### What was done
Shipped v1.0.7 (CSV upload feature) to both stores after debugging two release pipeline bugs.

### Changes made

| Change | Detail |
|--------|--------|
| `AGENTS.md` | Documented that `fastlane bump`'s `git push` step fails silently from WSL because git-credential-manager.exe lives in `/mnt/c/Program Files/...` and the space breaks the WSL shell. Workaround: push from PowerShell after the bump. |
| `fastlane/Fastfile` | Android `:release` lane chained `build` before `deploy`. Was calling `deploy` directly which expected a pre-built AAB. CI's `release.yml` invokes `fastlane release` on tag push with no separate build step, so the lane must do the build itself. |

### Key learnings
- **fastlane bump's push step fails silently from WSL on this machine**: WSL invokes `git-credential-manager.exe` at `/mnt/c/Program Files/Git/mingw64/bin/...` and the space in the path is treated as a word boundary. Fastlane reports "Successfully committed" and exits, but the commit + tag stay local. The tag never reaches GitHub, so no release workflow fires. Always verify with `git ls-remote --tags origin v<version>` from PowerShell. If empty, push the commit + tag manually from PowerShell where Windows-native git uses Windows credentials.
- **Fastfile Android `:release` lane must build the AAB itself**: The lane is the entry point for CI (called via `bundle exec fastlane release track:internal` on tag push). It previously only called `deploy` which expected the AAB at `build/app/outputs/bundle/release/app-release.aab` to already exist. Failure mode: every release silently failed with "Could not find aab file at path". Fix: `lane :release { build; deploy(options) }`.
- **iOS release lane was correct** because it uses `:release` to call `upload_to_testflight` which doesn't need a build (CI uses a separate macOS workflow that builds the IPA as a workflow step before fastlane runs). Asymmetry between platforms is normal here because the iOS build environment is fundamentally different (needs Xcode/macOS) and is structured as separate workflow steps; Android can build on the Linux runner inside the same lane.

---

## Session: May 21, 2026 — Patrol removed from CI; lives in manual workflow

Date: 2026-05-21

### What was done
After spending many hours debugging individual Patrol test hangs and fixing several real bugs (halftime timer, shift_alarm timer, season_clone overflow, settings prefs, shift_management timer), the root issue turned out to be Patrol's **test orchestrator itself** hanging unpredictably between tests on the Android emulator runner. Even after fixing every individual test, the orchestrator would hang for ~26+ minutes between tests — not in any test body, but in the Patrol-native bridge that hands off control between sequential tests. This is a Patrol 4.x flakiness pattern on CI emulators that we cannot fix from our code.

### Changes made

| Change | Detail |
|--------|--------|
| `.github/workflows/ci.yml` | Removed the `patrol-tests` job entirely. CI now only runs `flutter analyze` + `flutter test` (unit + widget). |
| `.github/workflows/patrol-manual.yml` | New workflow with `workflow_dispatch` trigger only. Takes a `test_path` input and runs that single test on demand from the Actions tab. Pinned `patrol_cli 4.3.1` + `patrol 4.5.0` (the only working combination). |

### Key learnings
- **Patrol's sequential test orchestrator is unreliable on CI emulators**: Each test can pass individually, but running them back-to-back via `patrol test file1.dart file2.dart ...` causes the runner to hang between tests. Even fixing every test body doesn't help — the hang is in Patrol's native side handing off to the next Dart test, not in our test code.
- **`patrol_cli` enforces strict version compatibility**: `patrol_cli 4.4.0` (released 2026-05-21) rejects patrol packages 4.4.0 AND 4.5.0 with "not compatible" errors despite identical version numbers. The only working pair we know is `patrol_cli 4.3.1 + patrol 4.5.0`. Pin both.
- **Don't gate PRs on flaky E2E tests**: When the test framework itself is unreliable, blocking merges on it means PRs that change unrelated code still fail to merge. Move E2E to manual on-demand runs and trust the widget tier.
- **Real bugs found and kept**: `_TraditionalGameScreenState._gameTimer` and `_handleTick`'s `db.incrementShiftDuration` calls outlive test bodies and deadlock `db.close()` if not cancelled via dispose. Fixed via `router.pop() + Future.delayed(600ms)` pattern in `halftime_journey_test`, `shift_alarm_journey_test`, `shift_management_journey_test`. CreateSeasonDialog Column needed `SingleChildScrollView` wrap. `settings_test` needed `prefs.clear()` at start. These fixes stay even though tests are no longer in CI.
- **`FlutterError.onError` upgrade to test failure**: In Flutter test mode, every `RenderFlex overflowed by N pixels` is upgraded to a test failure. Patrol's emulator (narrow screen) triggers many cosmetic overflows. Filter installed in `patrol_test/helpers/app_harness.dart` to print but not fail on overflow warnings.

---

## Session: May 20, 2026 — Patrol E2E: fix halftime_journey_test 76-minute hang

Date: 2026-05-20

### What was done
Diagnosed and fixed the root cause of `halftime_journey_test` blocking all subsequent Patrol tests for 76 minutes every CI run.

### Root cause
`_TraditionalGameScreenState._startTimer()` creates a `Timer.periodic` (1 s ticks) that calls `db.updateGameTime()` (unawaited) every 5 s. The test's `Future.delayed(const Duration(seconds: 9))` — intended to wait for a halftime alarm that is never fired by production code — combined with the running timer caused one of two failure modes: (a) the timer kept writing to Drift's executor queue while `db.close()` tried to drain it, or (b) the long `Future.delayed` itself became intertwined with the event loop state from the periodic timer. Either way, the test hung until the 90-minute CI timeout.

Separately: `triggerHalftimeAlert()` in `AlertService` is **never called** from `TraditionalGameScreen`. The test comment claiming it would fire was incorrect — the 9-second wait served no purpose.

### Changes made

| Change | Detail |
|--------|--------|
| `patrol_test/halftime_journey_test.dart` | Removed `Future.delayed(9s)`; added `router.pop()` after Start tap + 600 ms `Future.delayed` so `dispose()` cancels `_gameTimer` before `db.close()` teardown runs; replaced `anyOf(2,1)` with `expect(isGameActive, isTrue)` |

### Key learnings
- **`_TraditionalGameScreenState._gameTimer` must be cancelled before `db.close()`**: If the periodic timer is still running when the teardown calls `db.close()`, new DB writes arrive at Drift's executor while it tries to process the close message, preventing the close from completing.
- **Navigate back before test body ends**: Calling `router.pop()` triggers `dispose()` which cancels `_gameTimer`. Follow with `await Future.delayed(600ms)` to let the pop animation finish and dispose to run before DB close.
- **`triggerHalftimeAlert()` is defined but never called by `TraditionalGameScreen`**: The screen does not auto-advance halftime or fire alerts; both require explicit user interaction ("2nd Half" button). Patrol tests cannot rely on this path — test `isGameActive` instead.
- **Alphabetical CI ordering means halftime (#1) blocks everything**: Fix halftime before diagnosing other Patrol test failures.
- **Commits in this session**: `b474c9a` (prefs.clear in shift_management + substitution), `dc5737b` (remove $.pump(Duration)), `ff20b71` (navigate-back fix for halftime).

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
| `android/app/build.gradle.kts` | Removed `id("kotlin-android")` plugin; removed `kotlinOptions {}` block; bumped `compileOptions` to `VERSION_17` |
| `android/build.gradle.kts` | Removed `KotlinCompile` import and `tasks.withType<KotlinCompile>` block |
| `.github/workflows/ci.yml` | Added `patrol build android` pre-build step; `target: default`; `timeout-minutes: 40` |

### Key learnings
- **Gradle heap OOM kills the runner silently**: `Xmx8G + MaxMetaspaceSize=4G` = 12 GB on a 7 GB GitHub runner → Linux OOM killer kills the process → no logs uploaded. Signature: step shows "in_progress" with no `completedAt`, no output. Fix: cap at `Xmx2g -XX:MaxMetaspaceSize=512m`.
- **`android.enableJetifier=true` OOM on Flutter projects**: Jetifier transforms Flutter's own already-AndroidX ARM64 engine JARs; even 2g heap can't handle `JetifyTransform` on these large JARs. Always set `android.enableJetifier=false` for Flutter projects — the engine is already AndroidX.
- **Gradle version lookup**: AGP 8.11.1 requires Gradle 8.13 minimum. Gradle 8.14.0 does NOT exist at the distribution URL (404). Let the AGP build error message tell you the actual minimum required, then use that version.
- **Flutter Built-in Kotlin migration**: Remove `id("kotlin-android")` from the app's plugins block — `dev.flutter.flutter-gradle-plugin` manages Kotlin internally. Remove `kotlinOptions {}` too (only valid when explicit kotlin-android plugin is present).
- **Kotlin 2.2 breaking changes**: `kotlinOptions {}` DSL removed from root `build.gradle.kts` `tasks.withType<KotlinCompile>` blocks; `JvmTarget.JVM_1_6` enum value removed — delete the whole block.
- **JVM target mismatch after Built-in Kotlin migration**: Kotlin 2.2 defaults `jvmTarget` to the JDK version (17 in CI) when no explicit target is set. Removing `kotlinOptions { jvmTarget = "1.8" }` without updating `compileOptions` causes "Inconsistent JVM Target Compatibility" between `compileDebugJavaWithJavac` (1.8) and `compileDebugKotlin` (17). Fix: set `sourceCompatibility = JavaVersion.VERSION_17` and `targetCompatibility = JavaVersion.VERSION_17` in `compileOptions`. Desugaring (`isCoreLibraryDesugaringEnabled`) is unaffected — it operates at the D8/R8 level, not the compilation level.

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
