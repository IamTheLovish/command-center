# ledger-tally.ps1 - nightly: cc.ps1 tally, metrics.ps1, cc.ps1 ledger-lint (if present), kb.ps1 learn (only if kb.ps1 has the
# learn cursor and the model budget is open). Output summary: notes\LEDGER-TALLY.md. gh: none. Model: haiku via kb.ps1 learn only.
# Note: metrics.ps1 writes usage\metrics.*, kb.ps1 learn writes knowledge\ - both are the existing tools' own outputs.
param([string]$Root = 'D:\Command Center', [int]$ModelOk = 0, [string]$Date = '')
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'job-lib.ps1')
Init-Lib $Root $ModelOk
$day = Get-DayDefault $Date
$tools = Join-Path $Root 'tools'
$cc = Join-Path $tools 'cc.ps1'; $kb = Join-Path $tools 'kb.ps1'; $mx = Join-Path $tools 'metrics.ps1'
$sb = New-Object System.Text.StringBuilder
[void]$sb.AppendLine('# Ledger tally (job ledger-tally)')
[void]$sb.AppendLine('')
[void]$sb.AppendLine('updated: ' + (Get-Date).ToString('yyyy-MM-dd HH:mm') + ' | day tallied: ' + $day)
$fail = $false; $notes = New-Object System.Collections.ArrayList

function Add-Step([string]$title, $r, [int]$maxLines = 60) {
  [void]$sb.AppendLine('')
  [void]$sb.AppendLine('## ' + $title + ' (exit ' + $r.code + ')')
  [void]$sb.AppendLine('```')
  foreach ($l in (($r.text -split "`r?`n") | Select-Object -First $maxLines)) { [void]$sb.AppendLine($l) }
  [void]$sb.AppendLine('```')
}

$t = Invoke-Cc @($cc, 'tally', '-Date', $day)
Add-Step "cc.ps1 tally -Date $day" $t
if ($t.code -ne 0) { $fail = $true; [void]$notes.Add('tally failed') }

if (Test-Path -LiteralPath $mx) {
  $m = Invoke-Cc @($mx)
  Add-Step 'metrics.ps1' $m 25
  if ($m.code -ne 0) { $fail = $true; [void]$notes.Add('metrics failed') }
} else { [void]$sb.AppendLine(''); [void]$sb.AppendLine('metrics.ps1 missing - skipped'); [void]$notes.Add('metrics absent') }

if (Select-String -LiteralPath $cc -Pattern "'ledger-lint'" -Quiet) {
  $l = Invoke-Cc @($cc, 'ledger-lint', '-Date', $day)
  Add-Step "cc.ps1 ledger-lint -Date $day" $l 40
  [void]$notes.Add('lint exit ' + $l.code)    # lint findings are information, not a job failure
} else { [void]$sb.AppendLine(''); [void]$sb.AppendLine('ledger-lint not in cc.ps1 yet - skipped'); [void]$notes.Add('lint absent') }

$hasCursor = (Select-String -LiteralPath $kb -Pattern 'learn-cursor.json' -Quiet) -and (Select-String -LiteralPath $kb -Pattern 'function Cmd-Learn' -Quiet)
if (-not $hasCursor) {
  [void]$sb.AppendLine(''); [void]$sb.AppendLine('kb.ps1 learn skipped: kb.ps1 has no learn cursor yet (it could re-process rows)'); [void]$notes.Add('learn skipped: no cursor')
} elseif ($ModelOk -ne 1) {
  [void]$sb.AppendLine(''); [void]$sb.AppendLine('kb.ps1 learn skipped: model budget closed'); [void]$notes.Add('learn skipped: budget')
} else {
  $k = Invoke-Cc @($kb, 'learn', '-Date', $day)
  Add-Step "kb.ps1 learn -Date $day" $k 30
  if ($k.code -ne 0) { $fail = $true; [void]$notes.Add('learn failed') } else { [void]$notes.Add('learn ok') }
}
Write-Out (Join-Path $Root 'notes\LEDGER-TALLY.md') $sb.ToString()
Write-Output ('SUMMARY: day=' + $day + ' ' + ($notes -join '; '))
if ($fail) { exit 1 }
