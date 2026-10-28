# cc.ps1 - Command Center entry point (boot, ledger, handoff, checks, api wrappers). ASCII only, PowerShell 5.1.
# Usage: powershell -NoProfile -ExecutionPolicy Bypass -File "D:\Command Center\tools\cc.ps1" <subcommand> [options]
# See tools\README-cc.md. Time = system clock in America/New_York; acct and gen come from usage\state.json.
param(
  [Parameter(Position = 0)][string]$Cmd = 'help',
  [Parameter(Position = 1)][string]$Target = '',
  [string]$Root = 'D:\Command Center',
  [string]$Acct = '', [string]$Assignment = '', [string]$Model = '', [string]$Effort = '', [string]$Tier = '',
  [string]$Owns = '', [string]$Kb = '', [string]$Id = '', [string]$Result = '', [string]$Tokens = '',
  [string]$Note = '', [string]$Cause = '', [string]$Learn = '', [string]$Date = '', [string]$Pr = '',
  [string]$Branch = '', [string]$Repo = 'D:\BeyondAndTabs-Repo', [int]$Window = 200000, [string]$ClaudeDir = '', [string]$Session = '', [string]$CtxDir = '',
  [string]$Q = '', [int]$MaxTokens = 1500, [switch]$DryRun, [switch]$Force,
  # gate options (preflight / accept / report-lint / gate start|done)
  [string]$Task = '', [string]$Files = '', [string]$AllowOverlap = '', [string]$Override = '', [string]$Report = '', [string]$Stub = '',
  [switch]$EditsWorkflows, [switch]$Heavy, [switch]$NewPr, [switch]$NoCache, [switch]$NoLog, [switch]$Reviewer
)
$ErrorActionPreference = 'Stop'
$GateVerbose = ($VerbosePreference -eq 'Continue'); $VerbosePreference = 'SilentlyContinue'   # -Verbose = gate detail lines, not cmdlet chatter
. (Join-Path $PSScriptRoot 'cc-lib.ps1')
. (Join-Path $PSScriptRoot 'gate-lib.ps1')

function Fail([string]$m, [int]$code = 1) { Write-Output $m; exit $code }
function Need-State {
  $st = Get-State $Root
  if ($null -eq $st) { Fail 'ERR no usage\state.json - run: cc.ps1 boot -Acct A|B' 2 }
  return $st
}
function Find-GenFolder([string]$gen3) {
  $hd = Join-Path $Root 'command-center\handoffs'
  if (-not (Test-Path -LiteralPath $hd)) { return $null }
  $m = @(Get-ChildItem -LiteralPath $hd -Directory | Where-Object { $_.Name -like ("gen-$gen3-*") } | Sort-Object Name)
  if ($m.Count -eq 0) { return $null }
  return $m[$m.Count - 1]
}

