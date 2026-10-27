# flake-digest.ps1 - nightly: per-test failures over the last 24 h of build.yml runs (main + PRs), flags a test that failed
# and passed on the same sha, proposes a known_flakes.txt diff in notes\FLAKES-<date>.md. Never edits the repo. No model.
# gh used: run list, api (GET only).
param([string]$Root = 'D:\Command Center', [int]$ModelOk = 0, [string]$Date = '')
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'job-lib.ps1')
Init-Lib $Root $ModelOk
$stamp = (Get-Date).ToString('yyyy-MM-dd')
$out = Join-Path $Root ('notes\FLAKES-' + $stamp + '.md')
$cutoff = (Get-Date).ToUniversalTime().AddHours(-24)
$since = $cutoff.AddDays(-1).ToString('yyyy-MM-dd')

$limit = 300
$all = @(Gh-Json @('run', 'list', '-R', $script:Repo, '--workflow', 'build.yml', '--limit', "$limit", '--created', ('>=' + $since), '--json', 'databaseId,conclusion,status,headSha,headBranch,event,createdAt,attempt,displayTitle'))
$truncated = ($all.Count -ge $limit)
$runs = @($all | Where-Object { (Get-Utc $_.createdAt) -ge $cutoff })

# shas that have at least one green run in the window
$passed = @{}
foreach ($r in $runs) { if ([string]$r.conclusion -eq 'success') { $passed[[string]$r.headSha] = [string]$r.databaseId } }

$cap = 70; $apiRuns = 0
$tests = @{}     # name -> @{ n; shas = @{}; runs = list; events = @{} }
$other = @{}     # failed job names with no test name
$known = @(Get-KnownFlakes)
$rerun = 0
foreach ($r in $runs) {
  $att = 1; if ($r.attempt) { $att = [int]$r.attempt }
  $isFail = (@('failure', 'timed_out') -contains [string]$r.conclusion)
  if (-not $isFail -and $att -le 1) { continue }
  if ($apiRuns -ge $cap) { continue }
  $apiRuns++
  if ($att -gt 1) { $rerun++ }
  for ($n = 1; $n -le $att; $n++) {
    if ($n -eq $att -and -not $isFail) { continue }
    $p = 'repos/' + $script:Repo + '/actions/runs/' + $r.databaseId + '/jobs?per_page=100'
    if ($n -lt $att) { $p = 'repos/' + $script:Repo + '/actions/runs/' + $r.databaseId + '/attempts/' + $n + '/jobs?per_page=100' }
    try { $jobs = Gh-Json @('api', $p) } catch { continue }
    $fj = Get-FailedJobAnnotations $jobs
    if ($fj.jobs.Count -eq 0) { continue }
    $names = @(Get-FailedTests $fj.ann)
    $tag = [string]$r.databaseId + '#' + $n + '@' + ([string]$r.headSha).Substring(0, 7)
    if ($names.Count -eq 0) {
      foreach ($jn in $fj.jobs) { $k = 'job: ' + $jn; if (-not $other.ContainsKey($k)) { $other[$k] = 0 }; $other[$k]++ }
      continue
    }
    foreach ($t in $names) {
      if (-not $tests.ContainsKey($t)) { $tests[$t] = @{ n = 0; shas = @{}; runs = (New-Object System.Collections.ArrayList); events = @{} } }
      $e = $tests[$t]; $e.n++; $e.shas[[string]$r.headSha] = $true; [void]$e.runs.Add($tag); $e.events[[string]$r.event] = $true
    }
  }
}

