# Publish Release

Walk the user through publishing a new release of Soccer Assistant Coach to both the Google Play Store and Apple App Store.

## Your role

You are a release manager for this Flutter app. Work through the steps below sequentially, running commands and asking for confirmation at each stage. Do not skip steps. Track progress with the TodoWrite tool.

## Steps

### 1. Gather release info

Ask the user:
- What is the new version number? (e.g. `1.0.7`)
- What is the new build number? (e.g. `9` — must be higher than the last one; check `pubspec.yaml` for the current value)
- What changed in this release? (plain English — you will write the release notes from this)

### 2. Update release notes

Write the user's answer (polished into 1–3 sentences) to `fastlane/metadata/en-US/release_notes.txt`. Keep it under 4000 characters. This is what users see in the App Store and Play Store "What's New" section.

### 3. Bump the version

Run from WSL:
```
wsl bash -c "cd /mnt/c/Users/rdane/Documents/Projects/soccer-assistant-coach && bundle exec fastlane bump version:VERSION build:BUILD 2>&1"
```
Replace VERSION and BUILD with the values from step 1. This commits pubspec.yaml, tags the release, and pushes — which triggers both the Android AAB build and the iOS IPA build in GitHub Actions.

Confirm the tag was pushed successfully before continuing.

### 4. Build the Android AAB

The AAB must be built from Windows (not WSL) because the Flutter SDK scripts have Windows line endings that break under WSL.

Tell the user to run this in PowerShell or Git Bash (not WSL):
```
flutter build appbundle --release
```
Ask the user to confirm when the build finishes successfully before continuing.

### 5. Upload Android AAB to Play Store

Run from WSL:
```
wsl bash -c "cd /mnt/c/Users/rdane/Documents/Projects/soccer-assistant-coach && bundle exec fastlane android deploy 2>&1"
```
This uploads to the internal track by default. Confirm it succeeded.

Ask the user: do you want to promote straight to production, or test internally first?
- If production: run `bundle exec fastlane android deploy track:production`
- If internal first: remind them to promote later with `bundle exec fastlane android promote from:internal to:production`

### 6. Upload iOS metadata

Run from WSL:
```
wsl bash -c "cd /mnt/c/Users/rdane/Documents/Projects/soccer-assistant-coach && bundle exec fastlane ios metadata 2>&1"
```
This uploads the description, keywords, screenshots, copyright, and app review information to App Store Connect. Confirm all steps succeeded (look for "fastlane finished successfully").

### 7. Wait for iOS CI build

The iOS IPA is built by GitHub Actions (triggered by the tag push in step 3). It takes about 15–20 minutes. Tell the user to check the Actions tab on GitHub, or the TestFlight tab in App Store Connect, and confirm the build has finished processing before continuing.

### 8. Submit iOS for App Store review

Run from WSL:
```
wsl bash -c "cd /mnt/c/Users/rdane/Documents/Projects/soccer-assistant-coach && bundle exec fastlane ios submit 2>&1"
```
This selects the latest TestFlight build and submits it for App Store review. Confirm it succeeded.

### 9. Wrap up

Summarize what was completed:
- Version bumped and tagged
- Android AAB uploaded to Play Store
- iOS metadata uploaded
- iOS build submitted for App Store review

Remind the user:
- Apple review takes ~24–48 hours. When approved, go to App Store Connect and click **Release**.
- To promote Android from internal → production when ready: `bundle exec fastlane android promote from:internal to:production`

## Notes

- All `bundle exec fastlane` commands must run from WSL. Use `wsl bash -c "cd /mnt/c/... && bundle exec fastlane ..."` to run them from this session.
- The `fastlane/.env` file holds the App Store Connect API credentials locally. If a command fails with "No value found for key_id", the user needs to check that file.
- If `ios metadata` fails with "No data", add `app_review_information` to the lane (already present) and retry — it's a known Fastlane bug on first run for a new version.
- If `ios metadata` fails with "Precheck cannot check In-app purchases", that's already fixed with `precheck_include_in_app_purchases: false`.
- Set a timeout of 5 minutes on each WSL command — Fastlane can occasionally hang.
