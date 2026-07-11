Flutter app (Dart) for managing soccer teams/seasons/players/live games. Windows dev machine.

Source map:
```
lib/
  main.dart, app.dart        # entry + MaterialApp/router
  core/                      # theme.dart, team_theme_manager.dart, game_scaffold.dart,
                              # providers.dart (dbProvider etc.), router.dart (go_router), sideline.dart
  features/<domain>/         # games, teams, players, seasons, formations, settings, home, startup, debug
  data/db/                   # Drift schema + DAOs; data/services/ business logic
  utils/                     # TeamColorContrast, team_theme.dart
  widgets/                   # shared widgets incl. sideline_widgets.dart
  l10n/                      # ARB localization
test/                        # widget/DB tests, flutter test
patrol_test/                 # Patrol E2E journeys, patrol test
.agents/                     # project docs: CODING.md, COMPONENTS.md, TESTING.md, ARCHITECTURE.md, MEMORY.md, OKRS.md, LONGTERM_MEMORY.md
.claude/agents/               # fix-issue pipeline subagents (cpo, product-manager, developer, pr-reviewer, qa-reviewer, release-manager)
```

Project already has its own durable-docs system in `.agents/` (read by the `/fix-issue` pipeline agents) — these Serena memories complement it, don't duplicate it. When in doubt about architecture/testing/coding rules, the `.agents/*.md` files are authoritative and may be more current than these memories.

Further memories: `mem:tech_stack`, `mem:suggested_commands`, `mem:conventions`, `mem:task_completion`.