# Fix GitHub Issue (Orchestrator)

Triage open GitHub issues + PRs and dispatch the right specialist subagent for each: **cpo**,
**product-manager**, **developer**, **qa-reviewer**, or **release-manager** (defined in
[.claude/agents/](../agents/)).

Usage:
- `/fix-issue` — sweep all open issues + PRs, dispatch, loop until idle, then cut a release if `main` has unreleased commits.
- `/fix-issue <issue-number>` — triage one issue (no release check).
- `/fix-issue pr <pr-number>` — force a QA review on one PR (no release check).
- `/fix-issue release` — skip triage; dispatch the release-manager only.

## Your role

You are the **orchestrator**: you classify work and dispatch; you never write specs, code,
reviews, or releases, and you never post GitHub comments or touch labels yourself (except Step 2's
one-time label creation). Subagents talk to humans via issue/PR comments; you report a triage
summary to the user.

Pipeline: **cpo** (OKR/mission gate — greenlights to PM or declines `wont-fix` + closes) →
**product-manager** (spec, `dev_ready`) → **developer** (implements, opens PR) → **qa-reviewer**
(code review + dispatches the cloud patrol gate on the PR branch) → **release-manager** (patrol
gate on `main`, version bump, `vX.Y.Z` tag → Play beta + TestFlight).

## Step 1 — Parse `$ARGUMENTS`

Empty → sweep mode (with release check) · number → single issue · `pr <number>` → single PR ·
`release` → release-manager only.

## Step 2 — One-time label setup (idempotent; ignore errors)

```bash
gh label create "dev_ready" --color "0E8A16" --description "PM spec written; ready for the developer agent" 2>/dev/null || true
gh label create "awaiting-answer" --color "FBCA04" --description "Waiting on a human answer in the issue thread" 2>/dev/null || true
gh label create "wont-fix" --color "E11D21" --description "CPO declined: does not advance a product OKR" 2>/dev/null || true
```

## Step 3 — Gather candidates (in parallel; or fetch just the one item specified)

```bash
gh issue list --state open --limit 50 --json number,title,labels,author,updatedAt,comments
gh pr list --state open --limit 30 --json number,title,headRefName,author,labels,reviews,updatedAt,closingIssuesReferences,statusCheckRollup
```

## Step 4 — Triage

Classify each **open issue** into exactly one bucket — first match wins:

| Bucket | Trigger | Dispatch |
|---|---|---|
| **DONE** | Closed (incl. `wont-fix`), or has an open PR via `closingIssuesReferences` | skip |
| **BLOCKED** | Latest agent comment is a `<!-- *-agent:error -->` marker with no newer human comment | skip — **needs a human** (surface prominently) |
| **DEV** | Has `dev_ready` label | → developer |
| **CPO (new)** | No `<!-- cpo-agent:* -->` marker AND no `<!-- pm-agent:spec -->`/`<!-- pm-agent:question -->` marker | → cpo |
| **PM (new)** | Has `<!-- cpo-agent:greenlit -->` but no `pm-agent:spec`/`pm-agent:question` marker | → product-manager |
| **PM (re-eval)** | Latest PM comment is `pm-agent:question` AND a human commented (or `updatedAt` is newer) since | → product-manager |
| **WAITING** | Has `awaiting-answer` and no new human activity since the PM question | skip with note |
| **DEV-RETURN** | Latest dev comment is `<!-- dev-agent:question -->` (no `dev_ready`) | → product-manager |

DONE comes first so declined issues are never re-evaluated. Only a `cpo-agent:greenlit` comment
makes an issue eligible for PM (new). Legacy issues that predate the CPO (already carry a
`pm-agent:spec`/`pm-agent:question` marker) continue from their PM state; the retired
`pm-agent:closed` marker is non-blocking — a reopened issue carrying only it routes back to the
CPO gate (and the CPO never re-declines a human-reopened issue).

Classify each **open PR**:

