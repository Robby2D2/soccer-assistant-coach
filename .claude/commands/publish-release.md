# Publish Release

Cut a release of Soccer Assistant Coach from this Windows machine with minimal user input,
following the manual release flow in [docs/RELEASING.md](../../docs/RELEASING.md). Use TodoWrite
to track progress.

Fastlane runs only from WSL: every fastlane command is
`wsl bash -c "cd /mnt/c/Users/rdane/Documents/Projects/soccer-assistant-coach && bundle exec fastlane … 2>&1"`
with a 5-minute timeout. Everything else (git, gh, flutter) runs from PowerShell — `gh` by full
path: `& "C:\Program Files\GitHub CLI\gh.exe" …`.

## Step 1 — Gather release info (in parallel)

- Current `version: X.Y.Z+N` from `pubspec.yaml`.
- Last tags: `git tag --sort=-version:refname | head -5`.
- Changes: `git log $(git describe --tags --abbrev=0)..HEAD --oneline --no-merges`
  (no tags yet → last 20 commits).

## Step 2 — Propose the release and wait for confirmation

- **New version:** patch +1; suggest minor instead if the range includes a feature. Show reasoning.
- **New build:** current build +1.
- **Release notes:** 1–3 plain-English sentences from the user-facing commits (omit chore/CI/bump)
  for the store "What's New" section.

Present a summary (version, build, notes, included commits) and **wait for the user to confirm or
adjust before continuing**.

## Step 3 — Write the confirmed notes

To `fastlane/metadata/en-US/release_notes.txt`.

## Step 4 — Cut the release

```
wsl bash -c "cd /mnt/c/… && bundle exec fastlane create_release version:VERSION build:BUILD 2>&1"
```

This bumps pubspec, commits, tags `vVERSION`, and pushes — the tag push triggers `release.yml`
(Android → Play beta) and `release-ios.yml` (iOS → TestFlight).

**Then verify the push actually happened** — fastlane's push can fail silently from WSL (see
docs/RELEASING.md). From PowerShell:

```powershell
git ls-remote --tags origin vVERSION
# If empty, recover:
git push origin main
git push origin vVERSION
```

Do not continue until the tag is on origin.

## Step 5 — Confirm CI fired and watch it

```powershell
& "C:\Program Files\GitHub CLI\gh.exe" run list --workflow=release.yml --limit=3
& "C:\Program Files\GitHub CLI\gh.exe" run list --workflow=release-ios.yml --limit=3
```

Both should be queued/in-progress on the new tag. iOS takes ~15–20 min; watch with `gh run watch`
or report status and let the user check back.

## Step 6 — (Optional) refresh store metadata

If listing text/screenshots changed this release:

```
wsl bash -c "cd /mnt/c/… && bundle exec fastlane ios metadata 2>&1"
```

Ignorable warnings: "Error fetching app store review detail — No data" and "Skipping
release_notes… this is the first version".

## Step 7 — Wrap up

Summarize: version tagged, Android → Play **beta**, iOS → TestFlight. Next steps for the user:

- QA the build on beta/TestFlight.
- Promote when satisfied: `bundle exec fastlane promote_release version:VERSION` (WSL) or the
  `promote-release.yml` workflow — Android goes live in minutes; iOS enters Apple review
  (~24–48 h), then release manually in App Store Connect.

## Notes

- `fastlane/.env` holds local App Store Connect credentials — "No value found for key_id" means it
  needs populating.
- Stop and report rather than proceeding past a failed tag push (Step 4) — everything downstream
  depends on it.
