# run-job.ps1 - wraps every nightly job with the guardrails. ASCII only, PowerShell 5.1. Fails closed.
#   run-job.ps1 -Job main-red|flake-digest|stale-sweep|ledger-tally|auditor [-Date yyyy-MM-dd]
#   run-job.ps1 -Rehash            (human/commander only, after reviewing changes: scans, then rewrites hashes.json)
#   run-job.ps1 -Check             (scan all job scripts + verify hashes, run nothing)
#   run-job.ps1 -ScanFile <path>   (run the static scan on any file)
# Guardrails, in order: PAUSED file -> job name whitelist -> config -> SHA-256 of job scripts, lib and config vs hashes.json
# -> static scan of job scripts -> spend (hard stop, nightly model budget) -> lock -> ledger row -> run with timeout, killed by
# its own PID tree -> ledger close. On any failure: a line in notes\ALERTS.txt (same message at most once per 6 h), no retry.
# gh in Task Scheduler: the keyring login is not visible there, so gh jobs read the User env var CC_GH_TOKEN (never printed).
param([string]$Job = '', [switch]$Rehash, [switch]$Check, [string]$ScanFile = '', [string]$Root = 'D:\Command Center', [string]$Date = '', [double]$SimulateSpend = 0)
# -SimulateSpend only ADDS pretend dollars to today's and the total spend (to test the budget gates); it can never loosen a gate.
$ErrorActionPreference = 'Stop'
$jobsDir = Join-Path $Root 'tools\jobs'
$nj = Join-Path $Root 'notes\jobs'
$Known = @('main-red', 'flake-digest', 'stale-sweep', 'ledger-tally', 'auditor')
$ModelNeed = @{ 'main-red' = 'maybe'; 'flake-digest' = 'no'; 'stale-sweep' = 'no'; 'ledger-tally' = 'maybe'; 'auditor' = 'yes' }
$NeedsGh = @('main-red', 'flake-digest', 'stale-sweep')
$LedgerModel = @{ 'main-red' = 'script'; 'flake-digest' = 'script'; 'stale-sweep' = 'script'; 'ledger-tally' = 'script'; 'auditor' = 'sonnet (api)' }
$HashSet = @('job-lib.ps1', 'config.json') + @($Known | ForEach-Object { $_ + '.ps1' })
$hashFile = Join-Path $jobsDir 'hashes.json'

function A([string]$s) { if ($null -eq $s) { return '' }; return [regex]::Replace($s, '[^\x20-\x7E]', '?') }
function Append-Text([string]$path, [string]$line) {
  $d = Split-Path -Parent $path
  if (-not (Test-Path -LiteralPath $d)) { New-Item -ItemType Directory -Force -Path $d | Out-Null }
  [IO.File]::AppendAllText($path, ($line + "`r`n"), (New-Object System.Text.ASCIIEncoding))
}
function Log([string]$m) {
  $p = Join-Path $nj 'jobs.log'
  Append-Text $p ((Get-Date).ToString('yyyy-MM-dd HH:mm:ss') + ' ' + (A $m))
  try { if ((Get-Item -LiteralPath $p).Length -gt 300000) { $t = Get-Content -LiteralPath $p -Tail 2000; [IO.File]::WriteAllText($p, (($t -join "`r`n") + "`r`n"), (New-Object System.Text.ASCIIEncoding)) } } catch { }
}
function Alert([string]$m) {
  $line = (A $m); if ($line.Length -gt 400) { $line = $line.Substring(0, 400) }
  $p = Join-Path $Root 'notes\ALERTS.txt'; $dup = $false
  try {
    if (Test-Path -LiteralPath $p) {
      $key = ($line -replace '\s+', ' ')
      if ($key.Length -gt 90) { $key = $key.Substring(0, 90) }
      foreach ($old in (Get-Content -LiteralPath $p -Tail 60)) {
        if ($old.Length -gt 17 -and $old.Contains($key)) { if (((Get-Date) - [datetime]::ParseExact($old.Substring(0, 16), 'yyyy-MM-dd HH:mm', $null)).TotalHours -lt 6) { $dup = $true } }
      }
    }
  } catch { }
  if (-not $dup) { Append-Text $p ((Get-Date).ToString('yyyy-MM-dd HH:mm') + ' ' + $line) }
  Log ('ALERT ' + $line + $(if ($dup) { ' (repeat, not re-added to ALERTS.txt)' } else { '' }))
}
function Sha([string]$f) { (Get-FileHash -LiteralPath $f -Algorithm SHA256).Hash.ToLower() }

