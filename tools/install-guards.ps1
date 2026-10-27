# install-guards.ps1 - lovish runs this himself (D036, D041, D042; "add everything", Oct 27 03:22).
# 1) runs the tests (test-ctx-qguard 19 cases + gate-selftest) and stops if anything fails;
# 2) backs up %USERPROFILE%\.claude\settings.json, then adds: the statusLine (real context %), the question-guard
#    Stop hook, and the gate hook (PreToolUse on Task|Agent and Bash). Existing entries are kept; re-running is safe.
# Usage:  powershell -NoProfile -ExecutionPolicy Bypass -File "D:\Command Center\tools\install-guards.ps1"
#         add -Uninstall to remove exactly these entries again; -SkipTests only if you ran the tests yourself.
# Off switches without uninstalling: create %LOCALAPPDATA%\CommandCenter\hooks-off\question-guard (empty file).
param([switch]$Uninstall, [switch]$SkipTests)
$ErrorActionPreference = 'Stop'
$T = $PSScriptRoot
$ps = (Get-Process -Id $PID).Path
function Cmd([string]$f) { return ('powershell -NoProfile -ExecutionPolicy Bypass -File "' + (Join-Path $T $f) + '"') }
$ours = @('statusline-ctx.ps1', 'question-guard.ps1', 'gate-hook.ps1')
function IsOurs($h) { foreach ($n in $ours) { if ([string]$h.command -like ('*' + $n + '*')) { return $true } }; return $false }

if (-not $Uninstall -and -not $SkipTests) {
  Write-Host '== tests: test-ctx-qguard.ps1'
  & $ps -NoProfile -ExecutionPolicy Bypass -File (Join-Path $T 'test-ctx-qguard.ps1')
  if ($LASTEXITCODE -ne 0) { Write-Host 'Tests FAILED: nothing installed. Send the FAIL lines to Claude.'; exit 1 }
  Write-Host '== tests: cc.ps1 gate-selftest'
  & $ps -NoProfile -ExecutionPolicy Bypass -File (Join-Path $T 'cc.ps1') gate-selftest
  if ($LASTEXITCODE -ne 0) { Write-Host 'gate-selftest FAILED: nothing installed.'; exit 1 }
}

if (-not $Uninstall) {
  # Claude sessions are refused when they use -ExecutionPolicy Bypass (Joisco saw the same), and this PC's policy is
  # Restricted, so no Claude session can run cc.ps1 / the gates today. RemoteSigned for YOUR user lets local scripts run
  # (downloaded scripts still need a signature). Your choice; it is asked, never set silently.
  $pol = Get-ExecutionPolicy -Scope CurrentUser
  if ($pol -ne 'RemoteSigned' -and $pol -ne 'Unrestricted' -and $pol -ne 'Bypass') {
    Write-Host ('Your user execution policy is ' + $pol + '. Claude sessions cannot run the Command Center scripts until it is RemoteSigned.')
    $a = Read-Host 'Set CurrentUser to RemoteSigned? Type YES to set it, anything else skips'
    if ($a -eq 'YES') { Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned -Force; Write-Host 'CurrentUser policy: RemoteSigned' }
    else { Write-Host 'Skipped: sessions still cannot run cc.ps1 themselves.' }
  }
}

$dir = Join-Path $env:USERPROFILE '.claude'
$sp = Join-Path $dir 'settings.json'
if (-not (Test-Path -LiteralPath $dir)) { New-Item -ItemType Directory -Force -Path $dir | Out-Null }
$s = New-Object psobject
if (Test-Path -LiteralPath $sp) {
  $raw = Get-Content -LiteralPath $sp -Raw
  if ($raw.Trim()) { $s = $raw | ConvertFrom-Json }
  $bak = $sp + '.bak-' + (Get-Date).ToString('yyyyMMdd-HHmmss')
  Copy-Item -LiteralPath $sp -Destination $bak
  Write-Host ('Backup: ' + $bak)
}
if (-not ($s.PSObject.Properties.Name -contains 'hooks')) { $s | Add-Member -NotePropertyName hooks -NotePropertyValue (New-Object psobject) }
foreach ($ev in @('PreToolUse', 'Stop')) {
  if (-not ($s.hooks.PSObject.Properties.Name -contains $ev)) { $s.hooks | Add-Member -NotePropertyName $ev -NotePropertyValue @() }
  # drop our old entries first (idempotent re-install, and the whole uninstall)
  $keep = @()
  foreach ($grp in @($s.hooks.$ev)) {
    $hs = @(@($grp.hooks) | Where-Object { -not (IsOurs $_) })
    if ($hs.Count -gt 0) { $grp.hooks = $hs; $keep += $grp }
  }
  $s.hooks.$ev = $keep
}
if ($s.PSObject.Properties.Name -contains 'statusLine' -and (IsOurs $s.statusLine)) { $s.PSObject.Properties.Remove('statusLine') }

if (-not $Uninstall) {
  if ($s.PSObject.Properties.Name -contains 'statusLine') {
    Write-Host ('You already have a different statusLine: ' + [string]$s.statusLine.command)
    $a = Read-Host 'Replace it with the context-% statusline? Type YES to replace, anything else keeps yours'
    if ($a -eq 'YES') { $s.PSObject.Properties.Remove('statusLine') }
  }
  if (-not ($s.PSObject.Properties.Name -contains 'statusLine')) {
    $s | Add-Member -NotePropertyName statusLine -NotePropertyValue ([pscustomobject]@{ type = 'command'; command = (Cmd 'statusline-ctx.ps1'); refreshInterval = 5 })
  }
  $s.hooks.Stop = @($s.hooks.Stop) + @([pscustomobject]@{ hooks = @([pscustomobject]@{ type = 'command'; command = (Cmd 'question-guard.ps1'); timeout = 10 }) })
  $s.hooks.PreToolUse = @($s.hooks.PreToolUse) + @(
    [pscustomobject]@{ matcher = 'Task|Agent'; hooks = @([pscustomobject]@{ type = 'command'; command = (Cmd 'gate-hook.ps1'); timeout = 30 }) },
    [pscustomobject]@{ matcher = 'Bash'; hooks = @([pscustomobject]@{ type = 'command'; command = (Cmd 'gate-hook.ps1'); timeout = 10 }) })
}
$json = $s | ConvertTo-Json -Depth 30
$null = $json | ConvertFrom-Json   # must round-trip before we write it
[IO.File]::WriteAllText($sp, $json, (New-Object Text.UTF8Encoding($false)))
if ($Uninstall) { Write-Host 'Removed the statusline, question-guard and gate-hook entries. Restart Claude Code.' }
else { Write-Host 'Installed: statusline (real context %), question-guard Stop hook, gate hook (Task|Agent + Bash). Restart Claude Code to load them.' }
