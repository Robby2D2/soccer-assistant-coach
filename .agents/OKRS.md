# Product OKRs — Soccer Assistant Coach

**Mission (north star):** Make it effortless for a youth soccer coach to manage their
lineups and substitutions on the sideline.

These OKRs are the rubric the **CPO agent** uses to decide whether an incoming issue is
worth fixing. An issue earns a greenlight when resolving it would plausibly advance at
least one Key Result below. They are also a reference for the product-manager agent when
writing success metrics.

> Keep these stable. If the product strategy genuinely shifts, update this file in a
> dedicated commit so the change is auditable — the agents treat it as the source of truth.

---

## O1 — Sideline lineup & substitution management is effortless
*The core job. Everything else is in service of this.*

- **KR1.1** A coach can make a substitution in ≤2 taps and ≤5 seconds from the live game screen.
- **KR1.2** Building a starting lineup / formation for a game takes ≤60 seconds.
- **KR1.3** Playing-time fairness (who's owed minutes) is visible at a glance during a live game, with no manual tallying.

## O2 — The app is rock-solid and trustworthy on the sideline
*A coach mid-game has no patience for crashes, spinners, or lost data.*

- **KR2.1** Crash-free sessions stay ≥ 99.5%.
- **KR2.2** Every core flow (start game, substitute, save result) works fully offline.
- **KR2.3** Zero data loss: teams, rosters, and game state survive app restarts and updates.

## O3 — A new coach reaches their first managed game fast
*Coaches are volunteers with limited time; onboarding friction loses them.*

- **KR3.1** A first-time coach can create a team, add a roster, and start a game in ≤5 minutes.
- **KR3.2** No core task requires reading documentation to complete.
- **KR3.3** Importing/restoring an existing roster (e.g. CSV) takes ≤3 steps.

## O4 — The coach stays focused on coaching, not on the app
*Low cognitive load. Fewer taps, fewer decisions, less fiddling.*

- **KR4.1** Every primary sideline action is reachable in ≤2 taps from the live game screen.
- **KR4.2** New features add no setup steps or gates to existing core flows.
- **KR4.3** The UI is legible and tappable outdoors, one-handed, in bright sun (contrast + touch-target standards met).

---

### How to read these for triage

- An issue does **not** need to name an OKR to qualify — it needs a believable line from
  "we fixed this" to "a Key Result moved." A bug that crashes the roster screen serves
  **O2**; a confusing first-run flow serves **O3**; a 4-tap substitution serves **O1/O4**.
- "Nice idea, but it doesn't move any KR and adds surface area" is a decline.
- "Hard or large" is **not** a decline — cost is the PM's and developer's problem, not a
  strategic gate.
