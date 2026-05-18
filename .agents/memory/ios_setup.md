# iOS CI Setup Checklist

One-time steps required before the `release-ios.yml` GitHub Actions workflow will succeed.

## 1. Create an App Store Connect API Key

1. Go to [App Store Connect → Users & Access → Integrations → App Store Connect API](https://appstoreconnect.apple.com/access/integrations/api)
2. Create a new key with **Developer** role (or Admin if needed)
3. Download the `.p8` file — you can only download it once
4. Note the **Key ID** and **Issuer ID** shown on the page

## 2. Create a Private GitHub Repo for Match

Match stores distribution certificates and provisioning profiles in an encrypted git repo.

1. Create a new **private** repo on GitHub, e.g. `soccer-assistant-coach-certificates`
2. Create a GitHub **Personal Access Token (classic)** with `repo` scope at https://github.com/settings/tokens
3. Base64-encode your credentials for `MATCH_GIT_BASIC_AUTHORIZATION`:
   ```bash
   echo -n "your_github_username:your_personal_access_token" | base64
   ```

## 3. Initialize Match (run once from macOS)

```bash
cd /path/to/soccer-assistant-coach
export MATCH_GIT_URL="https://github.com/your-username/soccer-assistant-coach-certificates.git"
export APP_STORE_CONNECT_KEY_ID="XXXXXXXXXX"
export APP_STORE_CONNECT_ISSUER_ID="xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
export APP_STORE_CONNECT_KEY_CONTENT="$(base64 -i /path/to/AuthKey_XXXXXXXXXX.p8)"

bundle exec fastlane match init        # enter the git URL and a strong passphrase
bundle exec fastlane match appstore    # generates dist cert + App Store provisioning profile
```

Match will create the `fastlane/Matchfile` (already committed) and populate the certificates repo.

## 4. Add GitHub Actions Secrets

Go to the repo → Settings → Secrets and variables → Actions, and add:

| Secret name | Value |
|---|---|
| `APP_STORE_CONNECT_KEY_ID` | Key ID from App Store Connect (e.g. `AB12CD34EF`) |
| `APP_STORE_CONNECT_ISSUER_ID` | Issuer ID UUID from App Store Connect |
| `APP_STORE_CONNECT_KEY_CONTENT` | Base64-encoded contents of the `.p8` file: `base64 -i AuthKey_XXX.p8` |
| `MATCH_PASSWORD` | Passphrase chosen during `fastlane match init` |
| `MATCH_GIT_URL` | HTTPS URL of the certificates repo (e.g. `https://github.com/you/soccer-assistant-coach-certificates.git`) |
| `MATCH_GIT_BASIC_AUTHORIZATION` | Base64 of `username:personal_access_token` (from step 2) |

## 5. Verify the App Exists in App Store Connect

Ensure `com.useunix.soccerassistantcoach` is registered as an app in App Store Connect before the first upload.

## Notes

- Team ID: `DPS86D59PK`
- Bundle ID: `com.useunix.soccerassistantcoach`
- The `release-ios.yml` workflow runs on `macos-14` and is triggered automatically on every `v*` tag push alongside the Android workflow
- **Do not use `macos-13`** — queue wait times exceed 45 minutes in practice
- **Do not use `macos-latest` (macos-15)** — had persistent 6-hour hangs during testing
- **Admin API key required** — the App Store Connect key must have Admin role (not Developer). Developer role cannot create Distribution certificates, causing Match to fail
- All 6 secrets are configured in the repo: `APP_STORE_CONNECT_KEY_ID`, `APP_STORE_CONNECT_ISSUER_ID`, `APP_STORE_CONNECT_KEY_CONTENT`, `MATCH_PASSWORD`, `MATCH_GIT_URL`, `MATCH_GIT_BASIC_AUTHORIZATION`
- Match certificates repo is populated and ready
- One-time steps are complete as of 2026-05-18
