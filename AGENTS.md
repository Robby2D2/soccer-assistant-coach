# Agent Guidelines — Soccer Assistant Coach

This project is a Flutter app for managing soccer teams, seasons, players, and live games.

### GitHub CLI (`gh`)

`gh` is installed at `C:\Program Files\GitHub CLI\gh.exe` but is **not in the sandboxed PATH** used by Claude Code's Bash/PowerShell tools. Always invoke it with the full path in PowerShell:

```powershell
& "C:\Program Files\GitHub CLI\gh.exe" issue view 6
& "C:\Program Files\GitHub CLI\gh.exe" pr create --title "..." --body "..."
& "C:\Program Files\GitHub CLI\gh.exe" run list --workflow=release-ios.yml --limit=3
```

Do **not** use `gh` bare, `wsl bash -c "gh ..."`, or any other form — only the full Windows path works reliably from Claude Code tools.

---

### Development

Always refer to `.agents/CODING.md` for specific coding instructions and standards to follow.

### Testing

Always refer to `.agents/TESTING.md` for testing instructions and patterns.

### Architecture

Always refer to `.agents/ARCHITECTURE.md` for information on project structure, patterns, and significant decisions.

### Publishing a Release

Fastlane must be run from **WSL (Ubuntu)** using Bundler — it is not available in PowerShell or Git Bash.

The Flutter SDK shell scripts have Windows line endings (CRLF) that break under WSL, so **Android build and deploy run in different environments**. iOS builds run entirely in CI on a macOS runner.

#### The two-command release flow

```bash
# 1. Cut a release. Bumps pubspec, tags, pushes — CI ships to Play beta + TestFlight.
bundle exec fastlane create_release version:1.0.9 build:10

# 2. After QA on beta/TestFlight, promote to production.
#    Android → Play Store production track (live immediately).
#    iOS → submitted to Apple for App Store review (1-2 day review window).
bundle exec fastlane promote_release version:1.0.9
```

> **Heads up — fastlane's `git push` from WSL fails silently on this machine.** When fastlane invokes `git push` from WSL, git tries to call `git-credential-manager.exe` under `/mnt/c/Program Files/...`, and the space in `/Program Files/` is treated as a word boundary by the WSL shell. The push errors with `/mnt/c/Program: not found` and exits, but the local commit + tag are already created. You'll see "Successfully committed" but the tag never reaches GitHub and no release workflow fires. **Workaround:** after running `fastlane create_release` (or `fastlane bump`), verify the tag pushed and recover if needed:
> ```powershell
> # Verify (from PowerShell)
> git ls-remote --tags origin v1.0.9
>
> # If empty, push manually:
> git push origin main
> git push origin v1.0.9    # this is the push that actually triggers the release workflows
> ```
> Verify both CI releases kicked off: `gh run list --workflow=release.yml` and `gh run list --workflow=release-ios.yml`.
>
> **For a permanent fix** (one-time WSL setup using `$GITHUB_TOKEN`), see [`docs/wsl-git-credentials.md`](docs/wsl-git-credentials.md). After that setup, `fastlane create_release` pushes work end-to-end without manual recovery.

#### What happens during `create_release`

1. Updates `pubspec.yaml` to the new version + build number
2. Commits `chore: bump version to X.Y.Z+N`
3. Tags `vX.Y.Z` and pushes the commit + tag
4. Tag push fires `release.yml` and `release-ios.yml` on GitHub Actions:
   - Android: builds signed AAB → uploads to Play Store **beta** track as draft
   - iOS: builds IPA → uploads to **TestFlight**

#### What happens during `promote_release`

1. **Android**: calls `upload_to_play_store` with `track_promote_to: production` → live on Play Store production track within minutes
2. **iOS**: calls `upload_to_app_store` with `submit_for_review: true, automatic_release: false` → enters Apple's review queue. Apple reviews 1-2 days; you'll get an email when approved, then click "Release this version" in App Store Connect

#### Lower-level lanes (still useful)

- `bundle exec fastlane bump version:X.Y.Z build:N` — alias for the bump-and-tag part of `create_release`
- `bundle exec fastlane android promote from:beta to:production` — Play Store promote only
- `bundle exec fastlane android deploy track:internal` — upload existing AAB to a specific track
- `bundle exec fastlane ios submit` — iOS App Store review submission only

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
- **`bundle exec fastlane create_release version:X.Y.Z build:N`** — bump + tag + push; CI ships to Play beta + TestFlight (WSL)
- **`bundle exec fastlane promote_release version:X.Y.Z`** — Play beta → production + submit iOS for App Store review (WSL)
- `bundle exec fastlane bump version:X.Y.Z build:N` — bump + tag + push only (no convenience messages)
- `bundle exec fastlane android promote from:beta to:production` — Play Store promote between tracks (WSL)
- `bundle exec fastlane android deploy [track:internal|alpha|beta|production]` — upload existing AAB (WSL)
- `bundle exec fastlane android build` — build signed AAB locally (Windows terminal only)
- `bundle exec fastlane ios release` — full iOS build + TestFlight upload (macOS only)
- `bundle exec fastlane ios metadata` — upload App Store metadata and screenshots (WSL, no submission)
- `bundle exec fastlane ios submit` — upload metadata and submit latest build for App Store review (WSL)

**Store listing assets** live in `store/assets/` (Android) and `fastlane/screenshots/en-US/` (iOS) and can be regenerated with:
```bash
python -X utf8 store/generate_assets.py
```

**App Store metadata** (title, description, keywords, etc.) lives in `fastlane/metadata/en-US/`.

**Privacy policy + support pages** are hosted at `https://www.useunix.com/soccer-assistant-coach/` on the user's self-hosted nginx box (LAN address `192.168.2.1`, served at `/var/www/html/`). The source files live in [`docs/`](docs/) — `privacy-policy.html`, `contact.html`, `data-safety.html`, `index.html`, `robots.txt`. Redeploy after editing any of them:

```powershell
scp docs/*.html docs/robots.txt www@192.168.2.1:/var/www/html/soccer-assistant-coach/
```

The `www` user is in the `www-data` group, so no `sudo` is needed. The webserver is reachable from any machine on the LAN; SSH key auth is already configured for the current developer.

### Key Changes

At the end of every significant task or session, you MUST:
1. **Changes** Identify key learnings (new patterns, fixed bugs, architectural decisions).
2. **Architecture** Read `.agents/ARCHITECTURE.md` and update it with any key changes.
3. **Memory** Read `.agents/MEMORY.md` and update it with a concise summary of the changes made. This should always contain the most relevant information regarding the project as a whole. Always include a date for reference as well.
4. **Prune** When `.agents/MEMORY.md` approaches 200 lines, move older entries into topic-specific files under `.agents/memory/` (e.g., `.agents/memory/database.md`, `.agents/memory/theming.md`) and add or update a link to each file in `.agents/LONGTERM_MEMORY.md`.
