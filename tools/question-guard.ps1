# question-guard.ps1 - Claude Code Stop hook (D042; idea from Joisco's pack). If the final reply ends with a typed
# question, block ONCE and tell Claude to use AskUserQuestion buttons or take the recommended default.
# Off switch: create the file %LOCALAPPDATA%\CommandCenter\hooks-off\question-guard (dir override: CC_HOOKS_OFF_DIR).
# Never blocks on bad input, when stop_hook_active is true, or twice for the same message. ASCII only, PowerShell 5.1.
$ErrorActionPreference = 'SilentlyContinue'
$la = $env:LOCALAPPDATA; if (-not $la) { $la = [IO.Path]::GetTempPath() }
$base = Join-Path $la 'CommandCenter'
$off = $env:CC_HOOKS_OFF_DIR; if (-not $off) { $off = Join-Path $base 'hooks-off' }
if (Test-Path -LiteralPath (Join-Path $off 'question-guard')) { exit 0 }
$j = $null
try { $j = [Console]::In.ReadToEnd() | ConvertFrom-Json } catch { exit 0 }
if ($null -eq $j) { exit 0 }
if ($j.stop_hook_active -eq $true) { exit 0 }
$m = [string]$j.last_assistant_message
if (-not $m) { exit 0 }
$t = $m.TrimEnd()
if ($t.EndsWith('```')) { exit 0 }
$t = $t.TrimEnd([char[]]@('*', '_', '"', [char]39, ')', ']', ' ', "`t"))
if (-not $t.EndsWith('?')) { exit 0 }
$st = $env:CC_QGUARD_STATE; if (-not $st) { $st = Join-Path $base 'qguard' }
$sid = [string]$j.session_id; if ($sid -notmatch '^[A-Za-z0-9._-]{1,128}$') { $sid = 'unknown' }
$sha = [Security.Cryptography.SHA1]::Create()
$h = ([BitConverter]::ToString($sha.ComputeHash([Text.Encoding]::UTF8.GetBytes($m)))).Replace('-', '').Substring(0, 16)
$mark = Join-Path $st ($sid + '.last')
try { if ((Test-Path -LiteralPath $mark) -and (([string](Get-Content -LiteralPath $mark -Raw)).Trim() -eq $h)) { exit 0 } } catch { }
try {
  if (-not (Test-Path -LiteralPath $st)) { New-Item -ItemType Directory -Force -Path $st | Out-Null }
  Set-Content -LiteralPath $mark -Value $h -Encoding ASCII
} catch { exit 0 }
if (-not (Test-Path -LiteralPath $mark)) { exit 0 }
$reason = 'Your reply ends with a typed question. Ask it with AskUserQuestion buttons (recommended option first), or take the recommended default, say what you chose and how to undo it, and end without a question. (question-guard, D042. Off switch: hooks-off\question-guard)'
Write-Output (@{ decision = 'block'; reason = $reason } | ConvertTo-Json -Compress)
exit 0
