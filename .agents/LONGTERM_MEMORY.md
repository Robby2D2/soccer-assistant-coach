# Long-Term Memory — Soccer Assistant Coach

Table of contents for the topic files in `.agents/memory/`. Read a topic file only when working in
that area.

| Date | Topic | File | Summary |
|------|-------|------|---------|
| 2026-06-28 | Sideline design system | [memory/sideline_design.md](memory/sideline_design.md) | Rollout status, Live Game decisions (keep PageView, no next-on section), TeamColors/theming gotchas, Claude Design project pointer |
| 2026-06-07 | /fix-issue agent pipeline | [memory/agent_pipeline.md](memory/agent_pipeline.md) | Cloud (GitHub Actions) migration, BOT_TOKEN requirement, marker state machine rationale, error protocol origin, QA screenshot design |
| 2026-06-05 | CPO decision memory | [memory/cpo_decisions.md](memory/cpo_decisions.md) | CPO's standing greenlight/decline principles + precedent. Agent reads, never writes |
| 2026-06-05 | PM spec conventions | [memory/pm_conventions.md](memory/pm_conventions.md) | Terminology table, spec structure, metric→OKR alignment, recurring out-of-scope boundaries. Agent reads, never writes |
| 2026-05-22 | Releases & store publishing | [memory/releases.md](memory/releases.md) | Fastlane/WSL silent-push bug, Fastfile lane fixes, iOS keychain hang, store compliance, Android CI toolchain OOM signatures |
| 2026-05-21 | Patrol / E2E testing | [memory/testing.md](memory/testing.md) | Patrol 4.x version pinning, orchestrator hang (why the gate is sharded), timer/teardown discipline, emulator quirks |
| 2026-05-18 | iOS CI/CD setup | [memory/ios_setup.md](memory/ios_setup.md) | One-time checklist (complete). macos-14 runner, Admin API key, Match secrets |
| 2026-04-24 | Production readiness | [memory/production_readiness.md](memory/production_readiness.md) | Pre-store audit: PrivacyInfo.xcprivacy, Timer leak fix, migration tests |
| 2025-10-17 | Theming & contrast safety | [memory/theming_contrast.md](memory/theming_contrast.md) | `TeamColorContrast.onColorFor()` — why it exists, where applied |
| 2025-10-17 | Timer jumping fix | [memory/timer_jumping_fix.md](memory/timer_jumping_fix.md) | Root cause (dual calculation methods) and fix |
| 2025-10-13 | Home screen timer display | [memory/home_screen_timer.md](memory/home_screen_timer.md) | Time-remaining format with `+MM:SS` overtime |
| 2025-10-10 | Background timer | [memory/background_timer.md](memory/background_timer.md) | DateTime-based persistence across backgrounding/force-quit |
