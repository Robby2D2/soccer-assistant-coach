# Long-Term Memory — Soccer Assistant Coach

This file is a table of contents. Each entry links to a topic-specific file in `.agents/memory/`.

---

| Date | Topic | File | Summary |
|------|-------|------|---------|
| 2026-05-18 | iOS CI/CD setup | [memory/ios_setup.md](memory/ios_setup.md) | One-time checklist complete. Runner: macos-14. Admin API key required. Keychain hang fix documented in MEMORY.md May 18 entry. |
| 2025-10-17 | Theming & contrast safety | [memory/theming_contrast.md](memory/theming_contrast.md) | `TeamColorContrast.onColorFor()` utility — why it exists, where it's applied, future improvements |
| 2025-10-13 | Home screen timer display | [memory/home_screen_timer.md](memory/home_screen_timer.md) | Switched to time-remaining format with `+MM:SS` overtime; removed "time ago" display |
| 2025-10-10 | Background timer implementation | [memory/background_timer.md](memory/background_timer.md) | DateTime-based timer persistence across backgrounding and force-quit; manual test scenarios |
| 2025-10-17 | Timer jumping fix | [memory/timer_jumping_fix.md](memory/timer_jumping_fix.md) | Root cause (dual calculation methods) and fix (simple increment + resume-only recalculation) |
