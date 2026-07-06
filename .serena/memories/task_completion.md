Before marking any coding task complete, run and fix all errors (address warnings unless documented otherwise):
1. `flutter analyze`
2. `flutter test`

Every new feature or bug fix must include/update a test (even trivial fixes preferred to have one). For UI-affecting Patrol journeys on PRs, capture a mid-test screenshot of the fixed screen (see `mem:conventions`) so the qa-reviewer pipeline agent can attach visual proof to the GitHub issue.

Architecture-significant decisions get logged in `.agents/ARCHITECTURE.md`'s decisions table, not just in code comments — check there before re-deciding something that looks like prior art.