$main = @($runs | Where-Object { $_.headBranch -eq 'main' }).Count
$sb = New-Object System.Text.StringBuilder
[void]$sb.AppendLine('# Flake digest ' + $stamp)
[void]$sb.AppendLine('')
[void]$sb.AppendLine('window: last 24 h up to ' + (Get-Date).ToString('yyyy-MM-dd HH:mm') + ' | build.yml runs scanned: ' + $runs.Count + ' (main ' + $main + ', PR/other ' + ($runs.Count - $main) + ') | runs with reruns: ' + $rerun + ' | runs inspected via API: ' + $apiRuns + ' (cap ' + $cap + ')')
if ($truncated) { [void]$sb.AppendLine('WARNING: run list hit the ' + $limit + ' cap - counts may be low.') }
[void]$sb.AppendLine('')
[void]$sb.AppendLine('## Failures per test')
$flag = New-Object System.Collections.ArrayList
if ($tests.Count -eq 0) { [void]$sb.AppendLine('(no named test failures in the window)') }
else {
  [void]$sb.AppendLine('| test | fails | shas | failed+passed same sha | on known_flakes |')
  [void]$sb.AppendLine('|---|---|---|---|---|')
  foreach ($t in ($tests.Keys | Sort-Object { -$tests[$_].n }, { $_ })) {
    $e = $tests[$t]; $same = @($e.shas.Keys | Where-Object { $passed.ContainsKey($_) })
    $isKnown = ($known -contains $t)
    $sameTxt = 'no'
    if ($same.Count) { $sameTxt = 'YES (' + ((@($same | ForEach-Object { $_.Substring(0, 7) }) | Select-Object -First 3) -join ',') + ')' }
    [void]$sb.AppendLine('| ' + (Cell $t 80) + ' | ' + $e.n + ' | ' + $e.shas.Count + ' | ' + $sameTxt + ' | ' + $(if ($isKnown) { 'yes' } else { 'no' }) + ' |')
    if ($same.Count -gt 0) { [void]$flag.Add(@{ name = $t; sha = $same[0]; fails = $e.n; fr = ((@($e.runs | Where-Object { $_ -like ('*@' + $same[0].Substring(0, 7)) }) | Select-Object -First 3) -join ', '); pass = $passed[$same[0]]; known = $isKnown }) }
  }
}
[void]$sb.AppendLine('')
[void]$sb.AppendLine('## Failures with no test name (build/lint/other jobs)')
if ($other.Count -eq 0) { [void]$sb.AppendLine('(none)') } else { foreach ($k in ($other.Keys | Sort-Object)) { [void]$sb.AppendLine('- ' + (Cell $k 100) + ' x' + $other[$k]) } }
[void]$sb.AppendLine('')
[void]$sb.AppendLine('## Failed then passed on the same sha (flake evidence)')
if ($flag.Count -eq 0) { [void]$sb.AppendLine('(none)') } else { foreach ($f in $flag) { [void]$sb.AppendLine('- ' + $f.name + ' on ' + $f.sha.Substring(0, 7) + ': failed in run#attempt ' + $f.fr + ', green run ' + $f.pass + $(if ($f.known) { ' (already on the list)' } else { '' })) } }
[void]$sb.AppendLine('')
[void]$sb.AppendLine('## Proposed tools/known_flakes.txt diff (NOT applied - this job never edits the repo)')
$add = @($flag | Where-Object { -not $_.known })
$quiet = @($known | Where-Object { -not $tests.ContainsKey($_) })
[void]$sb.AppendLine('```diff')
[void]$sb.AppendLine('--- a/tools/known_flakes.txt')
[void]$sb.AppendLine('+++ b/tools/known_flakes.txt')
if ($add.Count -eq 0) { [void]$sb.AppendLine('(no additions proposed)') }
else {
  [void]$sb.AppendLine('@@ append @@')
  foreach ($f in $add) { [void]$sb.AppendLine('+' + $f.name + '   # failed then passed on the same commit ' + $f.sha.Substring(0, 7) + ' (run#attempt ' + $f.fr + ', green run ' + $f.pass + '), ' + $f.fails + ' fail(s) in 24 h up to ' + $stamp + '; cause not found') }
}
[void]$sb.AppendLine('```')
[void]$sb.AppendLine('')
[void]$sb.AppendLine('Known flakes with no failure in this 24 h window (' + $quiet.Count + '; a quiet day is weak evidence - check several digests before dropping a line):')
foreach ($q in $quiet) { [void]$sb.AppendLine('- ' + $q) }
Write-Out $out $sb.ToString()
Write-Output ('SUMMARY: runs=' + $runs.Count + ' tests-failing=' + $tests.Count + ' same-sha-flags=' + $flag.Count + ' proposed-adds=' + $add.Count + ' -> ' + (Split-Path -Leaf $out))
