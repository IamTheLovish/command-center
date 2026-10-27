# gate-lib.ps1 - mechanical gates (preflight / accept / report-lint / ledger-lint / boot-done / selftest).
# Dot-sourced by cc.ps1 after cc-lib.ps1. ASCII only, PowerShell 5.1. No model calls anywhere in here.
# Every gate returns a list of checks {Name,Status(PASS|WARN|FAIL),Reason,Detail[]}; Write-GateResult prints one line each.
# Stub mode (ctx.Stub = folder): gh data is read from files there (openprs.json, auth.txt, pr<N>.json, pr<N>.diff) - used by gate-selftest.

function New-GateCtx([hashtable]$o) {
  $c = @{ Root = 'D:\Command Center'; Repo = 'D:\BeyondAndTabs-Repo'; Stub = ''; NoCache = $false; NoLog = $false; Verbose = $false; Now = $null; PrCache = @{}; Rows = $null; GhCalls = 0 }
  if ($o) { foreach ($k in $o.Keys) { $c[$k] = $o[$k] } }
  return $c
}
function Get-GNow($ctx) { if ($ctx.Now) { return $ctx.Now }; return (Get-NowET) }
function Get-GRows($ctx) { if ($null -eq $ctx.Rows) { $ctx.Rows = @(Get-LedgerRows $ctx.Root) }; return $ctx.Rows }
function Add-Chk($L, [string]$n, [string]$s, [string]$r, $detail = @()) {
  [void]$L.Add([pscustomobject]@{ Name = $n; Status = $s; Reason = (Get-Trunc $r 230); Detail = @($detail) })
}
function Get-GIso($v) {
  if ($null -eq $v -or "$v" -eq '') { return $null }
  if ($v -is [datetime]) { return [DateTimeOffset]$v }
  try { return [DateTimeOffset]::Parse([string]$v, [Globalization.CultureInfo]::InvariantCulture) } catch { return $null }
}
function ConvertFrom-GJson([string]$t) {
  if (-not $t -or -not $t.Trim()) { return $null }
  try { return ($t | ConvertFrom-Json) } catch { return $null }
}
function ConvertTo-GEt([datetime]$utc) {
  foreach ($zid in @('Eastern Standard Time', 'America/New_York')) {
    try { $tz = [TimeZoneInfo]::FindSystemTimeZoneById($zid); return [TimeZoneInfo]::ConvertTimeFromUtc($utc.ToUniversalTime(), $tz) } catch { }
  }
  return $utc.ToUniversalTime().AddHours(-5)
}
function Get-GEpoch { return [DateTimeOffset]::UtcNow.ToUnixTimeSeconds() }

# ------------------------------------------------------------------ data layer (one gh call per data type, 10 min cache)
function Get-GateCachePath { return (Join-Path $env:TEMP 'cc-gate-cache.json') }
function Invoke-GhRaw($ctx, [string[]]$a, [bool]$merge) {
  if (-not (Get-Command gh -ErrorAction SilentlyContinue)) { return @{ Code = 127; Out = 'gh not found on PATH' } }
  $ctx.GhCalls = [int]$ctx.GhCalls + 1
  $old = $ErrorActionPreference; $ErrorActionPreference = 'Continue'
  $oe = [Console]::OutputEncoding
  try { [Console]::OutputEncoding = [Text.Encoding]::UTF8 } catch { }
  Push-Location $ctx.Repo
  try {
    if ($merge) { $o = (& gh @a 2>&1 | Out-String) } else { $o = (& gh @a 2>$null | Out-String) }
    $c = $LASTEXITCODE
  } finally { Pop-Location; $ErrorActionPreference = $old; try { [Console]::OutputEncoding = $oe } catch { } }
  return @{ Code = $c; Out = $o }
}
# kind: openprs | auth | pr (arg = number) | diff (arg = number). Returns @{Ok;Text;Err;Cached}.
function Get-GateData($ctx, [string]$kind, [string]$arg = '') {
  if ($ctx.Stub) {
    $f = ''
    switch ($kind) { 'openprs' { $f = 'openprs.json' } 'auth' { $f = 'auth.txt' } 'pr' { $f = 'pr' + $arg + '.json' } 'diff' { $f = 'pr' + $arg + '.diff' } }
    $p = Join-Path $ctx.Stub $f
    if (Test-Path -LiteralPath $p) { return @{ Ok = $true; Text = (Read-Text $p); Cached = $false } }
    return @{ Ok = $false; Text = ''; Err = ('stub file missing: ' + $f); Cached = $false }
  }
  $cacheable = ((($kind -eq 'openprs') -or ($kind -eq 'auth')) -and -not $ctx.NoCache)
  $cp = Get-GateCachePath
  if ($cacheable -and (Test-Path -LiteralPath $cp)) {
    try {
      $c = (Read-Text $cp) | ConvertFrom-Json
      $e = $c.$kind
      if ($e -and (((Get-GEpoch) - [double]$e.t) -lt 600)) { return @{ Ok = $true; Text = [string]$e.raw; Cached = $true } }
    } catch { }
  }
  $r = $null
  switch ($kind) {
    'openprs' { $r = Invoke-GhRaw $ctx @('pr', 'list', '--state', 'open', '--limit', '200', '--json', 'number,title,files,headRefName') $false }
    'auth' { $r = Invoke-GhRaw $ctx @('auth', 'status') $true }
    'pr' { $r = Invoke-GhRaw $ctx @('pr', 'view', $arg, '--json', 'number,title,state,mergedAt,headRefOid,headRefName,body,commits,statusCheckRollup,files,comments') $false }
    'diff' { $r = Invoke-GhRaw $ctx @('pr', 'diff', $arg) $false }
  }
  if ($r.Code -ne 0) { return @{ Ok = $false; Text = ''; Err = ('gh ' + $kind + ' failed: ' + (Get-Trunc $r.Out 120)); Cached = $false } }
  $txt = $r.Out
  if ($kind -eq 'auth') { $txt = (@($txt -split "\r?\n" | Where-Object { $_ -notmatch '(?i)token:' }) -join "`n") }
  if ($cacheable) {
    try {
      $h = [ordered]@{}
      if (Test-Path -LiteralPath $cp) { try { $old = (Read-Text $cp) | ConvertFrom-Json; foreach ($pp in $old.PSObject.Properties) { $h[$pp.Name] = $pp.Value } } catch { } }
      $h[$kind] = [ordered]@{ t = (Get-GEpoch); raw = $txt }
      Write-Text $cp ($h | ConvertTo-Json -Depth 4 -Compress) $false
    } catch { }
  }
  return @{ Ok = $true; Text = $txt; Cached = $false }
}
# live PR view, memoised per run. Returns the parsed object or $null (error in ctx.PrError).
function Get-GatePr($ctx, [string]$n) {
  if ($ctx.PrCache.ContainsKey($n)) { return $ctx.PrCache[$n] }
  $d = Get-GateData $ctx 'pr' $n
  $o = $null
  if ($d.Ok) { $o = ConvertFrom-GJson $d.Text; if ($null -eq $o) { $ctx.PrError = 'unparseable gh pr view output' } } else { $ctx.PrError = $d.Err }
  $ctx.PrCache[$n] = $o
  return $o
}
function Get-GateIdentity($ctx) {
  $p = Join-Path $ctx.Repo 'AGENTS.md'
  if ($ctx.Stub) { $sp = Join-Path $ctx.Stub 'AGENTS.md'; if (Test-Path -LiteralPath $sp) { $p = $sp } }
  $t = Read-Text $p
  $n = [regex]::Match($t, 'user\.name=([^\s`"'']+)')
  $e = [regex]::Match($t, 'user\.email=([^\s`"'']+)')
  if (-not $n.Success -or -not $e.Success) { return $null }
  return @{ Name = $n.Groups[1].Value; Email = $e.Groups[1].Value; Cmd = ('git -c user.name=' + $n.Groups[1].Value + ' -c user.email=' + $e.Groups[1].Value + ' commit') }
}

