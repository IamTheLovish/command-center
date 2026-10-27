# install-jobs.ps1 - registers the 5 "CC <job>" scheduled tasks for the current user (run only when logged on, no admin).
# Same pattern as janitor\install-janitor.ps1. Remove with uninstall-jobs.ps1. Pause everything with an empty file D:\Command Center\PAUSED.
$ErrorActionPreference = 'Stop'
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$vbs = Join-Path $here 'launch.vbs'
$settings = New-ScheduledTaskSettingsSet -MultipleInstances IgnoreNew -ExecutionTimeLimit (New-TimeSpan -Minutes 30) -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable
$daily = @{ 'ledger-tally' = '02:00'; 'flake-digest' = '02:30'; 'auditor' = '03:00'; 'stale-sweep' = '07:00' }
$desc = @{
  'main-red'     = 'Every 30 min: writes notes\MAIN-RED.md when build.yml on main is red, clears it when green.'
  'ledger-tally' = 'Nightly: cc tally, metrics, ledger-lint, kb learn (when the cursor exists).'
  'flake-digest' = 'Nightly: 24 h flake digest with a proposed known_flakes.txt diff (notes\FLAKES-date.md). Never edits the repo.'
  'auditor'      = 'Nightly: usage auditor Mode 2 via the API (sonnet) -> auditor\daily and auditor\advice.'
  'stale-sweep'  = 'Daily: stale PRs, red drafts, branches with no PR, expired claims (notes\STALE.md).'
}
foreach ($job in @('main-red', 'ledger-tally', 'flake-digest', 'auditor', 'stale-sweep')) {
  $action = New-ScheduledTaskAction -Execute 'wscript.exe' -Argument ('"' + $vbs + '" ' + $job)
  if ($job -eq 'main-red') {
    $trg = New-ScheduledTaskTrigger -Once -At (Get-Date).AddMinutes(2) -RepetitionInterval (New-TimeSpan -Minutes 30) -RepetitionDuration (New-TimeSpan -Days 3650)
  } else {
    $trg = New-ScheduledTaskTrigger -Daily -At $daily[$job]
  }
  Register-ScheduledTask -TaskName ('CC ' + $job) -Action $action -Trigger $trg -Settings $settings -Description $desc[$job] -Force | Out-Null
  $i = Get-ScheduledTaskInfo -TaskName ('CC ' + $job)
  Write-Output ('registered CC ' + $job + ' next run ' + $i.NextRunTime)
}