# static tripwire: job scripts may only read. The real boundary is job-lib.ps1 (Gh-Raw/Git-Read allow lists, Assert-Writable).
function Scan-File([string]$f) {
  $bad = New-Object System.Collections.ArrayList; $n = 0
  foreach ($line in (Get-Content -LiteralPath $f)) {
    $n++; $t = $line.Trim()
    if ($t.StartsWith('#') -or -not $t) { continue }
    $code = $t
    if ($code -match '(?i)\b(gh|git)(\.exe)?\s+(-C\s+\S+\s+)?(push|commit|add|rm|mv|reset|checkout|switch|merge|rebase|pull|clean|restore|stash|tag|apply|cherry-pick|revert|config|remote|branch|issue|release|repo|workflow|label|secret|gist|pr\s+(comment|merge|close|edit|create|review|ready|reopen)|run\s+(rerun|cancel|delete|watch))\b') { [void]$bad.Add("$n forbidden gh/git subcommand") }
    if ($code -match "(?i)'(-X|--method|-f|-F|--field|--raw-field|--input|graphql)'") { [void]$bad.Add("$n gh api write/graphql flag") }
    if ($code -match "(?i)'(comment|merge|close|reopen|rerun|cancel|delete|create|edit|review|ready|push|commit)'") { [void]$bad.Add("$n forbidden gh verb literal") }
    if ($code -match '(?i)\b(Set-Content|Add-Content|Out-File|New-Item|Remove-Item|Copy-Item|Move-Item|Rename-Item|Clear-Content|Set-ItemProperty|Tee-Object|WriteAllText|WriteAllLines|WriteAllBytes|AppendAllText|AppendAllLines)\b') { [void]$bad.Add("$n direct file write (use Write-Out/Remove-Out)") }
    if ($code -match '\s>>?\s*[\$"''A-Za-z]:?[\\\$"'']') { [void]$bad.Add("$n output redirect") }
    if ($code -match '(?i)\b(Invoke-WebRequest|Invoke-RestMethod|Invoke-Expression|iex|curl|wget|Start-Process|WebClient|Net\.Sockets|Set-ExecutionPolicy|schtasks|Register-ScheduledTask|Unregister-ScheduledTask|Stop-Process|taskkill|reg\s+add|setx|SetEnvironmentVariable|Import-Module|Add-Type)\b') { [void]$bad.Add("$n forbidden command (network, process, schedule, env, dynamic code)") }
    if ($code -match '^\.\s+' -and $code -notmatch "^\.\s+\(Join-Path \`$PSScriptRoot 'job-lib\.ps1'\)\s*$") { [void]$bad.Add("$n dot-source of something other than job-lib.ps1") }
  }
  return $bad.ToArray()
}
function Scan-All {
  $all = @()
  foreach ($k in $Known) {
    $f = Join-Path $jobsDir ($k + '.ps1')
    if (-not (Test-Path -LiteralPath $f)) { $all += ($k + '.ps1: missing'); continue }
    foreach ($b in @(Scan-File $f)) { $all += ($k + '.ps1 line ' + $b) }
  }
  return $all
}

