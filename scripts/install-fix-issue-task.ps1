# One-time setup: registers a Windows scheduled task that runs the /fix-issue
# orchestrator daily at 5:00 AM local time. Idempotent — re-running replaces
# any existing task with the same name. To remove: Unregister-ScheduledTask -TaskName 'SoccerAssistantCoach-FixIssueDaily' -Confirm:$false

$taskName  = "SoccerAssistantCoach-FixIssueDaily"
$repo      = "C:\Users\rdane\Documents\Projects\soccer-assistant-coach"
$scriptPath = Join-Path $repo "scripts\fix-issue-daily.ps1"

$action = New-ScheduledTaskAction `
    -Execute "powershell.exe" `
    -Argument "-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File `"$scriptPath`"" `
    -WorkingDirectory $repo

$trigger = New-ScheduledTaskTrigger -Daily -At 5am

$settings = New-ScheduledTaskSettingsSet `
    -WakeToRun `
    -StartWhenAvailable `
    -AllowStartIfOnBatteries `
    -DontStopIfGoingOnBatteries `
    -ExecutionTimeLimit (New-TimeSpan -Hours 2)

$principal = New-ScheduledTaskPrincipal `
    -UserId "$env:USERDOMAIN\$env:USERNAME" `
    -LogonType Interactive `
    -RunLevel Limited

if (Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue) {
    Unregister-ScheduledTask -TaskName $taskName -Confirm:$false
}

Register-ScheduledTask `
    -TaskName $taskName `
    -Description "Runs the soccer-assistant-coach /fix-issue orchestrator daily." `
    -Action $action `
    -Trigger $trigger `
    -Settings $settings `
    -Principal $principal | Out-Null

Get-ScheduledTask -TaskName $taskName | Format-List TaskName, State, Triggers, Actions
