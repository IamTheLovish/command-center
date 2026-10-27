# test-ctx-qguard.ps1 - tests for statusline-ctx.ps1, question-guard.ps1 and cc.ps1 ctx (D041, D042). ASCII, PowerShell 5.1.
# Written BEFORE the implementation (tests-first rule, lovish Oct 22 19:58). Exit 0 = all pass.
$ErrorActionPreference = 'Stop'
$T = $PSScriptRoot
$PsExe = (Get-Process -Id $PID).Path   # same PowerShell that runs this test
$TmpBase = $env:TEMP; if (-not $TmpBase) { $TmpBase = [IO.Path]::GetTempPath() }
$tmp = Join-Path $TmpBase ('cc-ctxq-test-' + [guid]::NewGuid().ToString('N').Substring(0, 8))
New-Item -ItemType Directory -Force -Path $tmp | Out-Null
$Results = New-Object System.Collections.ArrayList
function Case([string]$name, [bool]$ok, [string]$got) { [void]$Results.Add([pscustomobject]@{ Case = $name; Ok = $ok; Got = $got }) }
function Run-Script([string]$file, [string]$stdin, [hashtable]$envs) {
  foreach ($k in $envs.Keys) { Set-Item -Path ('env:' + $k) -Value $envs[$k] }
  try {
    $p = Join-Path $T $file
    if (-not (Test-Path -LiteralPath $p)) { return @{ Code = 99; Out = ('MISSING ' + $file) } }
    $out = ($stdin | & $PsExe -NoProfile -ExecutionPolicy Bypass -File $p 2>&1 | Out-String)
    return @{ Code = $LASTEXITCODE; Out = $out.Trim() }
  } finally { foreach ($k in $envs.Keys) { Remove-Item -Path ('env:' + $k) -ErrorAction SilentlyContinue } }
}
$ctxDir = Join-Path $tmp 'ctx'; $offDir = Join-Path $tmp 'off'; $qState = Join-Path $tmp 'qg'
$E = @{ CC_CTX_DIR = $ctxDir; CC_HOOKS_OFF_DIR = $offDir; CC_QGUARD_STATE = $qState }

# --- statusline-ctx.ps1
$j = '{"session_id":"sessA","context_window":{"used_percentage":42.5,"context_window_size":1000000},"workspace":{"current_dir":"D:\\x"}}'
$r = Run-Script 'statusline-ctx.ps1' $j $E
$f = Join-Path $ctxDir 'sessA.json'
$ok = ($r.Code -eq 0) -and (Test-Path -LiteralPath $f)
if ($ok) { $o = Get-Content -LiteralPath $f -Raw | ConvertFrom-Json; $ok = ($o.used_percentage -eq 42.5) -and ($o.context_window_size -eq 1000000) }
Case 'statusline writes per-session file with real pct + window' $ok $r.Out
Case 'statusline prints pct and 40% warning' (($r.Out -match '42') -and ($r.Out -match 'wrap up')) $r.Out
$r = Run-Script 'statusline-ctx.ps1' '{"session_id":"sessB"}' $E
Case 'statusline before first API call: exit 0, no crash' ($r.Code -eq 0) $r.Out
$r = Run-Script 'statusline-ctx.ps1' 'not json' $E
Case 'statusline bad input: exit 0 (never breaks the bar)' ($r.Code -eq 0) $r.Out
$j2 = '{"session_id":"sessC","context_window":{"used_percentage":55,"context_window_size":200000}}'
$r = Run-Script 'statusline-ctx.ps1' $j2 $E
Case 'statusline 55% says HAND OFF' ($r.Out -match 'HAND OFF') $r.Out

# --- cc.ps1 ctx reads the files
$cc = Join-Path $T 'cc.ps1'
$out = (& $PsExe -NoProfile -ExecutionPolicy Bypass -File $cc ctx -CtxDir $ctxDir -Session sessA 2>&1 | Out-String)
Case 'cc ctx -Session reads real pct and window' (($out -match '42\.5%') -and ($out -match '1000000')) $out.Trim()
$out = (& $PsExe -NoProfile -ExecutionPolicy Bypass -File $cc ctx -CtxDir $ctxDir 2>&1 | Out-String)
Case 'cc ctx without -Session lists every recent session' (($out -match 'sessA') -and ($out -match 'sessC')) $out.Trim()
Case 'cc ctx flags the 55% session to hand off' ($out -match 'sessC[^\r\n]*HAND OFF') $out.Trim()

