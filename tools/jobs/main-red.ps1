# main-red.ps1 - every 30 min: is the newest finished build.yml run on main red? Writes notes\MAIN-RED.md, clears it when green.
# gh used: run list, api (GET only). Model: haiku digest only when more than 20 annotation lines. Writes via Write-Out only.
param([string]$Root = 'D:\Command Center', [int]$ModelOk = 0, [string]$Date = '')
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'job-lib.ps1')
Init-Lib $Root $ModelOk
$out = Join-Path $Root 'notes\MAIN-RED.md'

$runs = @(Gh-Json @('run', 'list', '-R', $script:Repo, '--workflow', 'build.yml', '--branch', 'main', '--limit', '10', '--json', 'databaseId,conclusion,status,headSha,createdAt,event,displayTitle,url'))
$done = @($runs | Where-Object { @('success', 'failure', 'timed_out') -contains [string]$_.conclusion })
if ($done.Count -eq 0) { Write-Output 'SUMMARY: no finished success/failure run in the last 10; MAIN-RED.md left as it was'; exit 0 }
$r = $done[0]
$newest = $runs[0]
$sha7 = ([string]$r.headSha).Substring(0, 7)

if ([string]$r.conclusion -eq 'success') {
  Remove-Out $out
  Write-Output ('SUMMARY: main green at ' + $sha7 + ' (run ' + $r.databaseId + '); MAIN-RED.md cleared')
  exit 0
}

# red: gather evidence
$jobs = Gh-Json @('api', ('repos/' + $script:Repo + '/actions/runs/' + $r.databaseId + '/jobs?per_page=100'))
$fj = Get-FailedJobAnnotations $jobs
$tests = @(Get-FailedTests $fj.ann)
$known = @(Get-KnownFlakes)
$allKnown = ($tests.Count -gt 0)
foreach ($t in $tests) { if ($known -notcontains $t) { $allKnown = $false } }

$lines = New-Object System.Collections.ArrayList
foreach ($a in $fj.ann) {
  if ($a.annotation_level -eq 'notice') { continue }
  foreach ($l in (([string]$a.message) -split "`r?`n")) { if ($l.Trim()) { [void]$lines.Add('[' + $a.annotation_level + '] ' + (Ascii $l 220)) } }
}

# reuse an earlier digest for the same run (no repeat spend every 30 minutes)
$digest = ''
if (Test-Path -LiteralPath $out) {
  $old = Get-Content -LiteralPath $out -Raw
  if ($old -match ('run ' + $r.databaseId + '\b') -and $old -match '(?s)## Digest \(haiku\)\r?\n(.*)$') { $digest = $Matches[1].Trim() }
}
$digestNote = ''
if ($lines.Count -gt 20 -and -not $digest) {
  if ($ModelOk -eq 1) {
    try {
      $digest = Invoke-Model 'haiku' 'main-red-digest' 'Summarise why this CI run on main failed in at most 8 lines: which tests or tasks failed, the likely cause if the lines show one, and which lines are noise. Do not invent facts.' ([ordered]@{ 'failure-annotations' = ($lines -join "`n") }) 800
    Write-Output $script:LastModelLine } catch { $digestNote = 'digest skipped: ' + (Ascii $_.Exception.Message 160) }
  } else { $digestNote = 'digest skipped: model budget closed' }
}

$sb = New-Object System.Text.StringBuilder
[void]$sb.AppendLine('# MAIN IS RED')
[void]$sb.AppendLine('')
[void]$sb.AppendLine('updated: ' + (Get-Date).ToString('yyyy-MM-dd HH:mm') + ' (auto, job main-red; cleared when main is green)')
[void]$sb.AppendLine('run ' + $r.databaseId + ' | sha ' + $r.headSha + ' | ' + $r.event + ' | ' + $r.createdAt)
[void]$sb.AppendLine('title: ' + (Cell $r.displayTitle 150))
[void]$sb.AppendLine('url: ' + $r.url)
if ([string]$newest.databaseId -ne [string]$r.databaseId) { [void]$sb.AppendLine('newer run ' + $newest.databaseId + ' is ' + $(if ($newest.status -ne 'completed') { $newest.status } else { $newest.conclusion }) + ' (sha ' + ([string]$newest.headSha).Substring(0, 7) + ')') }
[void]$sb.AppendLine('failed jobs: ' + $(if ($fj.jobs.Count) { ($fj.jobs -join ', ') } else { '(none found)' }))
[void]$sb.AppendLine('')
[void]$sb.AppendLine('## Failing tests (' + $tests.Count + ')')
if ($tests.Count -eq 0) { [void]$sb.AppendLine('(no "<name> failed!" lines found - a build or task failure, not a flake)') }
foreach ($t in $tests) { [void]$sb.AppendLine('- ' + $t + ' : ' + $(if ($known -contains $t) { 'ON known_flakes.txt' } else { 'NOT on known_flakes.txt' })) }
[void]$sb.AppendLine('')
if ($allKnown) { [void]$sb.AppendLine('VERDICT: every failing test is on tools/known_flakes.txt - likely a flake, rerun is reasonable.') }
else { [void]$sb.AppendLine('VERDICT: NOT all failures are known flakes - treat as a real break. (' + $known.Count + ' names on the list)') }
[void]$sb.AppendLine('')
[void]$sb.AppendLine('## Failure annotation lines (' + $lines.Count + ', first 25 shown)')
foreach ($l in ($lines | Select-Object -First 25)) { [void]$sb.AppendLine($l) }
if ($digest) { [void]$sb.AppendLine(''); [void]$sb.AppendLine('## Digest (haiku)'); [void]$sb.AppendLine($digest) }
elseif ($digestNote) { [void]$sb.AppendLine(''); [void]$sb.AppendLine('(' + $digestNote + ')') }
Write-Out $out $sb.ToString()
Write-Output ('SUMMARY: main RED at ' + $sha7 + ' run ' + $r.databaseId + ' tests=' + $tests.Count + ' allKnownFlakes=' + $allKnown + ' annotationLines=' + $lines.Count + $(if ($digest) { ' digest=yes' } else { '' }))