# ------------------------------------------------------------------ output + logging
function Get-GateCounts($checks) {
  return @{ F = @($checks | Where-Object { $_.Status -eq 'FAIL' }).Count; W = @($checks | Where-Object { $_.Status -eq 'WARN' }).Count; P = @($checks | Where-Object { $_.Status -eq 'PASS' }).Count }
}
function Write-GateResult($ctx, [string]$title, $checks, $sw) {
  foreach ($c in $checks) {
    Write-Output ('{0} {1}: {2}' -f $c.Status, $c.Name, $c.Reason)
    if ($ctx.Verbose) { foreach ($d in @($c.Detail)) { if ($d) { Write-Output ('     ' + $d) } } }
  }
  $n = Get-GateCounts $checks
  $v = 'PASS'; if ($n.F -gt 0) { $v = 'FAIL' }
  Write-Output ('GATE {0}: {1} ({2} fail, {3} warn, {4} pass) {5:N1}s, gh calls {6}' -f $title, $v, $n.F, $n.W, $n.P, ($sw.ElapsedMilliseconds / 1000.0), $ctx.GhCalls)
  $ctx.LastOk = ($n.F -eq 0)
}
function Write-GateLedger($ctx, [string]$title, $checks, $sw) {
  if ($ctx.NoLog) { return }
  if ($null -eq (Get-State $ctx.Root)) { Write-Output 'WARN ledger: no state.json, gate row not logged'; return }
  $n = Get-GateCounts $checks
  $res = 'pass'; $failed = ''
  if ($n.F -gt 0) { $res = 'blocked'; $failed = ' failed: ' + ((@($checks | Where-Object { $_.Status -eq 'FAIL' } | ForEach-Object { $_.Name })) -join ',') }
  try {
    $id = Add-LedgerRow $ctx.Root @{ Assignment = ('gate ' + $title + ' -> ' + $(if ($n.F -gt 0) { 'FAIL' } else { 'PASS' }) + $failed); Model = 'script'; Effort = '-'; Tokens = '-'; Result = $res; Note = ('tier: chore; gate; ' + $n.W + ' warn; ' + [math]::Round($sw.ElapsedMilliseconds / 1000.0, 1) + 's') }
    if ($ctx.Verbose) { Write-Output ('     ledger id: ' + $id) }
  } catch { Write-Output ('WARN ledger: could not log gate row: ' + (Get-Trunc $_.Exception.Message 100)) }
}

# ------------------------------------------------------------------ ledger-lint
function Invoke-LedgerLint($ctx, [string]$date) {
  $L = New-Object System.Collections.ArrayList
  $now = Get-GNow $ctx
  if (-not $date) { $date = $now.ToString('yyyy-MM-dd') }
  $f = Join-Path $ctx.Root ('usage\ledger-' + $date + '.md')
  if (-not (Test-Path -LiteralPath $f)) { Add-Chk $L 'ledger-lint' 'PASS' ('no ledger file for ' + $date); return $L }
  $rows = @(Get-LedgerRows $ctx.Root $date)
  $mt = ConvertTo-GEt ((Get-Item -LiteralPath $f).LastWriteTimeUtc)
  $noId = @(); $order = @(); $future = @(); $acct = @(); $stale = @()
  $prev = $null
  foreach ($r in $rows) {
    if (-not $r.Id) { $noId += $r.LineNo }
    $stamp = Get-RowStamp $r
    if ($r.Acct -eq '?' -or $r.Gen -eq '?') { $acct += $r.LineNo }
    if ($stamp) {
      if ($prev -and $stamp -lt $prev.Stamp) { $order += ('line {0} {1} after {2}' -f $r.LineNo, $r.Time, $prev.Time) }
      if ($stamp -gt $mt.AddMinutes(2)) { $future += ('line {0} {1} > file mtime {2}' -f $r.LineNo, $r.Time, $mt.ToString('HH:mm')) }
      if ($r.Class -eq 'running' -and ($now.DateTime - $stamp).TotalHours -gt 12) { $stale += ('line {0} {1}' -f $r.LineNo, $r.Time) }
      $prev = @{ Stamp = $stamp; Time = $r.Time }
    }
  }
  $rng = { param($a) if ($a.Count -eq 0) { '' } else { ' (lines ' + $a[0] + '-' + $a[$a.Count - 1] + ')' } }
  if ($noId.Count) { Add-Chk $L 'ledger-no-id' 'FAIL' ("{0} of {1} row(s) have no [id:] tag = hand-typed{2}" -f $noId.Count, $rows.Count, (& $rng $noId)) @($noId | ForEach-Object { 'line ' + $_ }) } else { Add-Chk $L 'ledger-no-id' 'PASS' ("all {0} rows have ids" -f $rows.Count) }
  if ($future.Count) { Add-Chk $L 'ledger-time-future' 'FAIL' ("{0} row(s) timed after the file was last written ({1}); first: {2}" -f $future.Count, $mt.ToString('HH:mm'), $future[0]) $future } else { Add-Chk $L 'ledger-time-future' 'PASS' 'no row later than file mtime' }
  if ($order.Count) { Add-Chk $L 'ledger-time-order' 'FAIL' ("{0} row(s) out of time order; first: {1}" -f $order.Count, $order[0]) $order } else { Add-Chk $L 'ledger-time-order' 'PASS' 'times in order' }
  if ($acct.Count) { Add-Chk $L 'ledger-acct' 'FAIL' ("{0} row(s) with acct/gen '?'{1}" -f $acct.Count, (& $rng $acct)) } else { Add-Chk $L 'ledger-acct' 'PASS' 'no unknown acct/gen' }
  if ($stale.Count) { Add-Chk $L 'ledger-running' 'FAIL' ("{0} row(s) still 'running' after 12 h; first: {1}" -f $stale.Count, $stale[0]) $stale } else { Add-Chk $L 'ledger-running' 'PASS' 'no running row older than 12 h' }
  return $L
}

