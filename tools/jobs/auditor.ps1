# auditor.ps1 - nightly: AUDITOR.md Mode 2 via offload.ps1 (sonnet). Inputs: the day's ledger, that day's handoffs, tally and
# metrics, git log of the day (after git fetch), the last 3 daily reports. Writes auditor\daily\<date>.md and, when the model has
# valid advice, auditor\advice\<date>-nightly.md (status: unread). gh: none. git: fetch, log. No batch API in offload.ps1: normal call.
param([string]$Root = 'D:\Command Center', [int]$ModelOk = 0, [string]$Date = '')
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'job-lib.ps1')
Init-Lib $Root $ModelOk
if ($ModelOk -ne 1) { Write-Output 'SUMMARY: skipped, model budget closed'; exit 0 }
$day = Get-DayDefault $Date
$next = ([datetime]::ParseExact($day, 'yyyy-MM-dd', $null)).AddDays(1).ToString('yyyy-MM-dd')
$dailyOut = Join-Path $Root ('auditor\daily\' + $day + '.md')
$adviceOut = Join-Path $Root ('auditor\advice\' + $day + '-nightly.md')

# ---- inputs (all trimmed, ASCII, wrapped as data by Invoke-Model) ----
$ledger = Read-Safe (Join-Path $Root ('usage\ledger-' + $day + '.md')) 40000
if (-not $ledger) { $ledger = '(no ledger file for ' + $day + ')' }
$ho = New-Object System.Text.StringBuilder
$hd = Join-Path $Root 'command-center\handoffs'
if (Test-Path -LiteralPath $hd) {
  foreach ($d in (Get-ChildItem -LiteralPath $hd -Directory | Where-Object { $_.Name -like ('*' + $day + '*') } | Sort-Object Name)) {
    $f = Join-Path $d.FullName 'SELF-DIAGNOSIS.md'; if (-not (Test-Path -LiteralPath $f)) { $f = Join-Path $d.FullName 'HANDOFF.md' }
    if (Test-Path -LiteralPath $f) { [void]$ho.AppendLine('--- ' + $d.Name + '/' + (Split-Path -Leaf $f)); [void]$ho.AppendLine((Read-Safe $f 6000)) }
  }
}
$handoffs = $ho.ToString(); if (-not $handoffs.Trim()) { $handoffs = '(no handoff folders dated ' + $day + ')' }
$tal = Invoke-Cc @((Join-Path $Root 'tools\cc.ps1'), 'tally', '-Date', $day)
$metrics = Read-Safe (Join-Path $Root 'usage\metrics.md') 6000
$gitNote = ''
try { [void](Git-Read @('fetch', 'origin', '--quiet')) } catch { $gitNote = 'git fetch failed (' + (Ascii $_.Exception.Message 120) + '); log may be stale. ' }
try {
  $gl = Git-Read @('log', 'origin/main', ('--since=' + $day + ' 00:00'), ('--until=' + $next + ' 00:00'), '--no-merges', '--date=format:%H:%M', '--format=%h %ad %an: %s', '-n', '150')
} catch { $gl = '(git log failed: ' + (Ascii $_.Exception.Message 120) + ')' }
if (-not $gl.Trim()) { $gl = '(no commits on origin/main that day)' }
$prior = New-Object System.Text.StringBuilder
foreach ($f in (Get-ChildItem -LiteralPath (Join-Path $Root 'auditor\daily') -Filter '*.md' -ErrorAction SilentlyContinue | Where-Object { $_.BaseName -lt $day } | Sort-Object Name -Descending | Select-Object -First 3)) {
  [void]$prior.AppendLine('--- ' + $f.Name); [void]$prior.AppendLine((Read-Safe $f.FullName 3500))
}
$priorTxt = $prior.ToString(); if (-not $priorTxt.Trim()) { $priorTxt = '(no earlier daily reports)' }

$manual = Read-Safe (Join-Path $Root 'auditor\AUDITOR.md') 6000
$instr = @"
You are the Usage Auditor. Your operating manual follows, then the job. Do Mode 2 (end-of-day diagnosis) for $day only.
You cannot read chats or run tools here: use only the data blocks, and say plainly what you could not see. Never invent numbers.
OUTPUT FORMAT, exactly:
1. The daily report in markdown with the six numbered sections from Mode 2, readable in 2 minutes. No frontmatter.
2. Then one line containing only: =====ADVICE=====
3. Then 0 to 5 advice items, or the single word NONE. Each item is exactly three lines, items separated by a blank line:
target: <one of model-routing.md, lessons.md, COMMANDER.md>
rule: <the exact rule wording, ready to apply, one line, no pipe characters>
evidence: <ledger row id, handoff name or commit hash that supports it, plus a short quote>
Advice is applied automatically by a later session, so only write an item when the evidence is concrete and repeated; otherwise NONE.
MANUAL:
$manual
"@
$blocks = [ordered]@{
  'ledger'             = $ledger
  'new-handoffs'       = $handoffs
  'tally'              = $tal.text
  'metrics'            = $metrics
  'git-log-origin-main' = ($gitNote + $gl)
  'last-daily-reports' = $priorTxt
}
$reply = Invoke-Model 'sonnet' ('auditor-' + $day) $instr $blocks 6000
Write-Output $script:LastModelLine

# ---- split report / advice; script (not the model) adds frontmatter and validates advice ----
$parts = $reply -split '(?m)^\s*=====ADVICE=====\s*$', 2
$report = $parts[0].Trim()
$adviceRaw = ''; if ($parts.Count -gt 1) { $adviceRaw = $parts[1].Trim() }
if (-not $report) { throw 'model returned an empty report' }
$hdr = "---`ntitle: Auditor daily report $day`ntype: auditor-daily`nsource: nightly job (sonnet api), inputs: ledger, handoffs, tally, metrics, git log`ngenerated: " + (Get-Date).ToString('yyyy-MM-dd HH:mm') + "`n---`n"
Write-Out $dailyOut ($hdr + $report + "`n")

$valid = New-Object System.Collections.ArrayList
if ($adviceRaw -and $adviceRaw -notmatch '^\s*NONE\b') {
  foreach ($blk in ($adviceRaw -split '(\r?\n){2,}')) {
    if ($blk -match '(?im)^\s*target:\s*(model-routing\.md|lessons\.md|COMMANDER\.md)\s*$' ) {
      $tg = $Matches[1]
      $ru = [regex]::Match($blk, '(?im)^\s*rule:\s*(.+?)\s*$'); $ev = [regex]::Match($blk, '(?im)^\s*evidence:\s*(.+?)\s*$')
      if ($ru.Success -and $ev.Success -and $ru.Groups[1].Value.Length -ge 15 -and $ev.Groups[1].Value.Length -ge 5) {
        [void]$valid.Add(@{ t = $tg; r = (Ascii $ru.Groups[1].Value 400); e = (Ascii $ev.Groups[1].Value 300) })
      }
    }
    if ($valid.Count -ge 5) { break }
  }
}
if ($valid.Count -gt 0) {
  $a = New-Object System.Text.StringBuilder
  [void]$a.AppendLine('---'); [void]$a.AppendLine('status: unread'); [void]$a.AppendLine('source: nightly auditor job (sonnet api), audited day ' + $day); [void]$a.AppendLine('---')
  [void]$a.AppendLine('# Nightly advice ' + $day); [void]$a.AppendLine('')
  $i = 0
  foreach ($v in $valid) { $i++; [void]$a.AppendLine('## Item ' + $i); [void]$a.AppendLine('target: ' + $v.t); [void]$a.AppendLine('rule: ' + $v.r); [void]$a.AppendLine('evidence: ' + $v.e); [void]$a.AppendLine('') }
  Write-Out $adviceOut $a.ToString()
}
Write-Output ('SUMMARY: audited ' + $day + ', report ' + $report.Length + ' chars -> ' + (Split-Path -Leaf $dailyOut) + ', advice items valid=' + $valid.Count)
