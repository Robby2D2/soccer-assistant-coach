#!/usr/bin/env bash
# Run one patrol journey test on the already-booted emulator, then pull any screenshots the
# test captured (via captureScreenshot — patrol_test/helpers/screenshot.dart) off the app's
# internal support dir with run-as (the patrol debug APK is debuggable, so no root/storage
# perms are needed; exec-out cat is binary-safe).
#
# Why this is a file instead of inline YAML: reactivecircus/android-emulator-runner runs its
# `script:` input line-by-line, each in its own `sh -c`. Inline multi-line logic (a for-loop,
# a $? capture, shell variables) therefore breaks — the loop's `do`/`done` land in different
# shells. Invoking this script as a SINGLE line (one `sh -c` -> `bash <file>`) runs the whole
# thing in one shell, so the logic works.
#
# Exits with patrol's real status so the gate still fails on a genuinely red test.
set +e

test_target="$1"
"$HOME/.pub-cache/bin/patrol" test -t "$test_target" -d emulator-5554
status=$?

pkg=com.useunix.soccerassistantcoach
mkdir -p screenshots
files=$(adb -s emulator-5554 exec-out run-as "$pkg" ls files/screenshots 2>/dev/null | tr -d '\r')
for f in $files; do
  case "$f" in
    *.png)
      adb -s emulator-5554 exec-out run-as "$pkg" cat "files/screenshots/$f" \
        > "screenshots/$f" 2>/dev/null || true
      ;;
  esac
done

exit "$status"