# ------------------------------------------------------------------ state: boot_complete
function Set-StateBootComplete([string]$Root, [bool]$v) {
  $p = Join-Path $Root 'usage\state.json'
  $t = (Read-Text $p).Trim()
  $val = 'false'; if ($v) { $val = 'true' }
  if ($t -match '"boot_complete"\s*:\s*(true|false)') { $t = [regex]::Replace($t, '"boot_complete"\s*:\s*(true|false)', ('"boot_complete":' + $val)) }
  else { $i = $t.LastIndexOf('}'); if ($i -lt 0) { throw 'state.json is not an object' }; $t = $t.Substring(0, $i).TrimEnd() + ',"boot_complete":' + $val + '}' }
  Write-Text $p $t $false
}
function Invoke-BootDone($ctx, [bool]$force) {
  $L = New-Object System.Collections.ArrayList
  $st = Get-State $ctx.Root
  if ($null -eq $st) { Add-Chk $L 'boot-done' 'FAIL' 'no usage\state.json - run cc.ps1 boot first'; return $L }
  $unread = 0
  $ad = Join-Path $ctx.Root 'auditor\advice'
  if (Test-Path -LiteralPath $ad) {
    foreach ($f in (Get-ChildItem -LiteralPath $ad -Filter *.md -File)) {
      $t = Read-Text $f.FullName
      if ($t -match '(?s)^\s*---\s*\r?\n(.*?)\r?\n---') { if ($Matches[1] -match '(?m)^status:\s*unread') { $unread++ } }
    }
  }
  $ca = Read-Text (Join-Path $ctx.Root 'auditor\CHANGES-APPLIED.md')
  $un = @(Get-Section $ca 'Unannounced' | Where-Object { $_ -notmatch '^\s*[-*]?\s*\(?none\)?\.?\s*$' })
  if ($unread -gt 0) { Add-Chk $L 'advice' 'FAIL' ("{0} auditor advice file(s) still status: unread - apply them (cc.ps1 advice-done)" -f $unread) } else { Add-Chk $L 'advice' 'PASS' 'no unread advice' }
  if ($un.Count -gt 0) { Add-Chk $L 'announce' 'FAIL' ("{0} line(s) still under Unannounced in CHANGES-APPLIED.md - tell lovish, then move them to Announced" -f $un.Count) } else { Add-Chk $L 'announce' 'PASS' 'nothing unannounced' }
  $n = Get-GateCounts $L
  if ($n.F -eq 0 -or $force) {
    Set-StateBootComplete $ctx.Root $true
    $why = 'boot_complete=true'; if ($n.F -gt 0) { $why = 'boot_complete=true (FORCED past ' + $n.F + ' failing check(s))' }
    Add-Chk $L 'boot-done' 'PASS' $why
  } else { Add-Chk $L 'boot-done' 'FAIL' 'boot_complete stays false until the checks above pass (or -Force)' }
  return $L
}

