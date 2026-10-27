# cc-lib.ps1 - shared helpers for cc.ps1, kb.ps1, metrics.ps1. Dot-sourced. ASCII only, PowerShell 5.1.

$script:LibDir = Split-Path -Parent $MyInvocation.MyCommand.Path

function Get-NowET {
  $utc = [DateTimeOffset]::UtcNow
  foreach ($zid in @('Eastern Standard Time', 'America/New_York')) {
    try { $tz = [TimeZoneInfo]::FindSystemTimeZoneById($zid); return [TimeZoneInfo]::ConvertTime($utc, $tz) } catch { }
  }
  return $utc.ToOffset([TimeSpan]::FromHours(-5))
}

function Read-Text([string]$p) {
  if (-not (Test-Path -LiteralPath $p)) { return '' }
  return [IO.File]::ReadAllText($p, [Text.Encoding]::UTF8)
}
function Test-Bom([string]$p) {
  if (-not (Test-Path -LiteralPath $p)) { return $false }
  $b = New-Object byte[] 3
  $fs = [IO.File]::OpenRead($p)
  try { $n = $fs.Read($b, 0, 3) } finally { $fs.Close() }
  return ($n -eq 3 -and $b[0] -eq 0xEF -and $b[1] -eq 0xBB -and $b[2] -eq 0xBF)
}
function Write-Text([string]$p, [string]$t, [bool]$bom = $false) {
  $d = Split-Path -Parent $p
  if ($d -and -not (Test-Path -LiteralPath $d)) { New-Item -ItemType Directory -Force -Path $d | Out-Null }
  [IO.File]::WriteAllText($p, $t, (New-Object Text.UTF8Encoding($bom)))
}
function Split-Lines([string]$t) { return @($t -split "\r?\n") }
function Get-Section([string]$t, [string]$h) {
  $m = [regex]::Match($t, '(?m)^##\s*' + $h + '[^\r\n]*\r?\n')
  if (-not $m.Success) { return @() }
  $rest = $t.Substring($m.Index + $m.Length)
  $m2 = [regex]::Match($rest, '(?m)^##\s')
  if ($m2.Success) { $rest = $rest.Substring(0, $m2.Index) }
  return @(Split-Lines $rest | Where-Object { $_.Trim() })
}
function Get-Trunc([string]$s, [int]$n) {
  if ($null -eq $s) { return '' }
  $s = ($s -replace '\s+', ' ').Trim()
  if ($s.Length -le $n) { return $s }
  return $s.Substring(0, [Math]::Max(0, $n - 3)) + '...'
}

# ---- lock file (usage\.cc.lock) ----
function Enter-Lock([string]$Root) {
  $p = Join-Path $Root 'usage\.cc.lock'
  $d = Split-Path -Parent $p
  if (-not (Test-Path -LiteralPath $d)) { New-Item -ItemType Directory -Force -Path $d | Out-Null }
  for ($i = 0; $i -lt 400; $i++) {
    try {
      $fs = [IO.File]::Open($p, [IO.FileMode]::CreateNew, [IO.FileAccess]::Write, [IO.FileShare]::None)
      $bytes = [Text.Encoding]::ASCII.GetBytes("pid=$PID")
      $fs.Write($bytes, 0, $bytes.Length); $fs.Close()
      return $p
    } catch {
      try {
        $fi = Get-Item -LiteralPath $p -ErrorAction Stop
        if (((Get-Date) - $fi.LastWriteTime).TotalSeconds -gt 30) { Remove-Item -LiteralPath $p -Force -ErrorAction SilentlyContinue }
      } catch { }
      Start-Sleep -Milliseconds 100
    }
  }
  throw "lock busy: $p"
}
function Exit-Lock([string]$p) { if ($p) { Remove-Item -LiteralPath $p -Force -ErrorAction SilentlyContinue } }

# ---- state ----
function Get-State([string]$Root) {
  $p = Join-Path $Root 'usage\state.json'
  if (-not (Test-Path -LiteralPath $p)) { return $null }
  try { return ((Read-Text $p) | ConvertFrom-Json) } catch { return $null }
}
function Get-StateStart($st) {
  if ($null -eq $st -or -not $st.start) { return $null }
  if ($st.start -is [datetime]) { return [DateTimeOffset]$st.start }
  try { return [DateTimeOffset]::Parse([string]$st.start, [Globalization.CultureInfo]::InvariantCulture) } catch { return $null }
}

