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
- **Agent pipeline**: `/fix-issue` (CPO → PM → dev → QA → release) runs headless in GitHub Actions
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

## Session: 2026-06-28 — Sideline foundation + Live Game hero card

Implemented the Sideline design system foundation (`lib/core/sideline.dart` tokens,
`google_fonts` Hanken Grotesk / Spline Sans Mono, `TeamColors` ThemeExtension in `team_theme.dart`,
components in `lib/widgets/sideline_widgets.dart`) and rebuilt the Live Game screen around it
(hero shift card, alert banner, branded `SidelineGameHeader`, context-aware `_ShiftActionBar`).
`flutter analyze` clean; 81 tests green.

Key learnings (full detail in [`memory/sideline_design.md`](memory/sideline_design.md)):
- `applyTo` must set `extensions: [TeamColors…]` outright — spreading `base.extensions.values`
  fails the test front-end's stricter inference.
- All numerics use `sidelineMono()` (tabular figures) so clocks don't jitter.
- Team-color staleness fixed via `invalidateTeamTheme(ref, teamId)` on team-editor Save
  (a `watchTeam` StreamProvider leaks a pending timer in widget tests — don't).
- Decisions: keep the horizontal shift-planning `PageView`; no "Next on · least time" section.

## Session: 2026-06-07 — Roster count summary (issue #28) + QA screenshot pipeline

- Players screen got a reactive "N players · M active" bar (`_RosterCountSummary`), computed inline
  from the existing stream (no extra query); hidden on empty roster. New l10n strings ×3 locales;
  patrol journey test with screenshot.
- Journey tests can now capture the fixed UI mid-test (`captureScreenshot($, 'name')`), the gate
  uploads artifacts, and the QA agent embeds them in the issue via the public `ci-screenshots`
  branch. Design + rationale: [`memory/agent_pipeline.md`](memory/agent_pipeline.md); usage:
  [`TESTING.md`](TESTING.md).
- **Flutter is not pre-installed on the `fix-issue.yml` runner** — the developer agent must clone
  the SDK before running `flutter` commands.

---

<!-- Older sessions distilled into .agents/memory/ topic files — see LONGTERM_MEMORY.md -->
