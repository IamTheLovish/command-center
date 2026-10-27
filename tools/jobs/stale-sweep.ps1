# stale-sweep.ps1 - daily: open PRs idle 48 h or more, drafts with red checks, branches with no PR, claims past expiry,
# open PR count. Writes notes\STALE.md. Read only. No model. gh used: pr list, api (GET only).
param([string]$Root = 'D:\Command Center', [int]$ModelOk = 0, [string]$Date = '')
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'job-lib.ps1')
Init-Lib $Root $ModelOk
$cfg = Get-Cfg
$out = Join-Path $Root 'notes\STALE.md'
$now = (Get-Date).ToUniversalTime()

$prs = @(Gh-Json @('pr', 'list', '-R', $script:Repo, '--state', 'open', '--limit', '300', '--json', 'number,title,isDraft,updatedAt,headRefName,author,statusCheckRollup'))
$idle = New-Object System.Collections.ArrayList; $redDraft = New-Object System.Collections.ArrayList
foreach ($p in $prs) {
  $age = ($now - (Get-Utc $p.updatedAt)).TotalHours
  if ($age -ge 48) { [void]$idle.Add(@{ p = $p; h = $age }) }
  if ($p.isDraft) {
    $red = @($p.statusCheckRollup | Where-Object { @('FAILURE', 'TIMED_OUT', 'STARTUP_FAILURE', 'ERROR') -contains ([string]$_.conclusion).ToUpper() -or @('FAILURE', 'ERROR') -contains ([string]$_.state).ToUpper() })
    if ($red.Count -gt 0) { [void]$redDraft.Add(@{ p = $p; n = $red.Count }) }
  }
}

# branches: with no open PR; split by whether any PR ever used them
$allPrs = @(Gh-Json @('pr', 'list', '-R', $script:Repo, '--state', 'all', '--limit', '1000', '--json', 'headRefName,state'))
$everPr = @{}; foreach ($x in $allPrs) { $everPr[[string]$x.headRefName] = $true }
$openHeads = @{}; foreach ($p in $prs) { $openHeads[[string]$p.headRefName] = $true }
$branches = @(Gh-Pages ('repos/' + $script:Repo + '/branches'))
$never = New-Object System.Collections.ArrayList; $leftover = 0
foreach ($b in $branches) {
  $n = [string]$b.name
  if ($n -eq 'main' -or $openHeads.ContainsKey($n)) { continue }
  if ($everPr.ContainsKey($n)) { $leftover++ } else { [void]$never.Add(@{ name = $n; sha = [string]$b.commit.sha }) }
}
$dated = 0
foreach ($e in $never) {
  if ($dated -ge 40) { break }
  try { $c = Gh-Json @('api', ('repos/' + $script:Repo + '/commits/' + $e.sha)); $e.date = [string]$c.commit.committer.date; $e.who = [string]$c.commit.author.name } catch { }
  $dated++
}

# claims (tools/claim.py format): CLAIM slug | lane | branch | what | until ISO  /  RELEASE slug
$issue = [int]$cfg.claims_issue
$comments = @(Gh-Pages ('repos/' + $script:Repo + '/issues/' + $issue + '/comments'))
$claims = [ordered]@{}
$reClaim = New-Object Text.RegularExpressions.Regex('^CLAIM\s+(\S+)\s*\|\s*(.*?)\s*\|\s*(.*?)\s*\|\s*(.*?)\s*\|\s*until\s+(\S+)', 'Multiline')
$reRel = New-Object Text.RegularExpressions.Regex('^RELEASE\s+(\S+)', 'Multiline')
foreach ($c in $comments) {
  $body = [string]$c.body
  foreach ($m in $reClaim.Matches($body)) { $g = $m.Groups; $claims[$g[1].Value] = @{ slug = $g[1].Value; lane = $g[2].Value; branch = $g[3].Value; what = $g[4].Value; until = $g[5].Value; by = [string]$c.user.login } }
  foreach ($m in $reRel.Matches($body)) { $claims.Remove($m.Groups[1].Value) }
}
$expired = New-Object System.Collections.ArrayList; $active = 0
foreach ($k in $claims.Keys) {
  $c = $claims[$k]; $u = $null
  try { $u = Get-Utc $c.until } catch { }
  if ($null -ne $u -and $u -le $now) { [void]$expired.Add($c) } else { $active++ }
}