# ------------------------------------------------------------------ boot
function Get-BootDigest([int]$gen, [string]$acct) {
  $L = New-Object System.Collections.ArrayList
  $now = Get-NowET
  [void]$L.Add(('BOOT acct {0} gen-{1:D3} {2}{3}' -f $acct, $gen, $now.ToString('yyyy-MM-dd HH:mm zzz'), $(if ($DryRun) { ' (DRY RUN, state.json not written)' } else { '' })))
  # handoff gaps
  $hd = Join-Path $Root 'command-center\handoffs'
  $gaps = @()
  $newest = $null; $newestN = -1
  if (Test-Path -LiteralPath $hd) {
    foreach ($d in (Get-ChildItem -LiteralPath $hd -Directory | Sort-Object Name)) {
      $miss = @()
      if (-not (Test-Path -LiteralPath (Join-Path $d.FullName 'HANDOFF.md'))) { $miss += 'HANDOFF.md' }
      if (-not (Test-Path -LiteralPath (Join-Path $d.FullName 'SELF-DIAGNOSIS.md'))) { $miss += 'SELF-DIAGNOSIS.md' }
      if ($miss.Count) { $gaps += ($d.Name + ' missing ' + ($miss -join ', ')) }
      if ($d.Name -match '^gen-(\d+)' -and [int]$Matches[1] -gt $newestN) { $newestN = [int]$Matches[1]; $newest = $d }
    }
  }
  if ($gaps.Count -eq 0) { [void]$L.Add('Handoff gaps: none') }
  else {
    [void]$L.Add('Handoff gaps: ' + $gaps.Count)
    foreach ($g in ($gaps | Select-Object -First 3)) { [void]$L.Add('  ' + $g) }
  }
  # auditor advice
  $unread = @()
  $ad = Join-Path $Root 'auditor\advice'
  if (Test-Path -LiteralPath $ad) {
    foreach ($f in (Get-ChildItem -LiteralPath $ad -Filter *.md -File | Sort-Object Name)) {
      $t = Read-Text $f.FullName
      $fm = ''
      if ($t -match '(?s)^\s*---\s*\r?\n(.*?)\r?\n---') { $fm = $Matches[1] }
      if ($fm -match '(?m)^status:\s*unread') {
        $h = @([regex]::Matches($t, '(?m)^##\s+(.+?)\s*$') | ForEach-Object { $_.Groups[1].Value })
        $unread += ($f.Name + ': ' + (Get-Trunc ($h -join ' ; ') 150))
      }
    }
  }
  if ($unread.Count -eq 0) { [void]$L.Add('Advice unread: none') }
  else { [void]$L.Add('Advice unread: ' + $unread.Count); foreach ($u in ($unread | Select-Object -First 3)) { [void]$L.Add('  ' + $u) } }
  # unannounced
  $ca = Read-Text (Join-Path $Root 'auditor\CHANGES-APPLIED.md')
  $un = @(Get-Section $ca 'Unannounced')
  if ($un.Count -eq 0) { [void]$L.Add('Unannounced changes: none') }
  else { [void]$L.Add('Unannounced changes: ' + $un.Count + ' (tell lovish, then move to Announced)'); foreach ($u in ($un | Select-Object -First 2)) { [void]$L.Add('  ' + (Get-Trunc $u 150)) } }
  # ledger tail
  $rows = @(Get-LedgerRows $Root)
  [void]$L.Add('Last 15 ledger rows (time acct gen model effort result | assignment):')
  $tail = @($rows | Select-Object -Last 15)
  foreach ($r in $tail) {
    [void]$L.Add(('  {0} {1} {2} {3}/{4} {5} | {6}' -f $r.Time, $r.Acct, $r.Gen, (Get-Trunc $r.Model 14), $r.Effort, (Get-Trunc $r.Result 10), (Get-Trunc $r.Assignment 70)))
  }
  # open heavy
  $heavy = @($rows | Where-Object { ($_.Family -eq 'opus' -or $_.Family -eq 'fable') -and $_.Effort -match 'xhigh' -and $_.Class -eq 'running' })
  $ha = @($heavy | Where-Object { $_.Acct -eq 'A' }).Count
  $hb = @($heavy | Where-Object { $_.Acct -eq 'B' }).Count
  [void]$L.Add(('Open heavy rows (opus/fable xhigh, running): A={0} B={1} (cap 2 per account)' -f $ha, $hb))
  foreach ($r in ($heavy | Select-Object -Last 2)) { [void]$L.Add(('  {0} {1} {2} {3}' -f $r.Date, $r.Time, $r.Acct, (Get-Trunc $r.Assignment 80))) }
  # counts
  $q = @($rows | Where-Object { $_.Acct -eq '?' -or $_.Gen -eq '?' }).Count
  $run = @($rows | Where-Object { $_.Class -eq 'running' }).Count
  [void]$L.Add(('Ledger counts: "?" rows={0}  running rows={1}  total rows={2}' -f $q, $run, $rows.Count))
  # spend
  $spent = [double]0; $budget = 200
  $sl = Join-Path $Root 'api\spend-log.csv'
  if (Test-Path -LiteralPath $sl) { try { foreach ($x in (Import-Csv -LiteralPath $sl)) { $spent += [double]$x.cost_usd } } catch { } }
  $cj = Join-Path $Root 'api\config.json'
  if (Test-Path -LiteralPath $cj) { try { $budget = [double]((Read-Text $cj | ConvertFrom-Json).budget_usd) } catch { } }
  [void]$L.Add(('API spend: ${0}/${1}' -f ([math]::Round($spent, 2)), $budget))
  # next 3 actions
  if ($newest) {
    $ho = Read-Text (Join-Path $newest.FullName 'HANDOFF.md')
    $acts = @(Get-Section $ho 'Next 3 actions')
    [void]$L.Add('Newest handoff ' + $newest.Name + ' - Next 3 actions:')
    if ($acts.Count -eq 0) { [void]$L.Add('  (none found)') }
    foreach ($a in ($acts | Select-Object -First 5)) { [void]$L.Add('  ' + (Get-Trunc $a 160)) }
  } else { [void]$L.Add('No handoff folders found.') }
  $out = @($L.ToArray())
  if ($out.Count -gt 40) { $out = @($out[0..38]) + @('  ...truncated to 40 lines') }
  return $out
}
function Cmd-Boot {
  if ($Acct -ne 'A' -and $Acct -ne 'B') { Fail 'ERR boot needs -Acct A|B' 2 }
  $lock = $null
  if (-not $DryRun) { $lock = Enter-Lock $Root }
  try {
    $max = 0
    $hd = Join-Path $Root 'command-center\handoffs'
    if (Test-Path -LiteralPath $hd) {
      foreach ($d in (Get-ChildItem -LiteralPath $hd -Directory)) { if ($d.Name -match '^gen-(\d+)') { if ([int]$Matches[1] -gt $max) { $max = [int]$Matches[1] } } }
    }
    foreach ($r in (Get-LedgerRows $Root)) { if ($r.GenNum -gt $max) { $max = $r.GenNum } }
    $st = Get-State $Root
    if ($st -and $st.gen -and [int]$st.gen -gt $max) { $max = [int]$st.gen }
    $gen = $max + 1
    $now = Get-NowET
    if (-not $DryRun) {
      $json = '{"acct":"' + $Acct + '","gen":' + $gen + ',"start":"' + $now.ToString("yyyy-MM-dd'T'HH:mm:sszzz") + '","boot_complete":false}'
      Write-Text (Join-Path $Root 'usage\state.json') $json $false
    }
    $dg = @(Get-BootDigest $gen $Acct)
  } finally { Exit-Lock $lock }
  $dg | ForEach-Object { Write-Output $_ }
}

