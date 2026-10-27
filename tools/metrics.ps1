# metrics.ps1 - ledger metrics. Reads usage\ledger-*.md, writes usage\metrics.csv and usage\metrics.md. No model calls.
# ASCII only, PowerShell 5.1.   Usage: powershell -File tools\metrics.ps1 [-Root path] [-Baseline 2026-10-22]
param(
  [string]$Root = 'D:\Command Center',
  [string]$Baseline = '2026-10-22'
)
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'cc-lib.ps1')

function Get-Type($r) {
  $a = $r.Assignment
  if ($a -match '(?i)\bboot\b|handoff') { return 'boot-handoff' }
  if ($a -match '(?i)texture|block pack|silhouette|animation|\banim|vfx|\bart\b|hero') { return 'art-anim' }
  if ($a -match '(?i)review|audit|critique|verify|check|test run|mode a') { return 'review-audit' }
  if ($a -match '(?i)study|survey|\bscan|\bfind|trace|\bread\b|catalogue|digest|research|report|\bplan\b|diagnos|tally') { return 'research' }
  if ($a -match '(?i)PR\s*#|merge|build|implement|\bfix|ship|\badd\b|\bwire|\bport\b|refactor|create|write') { return 'build' }
  if ($a -match '(?i)\bcopy|ledger|skill|settings|\bCI\b|runner|vault|notes|token|\btools?\b|setup|apply|announce') { return 'chore' }
  return 'other'
}
function Get-Median($vals) {
  $v = @($vals | Where-Object { $_ -gt 0 } | Sort-Object)
  if ($v.Count -eq 0) { return 0 }
  $m = [int][math]::Floor($v.Count / 2)
  if ($v.Count % 2 -eq 1) { return [long]$v[$m] }
  return [long](($v[$m - 1] + $v[$m]) / 2)
}
function Get-Stats($rows, [string]$date, [string]$type, [string]$model) {
  $rows = @($rows)
  $pass = @($rows | Where-Object { $_.Class -eq 'pass' }).Count
  $redo = @($rows | Where-Object { $_.Class -eq 'redo' }).Count
  $esc = @($rows | Where-Object { $_.Class -eq 'escalated' }).Count
  $closed = $pass + $redo + $esc
  $pr = ''; $rr = ''
  if ($closed -gt 0) { $pr = [math]::Round(100.0 * $pass / $closed, 1); $rr = [math]::Round(100.0 * $redo / $closed, 1) }
  [pscustomobject][ordered]@{
    date = $date; type = $type; model = $model; rows = $rows.Count; pass = $pass; first_try_pass_pct = $pr
    redo = $redo; redo_pct = $rr; escalated = $esc
    median_tokens = (Get-Median ($rows | ForEach-Object { $_.TokNum }))
    q_rows = @($rows | Where-Object { $_.Acct -eq '?' -or $_.Gen -eq '?' }).Count
    unclosed = @($rows | Where-Object { $_.Class -eq 'running' -or $_.Class -eq 'pending' }).Count
    kb_rows = @($rows | Where-Object { $_.Kb.Count -gt 0 }).Count
  }
}
function Get-ModelKey($r) { if ($r.IsApi) { return $r.Family + ' (api)' } else { return $r.Family } }

$rows = @(Get-LedgerRows $Root)
foreach ($r in $rows) { $r | Add-Member -NotePropertyName Type -NotePropertyValue (Get-Type $r) -Force; $r | Add-Member -NotePropertyName MKey -NotePropertyValue (Get-ModelKey $r) -Force }
$out = New-Object System.Collections.ArrayList
[void]$out.Add((Get-Stats $rows 'ALL' 'ALL' 'ALL'))
$dates = @($rows | ForEach-Object { $_.Date } | Sort-Object -Unique)
foreach ($d in $dates) {
  $dr = @($rows | Where-Object { $_.Date -eq $d })
  [void]$out.Add((Get-Stats $dr $d 'ALL' 'ALL'))
  foreach ($t in @($dr | ForEach-Object { $_.Type } | Sort-Object -Unique)) {
    foreach ($m in @($dr | Where-Object { $_.Type -eq $t } | ForEach-Object { $_.MKey } | Sort-Object -Unique)) {
      [void]$out.Add((Get-Stats @($dr | Where-Object { $_.Type -eq $t -and $_.MKey -eq $m }) $d $t $m))
    }
  }
}
$csv = Join-Path $Root 'usage\metrics.csv'
$out | Export-Csv -LiteralPath $csv -NoTypeInformation -Encoding ASCII

