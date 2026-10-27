# uninstall-jobs.ps1 - removes the 5 "CC <job>" scheduled tasks (the Claude Janitor task is not touched).
foreach ($job in @('main-red', 'ledger-tally', 'flake-digest', 'auditor', 'stale-sweep')) {
  $n = 'CC ' + $job
  if (Get-ScheduledTask -TaskName $n -ErrorAction SilentlyContinue) { Unregister-ScheduledTask -TaskName $n -Confirm:$false; Write-Output ('removed ' + $n) }
  else { Write-Output ('not installed: ' + $n) }
}
