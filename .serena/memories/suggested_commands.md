Windows machine — run flutter/dart/gh/git through PowerShell, not the Bash tool (Bash tool is /usr/bin/bash and can't see Windows executables).

- `flutter analyze` / `flutter test` — required before considering any task done (see `mem:task_completion`).
- `flutter pub run build_runner build --delete-conflicting-outputs` — regenerate `*.g.dart` / `*.drift.dart`; never hand-edit generated files.
- `patrol test` — run E2E journeys in `patrol_test/` (Android emulator/iOS simulator required). Install once via `dart pub global activate patrol_cli` (lands in `%LOCALAPPDATA%\Pub\Cache\bin`, must be on PATH).
- `gh` CLI is at `C:\Program Files\GitHub CLI\gh.exe`, NOT on the sandboxed PATH — invoke with full path from PowerShell; multi-line bodies need a PowerShell single-quoted here-string (`@'...'@`, closing `'@` at column 0). In CI (GitHub Actions) `gh` is bare + bash-heredoc instead.
- Fastlane (release flow) must run from WSL via `bundle exec fastlane ...` — not available in PowerShell/Git Bash. See `.agents` docs / AGENTS.md for the full release flow (create_release / promote_release lanes) and a known silent-push-from-WSL gotcha.
- `python -X utf8 store/generate_assets.py` — regenerate store listing screenshots/assets.