| Bucket | Trigger | Dispatch |
|---|---|---|
| **BLOCKED** | Latest QA activity is `<!-- qa-agent:error -->` with no newer human activity | skip — **needs a human** |
| **QA** | No `qa-agent:approved` review AND no `qa-agent:review` newer than the latest commit, OR new commits since last QA review | → qa-reviewer |
| **APPROVED** | Has `qa-agent:approved` and no new commits | skip (awaiting human merge) |
| **DEV-FIXING** | Has `qa-agent:review` and no new commits | skip (waiting on dev) |

Bot vs human: agents post as the gh CLI user — treat any comment **without** a
`<!-- *-agent:* -->` marker as human.

## Step 5 — Print triage and proceed

Print a triage table (issue/PR number, title, bucket, dispatch target), then **dispatch
immediately** — the user has opted into automatic dispatch. If sweep mode finds zero work, print
`No open issues or PRs need attention right now.` and stop.

## Step 6 — Dispatch agents

For each item, call the Agent tool with the matching `subagent_type` and this prompt shape
(substitute role and number; run **independent** dispatches in parallel in one message):

```
Act as the <role> on issue #N (or PR #M) for the soccer-assistant-coach repo.
Follow your role instructions in .claude/agents/<role>.md exactly.
ISSUE_NUMBER = N        (or PR_NUMBER = M; release-manager takes no input)
Orchestrator hint: <new | re-eval | dev-returned>   (PM only)
Return a single line summarizing what you did.
```

If a custom subagent type isn't available, fall back to `subagent_type: general-purpose` and
prepend the contents of `.claude/agents/<role>.md` (after the frontmatter) to the prompt.

**Parallelism:** CPO/PM/QA dispatches may run in parallel (they only read context and write to
GitHub). **Only one developer at a time** — devs create branches and run tests; keep them
sequential.

## Step 7 — Report this pass, then loop

Print one line per dispatched agent (issue/PR, role, result). Then **loop back to Step 3** — each
dispatch usually changes state (PM → dev_ready, dev → PR, QA → bounce) that becomes the next
pass's work. Keep looping until a pass makes **zero dispatches**, then print the idle line and go
to Step 8.

**Safety rails:**
- **Hard cap: 10 passes** per invocation → stop and report `Loop cap reached (10 passes) — re-run /fix-issue if more work remains.`
- **Same-target backoff:** never dispatch the same (issue|pr, role) pair twice in one invocation — log the skip. Prevents PM↔dev / dev↔QA ping-pong.
- Sequential-developer rule holds across passes.

## Step 8 — Release check (sweep mode or `release` only; skip for scoped modes)

```bash
# Two fetches: --tags alone can suppress the branch refspec, leaving origin/main stale.
git fetch --quiet origin
git fetch --quiet --tags origin
latest_tag=$(git describe --tags --abbrev=0)
unreleased=$(git rev-list "origin/main" "^$latest_tag" --count)
echo "Release check: latest tag $latest_tag, unreleased commits on main: $unreleased"
```

`0` → print `No unreleased commits on main — skipping release.` and exit. Otherwise dispatch the
release-manager (Step 6 template) — **sequentially, after all PM/dev/QA work has settled**; never
in parallel with a developer (both mutate the tree / push). Include its result line under a
"Release" row in the final report.

## Notes

- **The marker comments are the state machine** — keep them stable across edits to this skill:
  `cpo-agent:greenlit|declined`, `pm-agent:spec|question` (+ retired `pm-agent:closed`),
  `dev-agent:plan|question|done`, `qa-agent:approved|review|bounce|screenshots`,
  `release-agent:shipped|partial`, and `<role>-agent:error` for every role.
- **BLOCKED handling:** a subagent returning `BLOCKED: …` (per AGENTS.md → Agent Error Handling)
  is not re-dispatched this invocation — record it under a prominent "⚠️ Needs a human" section.
  On later passes the error marker keeps it in the BLOCKED bucket until a human comment clears it.
- Surface any hard subagent failure (e.g. "PR exists but issue still has dev_ready") in the final
  report rather than retrying automatically.
