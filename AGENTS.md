# Agent Guidelines — Soccer Assistant Coach

A Flutter app that makes it effortless for a youth soccer coach to manage lineups and
substitutions on the sideline (teams, seasons, players, live games).

**Read the doc that matches your task — don't guess:**

| Topic | Doc |
|---|---|
| Coding standards | [.agents/CODING.md](.agents/CODING.md) |
| Shared UI components (check before building any UI) | [.agents/COMPONENTS.md](.agents/COMPONENTS.md) |
| Testing patterns (widget + patrol) | [.agents/TESTING.md](.agents/TESTING.md) |
| Project structure & decisions | [.agents/ARCHITECTURE.md](.agents/ARCHITECTURE.md) |
| Product OKRs (CPO/PM rubric) | [.agents/OKRS.md](.agents/OKRS.md) |
| Recent context + memory index | [.agents/MEMORY.md](.agents/MEMORY.md) → [.agents/LONGTERM_MEMORY.md](.agents/LONGTERM_MEMORY.md) |
| Publishing a release (manual + automated) | [docs/RELEASING.md](docs/RELEASING.md) |

## GitHub CLI (`gh`)

**In CI (how the `/fix-issue` pipeline agents run):** the agents (cpo, product-manager, developer,
pr-reviewer, qa-reviewer, release-manager) run headless in GitHub Actions on Linux
(`.github/workflows/fix-issue.yml`), where `gh` is on the PATH and authenticated via `GH_TOKEN`.
Use **bash** syntax, and always post multi-line comment/PR bodies with a quoted heredoc so
apostrophes, `$`, and backticks pass through literally — never inline `--body '…'`:

```bash
gh issue comment "$ISSUE_NUMBER" --body "$(cat <<'EOF'
…markdown body…
EOF
)"
```

Agent pushes and tags use `secrets.BOT_TOKEN` (a fine-grained PAT) — the default `GITHUB_TOKEN`
cannot trigger downstream workflows (`ci.yml`, `release.yml`, `release-ios.yml`), so a release tag
pushed with it would never fire CI.

**Locally on Windows (human use):** `gh` is not in the sandboxed PATH — invoke it by full path
from the **PowerShell tool** (the Bash tool runs `/usr/bin/bash` and can't parse `&`,
here-strings, or `$null`). Post bodies with a single-quoted here-string (closing `'@` at column 0):

```powershell
& "C:\Program Files\GitHub CLI\gh.exe" issue comment $ISSUE_NUMBER --body @'
…markdown body…
'@
```

## Agent Error Handling (halt + flag for a human)

Every pipeline agent follows this on genuine failure. **Never fake success; never push through an
unexpected failure.**

1. **Halt on an unrecoverable failure** — auth/network errors, rejected pushes, emulator/build/CI
   infrastructure errors unrelated to your change, missing tools, any unplanned non-zero exit.
   No blind retries, no fabricated results, no proceeding to later steps.
2. **Flag it** with one comment on the issue/PR, led by your role's `<!-- <role>-agent:error -->`
   marker, stating: what you were doing, what failed, and the key error text.
3. **Return `BLOCKED: <one-line reason>`** to the orchestrator instead of a success line.

**Not failures (normal control flow — do not halt):** `label create` on an existing label
(`2>/dev/null || true`), empty `gh` list results, "no PR found" / "already past gate" / "no new
human input", any lost concurrency race (see below), and `flutter analyze`/`flutter test` failing
because of **your own in-progress change** — that's iteration; fix it and continue. Halt only when
the failure is environmental/infra. When genuinely unsure, halt and flag — a human glance is
cheap; a silently broken pipeline is not.

## Concurrency (multiple simultaneous `/fix-issue` runs)

Several people (and CI) may run `/fix-issue` at the same time, each from their own clone. GitHub
(issues, PRs, labels, marker comments, tags, workflow runs) is the shared state; the CI
`concurrency` group only serializes Actions-triggered sweeps, not local ones. Every pipeline agent
follows these rules:

1. **Re-check before you write.** Immediately before posting a decision comment, pushing, tagging,
   or dispatching a workflow, re-fetch the relevant state. If another run already produced your
   outcome (marker present, PR open, tag exists, gate already running for the same SHA), return a
   one-line skip instead of duplicating it.
2. **Losing a race is benign, not an error.** "Already claimed / already reviewed / branch or PR
   already exists / tag appeared / push rejected because another run completed the same work" is
   normal control flow: skip line, no error comment. Follow Agent Error Handling only when a
   re-fetch shows the work is still yours and the failure remains unexplained.
3. **Writers claim; readers just re-check.** The developer agent claims an issue with a
   `dev-agent:claim` comment before doing any work (its instructions define the protocol). CPO,
   PM, and reviewers only re-check before posting — a rare duplicate comment is harmless; a
   duplicate PR or release is not.
4. **Never touch uncommitted human work.** Local runs share a human's working tree: if
   `git status --porcelain` is non-empty before you switch branches or pull, halt and flag —
   never stash, reset, or discard.

## Publishing a Release

The automated pipeline releases by pushing a `vX.Y.Z` tag (release-manager agent); tag push fires
`release.yml` (Play beta) + `release-ios.yml` (TestFlight). Promotion to production is always a
human decision. Full procedure — manual WSL/fastlane flow, all lanes, the WSL silent-push
workaround, store assets, privacy-page deploy — is in [docs/RELEASING.md](docs/RELEASING.md).

## Key Changes (end-of-session upkeep)

At the end of every significant task or session:

1. **Architecture** — record new patterns/decisions in `.agents/ARCHITECTURE.md`.
2. **Memory** — add a dated, concise entry to `.agents/MEMORY.md` (recent context only).
3. **Prune** — when `MEMORY.md` outgrows its stated line budget, distill older entries into topic
   files under `.agents/memory/` and index them in `.agents/LONGTERM_MEMORY.md`.
4. **Agent decision memory** — when a durable *pattern* emerges in CPO greenlight/decline calls or
   PM spec conventions, distill it into `.agents/memory/cpo_decisions.md` /
   `.agents/memory/pm_conventions.md`. Those agents read these files but never write them — only a
   human or this upkeep pass does. Keep entries short; the GitHub `wont-fix`/`dev_ready` trail
   already records the raw decisions.