$sb = New-Object System.Text.StringBuilder
[void]$sb.AppendLine('# Stale sweep')
[void]$sb.AppendLine('')
[void]$sb.AppendLine('updated: ' + (Get-Date).ToString('yyyy-MM-dd HH:mm') + ' (auto, job stale-sweep, read only)')
[void]$sb.AppendLine('**Open PRs: ' + $prs.Count + '** (drafts ' + @($prs | Where-Object { $_.isDraft }).Count + ') | idle 48 h+: ' + $idle.Count + ' | red drafts: ' + $redDraft.Count + ' | branches with no PR ever: ' + $never.Count + ' | expired claims: ' + $expired.Count + ' (active ' + $active + ', issue #' + $issue + ')')
[void]$sb.AppendLine('')
[void]$sb.AppendLine('## Open PRs idle 48 h or more')
if ($idle.Count -eq 0) { [void]$sb.AppendLine('(none)') }
foreach ($e in ($idle | Sort-Object { -$_.h })) { [void]$sb.AppendLine('- #' + $e.p.number + ' ' + $(if ($e.p.isDraft) { '[draft] ' } else { '' }) + (Cell $e.p.title 90) + ' | ' + (Cell $e.p.headRefName 50) + ' | idle ' + [math]::Floor($e.h / 24) + 'd ' + [math]::Floor($e.h % 24) + 'h | ' + (Cell $e.p.author.login 30)) }
[void]$sb.AppendLine('')
[void]$sb.AppendLine('## Draft PRs with red checks')
if ($redDraft.Count -eq 0) { [void]$sb.AppendLine('(none)') }
foreach ($e in $redDraft) { [void]$sb.AppendLine('- #' + $e.p.number + ' ' + (Cell $e.p.title 90) + ' | ' + (Cell $e.p.headRefName 50) + ' | failing checks: ' + $e.n) }
[void]$sb.AppendLine('')
[void]$sb.AppendLine('## Branches that never had a PR (' + $never.Count + '; newest first, dates for the first 40 only)')
if ($never.Count -eq 0) { [void]$sb.AppendLine('(none)') }
foreach ($e in ($never | Sort-Object { [string]$_.date } -Descending | Select-Object -First 60)) { [void]$sb.AppendLine('- ' + (Cell $e.name 70) + ' | last commit ' + $(if ($e.date) { $e.date.Substring(0, 10) } else { '?' }) + ' ' + (Cell $e.who 25)) }
[void]$sb.AppendLine('Branches whose PR is merged or closed but the branch is still there: ' + $leftover + ' (not listed).')
[void]$sb.AppendLine('')
[void]$sb.AppendLine('## Claims past expiry (claim.py format, issue #' + $issue + ')')
if ($expired.Count -eq 0) { [void]$sb.AppendLine('(none)') }
foreach ($c in $expired) { [void]$sb.AppendLine('- ' + (Cell $c.slug 50) + ' | ' + (Cell $c.lane 30) + ' | ' + (Cell $c.branch 50) + ' | until ' + (Cell $c.until 25) + ' | by ' + (Cell $c.by 25) + ' | ' + (Cell $c.what 80)) }
Write-Out $out $sb.ToString()
Write-Output ('SUMMARY: openPRs=' + $prs.Count + ' idle48h=' + $idle.Count + ' redDrafts=' + $redDraft.Count + ' noPrBranches=' + $never.Count + ' expiredClaims=' + $expired.Count + ' activeClaims=' + $active)
