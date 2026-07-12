# MEMORY

Rolling project memory: current state + recent session learnings. **Keep under ~120 lines** — when
an entry stops being "recent", distill it into a topic file under `.agents/memory/` and index it in
[`LONGTERM_MEMORY.md`](LONGTERM_MEMORY.md). Durable patterns belong in
[`ARCHITECTURE.md`](ARCHITECTURE.md) (decisions), [`TESTING.md`](TESTING.md) (test patterns), or
[`CODING.md`](CODING.md) (standards) — not here.

---

## Current state (as of 2026-06-28)

- **App**: Flutter, local-first (Drift/SQLite), Riverpod v3, go_router. Live on Play Store +
  App Store (`com.useunix.soccerassistantcoach`).
- **Agent pipeline**: `/fix-issue` (CPO → PM → dev → PR review → QA → release) runs headless in GitHub Actions
  on Linux (`fix-issue.yml`, cron). Patrol journeys run on a cloud emulator via the sharded
  `patrol-gate.yml` (dispatched by QA on PRs and by release-manager on `main`). Pushes/tags use
  `secrets.BOT_TOKEN` so downstream workflows fire. Details: [`memory/agent_pipeline.md`](memory/agent_pipeline.md).
- **Releases**: automated path = release-manager pushes a `vX.Y.Z` tag → `release.yml` (Play beta)
  + `release-ios.yml` (TestFlight); promotion to production is human-triggered. Manual/human path:
  `docs/RELEASING.md`. Debugging lore: [`memory/releases.md`](memory/releases.md).
- **Design**: "Sideline" design system foundation is live (tokens, `TeamColors` ThemeExtension,
  Live Game hero card/header/action bar). Teams/Roster deeper restyling still open — get user
  direction first. Details: [`memory/sideline_design.md`](memory/sideline_design.md).
- **Testing**: two-layer stack (widget/DB in `test/`, patrol journeys in `patrol_test/`); pin
  `patrol_cli 4.3.1` + `patrol 4.5.0`. Patterns: [`TESTING.md`](TESTING.md); CI lore:
  [`memory/testing.md`](memory/testing.md).

---

## Session: 2026-07-12 — Concurrency-safe pipeline (multiple simultaneous /fix-issue runs)