# ---- ledger parsing ----
function Get-Family([string]$m) {
  if ($m -match '(?i)(opus|fable|sonnet|haiku)') { return $Matches[1].ToLower() }
  return '(none)'
}
function ConvertTo-TokenCount([string]$s) {
  if (-not $s) { return [long]0 }
  $sum = [double]0
  foreach ($m in [regex]::Matches($s, '(?<![\$\d.])(\d[\d,]*(?:\.\d+)?)([kKmM])?(?!\w)')) {
    $v = [double](($m.Groups[1].Value) -replace ',', '')
    $sfx = $m.Groups[2].Value.ToLower()
    if ($sfx -eq 'k') { $v = $v * 1000 } elseif ($sfx -eq 'm') { $v = $v * 1000000 }
    $sum += $v
  }
  return [long]$sum
}
function Get-ResultClass([string]$r) {
  $x = $r.Trim().ToLower()
  if ($x -match '^pass') { return 'pass' }
  if ($x -match '^redo') { return 'redo' }
  if ($x -match '^escalat') { return 'escalated' }
  if ($x -match '^running') { return 'running' }
  if ($x -match '^pending') { return 'pending' }
  if ($x -match '^blocked') { return 'blocked' }
  return 'other'
}
function ConvertTo-LedgerRow([string]$line) {
  $t = $line.Trim()
  if (-not $t.StartsWith('|')) { return $null }
  if ($t -match '^\|\s*:?-{2,}') { return $null }
  if ($t -match '^\|\s*time\s*\|') { return $null }
  $inner = $t.Substring(1)
  if ($inner.EndsWith('|')) { $inner = $inner.Substring(0, $inner.Length - 1) }
  $c = @($inner -split '\|')
  if ($c.Count -lt 8) { return $null }
  $c = @($c | ForEach-Object { $_.Trim() })
  $note = ''
  if ($c.Count -ge 9) { $note = (($c[8..($c.Count - 1)]) -join '|').Trim() }
  $gen = $c[2]
  $gn = -1
  if ($gen -match '^\d+$') { $gn = [int]$gen }
  $id = ''
  if ($note -match '\[id:([0-9a-z]{3,8})\]') { $id = $Matches[1] }
  $kb = @()
  if ($note -match '\[kb:([^\]]*)\]') { $kb = @($Matches[1] -split '[,\s]+' | Where-Object { $_ }) }
  $o = New-Object psobject -Property ([ordered]@{
      Time = $c[0]; Acct = $c[1]; Gen = $gen; GenNum = $gn; Assignment = $c[3]; Model = $c[4]; Effort = $c[5]
      Tokens = $c[6]; Result = $c[7]; Note = $note
      Family = (Get-Family $c[4]); IsApi = [bool]($c[4] -match '(?i)api'); TokNum = (ConvertTo-TokenCount $c[6])
      Class = (Get-ResultClass $c[7]); Id = $id; Kb = $kb; Credited = [bool]($note -match '\[credited\]')
      File = ''; Date = ''; LineNo = 0
    })
  return $o
}
function Get-LedgerFiles([string]$Root) {
  $u = Join-Path $Root 'usage'
  if (-not (Test-Path -LiteralPath $u)) { return @() }
  return @(Get-ChildItem -LiteralPath $u -Filter 'ledger-*.md' -File | Sort-Object Name)
}
function Get-LedgerRows([string]$Root, [string]$Date = '') {
  $all = New-Object System.Collections.ArrayList
  foreach ($f in (Get-LedgerFiles $Root)) {
    $d = ''
    if ($f.Name -match '(\d{4}-\d{2}-\d{2})') { $d = $Matches[1] }
    if ($Date -and $d -ne $Date) { continue }
    $lines = Split-Lines (Read-Text $f.FullName)
    for ($i = 0; $i -lt $lines.Count; $i++) {
      $r = ConvertTo-LedgerRow $lines[$i]
      if ($r) { $r.File = $f.FullName; $r.Date = $d; $r.LineNo = $i + 1; [void]$all.Add($r) }
    }
  }
  return $all.ToArray()
}
function Get-RowStamp($r) {
  if ($r.Time -match '^(\d{1,2}):(\d{2})' -and $r.Date) {
    try { return [datetime]::ParseExact(($r.Date + ' ' + ('{0:D2}:{1}' -f [int]$Matches[1], $Matches[2])), 'yyyy-MM-dd HH:mm', [Globalization.CultureInfo]::InvariantCulture) } catch { return $null }
  }
  return $null
}
function Format-LedgerLine($r) {
  $f = @($r.Time, $r.Acct, $r.Gen, $r.Assignment, $r.Model, $r.Effort, $r.Tokens, $r.Result, $r.Note)
  $f = @($f | ForEach-Object { ([string]$_ -replace '[\r\n]+', ' ' -replace '\|', '/').Trim() })
  return '| ' + ($f -join ' | ') + ' |'
}
function New-LedgerId([string]$Root) {
  $have = @{}
  foreach ($r in (Get-LedgerRows $Root)) { if ($r.Id) { $have[$r.Id] = 1 } }
  while ($true) {
    $id = ('{0:x4}' -f (Get-Random -Minimum 4096 -Maximum 65535))
    if (-not $have.ContainsKey($id)) { return $id }
  }
}
$script:LedgerHeader = "| time | acct | gen | assignment | model | effort | tokens (if reported) | result: pass / redo / escalated | note |`n|---|---|---|---|---|---|---|---|---|"

