fastlane documentation
----

# Installation

Make sure you have the latest version of the Xcode command line tools installed:

```sh
xcode-select --install
```

For _fastlane_ installation instructions, see [Installing _fastlane_](https://docs.fastlane.tools/#installing-fastlane)

# Available Actions

### bump

```sh
[bundle exec] fastlane bump
```

Bump pubspec.yaml version, commit, tag, and push to trigger CI. Usage: bump version:1.0.5 build:5

### create_release

```sh
[bundle exec] fastlane create_release
```

Create a new release: bump version, tag, push. CI builds and ships to Play Store beta + TestFlight. Usage: create_release version:1.0.9 build:10

### promote_release

```sh
[bundle exec] fastlane promote_release
```

Promote v.X.Y.Z to production: submit iOS TestFlight build to Apple review, THEN promote Play Store beta to production. Usage: promote_release version:1.0.9

### promote_release_android

```sh
[bundle exec] fastlane promote_release_android
```

Promote ONLY Android beta to production (useful for partial recovery if a previous promote_release succeeded iOS but failed Android, or to roll Android forward independently). Usage: promote_release_android

### promote_release_ios

```sh
[bundle exec] fastlane promote_release_ios
```

Submit ONLY iOS TestFlight build for App Store review (useful for retrying iOS-only after fixing metadata/screenshot issues). Usage: promote_release_ios

----


## Android

### android build

```sh
[bundle exec] fastlane android build
```

Build a signed release AAB. Run from a Windows terminal (PowerShell/Git Bash), NOT from WSL — the Flutter SDK shell scripts have Windows line endings that break under WSL.

### android deploy

```sh
[bundle exec] fastlane android deploy
```

Upload AAB to Play Store. Run from WSL. Pass track:"internal"|"alpha"|"beta"|"production" (default: internal)

### android release

```sh
[bundle exec] fastlane android release
```

Build a signed AAB and upload to Play Store (default: internal track). Used by release.yml CI on tag push; runs end-to-end on the ubuntu-latest runner where Flutter SDK shell scripts have UNIX line endings.

### android promote

```sh
[bundle exec] fastlane android promote
```

Promote an existing release from one track to another. Run from WSL. Usage: promote from:internal to:beta

----


## iOS

### ios init_match

```sh
[bundle exec] fastlane ios init_match
```

One-time Match initialization — generates dist cert + App Store provisioning profile.

### ios setup_signing

```sh
[bundle exec] fastlane ios setup_signing
```

Sync certs and configure signing. Called by CI before flutter build ipa.

### ios release

```sh
[bundle exec] fastlane ios release
```

Upload an existing IPA to TestFlight. Set IPA_PATH env var or let it fall back to glob.

### ios build

```sh
[bundle exec] fastlane ios build
```

Sync certs and configure signing (local use). Run from macOS.

### ios deploy

```sh
[bundle exec] fastlane ios deploy
```

Upload an existing IPA at build/ios/ipa/*.ipa to TestFlight.

### ios metadata

```sh
[bundle exec] fastlane ios metadata
```

Upload metadata and screenshots to App Store Connect without submitting for review. Run from WSL.

### ios submit

```sh
[bundle exec] fastlane ios submit
```

Upload metadata, screenshots, and submit the latest TestFlight build for App Store review. Run from WSL.

----

This README.md is auto-generated and will be re-generated every time [_fastlane_](https://fastlane.tools) is run.

More information about _fastlane_ can be found on [fastlane.tools](https://fastlane.tools).

The documentation of _fastlane_ can be found on [docs.fastlane.tools](https://docs.fastlane.tools).
