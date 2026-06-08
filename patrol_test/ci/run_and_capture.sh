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
# Total-0 retry: patrol intermittently fails with "Total: 0 / Gradle test execution failed
# with code 1" — the connectedAndroidTest gradle task bails before instrumentation runs, so no
# Dart test code ever executes. There is no test result to mask: the suite has produced exactly
# zero outcomes. A one-shot retry costs ~45 s and shakes off this pre-existing flake. A real
# failure (Total: >0, Failed: >0) does NOT match the guard and falls through unchanged.
#
# Exits with patrol's real status so the gate still fails on a genuinely red test.
set +e

test_target="$1"

run_patrol() {
  "$HOME/.pub-cache/bin/patrol" test -t "$test_target" -d emulator-5554 2>&1 | tee patrol.log
  return "${PIPESTATUS[0]}"
}

run_patrol
status=$?

# Flake guard: non-zero exit + "Total: 0" => gradle never handed off to the instrumented test.
# A genuine red test reports Total: 1 with Failed: 1, so it will not match this regex.
if [ "$status" -ne 0 ] && grep -q "Total: 0" patrol.log; then
  echo "::warning::patrol reported Total: 0 (gradle bailed before instrumentation) — retrying once"
  run_patrol
  status=$?
fi

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
