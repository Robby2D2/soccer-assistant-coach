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

Upload the already-built AAB to Play Store (default: internal track). Run from WSL.

### android promote

```sh
[bundle exec] fastlane android promote
```

Promote an existing release from one track to another. Run from WSL. Usage: promote from:internal to:beta

----


## iOS

### ios release

```sh
[bundle exec] fastlane ios release
```

Sync certs via Match, build IPA, and upload to TestFlight. Run from macOS.

### ios build

```sh
[bundle exec] fastlane ios build
```

Sync certs via Match and build IPA without uploading. Run from macOS.

### ios deploy

```sh
[bundle exec] fastlane ios deploy
```

Upload an existing IPA at build/ios/ipa/Runner.ipa to TestFlight.

----

This README.md is auto-generated and will be re-generated every time [_fastlane_](https://fastlane.tools) is run.

More information about _fastlane_ can be found on [fastlane.tools](https://fastlane.tools).

The documentation of _fastlane_ can be found on [docs.fastlane.tools](https://docs.fastlane.tools).