- New **AGENTS.md → Concurrency** section (shared rules): re-check state immediately before any
  write; lost races are benign skips, never errors; writers claim, readers re-check; never touch
  a dirty working tree (local runs share a human's checkout).
- Developer now **claims** an issue via `<!-- dev-agent:claim <id> -->` (oldest active claim
  < 60 min wins), checks origin for an existing branch/PR before and after working, and treats a
  rejected feature-branch push as "lost the race". Orchestrator got a DEV-CLAIMED skip bucket.
- qa-reviewer + release-manager **reuse** an in-flight/green patrol-gate run for the same head SHA
  instead of dispatching a duplicate 20–40 min emulator run; never reuse across SHAs.
- release-manager: rejected bump/tag push = concurrent release won → benign abort (reset only its
  own bump commit); last-moment tag re-check before tagging; dirty-tree guard before checkout.
- qa screenshot push to `ci-screenshots`: non-FF rejection → `pull --rebase` + retry once
  (per-PR/per-SHA paths never conflict).

## Session: 2026-07-11 — Consistency guardrails + pr-reviewer agent

- New `.agents/COMPONENTS.md`: canonical shared-UI inventory ("one canonical widget per concept").
  CODING.md now requires checking it before building UI; developer agent loads it; keep it updated
  when adding/consolidating shared widgets (same PR).
- New `pr-reviewer` agent (`.claude/agents/pr-reviewer.md`): fast **static** review gate between
  developer and qa-reviewer — headline check is shared-component reuse (would have caught the
  duplicated game tiles). Markers: `pr-reviewer-agent:approved|review|bounce|error`. qa-reviewer
  slimmed to patrol gate + screenshots + final approve, and now requires a `pr-reviewer-agent:approved`
  newer than the latest commit before running (saves 20–40 min gate runs on PRs that would bounce).
  Orchestrator PR buckets updated in `fix-issue.md` (REVIEW → pr-reviewer, then QA).
- Follow-up: usage audit found 6 of the 8 classes in `team_header.dart`/`team_panels.dart` were
  **dead code** (~600 lines) — deleted. Survivors `TeamBrandedHeader` (assign-players, end-game)
  and `TeamListPanel` (teams list) are marked legacy in COMPONENTS.md: pre-Sideline, hand-rolled
  gradients/contrast — replace during the pending Teams/Roster Sideline restyle, don't adopt.

## Session: 2026-07-11 — Game summary consistency + active-game definition

- New shared `lib/widgets/game_result_card.dart` (`GameResultCard`): the single game summary tile
  (soccer icon, "vs Opponent", date pill, W/L/D-colored score badge, LIVE/Archived pills). Used by
  the games list, the team landing "Most Recent Game" card, and the traditional game screen's
  completed panel — extend it there rather than re-inlining game tiles. Score uses an en-dash
  (`3–2`), which the team-landing patrol test asserts on.
- Traditional game screen now uses the branded `SidelineGameHeader` band (body-top, no AppBar),
  matching the shift-mode game screen; the old `TeamAppBar` + `GameCompactTitle` header is gone
  from live-game screens (still used on edit/attendance/metrics sub-screens).
- Game metrics screen: removed the "Player Statistics" DataTable (duplicated play time); the
  playing-time bar chart now carries per-player goal/assist/save icon counts (zero counts hidden)
  and includes players with metrics but no recorded minutes.
- **`watchActiveGames` semantics changed**: a game is "active" (home-screen card) only if
  `in-progress` AND (timer running via `isGameActive` OR `startTime` is today). Previously any
  future-scheduled game showed as active because new games default to `gameStatus: 'in-progress'`.
  Patrol tests seeding `startTime: DateTime.now()` still satisfy the filter.

## Session: 2026-07-10 — Multi-season demo fixture (Real Madrid / Barcelona)

- New fixture `test/fixtures/five_seasons_real_madrid_barcelona.json` (~2 MB): 5 COMPLETE La Liga
  seasons (2021-22 → 2025-26), 2 clubs × 5 seasons, 160 players (real rosters/jerseys/club colors),
  380 games (38 per club per season vs the real league opponents; W/D/L + GF/GA match the real
  final tables, all Clásicos pinned to real results, headline scorer totals real — Benzema 27,
  Mbappé 31, etc.; 2025-26 back half is a projection), ~16 k metrics. Generated by script (not
  hand-edited); regenerate via the same approach if the schema changes. Verified by
  `test/import_five_seasons_fixture_test.dart` (~3 s import). Intentionally NOT in pubspec assets
  (unit test reads it via `File`; listing it would ship ~2 MB in release binaries).
- **Importer gap found + fixed**: export/import previously dropped the `seasons` table entirely
  (import only created one default season on an empty DB, so multi-season backups left teams with
  `seasonId` 2..5 dangling). Now `exportDatabase` emits `seasons` and `importDatabase` imports them
  as step 0 before teams, **replacing** existing season rows only when the backup contains a
  non-empty `seasons` array — `resetDatabaseSafely` intentionally preserves seasons, and legacy
  backups without the key keep the old fallback-season behavior.

## Session: 2026-07-10 — App Store screenshots refreshed (reject + resubmit v1.1.0)

- iPad App Store screenshots are now real captures: `process_screenshots.py` fans raw captures to
  `ipadPro129_` (2048×2732) alongside `iphone69_`. **Do not add an ipadPro13 (2064×2752) set** —
  deliver maps it to the same `APP_IPAD_PRO_3GEN_129` slot (10-image max), so it only
  duplicates/overflows (same collision class as the removed iphone67 set, 8c08d9d).
- **Screenshots are locked while a version is Waiting for Review** — ASC rejects every change with
  "Can't Create Screenshot while Waiting For Review" and deliver retry-loops for up to an hour
  (kill it; it won't recover). Fix: `ios submit` lane (`reject_if_possible: true`) cancels the
  pending submission, uploads, resubmits. Used it to resubmit v1.1.0 with the new set.
- All `upload_to_app_store` call sites now set `overwrite_screenshots: true` — deliver counts
  screenshots already on the remote version toward the 10-per-slot cap and otherwise skips new
  uploads ("Too many screenshots found") once old ones accumulate.
- Transient "X.png is missing on App Store Connect" right after upload is ASC propagation lag —
  deliver retries and verifies; only a failure after all 4 retries is real.

## Session: 2026-07-10 — Play listing images now repo-driven (supply layout)

- Root cause of "old screenshots on Play": listing images were only ever uploaded by hand in Play
  Console; every `upload_to_play_store` had `skip_upload_screenshots: true`, and the recapture
  commit (369f4d4) sat unmerged on `screenshots/restyle-recapture`. Merged it (layout-fix
  dependency was already in main via #40).
- Android listing images moved from `store/assets/` to the fastlane supply layout at
  `fastlane/metadata/android/en-US/images/` (`phoneScreenshots/`, `sevenInchScreenshots/`,
  `tenInchScreenshots/`, `featureGraphic.png`). `process_screenshots.py` + `generate_assets.py`
  write there directly; `store/assets/` is gone. Stale synthetic `*_02_lineup.png` mockups deleted.
- `promote_release` / `promote_release_android` now upload listing images
  (`sync_image_upload: true` = checksum-skip unchanged); new `android update_listing` lane pushes
  images on demand (WSL). Ran it — new 6-screen set live on Play (uploaded ~09:31, Play web can
  cache the old ones a bit). NB: desktop Play web shows the **tablet** screenshots.

## Session: 2026-07-10 — Released v1.1.0+21 (Sideline design); Apple agreement gotcha

- Cut v1.1.0 (build 21) via `create_release`: Sideline design system, Live Game screen, Sideline
  team screens, game-first landing, formations field preview. Android → Play beta OK.
- **New failure mode**: TestFlight upload rejected with "A required agreement is missing or has
  expired" — a pending Apple agreement only the Account Holder can accept in App Store Connect
  (Business section) / developer.apple.com. No API/CLI fix. After accepting, recover with
  `gh run rerun <run-id> --failed` — only the upload job reruns, build artifacts are reused.
- WSL fastlane push failed loudly this time (auth error, not silent); the PowerShell
  `git push origin main` + `git push origin vX.Y.Z` recovery in RELEASING.md works as documented.

## Session: 2026-07-09 — Patrol-gate hang on /team/:id = per-frame layout assertion (issue #39, PR #40)

The deterministic gate hang after PR #38 was **not** an animation: `_gameCard`'s
`Row(crossAxisAlignment: stretch)` inside a `SingleChildScrollView` (unbounded height) threw
`RenderBox was not laid out … !hasSize` **every frame**, keeping the render tree dirty forever —
so `pumpAndSettle` never returned (silent shard hang, zero patrol output) and the `/team/:id` body
rendered blank in production. Fixed with `IntrinsicHeight` around the Row.

Key learnings:
- **A hung patrol shard with no output needs device logcat**, not patrol stdout (which only shows
  per-action ⏳/✅ markers). `run_and_capture.sh` now backgrounds `adb logcat` for the whole run and
  `patrol-gate.yml` uploads it as a `logcat-<n>` artifact `if: always()` — survives timeout-cancelled
  jobs. This is what pinned the root cause (54–59 assertion repeats naming the exact Row).
- **`pumpAndSettle` never settling ⇒ something reschedules frames every frame**: unguarded
  `.repeat()` animations AND perpetual layout exceptions both do this. Grep for `.repeat(` first,
  then suspect per-frame exceptions.
- **Widget-tier render guard closes the gap**: `test/team_detail_screen_render_test.dart` pumps the
  real `TeamDetailScreen`; against pre-fix code it fails in ~2 s with the production assertion.
  Drift-under-FakeAsync dance baked in: DB work + real-time waits via `tester.runAsync`, plain
  `pump()` (never `pumpAndSettle` with open Drift streams), and a **durationed** pump after
  disposal before `await db.close()` — drift's stream-cache `Timer.run` (stream_queries.dart
  `markAsClosed`) must fire under the fake clock or `close()` deadlocks (10-min test timeout).
- Gate shard timeouts tightened 30/35 → 15/20 min (healthy shards ~10–12 min).
- Verified: analyze clean, 88 tests, gate run 29021853908 fully green (16/16 shards incl. both
  previously-hanging journeys).

## Session: 2026-07-09 — Agent-instruction overhaul (smaller, targeted docs)

Restructured all agent instructions. `MEMORY.md` was 47KB of session logs (vs its own 200-line
rule) loaded by every pipeline agent — distilled to this file; old sessions became topic files
(`memory/sideline_design.md`, `memory/agent_pipeline.md`, `memory/releases.md`, appended to
`memory/testing.md`). `AGENTS.md` shrank ~70% — release detail moved to `docs/RELEASING.md`.
The five `.claude/agents/*.md` dropped repeated tooling/error boilerplate (now referenced from
AGENTS.md) while keeping all HTML markers and commands. Fixed stale claims: fix-issue.md said QA
"boots an emulator" (it dispatches the cloud gate); publish-release.md predated `create_release`;
cpo_decisions/pm_conventions had Windows-path `gh` commands (agents run on Linux). TESTING.md's
test-file inventory tables (already drifted) became a "browse the directories" pointer.

---

<!-- Older sessions (incl. 2026-06-28 Sideline foundation, 2026-06-07 QA screenshot pipeline)
     distilled into .agents/memory/ topic files — see LONGTERM_MEMORY.md -->
