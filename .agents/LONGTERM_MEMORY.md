# Long-Term Memory — Soccer Assistant Coach

This file is a table of contents. Each entry links to a topic-specific file in `.agents/memory/`.

---

| Topic | File | Summary |
|-------|------|---------|
| Theming & contrast safety | [memory/theming_contrast.md](memory/theming_contrast.md) | `TeamColorContrast.onColorFor()` utility — why it exists, where it's applied, future improvements |
| Home screen timer display | [memory/home_screen_timer.md](memory/home_screen_timer.md) | Switched to time-remaining format with `+MM:SS` overtime; removed "time ago" display |
| Background timer implementation | [memory/background_timer.md](memory/background_timer.md) | DateTime-based timer persistence across backgrounding and force-quit; manual test scenarios |
| Timer jumping fix | [memory/timer_jumping_fix.md](memory/timer_jumping_fix.md) | Root cause (dual calculation methods) and fix (simple increment + resume-only recalculation) |
