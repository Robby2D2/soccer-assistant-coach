# Releasing — Soccer Assistant Coach

Two release paths exist. Debugging lore for everything below lives in
[`.agents/memory/releases.md`](../.agents/memory/releases.md).

## Automated path (the `/fix-issue` pipeline)

The release-manager agent (GitHub Actions, Linux) bumps `pubspec.yaml`, commits to `main`, and
pushes a `vX.Y.Z` tag using `BOT_TOKEN` (the default `GITHUB_TOKEN` cannot trigger downstream
workflows). The tag push fires `release.yml` (Android → Play **beta**) and `release-ios.yml`
(iOS → TestFlight), which run fastlane on the runners. No WSL, no local fastlane.
See `.claude/agents/release-manager.md`.

**Promotion to production is always human-triggered** — `promote_release` from WSL (below) or the
`promote-release.yml` workflow from the Actions tab.

## Manual path (human, from this Windows machine)

Fastlane runs only from **WSL (Ubuntu)** via Bundler (`bundle exec fastlane …`) — it is vendored
and unavailable in PowerShell/Git Bash. Flutter builds run on **Windows** (the SDK's CRLF scripts
break under WSL). iOS builds run only in CI on a macOS runner.

### The two-command flow

```bash
# 1. Cut a release: bumps pubspec, commits, tags, pushes → CI ships to Play beta + TestFlight.
bundle exec fastlane create_release version:1.0.9 build:10

# 2. After QA on beta/TestFlight, promote:
#    Android → Play production (live in minutes); iOS → submitted for Apple review (1–2 days,
#    then click "Release this version" in App Store Connect).
bundle exec fastlane promote_release version:1.0.9
```

> **WSL silent-push bug:** fastlane's `git push` from WSL can fail with `/mnt/c/Program: not found`
> (space in the credential-manager path) *after* the local commit + tag are created — "Successfully
> committed" prints but nothing reaches GitHub and no release workflow fires. After
> `create_release`/`bump`, always verify from PowerShell:
>
> ```powershell
> git ls-remote --tags origin v1.0.9
> # If empty:
> git push origin main
> git push origin v1.0.9    # this push triggers the release workflows
> ```
>
> Then confirm CI fired: `gh run list --workflow=release.yml` and
> `gh run list --workflow=release-ios.yml`. Permanent fix (one-time WSL setup):
> [`wsl-git-credentials.md`](wsl-git-credentials.md).

### All lanes

| Lane (WSL unless noted) | Does |
|---|---|
| `create_release version:X.Y.Z build:N` | bump + tag + push; CI ships to Play beta + TestFlight |
| `promote_release version:X.Y.Z` | Play beta → production; iOS submit for App Store review |
| `bump version:X.Y.Z build:N` | bump + tag + push only |
| `android promote from:beta to:production` | Play Store track promotion only |
| `android update_listing` | upload Play listing images (screenshots + feature graphic) only |
| `android deploy [track:internal\|alpha\|beta\|production]` | upload an existing AAB |
| `android build` | build signed AAB — **Windows terminal only** |
| `ios release` / `ios build` / `ios deploy` | full TestFlight flow / build only / upload existing IPA — **macOS only** |
| `ios metadata` | upload App Store metadata + screenshots (no submission) |
| `ios submit` | metadata + submit latest TestFlight build for review |

### Manual Android release

```bash
flutter build appbundle --release            # Windows (PowerShell/Git Bash)
bundle exec fastlane android deploy          # WSL; add track:… for non-internal
```

### iOS

CI-only (`release-ios.yml` on every `v*` tag; or Actions → "Release to App Store" → Run workflow).
No local iOS build path exists from Windows/WSL. One-time setup checklist:
[`.agents/memory/ios_setup.md`](../.agents/memory/ios_setup.md).

## Store assets & metadata

- Android listing images (screenshots + feature graphic): `fastlane/metadata/android/en-US/images/`
  in fastlane `supply` layout (`phoneScreenshots/`, `sevenInchScreenshots/`, `tenInchScreenshots/`,
  `featureGraphic.png`). iOS screenshots: `fastlane/screenshots/en-US/`.
- Recapture from the running app with `store/capture_screenshots.ps1` (drives
  `lib/main_screenshots.dart` on an emulator, then `store/process_screenshots.py` fans out to all
  store sizes, writing straight into the two directories above).
- Play listing images upload automatically with `promote_release` / `promote_release_android`, or
  on demand with `bundle exec fastlane android update_listing` (WSL). They are **not** uploaded by
  the beta `release`/`deploy` lanes — a recapture goes live at the next promote unless you push it
  with `update_listing`.
- App Store text metadata: `fastlane/metadata/en-US/`.

## Privacy policy & support pages

Hosted at `https://www.useunix.com/soccer-assistant-coach/` on the self-hosted nginx box
(LAN `192.168.2.1`, docroot `/var/www/html/`). Sources in [`docs/`](.) — `privacy-policy.html`,
`contact.html`, `data-safety.html`, `index.html`, `robots.txt`. Redeploy after edits (the `www`
user needs no sudo; SSH key auth is configured):

```powershell
scp docs/*.html docs/robots.txt www@192.168.2.1:/var/www/html/soccer-assistant-coach/
scp -r docs/screenshots www@192.168.2.1:/var/www/html/soccer-assistant-coach/
```
