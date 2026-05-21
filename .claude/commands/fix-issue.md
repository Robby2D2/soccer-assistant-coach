# Fix GitHub Issue

Given a GitHub issue number, fetch the issue, implement the fix on a new branch, and open a pull request.

Usage: `/fix-issue <issue-number>`

## Your role

You are a Flutter developer on this project. You will read the issue, plan a minimal implementation, write the code, verify it, and open a PR — all without unnecessary back-and-forth. Use TodoWrite to track your steps.

## Step 1 — Parse the argument

The issue number is passed as `$ARGUMENTS`. If it is empty or non-numeric, tell the user: "Usage: /fix-issue <issue-number>" and stop.

## Step 2 — Fetch the issue

Run in parallel:

**Issue details:**
```powershell
& "C:\Program Files\GitHub CLI\gh.exe" issue view $ARGUMENTS --json number,title,body,labels,assignees,comments
```

**Current branch (to return to if needed):**
```
git branch --show-current
```

**Recent commits for context:**
```
git log --oneline -5
```

If the issue is not found (exit code non-zero), report the error and stop.

## Step 3 — Read project context

Read these files in parallel to understand coding standards before planning anything:
- `.agents/CODING.md`
- `.agents/ARCHITECTURE.md`
- `.agents/MEMORY.md`

## Step 4 — Plan the implementation

Based on the issue title, body, labels, and comments:

1. Identify what the problem or feature is.
2. Identify which files are likely affected — use Glob and Grep to find relevant code rather than guessing.
3. Determine the minimal change needed. Do not add features beyond what the issue requests.
4. Note any tests that will need to be added or updated (refer to `.agents/TESTING.md`).

Present a brief plan (3–8 bullet points) to the user and wait for confirmation before writing any code. Format it as:

```
Issue #N: <title>

Plan:
  • <what you'll change and why>
  • <files affected>
  • <tests needed>

Proceed?
```

## Step 5 — Create a branch

Derive a short slug from the issue title (lowercase, hyphens, max 40 chars).

```
git checkout -b fix/<slug>-<issue-number>
```

Example: issue #42 "Crash when roster is empty" → `fix/crash-empty-roster-42`

For feature requests (label `enhancement`), use `feat/` prefix instead of `fix/`.

## Step 6 — Implement the changes

Follow the standards in `.agents/CODING.md` exactly:
- Match the existing code style (no new patterns unless CODING.md allows them).
- Write no comments unless the WHY is non-obvious.
- No error handling for cases that cannot occur.
- Keep changes minimal — only what the issue requires.

If you discover the scope is larger than expected, stop and tell the user rather than silently expanding.

## Step 7 — Run static analysis and tests

Run these in sequence (each depends on the previous succeeding):

**Analyze:**
```
flutter analyze
```
Fix any errors before continuing. Warnings from unrelated files are acceptable.

**Tests (if any tests exist for affected code):**
```
flutter test
```

If tests fail in areas unrelated to your change, note them but do not fix them — report to the user.

If your change requires new tests per `.agents/TESTING.md`, write them before this step.

## Step 8 — Commit

Stage only the files you changed. Never use `git add -A` or `git add .`.

Commit message format (follow the project's existing style from `git log`):
```
fix: <concise description in imperative mood>

Closes #<issue-number>
```

For features use `feat:` prefix.

## Step 9 — Push and open a PR

```powershell
git push -u origin HEAD
```

Then create the PR (use PowerShell here-string for the body):
```powershell
& "C:\Program Files\GitHub CLI\gh.exe" pr create `
  --title "<same as commit subject>" `
  --body @'
## Summary

<1–3 sentences describing what changed and why>

Closes #<issue-number>

## Test plan

- [ ] `flutter analyze` passes
- [ ] Existing tests pass
- [ ] <any manual verification steps specific to the change>

🤖 Generated with [Claude Code](https://claude.com/claude-code)
'@
```

## Step 10 — Wrap up

Print:
```
Done: PR opened for issue #N

  Branch:  fix/<slug>-N
  PR:      <url>
  Closes:  #N — <issue title>
```

Update `.agents/MEMORY.md` with a one-line entry for any non-obvious architectural decision made during implementation.

## Notes

- Never commit to `main` — always use a feature branch.
- If `flutter analyze` produces errors you can't fix (e.g., generated code), ask the user before continuing.
- If the issue is unclear, ask one focused clarifying question before starting Step 5.
- Do not run `flutter build` — analysis and tests are sufficient for PR validation.