# ------------------------------------------------------------------ ledger-add / close / tally
function Cmd-LedgerAdd {
  if (-not $Assignment -or -not $Model -or -not $Effort -or -not $Tier) { Fail 'ERR ledger-add needs -Assignment -Model -Effort -Tier' 2 }
  $note = 'tier: ' + $Tier
  if ($Owns) { $note += '; owns: ' + $Owns }
  if ($Kb) { $note += '; [kb:' + (($Kb -split '[,\s]+' | Where-Object { $_ }) -join ',') + ']' }
  $id = Add-LedgerRow $Root @{ Assignment = $Assignment; Model = $Model; Effort = $Effort; Tokens = '-'; Result = 'running'; Note = $note }
  Write-Output $id
}
function Cmd-LedgerClose {
  if (-not $Id) { Fail 'ERR ledger-close needs -Id' 2 }
  if (@('pass', 'redo', 'escalated') -notcontains $Result) { Fail 'ERR -Result must be pass|redo|escalated' 2 }
  if ($Cause -and (@('bad-premise', 'vague-brief', 'wrong-tier', 'lane-collision', 'flake', 'tool-limit', 'other') -notcontains $Cause)) { Fail 'ERR -Cause must be bad-premise|vague-brief|wrong-tier|lane-collision|flake|tool-limit|other' 2 }
  $parts = @('closed ' + (Get-NowET).ToString('HH:mm'))
  if ($Note) { $parts += $Note }
  if ($Cause) { $parts += 'cause: ' + $Cause }
  if ($Learn) { $parts += 'learn: ' + $Learn }
  try { $ba = Update-LedgerRow $Root $Id @{ Result = $Result; Tokens = $Tokens; AppendNote = ($parts -join '; ') } } catch { Fail ('ERR ' + $_.Exception.Message) 2 }
  Write-Output ('BEFORE ' + $ba[0])
  Write-Output ('AFTER  ' + $ba[1])
}
function Cmd-Tally {
  $d = $Date
  if (-not $d) { $d = (Get-NowET).ToString('yyyy-MM-dd') }
  $rows = @()
  if ($d -eq 'all') { $rows = @(Get-LedgerRows $Root) } else { $rows = @(Get-LedgerRows $Root $d) }
  Write-Output ('Tally ' + $d + ' rows=' + $rows.Count)
  Write-Output ('{0,-12} {1,5} {2,5} {3,5} {4,5} {5,8} {6,10}' -f 'model', 'rows', 'pass', 'redo', 'esc', 'running', 'tokens')
  $keys = @($rows | ForEach-Object { if ($_.IsApi) { $_.Family + ' (api)' } else { $_.Family } } | Sort-Object -Unique)
  foreach ($k in $keys) {
    $g = @($rows | Where-Object { $(if ($_.IsApi) { $_.Family + ' (api)' } else { $_.Family }) -eq $k })
    $run = @($g | Where-Object { $_.Class -eq 'running' -or $_.Class -eq 'pending' }).Count
    $tok = ($g | Measure-Object -Property TokNum -Sum).Sum
    Write-Output ('{0,-12} {1,5} {2,5} {3,5} {4,5} {5,8} {6,10}' -f $k, $g.Count, @($g | Where-Object { $_.Class -eq 'pass' }).Count, @($g | Where-Object { $_.Class -eq 'redo' }).Count, @($g | Where-Object { $_.Class -eq 'escalated' }).Count, $run, [long]$tok)
  }
}

# ------------------------------------------------------------------ branch-check
function Get-Iso($v) {
  if ($null -eq $v -or "$v" -eq '') { return $null }
  if ($v -is [datetime]) { return [DateTimeOffset]$v }
  try { return [DateTimeOffset]::Parse([string]$v, [Globalization.CultureInfo]::InvariantCulture) } catch { return $null }
}
function Run-Gh([string[]]$a) {
  if (-not (Get-Command gh -ErrorAction SilentlyContinue)) { return @{ Code = 127; Out = 'gh not found on PATH' } }
  $old = $ErrorActionPreference; $ErrorActionPreference = 'Continue'
  Push-Location $Repo
  try { $o = (& gh @a 2>&1 | Out-String); $c = $LASTEXITCODE } finally { Pop-Location; $ErrorActionPreference = $old }
  return @{ Code = $c; Out = $o }
}
function Cmd-BranchCheck {
  if (-not $Pr -and -not $Branch) { Fail 'ERR branch-check needs -Pr N or -Branch name' 2 }
  $st = Get-State $Root
  $myGen = -1; if ($st) { $myGen = [int]$st.gen }
  $now = Get-NowET
  $reasons = New-Object System.Collections.ArrayList
  $unknown = $false
  $label = ''
  $lastCommit = $null; $lastComment = $null
  $prNum = $Pr
  if (-not $prNum -and $Branch) {
    $r = Run-Gh @('pr', 'list', '--head', $Branch, '--state', 'open', '--json', 'number')
    if ($r.Code -eq 0) { try { $j = @($r.Out | ConvertFrom-Json); if ($j.Count -gt 0) { $prNum = [string]$j[0].number } } catch { } }
  }
  if ($prNum) {
    $label = 'PR #' + $prNum
    $r = Run-Gh @('pr', 'view', $prNum, '--json', 'number,headRefName,state,updatedAt,commits,comments')
    if ($r.Code -ne 0) { $unknown = $true; Write-Output ('WARN gh pr view failed: ' + (Get-Trunc $r.Out 160)) }
    else {
      $j = $r.Out | ConvertFrom-Json
      if ($j.headRefName -and -not $Branch) { $Branch = [string]$j.headRefName }
      $label += ' (' + $j.state + ', branch ' + $j.headRefName + ')'
      foreach ($c in @($j.commits)) { $t = Get-Iso $c.committedDate; if ($t -and (($null -eq $lastCommit) -or $t -gt $lastCommit)) { $lastCommit = $t } }
      $own = @{}; foreach ($r in (Get-LedgerRows $Root)) { if ($r.GenNum -eq $myGen -and $r.Id) { $own[[string]$r.Id] = 1 } }
      foreach ($c in @($j.comments)) { if (Test-OwnGenComment ([string]$c.body) $own) { continue }; $t = Get-Iso $c.createdAt; if ($t -and (($null -eq $lastComment) -or $t -gt $lastComment)) { $lastComment = $t } }
    }
  } else {
    $label = 'branch ' + $Branch
    $old = $ErrorActionPreference; $ErrorActionPreference = 'Continue'
    $t = $null
    foreach ($ref in @(('origin/' + $Branch), $Branch)) {
      $o = (& git -C $Repo log -1 --format=%cI $ref 2>$null | Out-String).Trim()
      if ($LASTEXITCODE -eq 0 -and $o) { $t = Get-Iso $o; break }
    }
    $ErrorActionPreference = $old
    if ($t) { $lastCommit = $t } else { $unknown = $true; Write-Output 'WARN no PR found and git log found no such branch ref' }
  }
  Write-Output ('branch-check ' + $label)
  if ($lastCommit) { $mins = [int]($now - $lastCommit).TotalMinutes; Write-Output ("last commit:  {0} min ago" -f $mins); if ($mins -lt 120) { [void]$reasons.Add("commit $mins min ago (<2h, another session may be on it)") } }
  else { Write-Output 'last commit:  unknown' }
  if ($lastComment) { $mins = [int]($now - $lastComment).TotalMinutes; Write-Output ("last comment: {0} min ago" -f $mins); if ($mins -lt 120) { [void]$reasons.Add("PR comment $mins min ago (<2h)") } }
  else { Write-Output 'last comment: none/unknown' }
  # ledger
  $pat = @()
  if ($prNum) { $pat += ('(?<![\w])#' + [regex]::Escape($prNum) + '(?!\d)'); $pat += ('(?i)\bPR\s*#?' + [regex]::Escape($prNum) + '(?!\d)') }
  if ($Branch) { $pat += [regex]::Escape($Branch) }
  $hits = New-Object System.Collections.ArrayList
  foreach ($r in (Get-LedgerRows $Root)) {
    $txt = $r.Assignment + ' ' + $r.Note
    $m = $false
    foreach ($p in $pat) { if ($txt -match $p) { $m = $true } }
    if ($m) { [void]$hits.Add($r) }
  }
  Write-Output ('ledger rows mentioning it: ' + $hits.Count + ' (last 5)')
  foreach ($r in ($hits | Select-Object -Last 5)) { Write-Output ('  {0} {1} {2} gen-{3} {4} | {5}' -f $r.Date, $r.Time, $r.Acct, $r.Gen, (Get-Trunc $r.Result 10), (Get-Trunc $r.Assignment 80)) }
  foreach ($r in $hits) {
    if ($r.GenNum -eq $myGen) { continue }
    if ($r.Assignment -match '(?i)boot') { [void]$reasons.Add("gen-$($r.Gen) owns it in a boot row ($($r.Date) $($r.Time))") }
    elseif ($r.Class -eq 'running') { [void]$reasons.Add("gen-$($r.Gen) has a running ledger row for it ($($r.Date) $($r.Time))") }
    $stamp = Get-RowStamp $r
    if ($stamp) {
      $age = ($now.DateTime - $stamp).TotalMinutes
      if ($age -ge -5 -and $age -lt 120 -and $r.Assignment -notmatch '(?i)boot') { [void]$reasons.Add("gen-$($r.Gen) touched it $([int]$age) min ago per ledger") }
    }
  }
  if ($reasons.Count -gt 0) { Write-Output 'BLOCKED:'; foreach ($x in ($reasons | Select-Object -Unique)) { Write-Output ('  - ' + $x) }; exit 1 }
  if ($unknown) { Write-Output 'UNKNOWN: could not verify commit/comment times (fail closed). Ledger shows no blocker.'; exit 2 }
  Write-Output 'OK: no other gen touched it within 2h and no boot-row owner'
}