# Append a row. $P keys: Assignment Model Effort Tokens Result Note. Returns the id.
function Add-LedgerRow([string]$Root, [hashtable]$P) {
  $st = Get-State $Root
  if ($null -eq $st) { throw 'no usage\state.json - run: cc.ps1 boot -Acct A|B first' }
  $now = Get-NowET
  $lock = Enter-Lock $Root
  try {
    $id = New-LedgerId $Root
    $note = [string]$P.Note
    $note = ($note + ' [id:' + $id + ']').Trim()
    $r = New-Object psobject -Property ([ordered]@{
        Time = $now.ToString('HH:mm'); Acct = [string]$st.acct; Gen = ('{0:D3}' -f [int]$st.gen); Assignment = [string]$P.Assignment
        Model = [string]$P.Model; Effort = [string]$P.Effort; Tokens = $(if ($P.Tokens) { [string]$P.Tokens } else { '-' })
        Result = $(if ($P.Result) { [string]$P.Result } else { 'running' }); Note = $note })
    $file = Join-Path $Root ('usage\ledger-' + $now.ToString('yyyy-MM-dd') + '.md')
    $line = Format-LedgerLine $r
    if (-not (Test-Path -LiteralPath $file)) {
      $txt = "# Usage ledger " + $now.ToString('yyyy-MM-dd') + "`n`n" + $script:LedgerHeader + "`n" + $line + "`n"
      Write-Text $file $txt $false
    } else {
      $cur = Read-Text $file
      $nl = "`n"
      if ($cur.Contains("`r`n")) { $nl = "`r`n" }
      if ($cur.Length -gt 0 -and -not $cur.EndsWith("`n")) { $cur = $cur + $nl }
      Write-Text $file ($cur + $line + $nl) (Test-Bom $file)
    }
    return $id
  } finally { Exit-Lock $lock }
}

# Rewrite a row found by [id:xxxx]. $Ch keys: Result, Tokens (replace), AppendNote. Returns the before/after lines.
function Update-LedgerRow([string]$Root, [string]$Id, [hashtable]$Ch) {
  $lock = Enter-Lock $Root
  try {
    $hit = $null
    foreach ($r in (Get-LedgerRows $Root)) { if ($r.Id -eq $Id) { $hit = $r } }
    if ($null -eq $hit) { throw "no ledger row with id $Id" }
    $txt = Read-Text $hit.File
    $nl = "`n"
    if ($txt.Contains("`r`n")) { $nl = "`r`n" }
    $lines = @($txt -split "\r?\n")
    $before = $lines[$hit.LineNo - 1]
    $row = ConvertTo-LedgerRow $before
    if ($Ch.ContainsKey('Result') -and $Ch.Result) { $row.Result = [string]$Ch.Result }
    if ($Ch.ContainsKey('Tokens') -and $Ch.Tokens) { $row.Tokens = [string]$Ch.Tokens }
    if ($Ch.ContainsKey('AppendNote') -and $Ch.AppendNote) {
      $n = $row.Note
      # keep the id/kb/credited tags at the end of the existing note; learn text goes last
      $row.Note = ($n + '; ' + $Ch.AppendNote).Trim('; ').Trim()
    }
    $after = Format-LedgerLine $row
    $lines[$hit.LineNo - 1] = $after
    Write-Text $hit.File ($lines -join $nl) (Test-Bom $hit.File)
    return @($before, $after)
  } finally { Exit-Lock $lock }
}

function Invoke-Offload([string]$Root, [string]$mdl, [string]$task, [string]$prompt, [string[]]$files, [int]$max) {
  $off = Join-Path $Root 'api\offload.ps1'
  if (-not (Test-Path -LiteralPath $off)) { $off = Join-Path (Split-Path -Parent $script:LibDir) 'api\offload.ps1' }
  $st = Get-State $Root
  if ($st) { $env:CC_ACCT = [string]$st.acct }
  $argl = @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', $off, '-Model', $mdl, '-Task', $task, '-Prompt', $prompt, '-MaxTokens', [string]$max)
  if ($files.Count -gt 0) { $argl += @('-Files', ($files -join ',')) }
  $old = $ErrorActionPreference; $ErrorActionPreference = 'Continue'
  try { $out = (& powershell @argl 2>&1 | Out-String).Trim() } finally { $ErrorActionPreference = $old }
  return $out
}
