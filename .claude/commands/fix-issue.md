# Fix GitHub Issue (Orchestrator)

Triage open GitHub issues + open pull requests and dispatch the right specialist agent for each: **product-manager**, **developer**, or **qa-reviewer**.

Usage:
- `/fix-issue` — sweep all open issues + PRs, triage, and dispatch (default mode).
- `/fix-issue <issue-number>` — triage one specific issue and dispatch.
- `/fix-issue pr <pr-number>` — force a QA review on one specific PR.

## Your role

You are the **orchestrator**. You do not write product specs, code, or reviews yourself — you classify work and hand each piece to the right specialist subagent (defined in [.claude/agents/](../agents/)). Each subagent communicates with humans through GitHub issue/PR comments. You report a triage summary back to the user.

The three specialists:
- **product-manager** — turns rough issues into specs with success metrics, asks clarifying questions when needed.
- **developer** — implements `dev_ready` issues, runs tests, opens PRs.
- **qa-reviewer** — reviews open PRs against code quality + spec acceptance criteria.

## Step 1 — Parse the argument

`$ARGUMENTS` may be:
- empty → sweep mode (default)
- a number → triage that one issue
- `pr <number>` → QA review that one PR

## Step 2 — One-time label setup

Ensure the labels the agents rely on exist on the repo. Idempotent — these silently no-op if they already exist:

```powershell
& "C:\Program Files\GitHub CLI\gh.exe" label create "dev_ready" --color "0E8A16" --description "PM spec written; ready for the developer agent" 2>$null
& "C:\Program Files\GitHub CLI\gh.exe" label create "awaiting-answer" --color "FBCA04" --description "Waiting on a human answer in the issue thread" 2>$null
```

Don't fail if these error — they likely already exist.

## Step 3 — Gather candidates

Run these in parallel:

**Open issues** (with labels + last comment author/timestamp for staleness checks):
```powershell
& "C:\Program Files\GitHub CLI\gh.exe" issue list --state open --limit 50 --json number,title,labels,author,updatedAt,comments
```

**Open PRs**:
```powershell
& "C:\Program Files\GitHub CLI\gh.exe" pr list --state open --limit 30 --json number,title,headRefName,author,labels,reviews,updatedAt,closingIssuesReferences,statusCheckRollup
```

If a specific issue/PR was passed, fetch only that one.

## Step 4 — Triage

For each **open issue**, classify into exactly one bucket. Process in this priority order — first match wins:

| Bucket | Trigger | Dispatch |
|---|---|---|
| **DEV** | Has `dev_ready` label | → developer |
| **PM (new)** | No comment has the marker `<!-- pm-agent:spec -->` or `<!-- pm-agent:question -->` | → product-manager |
| **PM (re-eval)** | Latest PM comment is `<!-- pm-agent:question -->` AND there is a non-bot human comment OR `updatedAt` newer than that PM comment | → product-manager |
| **WAITING** | Has `awaiting-answer` label and no new human activity since the PM question | skip with note |
| **DEV-RETURN** | Latest dev comment is `<!-- dev-agent:question -->` (no `dev_ready`) | → product-manager (dev is asking a question, PM should respond/route) |
| **DONE** | Closed, or has an open PR via `closingIssuesReferences` | skip |

For each **open PR**, classify:

| Bucket | Trigger | Dispatch |
|---|---|---|
| **QA** | No `<!-- qa-agent:approved -->` review AND no `<!-- qa-agent:review -->` review newer than the latest commit OR has new commits since last QA review | → qa-reviewer |
| **APPROVED** | Already has `<!-- qa-agent:approved -->` review and no new commits | skip (awaiting human merge) |
| **DEV-FIXING** | Has `<!-- qa-agent:review -->` review and no new commits | skip (waiting on dev) |

Detect bot vs human comments by author login — agents post as the gh CLI user; treat any comment **not** containing one of the `<!-- *-agent:* -->` markers as a human comment.

## Step 5 — Print triage and proceed

Print the triage table for transparency, then **dispatch immediately** — do not wait for confirmation. The user has opted into automatic dispatch.

```
Triage summary
──────────────
Issues:
  #12  "Add jersey-number sort"         → DEV          (developer)
  #18  "Crash on empty roster"          → PM (new)     (product-manager)
  #21  "Dark mode for substitution UI"  → PM (re-eval) (product-manager — human answered question)
  #25  "Stats export"                   → WAITING      (skip — no human reply yet)

Pull requests:
  #34  "fix: jersey-number sort"        → QA           (qa-reviewer)
  #31  "feat: ios share sheet"          → APPROVED     (skip — awaiting human merge)

Dispatching 4 agents…
```