# ------------------------------------------------------------------ preflight
$script:PlanStop = @('about', 'above', 'after', 'again', 'agent', 'agents', 'also', 'before', 'being', 'build', 'change', 'check', 'could', 'every', 'first', 'implement', 'later', 'other', 'please', 'should', 'since', 'still', 'their', 'there', 'these', 'those', 'update', 'using', 'where', 'which', 'while', 'would', 'write', 'tests', 'files', 'adds', 'make', 'needs', 'task', 'work', 'with', 'from', 'into', 'that', 'this', 'when', 'what', 'will', 'have')
function Test-GateBranchBusy($ctx, $prObj, [string]$prNum, [string]$branch) {
  $reasons = New-Object System.Collections.ArrayList
  $unknown = $false
  $now = Get-GNow $ctx
  $st = Get-State $ctx.Root
  $myGen = -1; if ($st) { $myGen = [int]$st.gen }
  $lastCommit = $null; $lastComment = $null
  if ($prObj) {
    foreach ($c in @($prObj.commits)) { $t = Get-GIso $c.committedDate; if ($t -and (($null -eq $lastCommit) -or $t -gt $lastCommit)) { $lastCommit = $t } }
    foreach ($c in @($prObj.comments)) { $t = Get-GIso $c.createdAt; if ($t -and (($null -eq $lastComment) -or $t -gt $lastComment)) { $lastComment = $t } }
  } elseif ($branch -and -not $ctx.Stub) {
    $old = $ErrorActionPreference; $ErrorActionPreference = 'Continue'
    foreach ($ref in @(('origin/' + $branch), $branch)) {
      $o = (& git -C $ctx.Repo log -1 --format=%cI $ref 2>$null | Out-String).Trim()
      if ($LASTEXITCODE -eq 0 -and $o) { $lastCommit = Get-GIso $o; break }
    }
    $ErrorActionPreference = $old
    if ($null -eq $lastCommit) { $unknown = $true }
  }
  if ($lastCommit) { $mins = [int]($now - $lastCommit).TotalMinutes; if ($mins -lt 120) { [void]$reasons.Add("commit $mins min ago (<2h, another session may be on it)") } }
  if ($lastComment) { $mins = [int]($now - $lastComment).TotalMinutes; if ($mins -lt 120) { [void]$reasons.Add("PR comment $mins min ago (<2h)") } }
  $pat = @()
  if ($prNum) { $pat += ('(?<![\w])#' + [regex]::Escape($prNum) + '(?!\d)'); $pat += ('(?i)\bPR\s*#?' + [regex]::Escape($prNum) + '(?!\d)') }
  if ($branch) { $pat += [regex]::Escape($branch) }
  foreach ($r in (Get-GRows $ctx)) {
    $txt = $r.Assignment + ' ' + $r.Note
    $m = $false; foreach ($p in $pat) { if ($txt -match $p) { $m = $true } }
    if (-not $m -or $r.GenNum -eq $myGen) { continue }
    if ($r.Assignment -match '(?i)boot') { [void]$reasons.Add("gen-$($r.Gen) owns it in a boot row ($($r.Date) $($r.Time))") }
    elseif ($r.Class -eq 'running') { [void]$reasons.Add("gen-$($r.Gen) has a running ledger row for it ($($r.Date) $($r.Time))") }
    $stamp = Get-RowStamp $r
    if ($stamp) { $age = ($now.DateTime - $stamp).TotalMinutes; if ($age -ge -5 -and $age -lt 120 -and $r.Assignment -notmatch '(?i)boot') { [void]$reasons.Add("gen-$($r.Gen) touched it $([int]$age) min ago per ledger") } }
  }
  return @{ Reasons = @($reasons | Select-Object -Unique); Unknown = $unknown }
}
function Get-PlanHits($ctx, [string[]]$files, [string]$task) {
  $pd = Join-Path $ctx.Root 'plans'
  if ($ctx.PlansDir) { $pd = $ctx.PlansDir }
  $out = @()
  if (-not (Test-Path -LiteralPath $pd)) { return $out }
  $kw = @([regex]::Matches($task, '[A-Za-z][A-Za-z0-9_]{4,}') | ForEach-Object { $_.Value.ToLower() } | Where-Object { $script:PlanStop -notcontains $_ } | Sort-Object -Unique)
  $need = [Math]::Min(2, $kw.Count)
  foreach ($f in (Get-ChildItem -LiteralPath $pd -Filter *.md -File | Sort-Object Name)) {
    $t = (Read-Text $f.FullName).ToLower().Replace('\', '/')
    $fh = @(); foreach ($x in $files) { $b = $x.Replace('\', '/').ToLower(); $leaf = $b.Substring($b.LastIndexOf('/') + 1); if ($b -and ($t.Contains($b) -or ($leaf.Length -gt 6 -and $t.Contains($leaf)))) { $fh += $leaf } }
    $kh = @(); foreach ($k in $kw) { if ($t.Contains($k)) { $kh += $k } }
    if ($fh.Count -gt 0 -or ($need -gt 0 -and $kh.Count -ge $need)) {
      $id = $f.BaseName; if ($f.BaseName -match '^(\d+)') { $id = $Matches[1] }
      $out += [pscustomobject]@{ Id = $id; File = $f.Name; Files = $fh; Kw = $kh }
    }
  }
  return $out
}
function Invoke-GatePreflight($ctx, [hashtable]$p) {
  $L = New-Object System.Collections.ArrayList
  $files = @(); if ($p.Files) { $files = @(([string]$p.Files) -split ',' | ForEach-Object { $_.Trim() } | Where-Object { $_ }) }
  # 1 boot (M10)
  $st = Get-State $ctx.Root
  if ($null -eq $st) { Add-Chk $L 'boot' 'FAIL' 'no usage\state.json - run cc.ps1 boot -Acct A|B' }
  else {
    $bc = $st.PSObject.Properties['boot_complete']
    if ($null -eq $bc) { Add-Chk $L 'boot' 'WARN' 'state.json has no boot_complete (booted before the gate existed); run cc.ps1 boot-done' }
    elseif (-not [bool]$bc.Value) { Add-Chk $L 'boot' 'FAIL' 'boot unfinished (boot_complete=false): apply advice, announce it, then cc.ps1 boot-done' }
    else { Add-Chk $L 'boot' 'PASS' ('complete, acct {0} gen-{1:D3}' -f $st.acct, [int]$st.gen) }
  }
  # 2 task text
  if (-not $p.Task -or -not ([string]$p.Task).Trim()) { Add-Chk $L 'task' 'FAIL' 'no -Task text: say what the assignment is' }
  # 3 PR / branch (M3)
  $prNum = [string]$p.Pr
  $branch = [string]$p.Branch
  if (-not $prNum -and $branch) {
    $d = Get-GateData $ctx 'openprs'
    if ($d.Ok) { $ps = ConvertFrom-GJson $d.Text; foreach ($x in @($ps)) { if ($x.headRefName -eq $branch) { $prNum = [string]$x.number; break } } }
  }
  $ownPr = $prNum
  if ($prNum) {
    $o = Get-GatePr $ctx $prNum
    if ($null -eq $o) { Add-Chk $L 'pr-state' 'FAIL' ("cannot read PR #{0} from gh: {1} (fail closed)" -f $prNum, $ctx.PrError) }
    else {
      $s = [string]$o.state
      if ($s -eq 'OPEN') { Add-Chk $L 'pr-state' 'PASS' ("PR #{0} is OPEN (branch {1})" -f $prNum, $o.headRefName) }
      elseif ($s -eq 'MERGED') { $m = Get-GIso $o.mergedAt; $ms = ''; if ($m) { $ms = $m.UtcDateTime.ToString('yyyy-MM-dd HH:mm') + 'Z' }; Add-Chk $L 'pr-state' 'WARN' ("PR #{0} is MERGED at {1}: do not brief it as unmerged or open" -f $prNum, $ms) }
      else { Add-Chk $L 'pr-state' 'WARN' ("PR #{0} is {1}" -f $prNum, $s) }
      if (-not $branch) { $branch = [string]$o.headRefName }
    }
    $busy = Test-GateBranchBusy $ctx $o $prNum $branch
    if (@($busy.Reasons).Count -gt 0) { Add-Chk $L 'branch-check' 'FAIL' ('BLOCKED: ' + ($busy.Reasons -join '; ')) }
    elseif ($busy.Unknown) { Add-Chk $L 'branch-check' 'FAIL' 'UNKNOWN: could not verify commit time (fail closed)' }
    else { Add-Chk $L 'branch-check' 'PASS' 'no other gen touched it within 2h, no boot-row owner' }
  } elseif ($branch) {
    $busy = Test-GateBranchBusy $ctx $null '' $branch
    if (@($busy.Reasons).Count -gt 0) { Add-Chk $L 'branch-check' 'FAIL' ('BLOCKED: ' + ($busy.Reasons -join '; ')) }
    elseif ($busy.Unknown) { Add-Chk $L 'branch-check' 'WARN' ("branch {0} has no PR and no git ref (new branch?)" -f $branch) }
    else { Add-Chk $L 'branch-check' 'PASS' ("branch {0}: no other gen touched it" -f $branch) }
  }
  # 4 open-PR file overlap (M6)
  if ($files.Count -gt 0) {
    $d = Get-GateData $ctx 'openprs'
    if (-not $d.Ok) { Add-Chk $L 'overlap' 'FAIL' ('cannot list open PRs: ' + $d.Err) }
    else {
      $prs = @(ConvertFrom-GJson $d.Text)
      $hits = @{}
      foreach ($x in $prs) {
        if ($ownPr -and ([string]$x.number -eq $ownPr)) { continue }
        if ($branch -and $x.headRefName -eq $branch) { continue }
        foreach ($pf in @($x.files)) {
          $pp = ([string]$pf.path).ToLower()
          foreach ($f in $files) {
            $n = $f.Replace('\', '/').ToLower().TrimStart('/')
            if ($pp -eq $n -or ($n.EndsWith('/') -and $pp.StartsWith($n))) { if (-not $hits.ContainsKey($x.number)) { $hits[$x.number] = New-Object System.Collections.ArrayList }; [void]$hits[$x.number].Add($f) }
          }
        }
      }
      if ($hits.Count -eq 0) { Add-Chk $L 'overlap' 'PASS' ("no open PR (of {0}) edits {1} file(s)" -f $prs.Count, $files.Count) }
      else {
        $lst = (@($hits.Keys | Sort-Object | ForEach-Object { '#' + $_ + ' (' + (@($hits[$_] | Select-Object -Unique | ForEach-Object { $_.Substring($_.Replace('\', '/').LastIndexOf('/') + 1) }) -join ',') + ')' }) -join ', ')
        $det = @($hits.Keys | Sort-Object | ForEach-Object { '#' + $_ + ': ' + (@($hits[$_] | Select-Object -Unique) -join ', ') })
        if ($p.AllowOverlap) { Add-Chk $L 'overlap' 'WARN' ("overlap allowed (" + (Get-Trunc ([string]$p.AllowOverlap) 80) + "): " + $lst) $det }
        else { Add-Chk $L 'overlap' 'FAIL' ("{0} open PR(s) edit the same lines/files: {1}. Rebase onto them or use -AllowOverlap ""reason""" -f $hits.Count, $lst) $det }
      }
    }
  }
  # 5 workflow scope (M2)
  $wf = [bool]$p.EditsWorkflows
  foreach ($f in $files) { if ($f.Replace('\', '/').TrimStart('/').ToLower().StartsWith('.github/workflows')) { $wf = $true } }
  if ($wf) {
    $d = Get-GateData $ctx 'auth'
    if (-not $d.Ok) { Add-Chk $L 'workflow-scope' 'FAIL' ('gh auth status failed: ' + $d.Err) }
    else {
      $m = [regex]::Match($d.Text, '(?i)Token scopes:\s*([^\r\n]*)')
      if (-not $m.Success) { Add-Chk $L 'workflow-scope' 'FAIL' 'gh auth status shows no "Token scopes" line; cannot confirm the workflow scope' }
      else {
        $sc = @($m.Groups[1].Value -split '[,\s'']+' | Where-Object { $_ })
        if ($sc -contains 'workflow') { Add-Chk $L 'workflow-scope' 'PASS' 'gh token has the workflow scope' }
        else { Add-Chk $L 'workflow-scope' 'FAIL' ("gh token lacks the 'workflow' scope (has: {0}); a push touching .github/workflows will be refused. lovish: gh auth refresh -h github.com -s workflow" -f ($sc -join ', ')) }
      }
    }
  }
  # 6 heavy cap
  if ($p.Heavy) {
    $acct = ''; if ($st) { $acct = [string]$st.acct }
    $h = @(Get-GRows $ctx | Where-Object { ($_.Family -eq 'opus' -or $_.Family -eq 'fable') -and $_.Effort -match 'xhigh' -and $_.Class -eq 'running' -and $_.Acct -eq $acct })
    if ($h.Count -ge 2) { Add-Chk $L 'heavy-cap' 'FAIL' ("account {0} already has {1} open heavy rows (opus/fable xhigh, running; cap 2): close one first" -f $acct, $h.Count) @($h | ForEach-Object { $_.Date + ' ' + $_.Time + ' ' + $_.Id + ' ' + (Get-Trunc $_.Assignment 80) }) }
    else { Add-Chk $L 'heavy-cap' 'PASS' ("account {0} has {1} open heavy row(s) of 2" -f $acct, $h.Count) }
  }
  # 7 new-PR budget (M7)
  if ($p.NewPr) {
    $d = Get-GateData $ctx 'openprs'
    if (-not $d.Ok) { Add-Chk $L 'pr-budget' 'FAIL' ('cannot count open PRs: ' + $d.Err) }
    else {
      $cnt = @(ConvertFrom-GJson $d.Text).Count
      $today = (Get-GNow $ctx).ToString('yyyy-MM-dd')
      $tri = @(Get-GRows $ctx | Where-Object { $_.Date -eq $today -and $_.Assignment -match '(?i)triage' -and $_.Assignment -match '(?i)\bPRs?\b' })
      $why = New-Object System.Collections.ArrayList
      $sev = 'PASS'
      if ($cnt -gt 40) { [void]$why.Add("$cnt open PRs (>40)"); $sev = 'FAIL' } elseif ($cnt -gt 20) { [void]$why.Add("$cnt open PRs (>20)"); $sev = 'WARN' }
      if ($tri.Count -eq 0) { [void]$why.Add("no PR triage row in today's ledger ($today)"); $sev = 'FAIL' }
      if ($sev -eq 'PASS') { Add-Chk $L 'pr-budget' 'PASS' ("$cnt open PRs, triage row present") }
      else {
        $txt = ($why -join '; ') + '. lovish Oct 24: finish open PRs first'
        if ($p.Override -and ([string]$p.Override).Trim().Length -ge 12) { Add-Chk $L 'pr-budget' 'WARN' ($txt + '. OVERRIDE quote: "' + (Get-Trunc ([string]$p.Override) 90) + '"') }
        elseif ($sev -eq 'FAIL') { Add-Chk $L 'pr-budget' 'FAIL' ($txt + '. Triage open PRs first, or pass -Override "<lovish quote>"') }
        else { Add-Chk $L 'pr-budget' 'WARN' $txt }
      }
    }
  }
  # 8 plans overlap (M8)
  $ph = @(Get-PlanHits $ctx $files ([string]$p.Task))
  if ($ph.Count -gt 0) {
    $ids = (@($ph | Select-Object -First 6 | ForEach-Object { $_.Id }) -join ', ')
    Add-Chk $L 'plans' 'WARN' ("existing plan(s) overlap: {0}. Read them before briefing (also claude/plans/INDEX.md, a Project doc)" -f $ids) @($ph | ForEach-Object { $_.File + ' files=[' + ($_.Files -join ',') + '] keywords=[' + ($_.Kw -join ',') + ']' })
  } else { Add-Chk $L 'plans' 'PASS' 'no plan in plans\ mentions these files/keywords' }
  # 9 commit identity (M5)
  $id = Get-GateIdentity $ctx
  if ($null -eq $id) { Add-Chk $L 'identity' 'FAIL' 'cannot read the required commit identity from AGENTS.md' }
  else { Add-Chk $L 'identity' 'PASS' ('paste in every brief: ' + $id.Cmd + '  (name ' + $id.Name + ', email ' + $id.Email + ')') }
  # 10 today's ledger hygiene (warn only)
  $ll = @(Invoke-LedgerLint $ctx '' | Where-Object { $_.Status -eq 'FAIL' })
  if ($ll.Count -gt 0) { Add-Chk $L 'ledger' 'WARN' ("today's ledger has {0} problem(s): {1}; run cc.ps1 ledger-lint" -f $ll.Count, (@($ll | ForEach-Object { $_.Name }) -join ',')) }
  return $L
}

# ------------------------------------------------------------------ accept
function Test-GateCiRollup($roll) {
  $bad = @(); $pend = @(); $ok = 0
  foreach ($c in @($roll)) {
    $name = [string]$c.name; if (-not $name) { $name = [string]$c.context }; if (-not $name) { $name = '?' }
    if ($c.__typename -eq 'StatusContext') {
      $s = [string]$c.state
      if ($s -eq 'SUCCESS') { $ok++ } elseif ($s -eq 'PENDING' -or $s -eq 'EXPECTED') { $pend += $name } else { $bad += ($name + '=' + $s) }
      continue
    }
    if ([string]$c.status -ne 'COMPLETED') { $pend += $name; continue }
    $cc = [string]$c.conclusion
    if ($cc -eq 'SUCCESS' -or $cc -eq 'SKIPPED' -or $cc -eq 'NEUTRAL') { $ok++ } else { $bad += ($name + '=' + $cc) }
  }
  return @{ Ok = $ok; Bad = $bad; Pend = $pend }
}
function Get-GateBuilders($ctx, [string]$n) {
  $o = @()
  foreach ($r in (Get-GRows $ctx)) {
    if ($r.Note -match ('(?i)owns:[^;]*#' + [regex]::Escape($n) + '(?!\d)') -or $r.Assignment -match ('(?i)\bowns\s+#' + [regex]::Escape($n) + '(?!\d)')) { $o += $r }
  }
  return $o
}
function Invoke-GateAccept($ctx, [string]$n) {
  $L = New-Object System.Collections.ArrayList
  $info = @{ Sha = ''; Reviewer = '' }
  $d = Get-GatePr $ctx $n
  if ($null -eq $d) { Add-Chk $L 'pr' 'FAIL' ("cannot read PR #{0} from gh: {1}" -f $n, $ctx.PrError); $ctx.AcceptInfo = $info; return $L }
  $sha = [string]$d.headRefOid
  $info.Sha = $sha
  if ($d.state -eq 'OPEN') { Add-Chk $L 'pr' 'PASS' ("#{0} OPEN, head {1}" -f $n, $sha.Substring(0, 8)) }
  else { $m = Get-GIso $d.mergedAt; $ms = ''; if ($m) { $ms = ' at ' + $m.UtcDateTime.ToString('yyyy-MM-dd HH:mm') + 'Z' }; Add-Chk $L 'pr' 'WARN' ("#{0} is {1}{2}; head {3}" -f $n, $d.state, $ms, $sha.Substring(0, 8)) }
  # CI
  $ci = Test-GateCiRollup $d.statusCheckRollup
  if (($ci.Ok + $ci.Bad.Count + $ci.Pend.Count) -eq 0) { Add-Chk $L 'ci' 'FAIL' 'no CI checks reported on this head' }
  elseif ($ci.Bad.Count -gt 0) { Add-Chk $L 'ci' 'FAIL' ("{0} check(s) failed/cancelled: {1}" -f $ci.Bad.Count, (($ci.Bad | Select-Object -First 4) -join ', ')) }
  elseif ($ci.Pend.Count -gt 0) { Add-Chk $L 'ci' 'FAIL' ("{0} check(s) not complete: {1}" -f $ci.Pend.Count, (($ci.Pend | Select-Object -First 4) -join ', ')) }
  else { Add-Chk $L 'ci' 'PASS' ("{0} checks, all complete and green" -f $ci.Ok) }
  # new GameTests need a flake-stress run
  $paths = @(@($d.files) | ForEach-Object { [string]$_.path })
  $testish = @($paths | Where-Object { $_ -match '(?i)\.java$' -and $_ -match '(?i)test' })
  if ($testish.Count -eq 0) { Add-Chk $L 'gametests' 'PASS' 'no test file changed' }
  else {
    $df = Get-GateData $ctx 'diff' $n
    if (-not $df.Ok) { Add-Chk $L 'gametests' 'WARN' ('cannot read the diff to look for new @GameTest: ' + $df.Err) }
    else {
      $added = [regex]::Matches($df.Text, '(?m)^\+\s*@GameTest\b').Count
      if ($added -eq 0) { Add-Chk $L 'gametests' 'PASS' 'diff adds no @GameTest' }
      else {
        $ev = ''
        foreach ($c in @($d.comments)) { if ([string]$c.body -match '\[Stress\]' -and [string]$c.body -match '0 with any failure') { $ev = 'PR comment' } }
        if (-not $ev) {
          foreach ($r in (Get-GRows $ctx)) {
            $t = $r.Assignment + ' ' + $r.Note
            if ($t -match ('#' + [regex]::Escape($n) + '(?!\d)') -and $t -match '\[Stress\]' -and $t -match '\d{8,}') { $ev = 'ledger row ' + $r.Id }
          }
        }
        if ($ev) { Add-Chk $L 'gametests' 'PASS' ("{0} new @GameTest, flake-stress evidence: {1}" -f $added, $ev) }
        else { Add-Chk $L 'gametests' 'FAIL' ("{0} new @GameTest but no flake-stress evidence: need a PR comment with '[Stress]' and '0 with any failure', or a ledger row citing #{1}, '[Stress]' and a run id" -f $added, $n) }
      }
    }
  }
  # Mode A (M4)
  $ma = Join-Path $ctx.Root ('reviews\pr-' + $n + '-modeA.md')
  $reviewer = ''
  if (-not (Test-Path -LiteralPath $ma)) { Add-Chk $L 'modeA' 'FAIL' ("no Mode A review: reviews\pr-{0}-modeA.md is missing (COMMANDER s7: Mode A before every merge)" -f $n) }
  else {
    $t = Read-Text $ma
    $why = New-Object System.Collections.ArrayList
    $vm = [regex]::Match($t, '(?im)^\s*VERDICT:\s*([A-Za-z]+)')
    if (-not $vm.Success) { [void]$why.Add('no VERDICT line') } elseif ($vm.Groups[1].Value.ToUpper() -ne 'PASS') { [void]$why.Add('VERDICT is ' + $vm.Groups[1].Value) }
    $sm = [regex]::Match($t, '(?im)^\s*(?:HEAD\s*)?SHA:\s*([0-9a-f]{7,40})')
    if (-not $sm.Success) { [void]$why.Add('no SHA line') }
    elseif (-not $sha.ToLower().StartsWith($sm.Groups[1].Value.ToLower())) { [void]$why.Add(("stale: file reviewed {0}, PR head is {1}" -f $sm.Groups[1].Value.Substring(0, 8), $sha.Substring(0, 8))) }
    $rm = [regex]::Match($t, '(?im)^\s*REVIEWER:\s*(.+?)\s*$')
    if ($rm.Success) { $reviewer = $rm.Groups[1].Value } else { [void]$why.Add('no REVIEWER line') }
    if ($why.Count -eq 0) { Add-Chk $L 'modeA' 'PASS' ("VERDICT PASS for head {0}" -f $sha.Substring(0, 8)) } else { Add-Chk $L 'modeA' 'FAIL' ($why -join '; ') }
    # independence + freshness
    $w2 = New-Object System.Collections.ArrayList
    $hc = $null
    foreach ($c in @($d.commits)) { if ([string]$c.oid -eq $sha) { $hc = $c } }
    if ($null -eq $hc) { $hc = @($d.commits) | Select-Object -Last 1 }
    $ct = $null; if ($hc) { $ct = Get-GIso $hc.committedDate }
    $fm = [DateTimeOffset](Get-Item -LiteralPath $ma).LastWriteTimeUtc
    if ($ct -and $fm -lt $ct) { [void]$w2.Add(("review file written {0}Z, before head commit {1}Z" -f $fm.UtcDateTime.ToString('yyyy-MM-dd HH:mm'), $ct.UtcDateTime.ToString('yyyy-MM-dd HH:mm'))) }
    if ($reviewer) {
      $rl = $reviewer.ToLower().Trim()
      $rid = ''; $im = [regex]::Match($rl, '\[?id:([0-9a-z]{3,8})\]?'); if ($im.Success) { $rid = $im.Groups[1].Value }
      $bl = @(Get-GateBuilders $ctx $n)
      if ($bl.Count -eq 0) { [void]$w2.Add('WARNONLY no ledger row says "owns #' + $n + '", so builder vs reviewer cannot be compared') }
      foreach ($b in $bl) {
        $bm = ([string]$b.Model).ToLower().Trim()
        if ($rid -and $b.Id -eq $rid) { [void]$w2.Add("reviewer is the builder (same ledger row $($b.Id))") }
        elseif ($b.Id -and $rl.Contains($b.Id.ToLower())) { [void]$w2.Add("reviewer is the builder (names row $($b.Id))") }
        elseif ($bm -and $bm -eq $rl) { [void]$w2.Add("reviewer '$reviewer' equals the builder's model label '$($b.Model)' in row $($b.Id)") }
        elseif ($bm -match 'commander' -and $rl -match 'commander') { [void]$w2.Add("reviewer and builder are both the commander (row $($b.Id)): a fresh agent must review") }
      }
      if ($rid -and -not @(Get-GRows $ctx | Where-Object { $_.Id -eq $rid })) { [void]$w2.Add("reviewer id $rid is not in the ledger") }
    }
    $hard = @($w2 | Where-Object { $_ -notlike 'WARNONLY*' }); $soft = @($w2 | Where-Object { $_ -like 'WARNONLY*' })
    if ($hard.Count -gt 0) { Add-Chk $L 'modeA-independent' 'FAIL' ($hard -join '; ') }
    elseif ($soft.Count -gt 0) { Add-Chk $L 'modeA-independent' 'WARN' (($soft[0]) -replace '^WARNONLY ', '') }
    else { Add-Chk $L 'modeA-independent' 'PASS' ("reviewer '{0}' is not the builder; file newer than head commit" -f (Get-Trunc $reviewer 40)) }
  }
  $info.Reviewer = $reviewer
  # commit authors (M5)
  $id = Get-GateIdentity $ctx
  if ($null -eq $id) { Add-Chk $L 'authors' 'FAIL' 'cannot read the required identity from AGENTS.md' }
  else {
    $bad = @()
    foreach ($c in @($d.commits)) {
      $a = $null; if (@($c.authors).Count -gt 0) { $a = @($c.authors)[0] }
      $nm = ''; $em = ''; if ($a) { $nm = [string]$a.name; $em = [string]$a.email }
      if ($nm.ToLower() -ne $id.Name.ToLower() -or $em.ToLower() -ne $id.Email.ToLower()) { $bad += ('{0} {1} <{2}>' -f ([string]$c.oid).Substring(0, 7), $nm, $em) }
    }
    $tot = @($d.commits).Count
    if ($bad.Count -eq 0) { Add-Chk $L 'authors' 'PASS' ("all {0} commits authored as {1} <{2}>" -f $tot, $id.Name, $id.Email) }
    else { Add-Chk $L 'authors' 'FAIL' ("{0} of {1} commit(s) not authored as {2} <{3}>: {4}" -f $bad.Count, $tot, $id.Name, $id.Email, (($bad | Select-Object -First 3) -join '; ')) $bad }
  }
  # PR body
  $b = ([string]$d.body).Replace([string][char]0x2019, "'")
  if ([regex]::IsMatch($b, "(?i)do not merge without lovish's OK")) { Add-Chk $L 'body' 'PASS' 'body has "Do not merge without lovish''s OK"' }
  else { Add-Chk $L 'body' 'FAIL' 'PR body lacks the line "Do not merge without lovish''s OK"' }
  $ctx.AcceptInfo = $info
  return $L
}
function Write-GateEvidence($ctx, [string]$n, $checks, $info) {
  $dir = Join-Path $ctx.Root 'evidence'
  $cn = Get-GateCounts $checks
  $v = 'PASS'; if ($cn.F -gt 0) { $v = 'FAIL' }
  $o = [ordered]@{ pr = [int]$n; sha = [string]$info.Sha; time = (Get-GNow $ctx).ToString('yyyy-MM-ddTHH:mm:sszzz'); verdict = $v; reviewer = [string]$info.Reviewer
    checks = @($checks | ForEach-Object { [ordered]@{ name = $_.Name; status = $_.Status; reason = $_.Reason } }) }
  $p = Join-Path $dir ('pr-' + $n + '.json')
  Write-Text $p ($o | ConvertTo-Json -Depth 5) $false
  return $p
}
function Get-GateEvidence($ctx, [string]$n) {
  $p = Join-Path $ctx.Root ('evidence\pr-' + $n + '.json')
  if (-not (Test-Path -LiteralPath $p)) { return $null }
  return (ConvertFrom-GJson (Read-Text $p))
}

# ------------------------------------------------------------------ report-lint
function Split-ReportUnits([string]$text) {
  $lines = @(Split-Lines $text)
  $units = New-Object System.Collections.ArrayList
  $cur = $null; $heading = ''
  $i = 0
  if ($lines.Count -gt 0 -and $lines[0].Trim() -eq '---') { $i = 1; while ($i -lt $lines.Count -and $lines[$i].Trim() -ne '---') { $i++ }; $i++ }
  for (; $i -lt $lines.Count; $i++) {
    $ln = $lines[$i]
    if (-not $ln.Trim()) { $cur = $null; continue }
    if ($ln -match '^\s{0,3}#{1,6}\s') {
      $heading = $ln.Trim()
      [void]$units.Add(@{ Line = $i + 1; Text = $ln; Heading = $heading; IsHeading = $true }); $cur = $null; continue
    }
    if ($ln -match '^\s*([-*+]|\d+[.)])\s' -or $ln -match '^\s*\|') {
      $cur = @{ Line = $i + 1; Text = $ln; Heading = $heading; IsHeading = $false }; [void]$units.Add($cur); continue
    }
    if ($cur) { $cur.Text = $cur.Text + ' ' + $ln.Trim() } else { $cur = @{ Line = $i + 1; Text = $ln; Heading = $heading; IsHeading = $false }; [void]$units.Add($cur) }
  }
  return $units
}
function Invoke-ReportLint($ctx, [string]$file) {
  $flags = New-Object System.Collections.ArrayList
  $stat = @{ Claims = 0; Perf = 0; Quest = 0; Accepted = 0; PerfSuppressed = 0 }
  if (-not (Test-Path -LiteralPath $file)) { return @{ Flags = $flags; Stat = $stat; Error = ('file not found: ' + $file) } }
  $units = @(Split-ReportUnits (Read-Text $file))
  $claimRe = '(?i)\b(verified|measured|fixed|confirmed|tested|done)\b'
  $evRe = @('(?i)\brun\s*(id\s*)?#?\d{6,}', 'actions/runs/\d+', '\b\d{9,}\b', '[A-Za-z0-9_./\\-]+\.(java|ps1|md|json|py|yml|yaml|gradle|csv|txt):\d+', '\b[a-z][a-z0-9]*(_[a-z0-9]+){2,}\b', '\b[A-Z][A-Za-z0-9]*Tests?\b', '\[Stress\]', '\b(?=[0-9a-f]*\d)(?=[0-9a-f]*[a-f])[0-9a-f]{7,40}\b')
  $perfRe = '(?i)\d[\d,.]*\s?[kKmM]?\s?(ms|us|ns|fps|packets?/s|pkts?/s|/s|%)(?![A-Za-z0-9])'
  $perfCtx = '(?i)perf|frame|fps|tick|lag|faster|slower|latency|garbage|packet|cpu|\bgc\b|alloc|runtime|speed|throughput|draw call|zoom'
  $evCache = @{}
  foreach ($u in $units) {
    $t = $u.Text
    # claims
    # quotes and `code` are not claims; a short lead-in line ending with ':' ("Done tonight:") only introduces the bullets below it
    $tc = [regex]::Replace($t, '"[^"]*"|`[^`]*`', ' ')
    $lead = ($tc.Trim().EndsWith(':') -and $tc.Trim().Length -lt 40)
    foreach ($m in [regex]::Matches($tc, $claimRe)) {
      if ($lead) { break }
      $pre = $tc.Substring([Math]::Max(0, $m.Index - 24), [Math]::Min(24, $m.Index))
      if ($pre -match "(?i)\b(not|never|no|yet|without|nothing)\s+(\w+\s+)?$" -or $pre -match "(?i)n't\s+(\w+\s+)?$") { continue }
      if ($m.Value.ToLower() -eq 'fixed') {
        $post = $tc.Substring($m.Index + $m.Length)
        $isClaim = ($post -match '(?i)^\s*(in|by|on|with|the|it|this|that|these|those|via|and|as|after|before|at|for|to|\d|#|[.,;:)\]!]|$)') -or ($pre -match '(?i)\b(is|was|were|been|now|are|be|has|have|had|got|get|gets)\s*$')
        if (-not $isClaim) { continue }
      }
      $stat.Claims++
      $hard = $false; foreach ($re in $evRe) { if ([regex]::IsMatch($t, $re)) { $hard = $true; break } }
      $gate = $false
      foreach ($pm in [regex]::Matches($t, '#(\d{2,4})(?!\d)')) {
        $n = $pm.Groups[1].Value
        if (-not $evCache.ContainsKey($n)) {
          $ev = Get-GateEvidence $ctx $n; $ok = $false
          if ($ev -and $ev.verdict -eq 'PASS') { $pr = Get-GatePr $ctx $n; if ($pr -and [string]$pr.headRefOid -eq [string]$ev.sha) { $ok = $true } }
          $evCache[$n] = $ok
        }
        if ($evCache[$n]) { $gate = $true }
      }
      if ($gate) { $stat.Accepted++ }
      elseif ($hard) { $stat.Accepted++ }
      else {
        $why = 'claims "' + $m.Value + '" with no evidence in the same bullet (cite a run id, file:line, test name, or a PR whose gate passed)'
        if ([regex]::IsMatch($t, '#\d{2,4}(?!\d)')) { $why = 'claims "' + $m.Value + '" citing a PR with no passing, current gate evidence (run: cc.ps1 gate done -Pr N)' }
        [void]$flags.Add([pscustomobject]@{ Line = $u.Line; Kind = 'claim'; Why = $why; Text = (Get-Trunc $t 140) })
      }
      break
    }
    # perf numbers
    if (-not $u.IsHeading -and [regex]::IsMatch($t, $perfRe)) {
      $pm2 = [regex]::Match($t, $perfRe)
      $isPct = $pm2.Value.Trim().EndsWith('%')
      if (-not $isPct -or [regex]::IsMatch($t, $perfCtx)) {
        $stat.Perf++
        $est = [regex]::IsMatch($t, '(?i)estimat|unmeasured|not measured|projected') -or [regex]::IsMatch($u.Heading, '(?i)estimat|unmeasured|not measured')
        $run = [regex]::IsMatch($t, '(?i)\brun\s*(id\s*)?#?\d{6,}|actions/runs/\d+|\b\d{9,}\b')
        if ($est -or $run) { $stat.PerfSuppressed++ }
        else { [void]$flags.Add([pscustomobject]@{ Line = $u.Line; Kind = 'perf'; Why = ('perf number "' + $pm2.Value.Trim() + '" not marked estimate and no run id'); Text = (Get-Trunc $t 140) }) }
      }
    }
  }
  # questions to lovish
  $secN = 0; $secLine = 0; $inQ = $false; $secHead = ''; $qMark = 0
  foreach ($u in $units) {
    if ($u.IsHeading) {
      if ($inQ -and $secN -gt 5) { [void]$flags.Add([pscustomobject]@{ Line = $secLine; Kind = 'questions'; Why = ("{0} numbered items for lovish in one list (max 5)" -f $secN); Text = (Get-Trunc $secHead 100) }); $stat.Quest = [Math]::Max($stat.Quest, $secN) }
      $inQ = [regex]::IsMatch($u.Text, '(?i)decision|question|needs? (your|lovish)|for lovish|\basks?\b|approv'); $secN = 0; $secLine = $u.Line; $secHead = $u.Text; continue
    }
    if ($u.Text -match '^\s*\d+[.)]\s') { if ($inQ) { $secN++ }; if ($u.Text.Trim().EndsWith('?')) { $qMark++ } }
  }
  if ($inQ -and $secN -gt 5) { [void]$flags.Add([pscustomobject]@{ Line = $secLine; Kind = 'questions'; Why = ("{0} numbered items for lovish in one list (max 5)" -f $secN); Text = (Get-Trunc $secHead 100) }); $stat.Quest = [Math]::Max($stat.Quest, $secN) }
  if ($qMark -gt 5 -and $stat.Quest -eq 0) { [void]$flags.Add([pscustomobject]@{ Line = 0; Kind = 'questions'; Why = ("{0} numbered questions in the report (max 5)" -f $qMark); Text = '' }); $stat.Quest = $qMark }
  return @{ Flags = $flags; Stat = $stat; Error = '' }
}
function Get-ReportLintChecks($ctx, [string]$file) {
  $L = New-Object System.Collections.ArrayList
  $r = Invoke-ReportLint $ctx $file
  if ($r.Error) { Add-Chk $L 'report-lint' 'FAIL' $r.Error; return @{ Checks = $L; R = $r } }
  $nf = $r.Flags.Count
  if ($nf -eq 0) { Add-Chk $L 'report-lint' 'PASS' ("0 flagged ({0} claim(s) backed, {1} perf number(s) estimate-marked)" -f $r.Stat.Accepted, $r.Stat.PerfSuppressed) }
  else {
    $byk = (@($r.Flags | Group-Object Kind | ForEach-Object { $_.Name + '=' + $_.Count }) -join ', ')
    Add-Chk $L 'report-lint' 'FAIL' ("{0} flagged line(s) ({1}); {2} perf number(s) suppressed by an estimate label" -f $nf, $byk, $r.Stat.PerfSuppressed) @($r.Flags | ForEach-Object { 'line {0} [{1}] {2} :: {3}' -f $_.Line, $_.Kind, $_.Why, $_.Text })
  }
  return @{ Checks = $L; R = $r }
}

# ------------------------------------------------------------------ gate done
function Invoke-GateDone($ctx, [hashtable]$p) {
  $L = New-Object System.Collections.ArrayList
  if (-not $p.Pr -and -not $p.Report) { Add-Chk $L 'args' 'FAIL' 'gate done needs -Pr N and/or -Report <file>'; return $L }
  if ($p.Pr) {
    $a = Invoke-GateAccept $ctx ([string]$p.Pr)
    foreach ($c in $a) { [void]$L.Add($c) }
    $ev = Write-GateEvidence $ctx ([string]$p.Pr) $a $ctx.AcceptInfo
    Add-Chk $L 'evidence' 'PASS' ('written ' + $ev)
  }
  if ($p.Report) {
    $rc = Get-ReportLintChecks $ctx ([string]$p.Report)
    foreach ($c in $rc.Checks) { [void]$L.Add($c) }
  }
  return $L
}