# ---------- maintenance modes ----------
if ($ScanFile) { $r = @(Scan-File $ScanFile); if ($r.Count) { $r | ForEach-Object { Write-Output ('SCAN FAIL ' + $_) }; exit 4 } else { Write-Output 'SCAN OK'; exit 0 } }
if ($Rehash) {
  $v = @(Scan-All)
  if ($v.Count) { $v | ForEach-Object { Write-Output ('SCAN FAIL ' + $_) }; Write-Output 'REHASH REFUSED: fix the scan failures first'; exit 4 }
  $h = [ordered]@{}
  foreach ($n in $HashSet) { $f = Join-Path $jobsDir $n; if (-not (Test-Path -LiteralPath $f)) { Write-Output "REHASH REFUSED: $n missing"; exit 4 }; $h[$n] = Sha $f }
  $o = [ordered]@{ rehashed = (Get-Date).ToString('s'); by = $env:USERNAME; files = $h }
  [IO.File]::WriteAllText($hashFile, ($o | ConvertTo-Json -Depth 4), (New-Object System.Text.ASCIIEncoding))
  Log 'rehash done'
  Write-Output ('REHASH OK ' + $h.Count + ' files'); exit 0
}
function Verify-Hashes {
  if (-not (Test-Path -LiteralPath $hashFile)) { return 'hashes.json missing' }
  try { $j = Get-Content -LiteralPath $hashFile -Raw | ConvertFrom-Json } catch { return 'hashes.json unreadable' }
  foreach ($n in $HashSet) {
    $f = Join-Path $jobsDir $n
    $want = [string]$j.files.$n
    if (-not $want) { return "$n has no recorded hash" }
    if (-not (Test-Path -LiteralPath $f)) { return "$n missing" }
    if ((Sha $f) -ne $want) { return "$n changed since the last rehash" }
  }
  return ''
}
if ($Check) {
  $hv = Verify-Hashes; $sv = @(Scan-All)
  Write-Output ('hashes: ' + $(if ($hv) { 'FAIL ' + $hv } else { 'OK' }))
  Write-Output ('scan: ' + $(if ($sv.Count) { 'FAIL ' + ($sv -join '; ') } else { 'OK' }))
  if ($hv -or $sv.Count) { exit 3 } else { exit 0 }
}

# ---------- guarded run ----------
if (Test-Path -LiteralPath (Join-Path $Root 'PAUSED')) { Log ("$Job paused"); Write-Output 'paused'; exit 0 }
if ($Known -notcontains $Job) { Log ("refused unknown job '" + (A $Job) + "'"); Write-Output 'ERR unknown job'; exit 2 }
try { $cfg = Get-Content -LiteralPath (Join-Path $jobsDir 'config.json') -Raw | ConvertFrom-Json; $budget = [double]$cfg.nightly_budget_usd; $hard = [double]$cfg.hard_stop_usd; $tmo = [int]$cfg.timeouts_min.$Job; if ($budget -le 0 -or $hard -le 0 -or $tmo -le 0) { throw 'bad values' } }
catch { Alert "$Job refused: config.json unreadable or invalid"; Write-Output 'ERR config'; exit 3 }
$hv = Verify-Hashes
if ($hv) { Alert "$Job REFUSED: $hv. Review tools\jobs, then run run-job.ps1 -Rehash"; Write-Output ('REFUSED: ' + $hv); exit 3 }
$sv = @(Scan-All)
if ($sv.Count) { Alert ("$Job REFUSED: static scan failed: " + ($sv -join '; ')); Write-Output 'REFUSED: scan'; exit 3 }

