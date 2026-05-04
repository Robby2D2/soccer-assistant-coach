# Agent Guidelines — Soccer Assistant Coach

This project is a Flutter app for managing soccer teams, seasons, players, and live games.

### Development

Always refer to `.agents/CODING.md` for specific coding instructions and standards to follow.

### Testing

Always refer to `.agents/TESTING.md` for testing instructions and patterns.

### Architecture

Always refer to `.agents/ARCHITECTURE.md` for information on project structure, patterns, and significant decisions.

### Publishing a Release

Fastlane must be run from **WSL (Ubuntu)** using Bundler — it is not available in PowerShell or Git Bash.

The Flutter SDK shell scripts have Windows line endings (CRLF) that break under WSL, so **build and deploy run in different environments**.

**Step 1 — Bump version** (WSL):
```bash
cd /mnt/c/Users/rdane/Documents/Projects/soccer-assistant-coach
bundle exec fastlane bump version:1.0.6 build:6
```
This updates `pubspec.yaml`, commits it, tags `vX.Y.Z`, and pushes.

**Step 2 — Build the AAB** (Windows — PowerShell or Git Bash):
```bash
flutter build appbundle --release
```

**Step 3 — Upload to Play Store** (WSL):
```bash
bundle exec fastlane deploy                   # internal track (default)
bundle exec fastlane deploy track:production  # or any other track
```

**Available lanes:**
- `bundle exec fastlane deploy [track:internal|alpha|beta|production]` — upload existing AAB (WSL)
- `bundle exec fastlane bump version:X.Y.Z build:N` — bump version, commit, tag, push (WSL)
- `fastlane build` — build signed release AAB (Windows terminal only, not WSL)

**Play Store listing assets** live in `store/assets/` and can be regenerated with:
```bash
python -X utf8 store/generate_assets.py
```

### Key Changes

At the end of every significant task or session, you MUST:
1. **Changes** Identify key learnings (new patterns, fixed bugs, architectural decisions).
2. **Architecture** Read `.agents/ARCHITECTURE.md` and update it with any key changes.
3. **Memory** Read `.agents/MEMORY.md` and update it with a concise summary of the changes made. This should always contain the most relevant information regarding the project as a whole. Always include a date for reference as well.
4. **Prune** When `.agents/MEMORY.md` approaches 200 lines, move older entries into topic-specific files under `.agents/memory/` (e.g., `.agents/memory/database.md`, `.agents/memory/theming.md`) and add or update a link to each file in `.agents/LONGTERM_MEMORY.md`.
