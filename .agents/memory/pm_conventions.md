# PM Spec Conventions — terminology & spec patterns

This is the product-manager agent's **long-term convention memory**. Its purpose is
consistency: two specs written weeks apart should use the same words, the same structure, and
draw the same scope boundaries — so the developer and QA agents see a stable target.

## How the PM remembers (two layers)

1. **Live precedent — GitHub (authoritative, self-truing).** Past specs live on the issues.
   Before writing a new spec, the PM can skim recent ones for wording and structure it should
   match:
   ```bash
   # Recent dev-ready / spec'd issues
   gh issue list --state all --label dev_ready --json number,title --limit 20
   # A specific past spec
   gh issue view <N> --json comments
   ```

2. **Distilled conventions — this file (curated).** The terminology and patterns below. The PM
   **reads** this file as context but does **not** write to it (it ingests untrusted issue text
   and must not edit repo files). Entries are added by a human, or during the `.agents/MEMORY.md`
   "Key Changes" upkeep pass, when a convention has stabilized.

---

## Terminology (use these exact words in specs)

| Use | Not | Note |
|-----|-----|------|
| **substitution** / **substitute** | swap, change, rotate | The core action. A "sub". |
| **lineup** | line-up, roster-for-the-game | The set of players on the field + bench for a game. |
| **roster** | team list, squad | The full set of players on a team for a season. |
| **season** | year, term | Top-level container for teams. |
| **live game** | match, fixture | The in-progress game screen. |
| **playing time** / **minutes** | game time, ice time | Fairness metric coaches track. |
| **formation** | shape, setup | Field positions for a lineup. |
| **coach** | user, manager | Always frame value in terms of the coach. |

## Spec conventions

- **Always use the exact spec template** in `.claude/agents/product-manager.md` Step 4
  (Problem / Value / Goal / Success metrics / Acceptance criteria / Out of scope). Don't
  reorder or rename headings — QA and the developer key off them.
- **Success metrics must tie to an OKR KR** where possible (see `.agents/OKRS.md`). Prefer the
  KR's own threshold as the metric (e.g. "substitute in ≤2 taps / ≤5s" for O1.1) so specs and
  strategy stay aligned.
- **Acceptance criteria are observable behaviors**, phrased as checkable bullets ("Coach can …",
  "After …, the screen shows …"). Never implementation detail (no file/class/widget names).
- **"Out of scope" is required** on every spec — name at least one thing this issue is *not*
  doing, to keep the developer's change tight.
- **Tap/time budgets:** when a spec touches a sideline action, state its tap/time budget
  explicitly (the app's bar is ≤2 taps from the live game screen — O4.1).
- **Mission fit is already settled** by the CPO before the PM sees the issue. Do not re-argue
  whether it belongs in the app; spec the greenlit intent.

## Recurring out-of-scope boundaries

> Common things to explicitly exclude so specs don't balloon. Grow as patterns recur.

- Cloud sync / accounts (the app is local-first by design — call out as out of scope unless the
  issue is specifically about that).
- Stats dashboards / charts beyond the simple in-game metrics already tracked.
- Multi-sport or non-coach audiences (these shouldn't reach the PM — they're CPO declines).
