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

```bash
# Open WSL and cd to the project
cd /mnt/c/Users/rdane/Documents/Projects/soccer-assistant-coach

# 1. Bump version — updates pubspec.yaml, commits, tags vX.Y.Z, and pushes
bundle exec fastlane bump version:1.0.6 build:6

# 2. Build the release AAB and upload to Play Store (internal track by default)
bundle exec fastlane release

# Or target a specific track
bundle exec fastlane deploy track:production
```

**Available lanes:**
- `bundle exec fastlane build` — build signed release AAB only
- `bundle exec fastlane deploy [track:internal|alpha|beta|production]` — upload existing AAB
- `bundle exec fastlane release [track:...]` — build + deploy in one step
- `bundle exec fastlane bump version:X.Y.Z build:N` — bump version, commit, tag, push

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