If sweep mode finds zero work, just print `No open issues or PRs need attention right now.` and stop.

If the user wants to be selective for a given run, they can either invoke `/fix-issue <issue-number>` to target one item, or interrupt the run before dispatch completes.

## Step 6 — Dispatch agents

For each dispatched item, call the appropriate subagent via the Agent tool. Run **independent** dispatches in parallel within a single message (multiple Agent tool calls).

Dispatch templates (substitute the issue/PR number):

**Product manager:**
```
Agent tool:
  subagent_type: product-manager
  description: "PM triage of issue #N"
  prompt: |
    Act as the product manager on issue #N for the soccer-assistant-coach repo.
    Follow your role instructions in .claude/agents/product-manager.md exactly.
    ISSUE_NUMBER = N
    Orchestrator hint: <new | re-eval | dev-returned>
    Return a single line summarizing what you did.
```

**Developer:**
```
Agent tool:
  subagent_type: developer
  description: "Implement issue #N"
  prompt: |
    Act as the developer on issue #N for the soccer-assistant-coach repo.
    Follow your role instructions in .claude/agents/developer.md exactly.
    ISSUE_NUMBER = N
    Return a single line summarizing what you did (PR url if opened, or the question you posted, or the reason you stopped).
```

**QA reviewer:**
```
Agent tool:
  subagent_type: qa-reviewer
  description: "QA review of PR #M"
  prompt: |
    Act as the QA reviewer on pull request #M for the soccer-assistant-coach repo.
    Follow your role instructions in .claude/agents/qa-reviewer.md exactly.
    PR_NUMBER = M
    Return a single line summarizing what you did.
```

If the custom subagent type isn't available in this session, fall back to `subagent_type: general-purpose` and prepend the contents of `.claude/agents/<role>.md` (everything after the YAML frontmatter) to the prompt.

### Parallelism rules

- Multiple PM dispatches can run in parallel — they only write to GitHub.
- Multiple QA dispatches can run in parallel — they only read code and write to GitHub.
- Only **one developer agent at a time** — they create branches and run tests. Run dev dispatches sequentially.

## Step 7 — Report this pass, then loop

Print a one-line summary per agent for the pass that just finished:

```
Orchestrator results — pass N
──────────────────────────────
  Issue #18  PM    → Spec written, marked dev_ready
  Issue #21  PM    → Asked 2 follow-up questions
  Issue #12  DEV   → PR opened: https://github.com/.../pull/35
  PR    #34  QA    → Requested changes — bounced back to dev (issue #29)

3 dispatched, 1 skipped.
```

Then **loop back to Step 3** and run another triage pass. One dispatch usually changes the state of an issue or PR (PM → dev_ready, dev → PR opened, QA → bounce), and that new state is the next pass's work. Keep looping until a pass produces **zero dispatches** (every open issue is WAITING/DONE and every open PR is APPROVED/DEV-FIXING).

When a pass dispatches nothing, print the idle line and stop:

```
Idle — every open issue is waiting on a human or done, and every open PR is awaiting human merge or fixes.
```

### Loop safety rails

- **Hard cap of 10 passes per `/fix-issue` invocation.** If you hit it, stop and report `Loop cap reached (10 passes) — re-run /fix-issue if more work remains.` This prevents runaway loops from a misbehaving subagent.
- **Same-target backoff.** Track which (issue|pr, role) pairs you've dispatched this invocation. If the same pair would be dispatched again in a later pass, skip it and log `Skipped re-dispatch of <pair> — already handled this invocation.` This prevents PM↔dev or dev↔QA ping-pong loops within one run.
- **Sequential dev rule still applies across passes.** Multiple PM/QA can run in parallel within a pass; developer dispatches stay sequential.

## Notes

- The orchestrator never edits code, posts GitHub comments, or modifies labels itself (except the one-time label creation in Step 2). Everything else is the subagents' job.
- Agent comment markers (`<!-- pm-agent:spec -->`, `<!-- pm-agent:question -->`, `<!-- dev-agent:plan -->`, `<!-- dev-agent:question -->`, `<!-- dev-agent:done -->`, `<!-- qa-agent:approved -->`, `<!-- qa-agent:review -->`, `<!-- qa-agent:bounce -->`) are the state machine — keep them stable across edits to this skill.
- If a subagent reports a hard failure (e.g., "PR already exists but issue still has dev_ready"), surface it in the final report rather than retrying automatically.
