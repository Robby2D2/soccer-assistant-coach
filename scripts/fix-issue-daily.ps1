# Daily automated run of the /fix-issue orchestrator.
# Triggered by Windows Task Scheduler — see install-fix-issue-task.ps1 for setup.
# Logs land in .claude/logs/fix-issue-<date>.log (already gitignored via *.log).

$ErrorActionPreference = "Continue"

$repo = "C:\Users\rdane\Documents\Projects\soccer-assistant-coach"
$logDir = Join-Path $repo ".claude\logs"
$null = New-Item -ItemType Directory -Force $logDir
$log = Join-Path $logDir ("fix-issue-{0}.log" -f (Get-Date -Format 'yyyy-MM-dd'))

Set-Location $repo

"`n=== /fix-issue daily run at $(Get-Date -Format 's') ===" | Out-File -FilePath $log -Append -Encoding utf8

& claude --print --dangerously-skip-permissions "/fix-issue" 2>&1 |
    Out-File -FilePath $log -Append -Encoding utf8

"=== finished at $(Get-Date -Format 's'), exit code $LASTEXITCODE ===" | Out-File -FilePath $log -Append -Encoding utf8
