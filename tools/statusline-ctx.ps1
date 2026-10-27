# statusline-ctx.ps1 - Claude Code statusLine command (D041). Reads the session JSON on stdin, writes the REAL context %
# for this session to %LOCALAPPDATA%\CommandCenter\ctx\<session_id>.json (override dir: CC_CTX_DIR) and prints one line.
# Fields per the statusline docs: session_id, context_window.used_percentage, context_window.context_window_size.
# Never fails: a status line must not break the bar. ASCII only, PowerShell 5.1. Read by: cc.ps1 ctx.
$ErrorActionPreference = 'SilentlyContinue'
$j = $null
try { $j = [Console]::In.ReadToEnd() | ConvertFrom-Json } catch { $j = $null }
if ($null -eq $j) { Write-Output 'ctx ?'; exit 0 }
$model = ''; if ($j.model) { $model = [string]$j.model.display_name }
$pct = $null; $size = $null
if ($j.context_window) {
  if ($null -ne $j.context_window.used_percentage) { $pct = [double]$j.context_window.used_percentage }
  if ($null -ne $j.context_window.context_window_size) { $size = [long]$j.context_window.context_window_size }
}
if ($null -eq $pct) { Write-Output (($model + ' ctx --').Trim()); exit 0 }
$dir = $env:CC_CTX_DIR
if (-not $dir) { $la = $env:LOCALAPPDATA; if (-not $la) { $la = [IO.Path]::GetTempPath() }; $dir = Join-Path $la 'CommandCenter\ctx' }
$sid = [string]$j.session_id
if ($sid -match '^[A-Za-z0-9._-]{1,128}$') {
  try {
    if (-not (Test-Path -LiteralPath $dir)) { New-Item -ItemType Directory -Force -Path $dir | Out-Null }
    $o = [ordered]@{ session_id = $sid; used_percentage = $pct; context_window_size = $size
      updated_utc = (Get-Date).ToUniversalTime().ToString('o'); cwd = [string]$j.cwd; transcript_path = [string]$j.transcript_path }
    $tmpf = Join-Path $dir ($sid + '.json.tmp')
    Set-Content -LiteralPath $tmpf -Value ($o | ConvertTo-Json -Compress) -Encoding ASCII
    Move-Item -LiteralPath $tmpf -Destination (Join-Path $dir ($sid + '.json')) -Force
  } catch { }
}
$msg = ''
if ($pct -ge 50) { $msg = ' HAND OFF now' } elseif ($pct -ge 40) { $msg = ' wrap up soon' }
$k = ''; if ($size) { $k = (' of {0}k' -f [math]::Round($size / 1000)) }
Write-Output ((('{0} ctx {1}%{2}{3}' -f $model, [math]::Round($pct, 1), $k, $msg)).Trim())
exit 0