# --- cc.ps1 handoff-lint (handoff shape)
$good = "# Handoff`n## RESUME HERE`nNext: x`n## Dead ends / ruled out`n- y`n"
$hp = Join-Path $tmp 'h-good.md'; Set-Content -LiteralPath $hp -Value $good -Encoding ASCII
$out = (& $PsExe -NoProfile -ExecutionPolicy Bypass -File $cc handoff-lint $hp 2>&1 | Out-String)
Case 'handoff-lint passes a short single-block handoff' ($out -match 'PASS handoff-lint') $out.Trim()
$hp2 = Join-Path $tmp 'h-appended.md'; Set-Content -LiteralPath $hp2 -Value ($good + "## Update after handoff (23:1x)`n- z`n") -Encoding ASCII
$out = (& $PsExe -NoProfile -ExecutionPolicy Bypass -File $cc handoff-lint $hp2 2>&1 | Out-String)
Case 'handoff-lint fails an appended update block (gen-013 slip)' (($out -match 'FAIL') -and ($out -match 'Update after handoff')) $out.Trim()
$hp3 = Join-Path $tmp 'h-big.md'; Set-Content -LiteralPath $hp3 -Value ($good + ('x' * 11000)) -Encoding ASCII
$out = (& $PsExe -NoProfile -ExecutionPolicy Bypass -File $cc handoff-lint $hp3 2>&1 | Out-String)
Case 'handoff-lint fails a handoff over 10 KB' (($out -match 'FAIL') -and ($out -match '10240')) $out.Trim()
$hp4 = Join-Path $tmp 'h-nodead.md'; Set-Content -LiteralPath $hp4 -Value "# Handoff`n## RESUME HERE`nNext`n" -Encoding ASCII
$out = (& $PsExe -NoProfile -ExecutionPolicy Bypass -File $cc handoff-lint $hp4 2>&1 | Out-String)
Case 'handoff-lint fails without a dead-ends section' (($out -match 'FAIL') -and ($out -match 'Dead ends')) $out.Trim()

# --- question-guard.ps1
$q = '{"session_id":"s1","last_assistant_message":"I built it. Want me to also push it?"}'
$r = Run-Script 'question-guard.ps1' $q $E
Case 'qguard blocks a reply ending in a typed question' (($r.Code -eq 0) -and ($r.Out -match '"decision"\s*:\s*"block"')) $r.Out
$r = Run-Script 'question-guard.ps1' $q $E
Case 'qguard allows the same message the second time (no loop)' (($r.Code -eq 0) -and ($r.Out -notmatch 'block')) $r.Out
$r = Run-Script 'question-guard.ps1' '{"session_id":"s1","last_assistant_message":"Done. The PR is #260."}' $E
Case 'qguard allows a normal ending' (($r.Code -eq 0) -and ($r.Out -notmatch 'block')) $r.Out
$r = Run-Script 'question-guard.ps1' ('{"session_id":"s1","last_assistant_message":"Run this:\n```\nif ($a) { ok? }\n```"}') $E
Case 'qguard ignores a ? inside a trailing code block' (($r.Code -eq 0) -and ($r.Out -notmatch 'block')) $r.Out
$r = Run-Script 'question-guard.ps1' '{"session_id":"s1","stop_hook_active":true,"last_assistant_message":"Another one?"}' $E
Case 'qguard never blocks when stop_hook_active' (($r.Code -eq 0) -and ($r.Out -notmatch 'block')) $r.Out
New-Item -ItemType Directory -Force -Path $offDir | Out-Null; Set-Content -LiteralPath (Join-Path $offDir 'question-guard') -Value 'off'
$r = Run-Script 'question-guard.ps1' '{"session_id":"s2","last_assistant_message":"Off switch test?"}' $E
Case 'qguard off switch file disables it' (($r.Code -eq 0) -and ($r.Out -notmatch 'block')) $r.Out
Remove-Item -LiteralPath (Join-Path $offDir 'question-guard')
$r = Run-Script 'question-guard.ps1' 'garbage' $E
Case 'qguard bad input: exit 0, no block' (($r.Code -eq 0) -and ($r.Out -notmatch 'block')) $r.Out

$pass = @($Results | Where-Object { $_.Ok }).Count
foreach ($c in $Results) { Write-Output ('{0}  {1}{2}' -f $(if ($c.Ok) { 'PASS' } else { 'FAIL' }), $c.Case, $(if ($c.Ok) { '' } else { '  | got: ' + ($c.Got -replace '\s+', ' ').Substring(0, [math]::Min(140, ($c.Got -replace '\s+', ' ').Length)) })) }
Write-Output ('TEST ctx-qguard {0}/{1}' -f $pass, $Results.Count)
Remove-Item -LiteralPath $tmp -Recurse -Force -ErrorAction SilentlyContinue
if ($pass -ne $Results.Count) { exit 1 }