# spend (own reader: runs before the lib is trusted)
function Read-Spend {
  $log = Join-Path $Root 'api\spend-log.csv'; $today = (Get-Date).ToString('yyyy-MM-dd'); $t = 0.0; $tot = 0.0; $n = 0
  if (Test-Path -LiteralPath $log) {
    foreach ($r in (Import-Csv -LiteralPath $log)) {
      $c = 0.0; [void][double]::TryParse([string]$r.cost_usd, [Globalization.NumberStyles]::Float, [Globalization.CultureInfo]::InvariantCulture, [ref]$c)
      $tot += $c; $n++; if ([string]$r.time -like ($today + '*')) { $t += $c }
    }
  }
  return @{ today = $t; total = $tot; rows = $n }
}
try { $sp = Read-Spend } catch { Alert "$Job refused: cannot read api\spend-log.csv"; exit 3 }
if ($SimulateSpend -gt 0) { $sp.today += $SimulateSpend; $sp.total += $SimulateSpend }
$spTxt = ('today $' + [math]::Round($sp.today, 4) + ' of $' + $budget + ' nightly, total $' + [math]::Round($sp.total, 2) + ' of $' + $hard + ' hard stop')
if ($sp.total -ge $hard) { Log "$Job skipped: total spend at or over hard stop ($spTxt)"; Alert "$Job skipped: total API spend over hard stop"; Write-Output 'skipped: hard stop'; exit 0 }
$modelOk = 1; if ($sp.today -ge $budget) { $modelOk = 0 }
if ($ModelNeed[$Job] -eq 'yes' -and $modelOk -eq 0) { Log "$Job skipped: nightly model budget spent ($spTxt)"; Write-Output 'skipped: nightly budget'; exit 0 }

# gh jobs: token for the Task Scheduler context (keyring is not visible there); never printed or logged. No login -> refuse, no ledger spam.
if ($NeedsGh -contains $Job) {
  $tok = [Environment]::GetEnvironmentVariable('CC_GH_TOKEN', 'Process'); if (-not $tok) { $tok = [Environment]::GetEnvironmentVariable('CC_GH_TOKEN', 'User') }
  if ($tok) { $env:GH_TOKEN = $tok }
  $ErrorActionPreference = 'Continue'
  & gh auth status *> $null
  $ghOk = ($LASTEXITCODE -eq 0)
  $ErrorActionPreference = 'Stop'
  if (-not $ghOk) { Alert "$Job refused: gh is not authenticated in this context. Set the User env var CC_GH_TOKEN (read-only token, see tools\jobs\README.md)"; Write-Output 'REFUSED: gh not authenticated'; exit 3 }
}

# lock (one run per job at a time)
$lock = Join-Path $nj ($Job + '.lock')
if (Test-Path -LiteralPath $lock) {
  try {
    $l = Get-Content -LiteralPath $lock -Raw | ConvertFrom-Json
    $alive = [bool](Get-Process -Id ([int]$l.pid) -ErrorAction SilentlyContinue)
    if ($alive -and (((Get-Date) - [datetime]$l.started).TotalMinutes -lt (2 * $tmo))) { Log "$Job skipped: already running (pid $($l.pid))"; Write-Output 'skipped: running'; exit 0 }
  } catch { }
}
Append-Text $lock ''; [IO.File]::WriteAllText($lock, ((@{ pid = $PID; started = (Get-Date).ToString('s') } | ConvertTo-Json -Compress)), (New-Object System.Text.ASCIIEncoding))