function Get-MdTable($items, [string[]]$cols) {
  $l = New-Object System.Collections.ArrayList
  [void]$l.Add('| ' + ($cols -join ' | ') + ' |')
  [void]$l.Add('|' + (($cols | ForEach-Object { '---' }) -join '|') + '|')
  foreach ($i in $items) { [void]$l.Add('| ' + (($cols | ForEach-Object { [string]$i.$_ }) -join ' | ') + ' |') }
  return $l
}
$now = Get-NowET
$md = New-Object System.Collections.ArrayList
[void]$md.Add('# Ledger metrics')
[void]$md.Add('')
[void]$md.Add('Generated ' + $now.ToString('yyyy-MM-dd HH:mm zzz') + ' by tools\metrics.ps1 from usage\ledger-*.md (' + $rows.Count + ' rows). Do not edit.')
[void]$md.Add('First-try pass % = pass / (pass + redo + escalated). A redo row marks a failed try, and the later pass row of the retry also counts as a pass, so the rate is flattering. "q" = acct or gen is "?". Unclosed = running or pending. Type is guessed from the assignment text.')
[void]$md.Add('')
[void]$md.Add('## By date')
$cols = @('date', 'rows', 'pass', 'first_try_pass_pct', 'redo', 'redo_pct', 'escalated', 'median_tokens', 'q_rows', 'unclosed', 'kb_rows')
foreach ($x in (Get-MdTable @($out | Where-Object { $_.type -eq 'ALL' }) $cols)) { [void]$md.Add($x) }
[void]$md.Add('')
[void]$md.Add('## By assignment type (all dates)')
$cols2 = @('type', 'rows', 'pass', 'first_try_pass_pct', 'redo', 'redo_pct', 'escalated', 'median_tokens', 'q_rows', 'unclosed', 'kb_rows')
$bt = @($rows | ForEach-Object { $_.Type } | Sort-Object -Unique | ForEach-Object { $t = $_; Get-Stats @($rows | Where-Object { $_.Type -eq $t }) 'ALL' $t 'ALL' })
foreach ($x in (Get-MdTable $bt $cols2)) { [void]$md.Add($x) }
[void]$md.Add('')
[void]$md.Add('## By model (all dates)')
$cols3 = @('model', 'rows', 'pass', 'first_try_pass_pct', 'redo', 'redo_pct', 'escalated', 'median_tokens', 'q_rows', 'unclosed', 'kb_rows')
$bm = @($rows | ForEach-Object { $_.MKey } | Sort-Object -Unique | ForEach-Object { $m = $_; Get-Stats @($rows | Where-Object { $_.MKey -eq $m }) 'ALL' 'ALL' $m })
foreach ($x in (Get-MdTable $bm $cols3)) { [void]$md.Add($x) }
[void]$md.Add('')
[void]$md.Add('## By type and model per date')
[void]$md.Add('See usage\metrics.csv (one row per date x type x model).')
$base = @($rows | Where-Object { $_.Date -eq $Baseline })
$bs = Get-Stats $base $Baseline 'ALL' 'ALL'
[void]$md.Add('')
[void]$md.Add('## Baseline ' + $Baseline)
[void]$md.Add(('rows {0}, first-try pass {1}%, redo {2}%, escalated {3}, median tokens {4}, "?" rows {5}, unclosed {6}, rows with Kb ids {7}' -f $bs.rows, $bs.first_try_pass_pct, $bs.redo_pct, $bs.escalated, $bs.median_tokens, $bs.q_rows, $bs.unclosed, $bs.kb_rows))
Write-Text (Join-Path $Root 'usage\metrics.md') (($md -join "`r`n") + "`r`n") $false

Write-Output ('metrics: {0} rows over {1} date(s) -> usage\metrics.csv ({2} lines), usage\metrics.md ({3} lines)' -f $rows.Count, $dates.Count, ($out.Count + 1), $md.Count)
Write-Output ('BASELINE ' + $Baseline + ': rows={0} first-try pass={1}% redo={2}% (redo rows {3}) escalated={4} median tokens={5} "?" rows={6} unclosed={7} Kb rows={8}' -f $bs.rows, $bs.first_try_pass_pct, $bs.redo_pct, $bs.redo, $bs.escalated, $bs.median_tokens, $bs.q_rows, $bs.unclosed, $bs.kb_rows)
foreach ($m in @($base | ForEach-Object { $_.MKey } | Sort-Object -Unique)) {
  $s = Get-Stats @($base | Where-Object { $_.MKey -eq $m }) $Baseline 'ALL' $m
  Write-Output ('  {0,-14} rows={1} pass={2}% redo={3} esc={4} medTok={5} unclosed={6}' -f $m, $s.rows, $s.first_try_pass_pct, $s.redo, $s.escalated, $s.median_tokens, $s.unclosed)
}
