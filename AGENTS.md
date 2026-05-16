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

The Flutter SDK shell scripts have Windows line endings (CRLF) that break under WSL, so **Android build and deploy run in different environments**. iOS builds run entirely in CI on a macOS runner.

#### Bumping the version (WSL) — triggers both Android and iOS CI

```bash
cd /mnt/c/Users/rdane/Documents/Projects/soccer-assistant-coach
bundle exec fastlane bump version:1.0.6 build:6
```
This updates `pubspec.yaml`, commits it, tags `vX.Y.Z`, and pushes — which triggers both `release.yml` (Android) and `release-ios.yml` (iOS) in GitHub Actions.

#### Android — manual release

**Step 1 — Build the AAB** (Windows — PowerShell or Git Bash):
```bash
flutter build appbundle --release
```

**Step 2 — Upload to Play Store** (WSL):
```bash
bundle exec fastlane android deploy                   # internal track (default)
bundle exec fastlane android deploy track:production  # or any other track
```

#### iOS — CI only (macOS required)

iOS releases run automatically via GitHub Actions (`release-ios.yml`) on every `v*` tag push. There is no supported local iOS build path from Windows/WSL.

To trigger manually without a version bump: go to Actions → "Release to App Store" → Run workflow.

**Available lanes (macOS only):**
- `bundle exec fastlane ios release` — sync certs, build IPA, upload to TestFlight
- `bundle exec fastlane ios build` — sync certs and build IPA only
- `bundle exec fastlane ios deploy` — upload existing `build/ios/ipa/Runner.ipa` to TestFlight

#### One-time iOS setup (do this before first iOS CI run)

See the detailed checklist in `.agents/memory/ios_setup.md`.

#### Available lanes summary
- `bundle exec fastlane bump version:X.Y.Z build:N` — bump version, commit, tag, push (WSL)
- `bundle exec fastlane android deploy [track:internal|alpha|beta|production]` — upload AAB (WSL)
- `bundle exec fastlane android build` — build signed AAB (Windows terminal only)
- `bundle exec fastlane ios release` — full iOS build + TestFlight upload (macOS only)

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