$id = ''; $rc = 1; $timedOut = $false; $summary = ''; $cost = 0.0
$cc = Join-Path $Root 'tools\cc.ps1'
try {
  # ledger row (retry once: another agent may hold the ledger lock)
  for ($try = 1; $try -le 2 -and -not $id; $try++) {
    $ErrorActionPreference = 'Continue'
    $o = & powershell -NoProfile -ExecutionPolicy Bypass -File $cc ledger-add -Assignment ("scheduled job $Job (nightly jobs, D037)") -Model $LedgerModel[$Job] -Effort low -Tier mechanical 2>&1
    $ErrorActionPreference = 'Stop'
    $last = ((@($o) | ForEach-Object { [string]$_ } | Where-Object { $_.Trim() }) | Select-Object -Last 1)
    if ($last -match '^\s*([0-9a-f]{4})\s*$') { $id = $Matches[1] } elseif ($try -lt 2) { Start-Sleep -Seconds 4 }
  }
  if (-not $id) { Alert "$Job not run: could not write the ledger row"; Write-Output 'ERR ledger-add'; exit 1 }

  $before = $sp.rows
  $outF = Join-Path $nj ('last-' + $Job + '.out'); $errF = Join-Path $nj ('last-' + $Job + '.err')
  $argl = @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', ('"' + (Join-Path $jobsDir ($Job + '.ps1')) + '"'), '-Root', ('"' + $Root + '"'), '-ModelOk', "$modelOk")
  if ($Date) { if ($Date -notmatch '^\d{4}-\d{2}-\d{2}$') { throw 'bad -Date' }; $argl += @('-Date', $Date) }
  $p = Start-Process -FilePath 'powershell.exe' -ArgumentList $argl -PassThru -WindowStyle Hidden -RedirectStandardOutput $outF -RedirectStandardError $errF
  $null = $p.Handle
  if (-not $p.WaitForExit($tmo * 60 * 1000)) {
    $timedOut = $true
    & taskkill /PID $p.Id /T /F | Out-Null     # its own PID tree only, never by image name
    Start-Sleep -Seconds 2
  } else { $p.WaitForExit(); $rc = $p.ExitCode }
  if ($timedOut) { $rc = 5 }

  $txt = ''; if (Test-Path -LiteralPath $outF) { $raw = Get-Content -LiteralPath $outF -Raw; if ($raw) { $txt = [string]$raw } }
  $sm = [regex]::Matches($txt, '(?m)^SUMMARY:\s*(.+)$'); if ($sm.Count) { $summary = $sm[$sm.Count - 1].Groups[1].Value.Trim() }
  if (-not $summary -and $rc -ne 0) {
    $et = ''; if (Test-Path -LiteralPath $errF) { $raw2 = Get-Content -LiteralPath $errF -Raw; if ($raw2) { $et = [string]$raw2 } }
    if ($et -match 'gh auth login') { $summary = 'gh is not authenticated in this context: set the User env var CC_GH_TOKEN (see README.md)' }
    else { $summary = 'no summary; ' + ((A $et) -replace '\s+', ' ') }
  }
  $summary = (A $summary) -replace '[\r\n|]+', ' '; if ($summary.Length -gt 200) { $summary = $summary.Substring(0, 200) }
  try { $rows = @(Import-Csv -LiteralPath (Join-Path $Root 'api\spend-log.csv')); for ($i = $before; $i -lt $rows.Count; $i++) { $c = 0.0; [void][double]::TryParse([string]$rows[$i].cost_usd, [Globalization.NumberStyles]::Float, [Globalization.CultureInfo]::InvariantCulture, [ref]$c); $cost += $c } } catch { }
}
catch { $rc = 1; $summary = 'run-job error: ' + ((A $_.Exception.Message) -replace '\s+', ' ') }
finally {
  Remove-Item -LiteralPath $lock -Force -ErrorAction SilentlyContinue
}
$costTxt = ('cost $' + ('{0:N4}' -f $cost))
if ($timedOut) { $res = 'escalated'; $why = "TIMEOUT after $tmo min, killed pid tree"; Alert "$Job timed out after $tmo min (killed)" }
elseif ($rc -ne 0) { $res = 'escalated'; $why = "exit $rc"; Alert "$Job failed (exit $rc): $summary" }
else { $res = 'pass'; $why = 'ok' }
if ($id) {
  $ErrorActionPreference = 'Continue'
  $cl = & powershell -NoProfile -ExecutionPolicy Bypass -File $cc ledger-close -Id $id -Result $res -Note ("$why; $costTxt; $summary") 2>&1
  if ($LASTEXITCODE -ne 0) { Alert "$Job ledger-close failed for row $id" }
}
Log ("$Job $res id=$id $costTxt rc=$rc :: $summary")
Write-Output ("$Job $res id=$id $costTxt :: $summary")
if ($res -eq 'pass') { exit 0 } else { exit 1 }
