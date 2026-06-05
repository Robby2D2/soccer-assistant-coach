# CPO Decision Memory — precedent & rationale

This is the CPO agent's **long-term decision memory**. Its purpose is consistency: the same
*class* of request should get the same answer every time, with the same reasoning, no matter
how many weeks apart two issues arrive.

## How the CPO remembers (two layers)

1. **Live precedent — GitHub (authoritative, self-truing).** The actual record of what was
   greenlit or declined lives on the issues themselves. Before deciding, the CPO queries it:
   ```powershell
   # Past declines (with the "why" in each thread's cpo-agent:declined comment)
   & "C:\Program Files\GitHub CLI\gh.exe" issue list --state closed --label wont-fix --json number,title,closedAt --limit 30
   # A specific past rationale
   & "C:\Program Files\GitHub CLI\gh.exe" issue view <N> --json comments
   ```
   This layer cannot drift from reality — it *is* reality. Always prefer it for "have we seen
   this before?"

2. **Distilled principles — this file (curated).** Generalized rules-of-thumb that the raw
   issue list doesn't make obvious on its own. The CPO **reads** this file as context but does
   **not** write to it (it ingests untrusted issue text and must not edit repo files). Entries
   here are added by a human, or during the `.agents/MEMORY.md` "Key Changes" upkeep pass, when
   a pattern has clearly emerged across several decisions.

> When a new decision **contradicts** a principle below, that's a signal — the CPO should call
> it out explicitly in its issue comment ("this departs from our usual stance on X because …")
> so a human can decide whether the principle needs updating.

---

## Standing principles

> Seeded from the OKRs and the product mission. Grow this list only when real decisions reveal
> a durable pattern — keep it short and high-signal.

### Decline as a class
- **Different audience or stakeholder than the coach** — parent-facing stat portals, player
  self-service apps, league-admin scheduling/registration, club-director dashboards. The app
  serves the *coach on the sideline*; these move no OKR for that user.
- **Different sport / general-purpose pivots** — basketball, baseball, generic "team manager."
- **Heavyweight analytics / reporting tooling** — deep stats engines, charts, BI-style exports.
  These add surface area and cognitive load (works against **O4**) without moving O1–O3.
- **Setup gates / friction added to core flows** — mandatory accounts, onboarding walls,
  multi-step configuration before a coach can run a game. Directly opposes **O3** and **O4**.
- **Monetization/paywall gating of existing core flows** — turning a sideline-critical action
  into a paid feature.

### Greenlight as a class
- **Any crash, data loss, or freeze on a core flow** — serves **O2**, essentially always worth doing.
- **Anything that cuts taps/time/confusion in lineup building or substitutions** — **O1/O4**.
- **Anything that shortens a new coach's path to their first managed game** — **O3**.
- **Offline reliability of a core flow** — **O2**.

### Judgment notes
- "Hard / large / expensive" is **never** a decline reason — cost is the PM's and developer's
  concern, not a strategic gate.
- When genuinely on the fence, **greenlight** — a wrongly-declined issue is costlier than a
  wrongly-passed one (the PM can still scope it down).
- Never re-decline an issue a human reopened after a prior `cpo-agent:declined` comment.

---

## Decision log (notable precedents)

> One terse line per genuinely-novel decision worth remembering. Most decisions don't need an
> entry — the GitHub label list already records them. Add a row here only when the *reasoning*
> is a useful precedent for future borderline calls. Newest first.

| Date | Issue | Decision | One-line rationale |
|------|-------|----------|--------------------|
| _(seed)_ | — | — | _No logged precedents yet; rely on the standing principles + GitHub label list above._ |
