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

# Cap a single test at 11 min. Patrol's 4.x orchestrator can hang WITHIN a test (the gradle
# connectedAndroidTest task never returns). Without a cap that hang runs until the job's
# timeout-minutes and gets force-cancelled — too late for the workflow's shard-level retry to
# fire. `timeout` kills the hang (exit 124, no "Total:" line) so the step fails FAST and the retry
# step can boot a fresh emulator. A normal single test finishes in ~1-2 min, so 11 min is slack.
PATROL_TIMEOUT="${PATROL_TIMEOUT:-660}"

run_patrol() {
  # --no-uninstall keeps the app installed after the test so we can pull its captured
  # screenshots with run-as. By default patrol (AGP 8.2+) uninstalls the app once the test
  # finishes, which wipes its private files dir before the pull ("run-as: unknown package").
  timeout --kill-after=30 "$PATROL_TIMEOUT" \
    "$HOME/.pub-cache/bin/patrol" test -t "$test_target" -d emulator-5554 --no-uninstall 2>&1 \
    | tee patrol.log
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

# Distinguish a GENUINE test failure from an infra flake so the workflow's shard-level retry only
# re-runs flakes, never a real red (which would waste ~13 min re-confirming, or worse, mask it).
# Instrumentation actually ran and reported an outcome iff the log carries a non-zero Total; paired
# with a non-zero exit that's a real failure — drop a marker the workflow gates its retry on
# (hashFiles genuine_failure.flag). A hang (timeout => no Total line) or a gradle bail (Total: 0)
# leaves no marker and is retried on a fresh emulator. CWD here is $GITHUB_WORKSPACE (repo root).
if [ "$status" -ne 0 ] && grep -qE "Total: [1-9]" patrol.log; then
  echo "::warning::patrol reported a genuine test failure — flagging so the retry is skipped"
  touch genuine_failure.flag
fi

# Pull any screenshots the test captured off the (still-installed) app with run-as.
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
