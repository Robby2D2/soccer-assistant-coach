# Publish Release

Automatically determine release info and walk through publishing Soccer Assistant Coach to both the Google Play Store and Apple App Store with minimal user input.

## Your role

You are a release manager for this Flutter app. Gather all information automatically, present a single confirmation summary, then execute the release steps in order. Use the TodoWrite tool to track progress.

## Step 1 — Gather release info automatically

Run these in parallel:

**Current version and build:**
Read `pubspec.yaml` and extract the `version:` line (format: `X.Y.Z+N`).

**Last release tag:**
```
git tag --sort=-version:refname | head -5
```

**Commits since last tag (what changed):**
```
git log $(git describe --tags --abbrev=0)..HEAD --oneline --no-merges
```
If there are no tags yet, use `git log --oneline --no-merges -20`.

**Current build number** is the `+N` part of the version line in pubspec.yaml.

## Step 2 — Propose the release

From the information gathered, determine:
- **New version**: bump the patch number by 1 (e.g. `1.0.6` → `1.0.7`). If commits include a feature (not just fixes/chores), suggest bumping minor instead. Show your reasoning.
- **New build number**: current build number + 1.
- **Release notes**: synthesize the git commits into 1–3 plain-English sentences suitable for the App Store / Play Store "What's New" section. Omit chore/CI/bump commits. Focus on user-facing changes.

Show a confirmation summary like:

```
Ready to publish:
  Version:       1.0.7 (was 1.0.6)
  Build:         9 (was 8)
  Release notes: [your drafted notes]

Changes included:
  abc1234 feat: add CSV import for creating teams
  def5678 fix: lineup builder crash on empty roster

Proceed? (or say what to change)
```

Wait for the user to confirm or request adjustments before continuing.

## Step 3 — Update release notes

Write the confirmed release notes to `fastlane/metadata/en-US/release_notes.txt`.

## Step 4 — Bump the version

Run from WSL (replace VERSION and BUILD with confirmed values):
```
wsl bash -c "cd /mnt/c/Users/rdane/Documents/Projects/soccer-assistant-coach && bundle exec fastlane bump version:VERSION build:BUILD 2>&1"
```
This commits pubspec.yaml, tags the release, and pushes — which triggers both CI pipelines (Android AAB build + iOS IPA build) automatically.

Confirm the tag was pushed successfully before continuing.

## Step 5 — Build the Android AAB

The AAB must be built on Windows (not WSL) due to Flutter SDK line-ending issues.

Run using the Bash tool (not WSL):
```
flutter build appbundle --release
```
Wait for it to complete. If it fails, report the error and stop.

## Step 6 — Upload Android AAB to Play Store

Run from WSL:
```
wsl bash -c "cd /mnt/c/Users/rdane/Documents/Projects/soccer-assistant-coach && bundle exec fastlane android deploy 2>&1"
```
Confirm it succeeded (look for "fastlane.tools finished successfully").

## Step 7 — Upload iOS metadata

Run from WSL:
```
wsl bash -c "cd /mnt/c/Users/rdane/Documents/Projects/soccer-assistant-coach && bundle exec fastlane ios metadata 2>&1"
```
Confirm it succeeded. Known non-fatal warnings to ignore:
- "Error fetching app store review detail - No data" — harmless on first run per version
- "Skipping release_notes... this is the first version" — only appears for v1.0; ignore for subsequent versions

## Step 8 — Wait for iOS CI build

The iOS IPA is built by GitHub Actions (triggered by the tag push in step 4). It takes ~15–20 minutes.

Check CI status (use full path — `gh` is not in the sandboxed PATH):
```powershell
& "C:\Program Files\GitHub CLI\gh.exe" run list --workflow=release-ios.yml --limit=3
```
If the run is still in progress, tell the user and ask them to confirm when TestFlight shows the build as processed before you continue to step 9. You can also check with:
```powershell
& "C:\Program Files\GitHub CLI\gh.exe" run watch
```

## Step 9 — Submit iOS for App Store review

Run from WSL:
```
wsl bash -c "cd /mnt/c/Users/rdane/Documents/Projects/soccer-assistant-coach && bundle exec fastlane ios submit 2>&1"
```
Confirm it succeeded.

## Step 10 — Wrap up

Print a final summary:
```
Release 1.0.7 published:
  ✅ Version bumped and tagged v1.0.7
  ✅ Android AAB uploaded to Play Store (internal track)
  ✅ iOS metadata and screenshots uploaded
  ✅ iOS build submitted for App Store review

Next steps:
  • Apple review: ~24–48h. Release manually in App Store Connect when approved.
  • Android: promote to production when ready:
      bundle exec fastlane android promote from:internal to:production
```

## Notes

- All `bundle exec fastlane` commands must run via `wsl bash -c "..."`.
- The `fastlane/.env` file holds local App Store Connect API credentials. If a command fails with "No value found for key_id", the user needs to check that file is populated.
- Set a 5-minute timeout on each WSL fastlane command.
- Do not proceed past step 4 if the tag push fails — the CI pipelines depend on it.
