# gate-hook.ps1 - Claude Code PreToolUse hook (NOT installed; see install-gate-hook.md). ASCII only, PowerShell 5.1.
# Reads the hook JSON on stdin. Exit 2 = block the tool call and show stderr to Claude. Exit 0 = allow.
#  - Bash: blocks killing processes by name/pattern (pkill, killall, taskkill /IM, Stop-Process -Name).
#  - Task/Agent: runs `cc.ps1 gate start` (no ledger row) on the brief and blocks on FAIL. A 'ROLE: reviewer' line adds -Reviewer.
$ErrorActionPreference = 'Stop'
$cc = Join-Path $PSScriptRoot 'cc.ps1'
function Block([string]$m) { [Console]::Error.WriteLine($m); exit 2 }
try { $raw = [Console]::In.ReadToEnd(); $j = $raw | ConvertFrom-Json } catch { exit 0 }
$tool = [string]$j.tool_name
if ($tool -eq 'Bash') {
  $cmd = [string]$j.tool_input.command
  if ($cmd -match '(?i)\bpkill\b|\bkillall\b|taskkill(\.exe)?\s+.*?/im\b|Stop-Process\s+.*?-Name\b') {
    Block 'BLOCKED by gate-hook: never stop processes by name or pattern (pkill -f, killall, taskkill /IM, Stop-Process -Name). Find the exact PID you started and stop that PID.'
  }
  exit 0
}
if ($tool -eq 'Task' -or $tool -eq 'Agent') {
  $desc = [string]$j.tool_input.description
  $prompt = [string]$j.tool_input.prompt
  $all = $desc + ' ' + $prompt
  $a = @('gate', 'start', '-NoLog', '-Task', $(if ($desc) { $desc } else { (($prompt -replace '\s+', ' ').Trim()) }))
  if ($all -match '(?i)\bPR\s*#?(\d{2,4})\b') { $a += @('-Pr', $Matches[1]) }
  if ($all -match '(?i)\.github[\\/]workflows') { $a += '-EditsWorkflows' }
  if ($all -match '(?i)\bxhigh\b') { $a += '-Heavy' }
  if ($all -match '(?i)\b(open|create|new)\s+(a\s+)?(pull request|PR)\b') { $a += '-NewPr' }
  # M17: a brief with a 'ROLE: reviewer' line is read-only review work; recent activity on the branch is then a WARN
  if ($prompt -match '(?im)^\s*ROLE:\s*reviewer\b') { $a += '-Reviewer' }
  $fm = @([regex]::Matches($all, '[A-Za-z0-9_./-]+\.(java|py|yml|yaml|json|gradle)\b') | ForEach-Object { $_.Value } | Where-Object { $_ -match '/' } | Select-Object -Unique)
  if ($fm.Count -gt 0) { $a += @('-Files', ($fm -join ',')) }
  $out = (& powershell -NoProfile -ExecutionPolicy Bypass -File $cc @a 2>&1 | Out-String)
  if ($LASTEXITCODE -ne 0) { Block ("BLOCKED by gate-hook: cc.ps1 gate start FAILED. Fix the FAIL lines or ask lovish; do not retry unchanged.`n" + $out) }
  exit 0
}
exit 0
