# Capture real marketing screenshots from a connected Android emulator.
#
# Pipeline:
#   1. Verifies a device/emulator is connected.
#   2. Launches `flutter run -t lib/main_screenshots.dart` in the background.
#      That entry-point seeds an in-memory DB from the scrubbed marketing
#      fixture and cycles through the marketing routes, writing a marker
#      file (`/sdcard/Android/data/<pkg>/files/screenshot_ready_<name>`)
#      between each navigation and waiting for the runner to delete it.
#   3. For each expected marker, polls the device via `adb shell ls`. When
#      the marker appears, captures the screen with `adb exec-out screencap
#      -p` and deletes the marker so the app advances to the next screen.
#   4. Kills the app and hands off to `process_screenshots.py` to resize
#      to all store dimensions (phone, tablet7, tablet10, iPhone 6.7", 6.9").
#
# Prereqs:
#   - Android emulator running and visible to `flutter devices`
#   - `flutter pub get` already run
#
# Run from the project root:
#   .\store\capture_screenshots.ps1

$ErrorActionPreference = 'Stop'

$pkg       = 'com.useunix.soccerassistantcoach'
$markerDir = "/sdcard/Android/data/$pkg/files"
$rawDir    = Join-Path $PSScriptRoot 'raw'
$screens   = @('team_landing', 'teams', 'formations', 'live_game', 'roster', 'stats')

if (-not (Test-Path $rawDir)) { New-Item -ItemType Directory -Path $rawDir | Out-Null }

# 1. Confirm exactly one Android device/emulator.
$adbDevices = @(& adb devices | Select-Object -Skip 1 | Where-Object { $_ -match "device$" })
if ($adbDevices.Count -eq 0) {
    throw 'No Android emulator/device connected. Start one with: flutter emulators --launch <id>'
}
$deviceId = ($adbDevices[0] -split "`t")[0]
Write-Host "Using device: $deviceId"

# 2. Clean any stale markers on the device.
& adb shell "rm -f $markerDir/screenshot_ready_*" 2>$null | Out-Null

# 3. Launch flutter run in the background. Output goes to a log we can tail
#    if anything goes wrong.
$projectRoot = Resolve-Path (Join-Path $PSScriptRoot '..')
$logPath     = Join-Path $rawDir 'flutter-run.log'
Write-Host "Launching flutter run -t lib/main_screenshots.dart (log: $logPath)..."
# Use the .bat shim explicitly so Start-Process doesn't choke on PATHEXT.
$flutterCmd = (Get-Command flutter.bat).Source
$flutter = Start-Process -FilePath $flutterCmd `
    -ArgumentList @(
        'run',
        '-t', 'lib/main_screenshots.dart',
        '-d', $deviceId,
        '--no-hot'
    ) `
    -WorkingDirectory $projectRoot `
    -RedirectStandardOutput $logPath `
    -RedirectStandardError "$logPath.err" `
    -NoNewWindow -PassThru

try {
    # 4. For each expected screen, poll for marker, screencap, delete marker.
    foreach ($name in $screens) {
        $marker  = "$markerDir/screenshot_ready_$name"
        $outFile = Join-Path $rawDir "$name.png"
        Write-Host -NoNewline "Waiting for '$name'..."

        # First marker may take 60-90s (Gradle + APK install). Subsequent
        # markers should appear within seconds.
        $timeoutSec = if ($name -eq $screens[0]) { 300 } else { 60 }
        $deadline   = (Get-Date).AddSeconds($timeoutSec)
        $found      = $false
        while ((Get-Date) -lt $deadline) {
            if ($flutter.HasExited) {
                throw "flutter run exited before producing marker '$name'. See $logPath."
            }
            $ls = & adb shell "ls $marker 2>/dev/null"
            if ($ls -and $ls.Trim() -eq $marker) { $found = $true; break }
            Start-Sleep -Milliseconds 800
        }
        if (-not $found) {
            throw "Timed out waiting for marker '$name' after $timeoutSec sec. See $logPath."
        }

        Write-Host " capturing -> $outFile"
        # Don't use `>` — PowerShell mangles binary streams with CRLF insertion.
        # Take the screencap on-device, then `adb pull` the file (binary-safe).
        $devicePng = "/sdcard/$name.png"
        & adb shell "screencap -p $devicePng" | Out-Null
        # adb pull always writes its progress line to stderr (even on success).
        # PowerShell 5.1's $ErrorActionPreference=Stop turns that into a fatal
        # NativeCommandError, so locally relax it for this one command and
        # consult $LASTEXITCODE to detect real failures.
        $prevEAP = $ErrorActionPreference
        $ErrorActionPreference = 'Continue'
        & adb pull $devicePng $outFile 2>&1 | Out-Null
        $pullCode = $LASTEXITCODE
        $ErrorActionPreference = $prevEAP
        if ($pullCode -ne 0) {
            throw "adb pull failed for '$name' (exit $pullCode)."
        }
        & adb shell "rm -f $devicePng" | Out-Null
        $size = (Get-Item $outFile).Length
        if ($size -lt 1024) {
            throw "screencap produced a tiny file ($size bytes) for '$name'."
        }

        # Delete marker so the app advances.
        & adb shell "rm -f $marker" | Out-Null
    }

    Write-Host 'All screens captured.'
}
finally {
    # 5. Always kill flutter run on the way out (otherwise it stays attached).
    if (-not $flutter.HasExited) {
        Stop-Process -Id $flutter.Id -Force -ErrorAction SilentlyContinue
    }
    & adb shell "am force-stop $pkg" 2>$null | Out-Null
}

# 6. Verify the raw captures landed.
$missing = @()
foreach ($name in $screens) {
    $p = Join-Path $rawDir "$name.png"
    if (-not (Test-Path $p) -or (Get-Item $p).Length -lt 1024) { $missing += $name }
}
if ($missing.Count -gt 0) {
    throw "Missing or empty raw captures: $($missing -join ', ')"
}

# 7. Fan out to all store sizes.
Write-Host 'Resizing to store dimensions...'
& python -X utf8 (Join-Path $PSScriptRoot 'process_screenshots.py')

Write-Host ''
Write-Host 'Done. See:'
Write-Host '  store/raw/                          (native emulator captures)'
Write-Host '  store/assets/                       (Play Store: phone, tablet7, tablet10)'
Write-Host '  fastlane/screenshots/en-US/         (App Store: iPhone 6.7, 6.9)'