# ------------------------------------------------------------------ ctx
function Cmd-Ctx {
  # D041: read the REAL context % that statusline-ctx.ps1 writes per session; estimate only as the fallback.
  $dir = $CtxDir
  if (-not $dir) { $dir = $env:CC_CTX_DIR }
  if (-not $dir -and $env:LOCALAPPDATA) { $dir = Join-Path $env:LOCALAPPDATA 'CommandCenter\ctx' }
  if ($dir -and (Test-Path -LiteralPath $dir)) {
    $st = @(Get-ChildItem -LiteralPath $dir -Filter '*.json' -File | Sort-Object LastWriteTime -Descending)
    if ($Session) { $st = @($st | Where-Object { $_.BaseName -eq $Session }) }
    else { $st = @($st | Where-Object { $_.LastWriteTime -gt (Get-Date).AddHours(-12) }) }
    if ($st.Count -gt 0) {
      foreach ($f in $st) {
        try { $o = (Get-Content -LiteralPath $f.FullName -Raw) | ConvertFrom-Json } catch { continue }
        $pct = [double]$o.used_percentage
        $ageMin = [int]((Get-Date) - $f.LastWriteTime).TotalMinutes
        $act = ''
        if ($pct -ge 50) { $act = '  HAND OFF now (stop new work)' } elseif ($pct -ge 40) { $act = '  start the handoff' }
        Write-Output ('ctx {0}% of {1} tokens  session {2}  updated {3} min ago{4}' -f $pct, $o.context_window_size, $o.session_id, $ageMin, $act)
      }
      return
    }
    if ($Session) { Write-Output ('ctx: no statusline file for session ' + $Session + ' in ' + $dir); return }
  }
  Write-Output 'ctx: no statusline data (run tools\install-guards.ps1); falling back to the transcript ESTIMATE below'
  Cmd-CtxEstimate
}

function Get-HandoffShapeIssues([string]$p) {
  # Handoff shape (Joisco pack + gen-013 slip): <= 10 KB, exactly one RESUME HERE, no appended update blocks, a dead-ends list.
  $why = New-Object System.Collections.ArrayList
  $len = (Get-Item -LiteralPath $p).Length
  if ($len -gt 10240) { [void]$why.Add(('HANDOFF.md is {0} bytes (limit 10240): rewrite to one RESUME HERE block, move history to an archive file' -f $len)) }
  $t = Read-Text $p
  $rh = [regex]::Matches($t, '(?im)^#{1,3}\s*RESUME HERE').Count
  if ($rh -ne 1) { [void]$why.Add(('needs exactly one "## RESUME HERE" heading (found {0})' -f $rh)) }
  $up = [regex]::Matches($t, '(?im)^#{1,3}\s*Update after handoff').Count
  if ($up -gt 0) { [void]$why.Add(('{0} appended "Update after handoff" block(s): fold them into RESUME HERE' -f $up)) }
  if (-not [regex]::IsMatch($t, '(?im)^#{1,3}\s*(Dead ends|Ruled out)')) { [void]$why.Add('missing a "## Dead ends / ruled out" section') }
  return ,$why
}
function Cmd-HandoffLint {
  if (-not $Target) { Fail 'ERR handoff-lint <path to HANDOFF.md>' 2 }
  if (-not (Test-Path -LiteralPath $Target)) { Fail ('ERR not found: ' + $Target) 2 }
  $w = Get-HandoffShapeIssues $Target
  if ($w.Count -eq 0) { Write-Output 'PASS handoff-lint'; return }
  Write-Output 'FAIL handoff-lint'
  foreach ($x in $w) { Write-Output ('  - ' + $x) }
  exit 1
}

