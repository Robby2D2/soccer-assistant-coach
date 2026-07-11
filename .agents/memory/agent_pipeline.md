# /fix-issue Agent Pipeline — design history & operating notes (June 2026)

Current behavior is defined by `.claude/commands/fix-issue.md` + `.claude/agents/*.md`. This file
records the *why* behind decisions that aren't obvious from those files.

## Pipeline shape (since 2026-06-05; pr-reviewer added 2026-07-11)

CPO → PM → developer → pr-reviewer → QA → release-manager, orchestrated by `/fix-issue`, running
**headless in GitHub Actions on Linux runners** (`.github/workflows/fix-issue.yml`, cron + manual
dispatch). The old Windows Task Scheduler job (`SoccerAssistantCoach-FixIssueDaily`) is deprecated.
The pr-reviewer split (static review before the emulator gate) exists so consistency/reuse
violations bounce in minutes instead of after a 20–40 min patrol run — qa-reviewer refuses to run
without a `pr-reviewer-agent:approved` newer than the latest commit.

- **CPO owns "should we care?"** (mission fit + OKR worth, rubric in `.agents/OKRS.md`) and is the
  only agent that closes issues (`wont-fix` + not planned). Moving mission-fit out of the PM
  narrowed it to a pure spec-writer, which produces more reliable specs.
- **State machine is marker-driven**: `<!-- <role>-agent:<event> -->` HTML comments on issues/PRs.
  Keep markers stable across edits. `pm-agent:closed` is retired (legacy, non-blocking); a reopened
  issue carrying only it routes back to the CPO gate.
- **Decision memory is two-layer** (anti-drift + anti-poisoning): the GitHub label/comment trail is
  the authoritative, self-truing record; `.agents/memory/cpo_decisions.md` /
  `pm_conventions.md` hold distilled principles. Judgment agents **read but never write** those
  files — they ingest untrusted issue text, so they get no repo-file writes.

## Cloud migration — required setup & key facts

- **`GITHUB_TOKEN` cannot trigger other workflows.** All agent pushes/tags use the fine-grained PAT
  `secrets.BOT_TOKEN` (contents, pull-requests, issues, workflows RW) so `ci.yml` / `release.yml` /
  `release-ios.yml` actually fire. `fix-issue.yml` checks out with `BOT_TOKEN`.
- Claude auth: repo secret `ANTHROPIC_API_KEY` or `CLAUDE_CODE_OAUTH_TOKEN`.
- The patrol emulator runs **inside the GitHub runner** via `patrol-gate.yml` (sharded, one matrix
  job per test file, `fail-fast: false` — isolates the Patrol 4.x between-tests hang). QA dispatches
  it against PR branches; release-manager against `main`.
- **Flutter is not pre-installed on the `fix-issue.yml` runner** — the developer agent must clone
  the SDK (`git clone https://github.com/flutter/flutter.git --branch stable --depth 1`) before
  `flutter gen-l10n` / `analyze` / `test`.
- Release path: release-manager bumps `pubspec.yaml` and pushes a `vX.Y.Z` tag itself — no WSL, no
  local fastlane, so the WSL silent-push credential-manager bug can't occur in the automated path.

## Error-handling protocol (origin)

The first live run (issue #18 → PR #19) surfaced shell-quoting failures and motivated the canonical
**Agent Error Handling** section in `AGENTS.md`: halt on unrecoverable failure, post one
`<!-- <role>-agent:error -->` comment, return `BLOCKED:`. The orchestrator's BLOCKED bucket skips
those items until a human replies. Comment bodies are always posted via quoted bash heredocs
(`--body "$(cat <<'EOF' … EOF)"`) — inline `--body '…'` corrupts apostrophes.

## QA screenshot attachment (2026-06-07)

Journey tests capture the fixed UI mid-test (`captureScreenshot($, 'name')` — see
`.agents/TESTING.md`); the gate uploads per-shard artifacts; the QA agent pushes PNGs to the public
**`ci-screenshots` orphan branch** under `pr-<n>/<sha>/` and embeds raw.githubusercontent.com URLs
in an issue comment. Why this design:

- Patrol 4.5.0 has **no screenshot API**; `RenderRepaintBoundary.toImage` is pure Dart and
  headless-safe (the harness wraps the app in a keyed `RepaintBoundary`).
- Final-frame capture is structurally wrong — journey tests deliberately end away from the fix
  (pop, then DB assertion), so the test itself must capture at the assertion point.
- PNGs are pulled off the emulator with `adb exec-out run-as com.useunix.soccerassistantcoach cat`
  (debuggable APK ⇒ no root needed), from `files/screenshots/`.
- The repo is public → branch files get no-auth raw URLs that render inline. The `<sha>` path
  segment defeats GitHub's ~5-min raw cache. This is the QA agent's only sanctioned push
  (assets, never code).