function Cmd-CtxEstimate {
  $base = $ClaudeDir
  if (-not $base) { $base = Join-Path $env:USERPROFILE '.claude\projects' }
  $files = @()
  if (Test-Path -LiteralPath $base) { $files = @(Get-ChildItem -Path (Join-Path $base '*\*.jsonl') -File -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending) }
  if ($files.Count -eq 0) { Write-Output ('ctx: no session files found under ' + $base); return }
  $f = $files[0]
  foreach ($tailN in @(400, 4000)) {
    $lines = @(Get-Content -LiteralPath $f.FullName -Tail $tailN -Encoding UTF8)
    for ($i = $lines.Count - 1; $i -ge 0; $i--) {
      $ln = $lines[$i]
      if ($ln -notmatch '"type"\s*:\s*"assistant"' -or $ln -notmatch '"usage"') { continue }
      try { $o = $ln | ConvertFrom-Json } catch { continue }
      if ($o.isSidechain -eq $true) { continue }
      $u = $o.message.usage
      if ($null -eq $u) { continue }
      $tot = [long]0
      foreach ($k in @('input_tokens', 'cache_read_input_tokens', 'cache_creation_input_tokens')) { if ($u.$k) { $tot += [long]$u.$k } }
      $pct = [math]::Round(100.0 * $tot / $Window, 1)
      $ageMin = [int]((Get-Date) - $f.LastWriteTime).TotalMinutes
      Write-Output ("ctx ~{0}% ({1} of {2} tokens) session {3} updated {4} min ago" -f $pct, $tot, $Window, $f.Name, $ageMin)
      if ($pct -ge 50) { Write-Output 'STOP new work, hand off now (COMMANDER s4: stop by ~50%)' }
      elseif ($pct -ge 40) { Write-Output 'Start the handoff (COMMANDER s4: ~40%)' }
      return
    }
  }
  Write-Output ('ctx: no assistant usage found in newest session ' + $f.FullName)
}

# ------------------------------------------------------------------ handoff-stub / verify
function Get-GenSummary($rows) {
  $fam = @('haiku', 'sonnet', 'opus', 'fable')
  $o = @{}
  $o.n = $rows.Count
  $o.redo = @($rows | Where-Object { $_.Class -eq 'redo' }).Count
  $o.esc = @($rows | Where-Object { $_.Class -eq 'escalated' }).Count
  $o.by = @{}; $o.tok = @{}
  foreach ($f in $fam) {
    $g = @($rows | Where-Object { $_.Family -eq $f })
    $o.by[$f] = $g.Count
    $o.tok[$f] = [long](($g | Measure-Object -Property TokNum -Sum).Sum)
  }
  $o.unclosed = @($rows | Where-Object { $_.Class -eq 'running' -or $_.Class -eq 'pending' })
  return $o
}
function Cmd-HandoffStub {
  $st = Need-State
  $gen3 = '{0:D3}' -f [int]$st.gen
  $now = Get-NowET
  $existing = Find-GenFolder $gen3
  if ($existing -and -not $Force) { Fail ('ERR handoff folder exists: ' + $existing.FullName + ' (use -Force to reuse)') }
  $dir = Join-Path $Root ('command-center\handoffs\gen-' + $gen3 + '-' + $now.ToString('yyyy-MM-dd-HHmm'))
  if ($existing) { $dir = $existing.FullName }
  $rows = @(Get-LedgerRows $Root | Where-Object { $_.GenNum -eq [int]$st.gen })
  $sum = Get-GenSummary $rows
  $tokLine = (@('haiku', 'sonnet', 'opus', 'fable') | ForEach-Object { $_ + ' ' + $sum.tok[$_] }) -join ' / '
  $byLine = (@('haiku', 'sonnet', 'opus', 'fable') | ForEach-Object { $_ + ' ' + $sum.by[$_] }) -join ' / '
  $wt = 'unavailable'
  $old = $ErrorActionPreference; $ErrorActionPreference = 'Continue'
  try { $w = (& git -C $Repo worktree list 2>&1 | Out-String).Trim(); if ($LASTEXITCODE -eq 0 -and $w) { $wt = $w } else { $wt = 'git worktree list failed: ' + (Get-Trunc $w 120) } } catch { $wt = 'git not available' }
  $ErrorActionPreference = $old
  New-Item -ItemType Directory -Force -Path $dir | Out-Null

  # HANDOFF.md
  $tpl = Split-Lines (Read-Text (Join-Path $Root 'command-center\HANDOFF-TEMPLATE.md'))
  $o = New-Object System.Collections.ArrayList
  $sec = ''
  foreach ($ln in $tpl) {
    if ($ln -match '^# Handoff') { [void]$o.Add(('# Handoff - gen-{0} to gen-{1:D3}' -f $gen3, ([int]$st.gen + 1))); continue }
    if ($ln -match '^Date/time') { [void]$o.Add(('Date/time: {0} | Account: {1} | Estimated context used at handoff: ~TODO%' -f $now.ToString('yyyy-MM-dd HH:mm zzz'), $st.acct)); continue }
    if ($ln -match '^##\s*(.*)') {
      $sec = $Matches[1]
      [void]$o.Add($ln)
      if ($sec -match '^Done this generation') {
        [void]$o.Add(('Computed: assignments {0}, redos {1}, escalations {2}, unclosed {3}' -f $sum.n, $sum.redo, $sum.esc, $sum.unclosed.Count))
        [void]$o.Add('By model: ' + $byLine)
        [void]$o.Add('Tokens: ' + $tokLine)
        foreach ($r in $rows) { [void]$o.Add(('- [{0}] {1} {2} {3}/{4} -> {5}{6}: {7}' -f $(if ($r.Id) { $r.Id } else { 'no-id' }), $r.Date, $r.Time, $r.Family, $r.Effort, $r.Result, $(if ($r.Tokens -ne '-') { ' (' + $r.Tokens + ')' } else { '' }), (Get-Trunc $r.Assignment 110))) }
        [void]$o.Add('TODO: condense the list above into what was achieved')
      } elseif ($sec -match '^In flight') {
        if ($sum.unclosed.Count -eq 0) { [void]$o.Add('Unclosed rows: none') } else { [void]$o.Add('Unclosed rows:'); foreach ($r in $sum.unclosed) { [void]$o.Add(('- [{0}] {1} {2}: {3}' -f $r.Id, $r.Time, $r.Result, (Get-Trunc $r.Assignment 110))) } }
        [void]$o.Add('TODO: agents running and where their files are')
      } elseif ($sec -match '^Repo') {
        [void]$o.Add('git worktree list:'); [void]$o.Add('```'); [void]$o.Add($wt); [void]$o.Add('```')
        [void]$o.Add('TODO: this gen branch and any claims')
      } elseif ($sec -match '^(Goal|Decisions|Open questions)') { [void]$o.Add('TODO') }
      continue
    }
    if ($ln -match '^([123])\.\s*$') { [void]$o.Add($Matches[1] + '. TODO'); continue }
    [void]$o.Add($ln)
  }
  Write-Text (Join-Path $dir 'HANDOFF.md') (($o -join "`r`n") + "`r`n") $false

  # SELF-DIAGNOSIS.md
  $tpl = Split-Lines (Read-Text (Join-Path $Root 'command-center\SELF-DIAGNOSIS-TEMPLATE.md'))
  $o = New-Object System.Collections.ArrayList
  $rate = 0; if ($sum.n -gt 0) { $rate = [math]::Round(100.0 * ($sum.redo + $sum.esc) / $sum.n, 1) }
  foreach ($ln in $tpl) {
    if ($ln -match '^# Self-diagnosis') { [void]$o.Add('# Self-diagnosis - gen-' + $gen3); continue }
    if ($ln -match '^- Assignments:') { [void]$o.Add(('- Assignments: {0} by model: {1}' -f $sum.n, ($byLine))); continue }
    if ($ln -match '^- Redos:') { [void]$o.Add(('- Redos: {0} escalations: {1} rate: {2}% (redo+escalated / assignments)' -f $sum.redo, $sum.esc, $rate)); [void]$o.Add('- Tokens by model: ' + $tokLine + '; unclosed rows: ' + $sum.unclosed.Count); continue }
    if ($ln -match '^- (Work I did|Agents that were)') { [void]$o.Add($ln + ' TODO'); continue }
    if ($ln -match '^- To (lessons|model-routing)') { [void]$o.Add($ln + ' TODO'); continue }
    [void]$o.Add($ln)
    if ($ln -match '^## (Mistakes|Efficiency|Auditor advice)') { [void]$o.Add('TODO') }
  }
  Write-Text (Join-Path $dir 'SELF-DIAGNOSIS.md') (($o -join "`r`n") + "`r`n") $false
  Write-Output ('handoff stub written: ' + $dir)
  Write-Output ('  rows {0}, redo {1}, esc {2}, unclosed {3}; fill every TODO, then run handoff-verify' -f $sum.n, $sum.redo, $sum.esc, $sum.unclosed.Count)
}
function Cmd-HandoffVerify {
  $st = Need-State
  $gen3 = '{0:D3}' -f [int]$st.gen
  $why = New-Object System.Collections.ArrayList
  $dir = Find-GenFolder $gen3
  if ($null -eq $dir) { [void]$why.Add("no handoff folder for gen-$gen3") }
  else {
    foreach ($n in @('HANDOFF.md', 'SELF-DIAGNOSIS.md')) {
      $p = Join-Path $dir.FullName $n
      if (-not (Test-Path -LiteralPath $p)) { [void]$why.Add("$n missing") }
      else {
        $t = Read-Text $p
        $c = [regex]::Matches($t, '\bTODO\b').Count
        if ($c -gt 0) { [void]$why.Add("$n has $c unfilled TODO marker(s)") }
        if ($n -eq 'HANDOFF.md') { foreach ($x in (Get-HandoffShapeIssues $p)) { [void]$why.Add($x) } }
      }
    }
  }
  $run = @(Get-LedgerRows $Root | Where-Object { $_.GenNum -eq [int]$st.gen -and $_.Class -eq 'running' })
  if ($run.Count -gt 0) { [void]$why.Add(("{0} row(s) of gen-{1} still running: {2}" -f $run.Count, $gen3, (($run | ForEach-Object { if ($_.Id) { $_.Id } else { $_.Time } }) -join ','))) }
  $ml = Join-Path $Root 'command-center\mistakes-ledger.md'
  $start = Get-StateStart $st
  if (-not (Test-Path -LiteralPath $ml)) { [void]$why.Add('mistakes-ledger.md missing') }
  elseif ($null -eq $start) { [void]$why.Add('state.json start unreadable') }
  elseif ((Get-Item -LiteralPath $ml).LastWriteTimeUtc -le $start.UtcDateTime) { [void]$why.Add('mistakes-ledger.md not modified since state.start (' + $start.ToString('yyyy-MM-dd HH:mm') + ')') }
  if ($why.Count -eq 0) { Write-Output ('PASS handoff-verify gen-' + $gen3); return }
  Write-Output ('FAIL handoff-verify gen-' + $gen3)
  foreach ($w in $why) { Write-Output ('  - ' + $w) }
  exit 1
}

# ------------------------------------------------------------------ advice-done
function Cmd-AdviceDone {
  $st = Need-State
  if (-not $Target) { Fail 'ERR advice-done <file>' 2 }
  $p = $Target
  if (-not (Test-Path -LiteralPath $p)) { $p = Join-Path $Root ('auditor\advice\' + $Target) }
  if (-not (Test-Path -LiteralPath $p)) { Fail ('ERR advice file not found: ' + $Target) 2 }
  $gen3 = '{0:D3}' -f [int]$st.gen
  $txt = Read-Text $p
  $nl = "`n"; if ($txt.Contains("`r`n")) { $nl = "`r`n" }
  $new = 'status: applied gen-' + $gen3
  if ($txt -match '(?m)^status:[^\r\n]*') { $txt = [regex]::Replace($txt, '(?m)^status:[^\r\n]*', $new, 1) }
  elseif ($txt -match '^\s*---') { $txt = [regex]::Replace($txt, '^(\s*---[^\r\n]*\r?\n)', ('$1' + $new + $nl), 1) }
  else { $txt = '---' + $nl + $new + $nl + '---' + $nl + $txt }
  Write-Text $p $txt (Test-Bom $p)
  $ca = Join-Path $Root 'auditor\CHANGES-APPLIED.md'
  $ct = Read-Text $ca
  $cnl = "`n"; if ($ct.Contains("`r`n")) { $cnl = "`r`n" }
  $name = Split-Path -Leaf $p
  $line = '- [' + (Get-NowET).ToString('yyyy-MM-dd') + ', gen-' + $gen3 + '] APPLIED: advice ' + $name + ' marked applied' + $(if ($Note) { ' - ' + $Note } else { '' })
  $m = [regex]::Match($ct, '(?m)^##\s*Unannounced[^\r\n]*\r?\n')
  if (-not $m.Success) { $ct = $ct.TrimEnd() + $cnl + $cnl + '## Unannounced' + $cnl + $line + $cnl }
  else {
    $after = $ct.Substring($m.Index + $m.Length)
    $m2 = [regex]::Match($after, '(?m)^##\s')
    $secEnd = $after.Length; if ($m2.Success) { $secEnd = $m2.Index }
    $body = $after.Substring(0, $secEnd).TrimEnd("`r", "`n")
    $rest = $after.Substring($secEnd)
    $ins = $m.Value + $(if ($body) { $body + $cnl } else { '' }) + $line + $cnl + $(if ($rest) { $cnl } else { '' })
    $ct = $ct.Substring(0, $m.Index) + $ins + $rest
  }
  Write-Text $ca $ct (Test-Bom $ca)
  Write-Output ('advice ' + $name + ' -> ' + $new)
  Write-Output ('CHANGES-APPLIED Unannounced += ' + $line)
}

# ------------------------------------------------------------------ api wrappers
function Log-ApiRow([string]$assign, [string]$mdlLabel, [string]$eff, [string]$out) {
  if ($null -eq (Get-State $Root)) { Write-Output 'WARN no state.json - api row not logged'; return }
  $res = 'pass'; $tok = '-'; $note = 'tier: chore; api'
  if ($out -match '^OK\s') {
    $in = 0; $ot = 0; $cost = ''
    if ($out -match 'in=(\d+)') { $in = [int]$Matches[1] }
    if ($out -match 'out=(\d+)') { $ot = [int]$Matches[1] }
    if ($out -match 'cost=\$([0-9.]+)') { $cost = $Matches[1] }
    $tok = "$in in / $ot out, `$$cost"
    $note = 'tier: chore; api cost $' + $cost
    if ($out -match '-> (.+?)(\s+WARN.*)?$') { $note += '; out: ' + $Matches[1].Trim() }
  } else { $res = 'redo'; $note = 'tier: chore; api ERR: ' + (Get-Trunc $out 120) }
  $id = Add-LedgerRow $Root @{ Assignment = $assign; Model = $mdlLabel; Effort = $eff; Tokens = $tok; Result = $res; Note = $note }
  Write-Output ('ledger id: ' + $id)
}
function Cmd-Digest {
  if (-not $Target) { Fail 'ERR digest <path|glob> [-Q question]' 2 }
  Need-State | Out-Null
  $fl = @(Get-ChildItem -Path $Target -File -ErrorAction SilentlyContinue | Select-Object -First 20)
  if ($fl.Count -eq 0 -and (Test-Path -LiteralPath $Target -PathType Container)) { $fl = @(Get-ChildItem -LiteralPath $Target -File | Select-Object -First 20) }
  if ($fl.Count -eq 0) { Fail ('ERR no files match ' + $Target) 2 }
  $bytes = ($fl | Measure-Object -Property Length -Sum).Sum
  if ($bytes -gt 1500000 -and -not $Force) { Fail ('ERR ' + $bytes + ' bytes is large; narrow the glob or use -Force') 2 }
  $q = $Q
  if (-not $q) { $q = 'Digest these files: key facts, numbers, decisions and open problems, as at most 15 bullets. Say when unsure.' }
  $label = 'digest ' + (Get-Trunc ($fl | ForEach-Object { $_.Name } | Select-Object -First 3 | Out-String).Replace("`r`n", ' ') 60)
  $out = Invoke-Offload $Root 'haiku' 'cc-digest' $q @($fl | ForEach-Object { $_.FullName }) $MaxTokens
  Write-Output $out
  Log-ApiRow ($label + ' (' + $fl.Count + ' files)') 'haiku (api)' 'low' $out
}
function Cmd-ReviewDiff {
  if (-not $Pr) { Fail 'ERR review-diff -Pr N' 2 }
  Need-State | Out-Null
  $r = Run-Gh @('pr', 'diff', $Pr)
  if ($r.Code -ne 0) { Fail ('ERR gh pr diff failed: ' + (Get-Trunc $r.Out 200)) 2 }
  $tmp = Join-Path $env:TEMP ('cc-pr' + $Pr + '-diff.patch')
  Write-Text $tmp $r.Out $false
  $q = $Q
  if (-not $q) { $q = 'Review this PR diff for a Minecraft mod. List concrete bugs, regression risks, missing tests, thread-safety and gating problems, most severe first, citing file and hunk. Max 20 bullets. Say when unsure.' }
  $out = Invoke-Offload $Root 'sonnet' ('cc-review-pr' + $Pr) $q @($tmp) ([math]::Max($MaxTokens, 3000))
  Write-Output $out
  Log-ApiRow ('review-diff PR #' + $Pr) 'sonnet (api)' 'medium' $out
}

# ------------------------------------------------------------------ gates (logic in gate-lib.ps1; no model calls)
function New-CcGateCtx { return (New-GateCtx @{ Root = $Root; Repo = $Repo; Stub = $Stub; NoCache = [bool]$NoCache; NoLog = [bool]$NoLog; Verbose = $GateVerbose }) }
function Get-StartParams { return @{ Task = $Task; Pr = $Pr; Branch = $Branch; Files = $Files; EditsWorkflows = [bool]$EditsWorkflows; Heavy = [bool]$Heavy; NewPr = [bool]$NewPr; Reviewer = [bool]$Reviewer; AllowOverlap = $AllowOverlap; Override = $Override } }
function Finish-Gate($ctx, [string]$title, $checks, $sw, [string]$logTitle) {
  Write-GateResult $ctx $title $checks $sw
  Write-GateLedger $ctx $logTitle $checks $sw
  if (-not $ctx.LastOk) { exit 1 }
}
function Cmd-Preflight {
  $sw = [Diagnostics.Stopwatch]::StartNew(); $ctx = New-CcGateCtx
  $c = Invoke-GatePreflight $ctx (Get-StartParams)
  Finish-Gate $ctx 'start' $c $sw ('preflight: ' + (Get-Trunc $Task 80))
}
function Cmd-Accept {
  if (-not $Pr) { Fail 'ERR accept needs -Pr N' 2 }
  $sw = [Diagnostics.Stopwatch]::StartNew(); $ctx = New-CcGateCtx
  $c = Invoke-GateAccept $ctx $Pr
  $c2 = New-Object System.Collections.ArrayList; foreach ($x in $c) { [void]$c2.Add($x) }
  $ev = Write-GateEvidence $ctx $Pr $c $ctx.AcceptInfo
  Add-Chk $c2 'evidence' 'PASS' ('written ' + $ev)
  Finish-Gate $ctx ('accept #' + $Pr) $c2 $sw ('accept PR #' + $Pr)
}
function Cmd-ReportLint {
  $f = $Target; if (-not $f) { $f = $Report }
  if (-not $f) { Fail 'ERR report-lint <file>' 2 }
  $sw = [Diagnostics.Stopwatch]::StartNew(); $ctx = New-CcGateCtx
  $rc = Get-ReportLintChecks $ctx $f
  foreach ($fl in @($rc.R.Flags | Select-Object -First 40)) { Write-Output ('  line {0} [{1}] {2} :: {3}' -f $fl.Line, $fl.Kind, $fl.Why, $fl.Text) }
  $ctx.Verbose = $false
  Finish-Gate $ctx 'report-lint' $rc.Checks $sw ('report-lint ' + (Split-Path -Leaf $f))
}
function Cmd-LedgerLint {
  $sw = [Diagnostics.Stopwatch]::StartNew(); $ctx = New-CcGateCtx
  $c = Invoke-LedgerLint $ctx $Date
  Finish-Gate $ctx 'ledger-lint' $c $sw 'ledger-lint'
}
function Cmd-BootDone {
  Need-State | Out-Null
  $sw = [Diagnostics.Stopwatch]::StartNew(); $ctx = New-CcGateCtx
  $c = Invoke-BootDone $ctx ([bool]$Force)
  Finish-Gate $ctx 'boot-done' $c $sw 'boot-done'
}
# gate start = preflight. gate done = accept (-Pr) + report-lint (-Report); writes evidence\pr-N.json.
function Cmd-Gate {
  $sw = [Diagnostics.Stopwatch]::StartNew(); $ctx = New-CcGateCtx
  if ($Target -eq 'start') {
    $c = Invoke-GatePreflight $ctx (Get-StartParams)
    Finish-Gate $ctx 'start' $c $sw ('start: ' + (Get-Trunc $Task 80))
  } elseif ($Target -eq 'done') {
    $c = Invoke-GateDone $ctx @{ Pr = $Pr; Report = $Report }
    $t = 'done'; if ($Pr) { $t = 'done #' + $Pr }
    Finish-Gate $ctx $t $c $sw $t
  } else { Fail 'ERR gate start|done  (start: -Task [-Pr -Branch -Files -EditsWorkflows -Heavy -NewPr -Reviewer]; done: -Pr N [-Report file])' 2 }
}
function Cmd-GateSelftest {
  . (Join-Path $PSScriptRoot 'gate-selftest.ps1')
  Invoke-GateSelftest $PSScriptRoot $GateVerbose
  if (-not $script:StOk) { exit 1 }
}

function Show-Help {
  Write-Output 'cc.ps1 <boot|boot-done|ledger-add|ledger-close|tally|branch-check|ctx [-Session id]|handoff-lint <file>|handoff-stub|handoff-verify|advice-done|digest|review-diff|gate start|gate done|preflight|accept|report-lint|ledger-lint|gate-selftest> [options]  (see tools\README-cc.md)'
}

switch ($Cmd) {
  'boot' { Cmd-Boot }
  'ledger-add' { Cmd-LedgerAdd }
  'ledger-close' { Cmd-LedgerClose }
  'tally' { Cmd-Tally }
  'branch-check' { Cmd-BranchCheck }
  'ctx' { Cmd-Ctx }
  'handoff-lint' { Cmd-HandoffLint }
  'handoff-stub' { Cmd-HandoffStub }
  'handoff-verify' { Cmd-HandoffVerify }
  'advice-done' { Cmd-AdviceDone }
  'digest' { Cmd-Digest }
  'review-diff' { Cmd-ReviewDiff }
  'gate' { Cmd-Gate }
  'preflight' { Cmd-Preflight }
  'accept' { Cmd-Accept }
  'report-lint' { Cmd-ReportLint }
  'ledger-lint' { Cmd-LedgerLint }
  'boot-done' { Cmd-BootDone }
  'gate-selftest' { Cmd-GateSelftest }
  default { Show-Help }
}
