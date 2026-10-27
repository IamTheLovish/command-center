# gate-selftest.ps1 - replays tonight's real mistakes (M1-M11 + extras) against tools\gate-fixtures with stubbed gh data.
# Dot-sourced by cc.ps1 (gate-selftest). Offline, in-process, a few seconds. Any change to the gate scripts must keep n/n.
# Fixtures marked SYNTHETIC are labelled inside the file; everything named *.real.* is a saved real gh response / real file from Oct 26-27.

$script:StR = New-Object System.Collections.ArrayList
function St-Case([string]$case, [bool]$ok, [string]$want, [string]$got) {
  [void]$script:StR.Add([pscustomobject]@{ Case = $case; Ok = $ok; Want = $want; Got = (Get-Trunc $got 170) })
}
function St-Assert([string]$case, $checks, [string]$name, [string]$status, [string]$rx) {
  $c = @($checks | Where-Object { $_.Name -eq $name }) | Select-Object -First 1
  $ok = $false; $got = '(check missing)'
  if ($c) { $got = $c.Status + ': ' + $c.Reason; $ok = (($c.Status -eq $status) -and [regex]::IsMatch($c.Reason, $rx)) }
  St-Case $case $ok ($name + ' ' + $status + ' /' + $rx + '/') $got
}
function St-SetTime([string]$path, [string]$utc) { (Get-Item -LiteralPath $path).LastWriteTimeUtc = [DateTime]::SpecifyKind([datetime]::Parse($utc, [Globalization.CultureInfo]::InvariantCulture), 'Utc') }
function St-Root([string]$tmp, [string]$name, [string]$fx, [string]$stateJson) {
  $r = Join-Path $tmp ('root-' + $name)
  foreach ($d in @('usage', 'reviews', 'evidence', 'knowledge', 'plans', 'auditor\advice')) { New-Item -ItemType Directory -Force -Path (Join-Path $r $d) | Out-Null }
  Write-Text (Join-Path $r 'usage\state.json') $stateJson $false
  Write-Text (Join-Path $r 'auditor\CHANGES-APPLIED.md') "# Auditor changes applied`r`n`r`n## Unannounced`r`n`r`n## Announced`r`n" $false
  return $r
}
function St-Stub([string]$tmp, [string]$name, [string]$fx, [string]$auth) {
  $s = Join-Path $tmp ('stub-' + $name)
  New-Item -ItemType Directory -Force -Path $s | Out-Null
  Copy-Item (Join-Path $fx 'openprs.real.json') (Join-Path $s 'openprs.json')
  foreach ($n in @('247', '248', '224')) { Copy-Item (Join-Path $fx ('pr' + $n + '.real.json')) (Join-Path $s ('pr' + $n + '.json')) }
  Copy-Item (Join-Path $fx 'pr247.real.diff') (Join-Path $s 'pr247.diff')
  Copy-Item (Join-Path $fx $auth) (Join-Path $s 'auth.txt')
  Copy-Item (Join-Path $fx 'AGENTS.excerpt.md') (Join-Path $s 'AGENTS.md')
  return $s
}
function St-Stress289([string]$stubDir, [string]$fx) {
  Copy-Item (Join-Path $fx 'pr289.real.json') (Join-Path $stubDir 'pr289.json')
  Copy-Item (Join-Path $fx 'pr289.real.diff') (Join-Path $stubDir 'pr289.diff')
  foreach ($f in @(Get-ChildItem -LiteralPath $fx -Filter 'stress-*.real.txt')) { Copy-Item $f.FullName (Join-Path $stubDir ($f.Name -replace '\.real\.txt$', '.txt')) }
}
function St-Ctx([string]$root, [string]$stub, $now) { return (New-GateCtx @{ Root = $root; Repo = $root; Stub = $stub; NoLog = $true; Now = $now }) }
function St-ModeA([string]$root, [string]$n, [string]$sha, [string]$reviewer, [string]$mtimeUtc) {
  $p = Join-Path $root ('reviews\pr-' + $n + '-modeA.md')
  Write-Text $p ("# Mode A review PR #$n`r`nVERDICT: PASS`r`nREVIEWER: $reviewer`r`nSHA: $sha`r`n") $false
  St-SetTime $p $mtimeUtc
}
function St-Fix247([string]$stubDir, [string]$mode) {
  $p = Join-Path $stubDir 'pr247.json'
  $t = Read-Text $p
  if ($mode -match 'open') { $t = [regex]::Replace($t, '"state":\s*"MERGED"', '"state":  "OPEN"'); $t = [regex]::Replace($t, '"mergedAt":\s*"[^"]*"', '"mergedAt":  null') }
  if ($mode -match 'authors') { $t = [regex]::Replace($t, '"email":\s*"noreply@anthropic.com"', '"email":  "IamTheLovish@users.noreply.github.com"'); $t = [regex]::Replace($t, '"name":\s*"Claude"', '"name":  "IamTheLovish"') }
  if ($mode -match 'acctnoreply') { $t = [regex]::Replace($t, '"email":\s*"noreply@anthropic.com"', '"email":  "339019718+IamTheLovish@users.noreply.github.com"'); $t = [regex]::Replace($t, '"name":\s*"Claude"', '"name":  "Lovish"') }
  if ($mode -match 'otheracct') { $t = [regex]::Replace($t, '"email":\s*"noreply@anthropic.com"', '"email":  "12345+SomeoneElse@users.noreply.github.com"'); $t = [regex]::Replace($t, '"name":\s*"Claude"', '"name":  "Lovish"') }
  if ($mode -match 'stress') {
    $t = [regex]::Replace($t, '"comments":\s*\[\s*\]', '"comments":  [{"body":"[Stress] flake-stress 30 runs: 0 with any failure","createdAt":"2026-10-27T03:00:00Z"}]')
    # SYNTHETIC (M20): the saved #247 diff stops at the @GameTest lines, so each gets a method name, and a flake-stress
    # run of #247's branch (found by its run-name title) whose summary passes all six
    $script:StK = 0
    $df = [regex]::Replace((Read-Text (Join-Path $stubDir 'pr247.diff')), '(?m)^(\+\s*@GameTest\b[^\r\n]*)', { param($m) $script:StK++; $m.Groups[1].Value + "`n+    public static void perf_quick_wins_case_" + $script:StK + '(GameTestHelper helper) {' })
    Write-Text (Join-Path $stubDir 'pr247.diff') $df $false
    Write-Text (Join-Path $stubDir 'stressruns.json') '[{"databaseId":40500000001,"displayTitle":"flake-stress claude/perf-quick-wins","status":"completed","conclusion":"success","createdAt":"2026-10-27T03:00:00Z"}]' $false
    $sum = "workflow: flake-stress`nref: claude/perf-quick-wins`n[Stress] 6 runners; 0 with any failure"
    for ($i = 1; $i -le $script:StK; $i++) { $sum += "`nperf_quick_wins_case_" + $i + ': failed 0, passed 6' }
    Write-Text (Join-Path $stubDir 'stress-40500000001.txt') $sum $false
    $script:StK = 0
  }
  if ($mode -match 'cmt-(\w+)') { $tag = $Matches[1]; $b = 'VERDICT: PASS\nREVIEWER: opus reviewer'; if ($tag -ne 'none') { $b += (' [id:' + $tag + ']') }; $t = [regex]::Replace($t, '"comments":\s*\[\s*\]', ('"comments":  [{"body":"' + $b + '","createdAt":"2026-10-27T11:47:00Z"}]')) }
  if ($mode -match 'cifail') { $rx = New-Object regex('"conclusion":\s*"SUCCESS"'); $t = $rx.Replace($t, '"conclusion":  "FAILURE"', 1) }
  Write-Text $p $t $false
}

function Invoke-GateSelftest([string]$ToolsDir, [bool]$verbose) {
  $sw = [Diagnostics.Stopwatch]::StartNew()
  $script:StR = New-Object System.Collections.ArrayList
  $fx = Join-Path $ToolsDir 'gate-fixtures'
  $tmp = Join-Path $env:TEMP ('cc-gate-selftest-' + $PID)
  if (Test-Path -LiteralPath $tmp) { Remove-Item -LiteralPath $tmp -Recurse -Force }
  New-Item -ItemType Directory -Force -Path $tmp | Out-Null
  $now = [DateTimeOffset]::Parse('2026-10-27T08:00:00-04:00', [Globalization.CultureInfo]::InvariantCulture)
  $good = '{"acct":"B","gen":14,"start":"2026-10-27T00:40:00-04:00","boot_complete":true}'
  $head247 = '70c1dfb262d0db2fe17b2db223628fa54e9585d0'
  $after = '2026-10-27 05:00:00'; $before = '2026-10-27 01:00:00'
  $ledgerHdr = "# Usage ledger`r`n`r`n| time | acct | gen | assignment | model | effort | tokens | result | note |`r`n|---|---|---|---|---|---|---|---|---|`r`n"

  # ---- M1 ledger-lint on the real hand-typed ledger of Oct 26
  $r1 = St-Root $tmp 'm1' $fx $good
  Copy-Item (Join-Path $fx 'ledger-2026-10-26.real.md') (Join-Path $r1 'usage\ledger-2026-10-26.md')
  St-SetTime (Join-Path $r1 'usage\ledger-2026-10-26.md') '2026-10-27 03:26:48'
  $c = Invoke-LedgerLint (St-Ctx $r1 '' $now) '2026-10-26'
  St-Assert 'M1 hand-typed rows' $c 'ledger-no-id' 'FAIL' 'hand-typed'
  St-Assert 'M1 times after file mtime' $c 'ledger-time-future' 'FAIL' 'after the file was last written'
  St-Assert 'M1 times out of order' $c 'ledger-time-order' 'FAIL' 'out of time order'

  # ---- M2 workflow scope
  $r2 = St-Root $tmp 'm2' $fx $good
  $s2 = St-Stub $tmp 'noscope' $fx 'auth-noworkflow.txt'
  $c = Invoke-GatePreflight (St-Ctx $r2 $s2 $now) @{ Task = 'x'; EditsWorkflows = $true }
  St-Assert 'M2 token lacks workflow scope' $c 'workflow-scope' 'FAIL' "lacks the 'workflow' scope"
  $s2b = St-Stub $tmp 'scope' $fx 'auth-workflow.txt'
  $c = Invoke-GatePreflight (St-Ctx $r2 $s2b $now) @{ Task = 'x'; Files = '.github/workflows/ci.yml' }
  St-Assert 'M2 control: scope present passes' $c 'workflow-scope' 'PASS' 'has the workflow scope'

  # ---- M3 stale PR state
  $c = Invoke-GatePreflight (St-Ctx $r2 $s2 $now) @{ Task = 'x'; Pr = '224' }
  St-Assert 'M3 merged PR is shown as merged' $c 'pr-state' 'WARN' 'MERGED at 2026-10-2'

  # ---- M4 / M5 accept on #247 and #248 as they really were
  $c = Invoke-GateAccept (St-Ctx $r2 $s2 $now) '247'
  St-Assert 'M4 #247 no Mode A file' $c 'modeA' 'FAIL' 'no Mode A review'
  St-Assert 'M5 #247 commits authored as Claude' $c 'authors' 'FAIL' 'not authored as IamTheLovish'
  $c = Invoke-GateAccept (St-Ctx $r2 $s2 $now) '248'
  St-Assert 'M4 #248 no Mode A file' $c 'modeA' 'FAIL' 'no Mode A review'
  St-Assert 'M5 #248 commits authored as Claude' $c 'authors' 'FAIL' 'not authored as IamTheLovish'

  # ---- M6 overlap with open PRs
  $c = Invoke-GatePreflight (St-Ctx $r2 $s2 $now) @{ Task = 'add UNIT_SHADOW'; Files = 'bar/src/main/java/com/solegendary/reignofnether/matchstart/EyesOverlaysScene.java' }
  St-Assert 'M6 open PR edits the same file' $c 'overlap' 'FAIL' '#216'
  $c = Invoke-GatePreflight (St-Ctx $r2 $s2 $now) @{ Task = 'x'; Files = 'bar/src/main/java/com/solegendary/reignofnether/matchstart/EyesOverlaysScene.java'; AllowOverlap = 'coordinated with 216 owner' }
  St-Assert 'M6 -AllowOverlap downgrades to WARN' $c 'overlap' 'WARN' 'overlap allowed'
  # M18 (Oct 27, #286): a read-only reviewer edits no file, so another PR touching the same files is only a WARN
  $c = Invoke-GatePreflight (St-Ctx $r2 $s2 $now) @{ Task = 'x'; Files = 'bar/src/main/java/com/solegendary/reignofnether/matchstart/EyesOverlaysScene.java'; Reviewer = $true }
  St-Assert 'M18 reviewer: open-PR overlap only warns' $c 'overlap' 'WARN' 'reviewer \(read-only\)'

  # ---- M7 PR pile-up
  $c = Invoke-GatePreflight (St-Ctx $r2 $s2 $now) @{ Task = 'x'; NewPr = $true }
  St-Assert 'M7 41 open PRs blocks a new one' $c 'pr-budget' 'FAIL' '41 open PRs'
  $c = Invoke-GatePreflight (St-Ctx $r2 $s2 $now) @{ Task = 'x'; NewPr = $true; Override = 'lovish 00:20: open it anyway' }
  St-Assert 'M7 override is recorded as WARN' $c 'pr-budget' 'WARN' 'OVERRIDE quote'

  # ---- M8 existing plans (SYNTHETIC plan stubs)
  $r8 = St-Root $tmp 'm8' $fx $good
  Copy-Item (Join-Path $fx 'plans\*.md') (Join-Path $r8 'plans')
  $c = Invoke-GatePreflight (St-Ctx $r8 $s2 $now) @{ Task = 'add UNIT_SHADOW to the shadow pass'; Files = 'bar/src/main/java/com/solegendary/reignofnether/matchstart/EyesOverlaysScene.java' }
  St-Assert 'M8 plans 007/012 overlap is named' $c 'plans' 'WARN' '007, 012'

  # ---- M10 unfinished boot
  $r10 = St-Root $tmp 'm10' $fx '{"acct":"B","gen":14,"start":"2026-10-27T00:40:00-04:00","boot_complete":false}'
  $c = Invoke-GatePreflight (St-Ctx $r10 $s2 $now) @{ Task = 'x' }
  St-Assert 'M10 boot_complete=false blocks work' $c 'boot' 'FAIL' 'boot unfinished'
  Write-Text (Join-Path $r10 'auditor\CHANGES-APPLIED.md') "# x`r`n`r`n## Unannounced`r`n- APPLIED: something not yet told to lovish`r`n`r`n## Announced`r`n" $false
  $c = Invoke-BootDone (St-Ctx $r10 $s2 $now) $false
  St-Assert 'M10 boot-done refuses while changes are unannounced' $c 'boot-done' 'FAIL' 'stays false'
  Write-Text (Join-Path $r10 'auditor\CHANGES-APPLIED.md') "# x`r`n`r`n## Unannounced`r`n`r`n## Announced`r`n- APPLIED: told`r`n" $false
  $c = Invoke-BootDone (St-Ctx $r10 $s2 $now) $false
  St-Assert 'M10 boot-done sets true once announced' $c 'boot-done' 'PASS' 'boot_complete=true'
  $c = Invoke-GatePreflight (St-Ctx $r10 $s2 $now) @{ Task = 'x' }
  St-Assert 'M10 preflight boot passes after boot-done' $c 'boot' 'PASS' 'complete'

  # ---- heavy cap
  $rh = St-Root $tmp 'heavy' $fx $good
  Write-Text (Join-Path $rh 'usage\ledger-2026-10-27.md') ($ledgerHdr + "| 00:01 | B | 014 | audit one | opus | xhigh | - | running | tier: core [id:h111] |`r`n| 00:02 | B | 014 | audit two | fable | xhigh | - | running | tier: core [id:h222] |`r`n") $false
  $c = Invoke-GatePreflight (St-Ctx $rh $s2 $now) @{ Task = 'x'; Heavy = $true }
  St-Assert 'heavy: 3rd heavy agent blocked' $c 'heavy-cap' 'FAIL' '2 open heavy rows'

  # ---- M16 own review comment blocked its own gen (Oct 27 03:40, PR #257: the commander's Mode A comment 13 min earlier
  #      blocked handing the fix to a builder). A comment tagged with a CURRENT-gen ledger id is not another session.
  $r16 = St-Root $tmp 'm16' $fx $good
  Write-Text (Join-Path $r16 'usage\ledger-2026-10-27.md') ($ledgerHdr + "| 07:40 | B | 013 | build something | opus | xhigh | - | pass | tier: core [id:bb22] |`r`n| 07:45 | B | 014 | Mode A review | opus | high | - | pass | tier: standard [id:aa11] |`r`n") $false
  foreach ($case in @(@('aa11', 'PASS', 'no other gen', 'M16 own-gen tagged comment does not block'), @('bb22', 'FAIL', 'PR comment', 'M16 control: other gen tagged comment still blocks'), @('none', 'FAIL', 'PR comment', 'M16 control: untagged comment still blocks'))) {
    $s16 = St-Stub $tmp ('m16-' + $case[0]) $fx 'auth-noworkflow.txt'
    St-Fix247 $s16 ('open cmt-' + $case[0])
    $c = Invoke-GatePreflight (St-Ctx $r16 $s16 $now) @{ Task = 'x'; Pr = '247' }
    St-Assert $case[3] $c 'branch-check' $case[1] $case[2]
  }

  # ---- M17 reviewers blocked by the 2h rule (Oct 27 overnight: Mode A reviewers could not start on a branch whose
  #      builder had just pushed, which is exactly when a review is due). A read-only reviewer gets WARN for recent
  #      activity; a running builder row of another gen still blocks it, and builders are unchanged.
  $s17 = St-Stub $tmp 'm17' $fx 'auth-noworkflow.txt'
  St-Fix247 $s17 'open cmt-none'
  $c = Invoke-GatePreflight (St-Ctx $r16 $s17 $now) @{ Task = 'x'; Pr = '247'; Reviewer = $true }
  St-Assert 'M17 reviewer: recent comment only warns' $c 'branch-check' 'WARN' 'PR comment'
  $c = Invoke-GatePreflight (St-Ctx $r16 $s17 $now) @{ Task = 'x'; Pr = '247' }
  St-Assert 'M17 control: builder still blocked by recent comment' $c 'branch-check' 'FAIL' 'PR comment'
  $r17 = St-Root $tmp 'm17' $fx $good
  Write-Text (Join-Path $r17 'usage\ledger-2026-10-27.md') ($ledgerHdr + "| 07:50 | A | 013 | owns #247 fix round 2 | opus | xhigh | - | running | tier: core [id:cc33] |`r`n") $false
  $c = Invoke-GatePreflight (St-Ctx $r17 $s17 $now) @{ Task = 'x'; Pr = '247'; Reviewer = $true }
  St-Assert 'M17 control: reviewer still blocked by a running builder row' $c 'branch-check' 'FAIL' 'running ledger row'

  # ---- accept: independence, stale sha, old file, gametests, CI
  $s3 = St-Stub $tmp 'pos' $fx 'auth-noworkflow.txt'
  St-Fix247 $s3 'open authors stress'
  $r3 = St-Root $tmp 'pos' $fx $good
  St-ModeA $r3 '247' $head247 'fresh-reviewer-sonnet [id:r222]' $after
  Write-Text (Join-Path $r3 'usage\ledger-2026-10-27.md') ($ledgerHdr + "| 00:01 | B | 014 | build perf PR | sonnet | high | - | pass | tier: standard; owns: #247 [id:b111] |`r`n| 00:02 | B | 014 | fresh Mode A review of 247 | opus | high | - | pass | tier: core [id:r222] |`r`n") $false
  $c = Invoke-GateAccept (St-Ctx $r3 $s3 $now) '247'
  $nf = Get-GateCounts $c
  St-Case 'POSITIVE accept: all-correct data passes' ($nf.F -eq 0) 'no FAIL check' ('fail=' + $nf.F + ' warn=' + $nf.W + ' pass=' + $nf.P + ' ' + ((@($c | Where-Object { $_.Status -ne 'PASS' } | ForEach-Object { $_.Name + ':' + $_.Reason })) -join ' | '))
  St-Assert 'POSITIVE accept: Mode A accepted' $c 'modeA' 'PASS' 'VERDICT PASS'
  St-Assert 'POSITIVE accept: reviewer independent' $c 'modeA-independent' 'PASS' 'not the builder'

  $r4 = St-Root $tmp 'self' $fx $good
  St-ModeA $r4 '247' $head247 'sonnet' $after
  Write-Text (Join-Path $r4 'usage\ledger-2026-10-27.md') ($ledgerHdr + "| 00:01 | B | 014 | build perf PR | sonnet | high | - | pass | tier: standard; owns: #247 [id:b111] |`r`n") $false
  $c = Invoke-GateAccept (St-Ctx $r4 $s3 $now) '247'
  St-Assert 'M4+ builder reviewing own PR is rejected' $c 'modeA-independent' 'FAIL' 'equals the builder'
  $r4b = St-Root $tmp 'self2' $fx $good
  St-ModeA $r4b '247' $head247 'builder agent [id:b111]' $after
  Copy-Item (Join-Path $r4 'usage\ledger-2026-10-27.md') (Join-Path $r4b 'usage\ledger-2026-10-27.md')
  $c = Invoke-GateAccept (St-Ctx $r4b $s3 $now) '247'
  St-Assert 'M4+ reviewer naming the builder row id is rejected' $c 'modeA-independent' 'FAIL' 'reviewer is the builder'

  $r5 = St-Root $tmp 'stale' $fx $good
  St-ModeA $r5 '247' '1111111111111111111111111111111111111111' 'fresh agent' $after
  $c = Invoke-GateAccept (St-Ctx $r5 $s3 $now) '247'
  St-Assert 'M4+ stale sha in the Mode A file' $c 'modeA' 'FAIL' 'stale'
  $r6 = St-Root $tmp 'old' $fx $good
  St-ModeA $r6 '247' $head247 'fresh agent' $before
  $c = Invoke-GateAccept (St-Ctx $r6 $s3 $now) '247'
  St-Assert 'M4+ Mode A file older than the head commit' $c 'modeA-independent' 'FAIL' 'before head commit'

  $s4 = St-Stub $tmp 'nostress' $fx 'auth-noworkflow.txt'
  St-Fix247 $s4 'open authors'
  $c = Invoke-GateAccept (St-Ctx $r3 $s4 $now) '247'
  St-Assert 'new @GameTest without stress evidence' $c 'gametests' 'FAIL' '6 new @GameTest but no flake-stress'
  $s5 = St-Stub $tmp 'cifail' $fx 'auth-noworkflow.txt'
  St-Fix247 $s5 'open authors stress cifail'
  $c = Invoke-GateAccept (St-Ctx $r3 $s5 $now) '247'
  St-Assert 'failing CI check' $c 'ci' 'FAIL' 'failed/cancelled'

  # M19 (Oct 27 night): lovish's own GitHub-web commits carry the account's numeric noreply address; same account
  $s19 = St-Stub $tmp 'acct' $fx 'auth-noworkflow.txt'
  St-Fix247 $s19 'open acctnoreply stress'
  $c = Invoke-GateAccept (St-Ctx $r3 $s19 $now) '247'
  St-Assert 'M19 the account numeric noreply is IamTheLovish' $c 'authors' 'PASS' 'authored as IamTheLovish'
  $s19b = St-Stub $tmp 'acct2' $fx 'auth-noworkflow.txt'
  St-Fix247 $s19b 'open otheracct stress'
  $c = Invoke-GateAccept (St-Ctx $r3 $s19b $now) '247'
  St-Assert 'M19 control: another account numeric noreply still fails' $c 'authors' 'FAIL' 'not authored as IamTheLovish'

  # ---- M20 (Oct 27 night): flake-stress runs 40565576897, 40581759617, 40582259285 and 40582056986 were given bare test
  #      names, ran 0 tests ("All 0 required tests passed" on every runner) and were posted as "[Stress] 0 with any
  #      failure"; #273 and #289 merged on them. Real #289 (pr289.real.*) and the real summaries of every run its body and
  #      comments cite (stress-<id>.real.txt): its new @GameTest sealed_arena_has_no_fluid_after_openGround is in no
  #      summary of a flake-stress run of its branch (40581759617 ran 0 tests, 40572402176 listed only vanilla_path).
  $r20 = St-Root $tmp 'm20' $fx $good
  $s20 = St-Stub $tmp 'm20' $fx 'auth-noworkflow.txt'
  St-Stress289 $s20 $fx
  $c = Invoke-GateAccept (St-Ctx $r20 $s20 $now) '289'
  St-Assert 'M20 #289: a [Stress] comment over a 0-test run is no evidence' $c 'gametests' 'FAIL' 'sealed_arena_has_no_fluid_after_openGround'
  # SYNTHETIC controls: a run of the branch (run-name title) whose summary names the test passes; the same summary on a
  # run that checked out main, or with passed 0, does not
  $one = "workflow: flake-stress`nref: {0}`n[Stress] 6 runners; 0 with any failure`nsealed_arena_has_no_fluid_after_openGround: failed 0, passed {1}"
  foreach ($case in @(@('ok', 'claude/flake-015b-pathing-arenas', '6', 'PASS', 'passed 6', 'M20 control: a run of the branch naming the test passes'),
                      @('main', 'main', '6', 'FAIL', 'sealed_arena_has_no_fluid_after_openGround', 'M20 control: the same summary from a run of main does not count'),
                      @('zero', 'claude/flake-015b-pathing-arenas', '0', 'FAIL', 'sealed_arena_has_no_fluid_after_openGround', 'M20 control: passed 0 is not a pass'))) {
    $sc = St-Stub $tmp ('m20-' + $case[0]) $fx 'auth-noworkflow.txt'
    St-Stress289 $sc $fx
    Write-Text (Join-Path $sc 'stressruns.json') '[{"databaseId":40599999999,"displayTitle":"flake-stress claude/flake-015b-pathing-arenas","status":"completed","conclusion":"success","createdAt":"2026-10-27T22:00:00Z"}]' $false
    Write-Text (Join-Path $sc 'stress-40599999999.txt') ($one -f $case[1], $case[2]) $false
    $c = Invoke-GateAccept (St-Ctx $r20 $sc $now) '289'
    St-Assert $case[5] $c 'gametests' $case[3] $case[4]
  }

  # ---- report-lint
  $rr = St-Root $tmp 'rep' $fx $good
  $rc = St-Ctx $rr $s3 $now
  $q = Join-Path $rr 'q.md'
  Write-Text $q "# Report`r`n`r`n## Needs your decision`r`n1. a?`r`n2. b?`r`n3. c?`r`n4. d?`r`n5. e?`r`n6. f?`r`n7. g?`r`n" $false
  $x = Invoke-ReportLint $rc $q
  St-Case 'M11 more than 5 questions' (@($x.Flags | Where-Object { $_.Kind -eq 'questions' }).Count -eq 1) 'one questions flag' ('flags=' + $x.Flags.Count)
  $cl = Join-Path $rr 'claims.md'
  Write-Text $cl "- Fixed the leak in the knockback list.`r`n- Verified, PR #247 is ready.`r`n- Fixed the leak, test knockback_ignore_list_is_empty_after_a_tick passes.`r`n- Not verified yet.`r`n- lovish said `"done for the game`" in the brief.`r`n- Needs a fixed build order and fixed timers.`r`n- Shadow cost has never been measured.`r`n- Cost is unmeasured so far.`r`n`r`nDone tonight:`r`n" $false
  $x = Invoke-ReportLint $rc $cl
  St-Case 'overclaim: bare verified/fixed lines flagged, evidence line and negation not' (($x.Flags.Count -eq 2) -and $x.Flags[0].Line -eq 1 -and $x.Flags[1].Line -eq 2) 'flags on lines 1,2' ('flags=' + (($x.Flags | ForEach-Object { $_.Line }) -join ','))
  St-Case 'overclaim: PR # alone is not evidence' ($x.Flags[1].Why -match 'no passing, current gate evidence') 'gate-evidence reason' $x.Flags[1].Why
  Write-Text (Join-Path $rr 'evidence\pr-247.json') ('{"pr":247,"sha":"' + $head247 + '","verdict":"PASS","checks":[]}') $false
  $x = Invoke-ReportLint $rc $cl
  St-Case 'evidence file PASS for the current sha accepts the PR claim' ($x.Flags.Count -eq 1 -and $x.Flags[0].Line -eq 1) 'only line 1 flagged' ('flags=' + (($x.Flags | ForEach-Object { $_.Line }) -join ','))
  Write-Text (Join-Path $rr 'evidence\pr-247.json') '{"pr":247,"sha":"2222222222222222222222222222222222222222","verdict":"PASS","checks":[]}' $false
  $x = Invoke-ReportLint $rc $cl
  St-Case 'evidence for a stale sha is not accepted' ($x.Flags.Count -eq 2) 'two flags' ('flags=' + $x.Flags.Count)
  $pf = Join-Path $rr 'perf.md'
  Write-Text $pf "- Unit move packets cost 38 ms per tick.`r`n- Unit move packets cost 38 ms per tick (estimate).`r`n- Cost 38 ms per tick, run 40441399510.`r`n## Perf (estimates, unmeasured)`r`n- Cost 38 ms per tick.`r`n" $false
  $x = Invoke-ReportLint $rc $pf
  St-Case 'perf numbers: only the unlabelled one is flagged' ($x.Flags.Count -eq 1 -and $x.Flags[0].Line -eq 1 -and $x.Stat.PerfSuppressed -eq 3) 'flag on line 1, 3 suppressed' ('flags=' + $x.Flags.Count + ' suppressed=' + $x.Stat.PerfSuppressed)

  # ---- M9 kb learn twice + dedup (child processes)
  $kb = Join-Path $ToolsDir 'kb.ps1'
  $rk = St-Root $tmp 'kb' $fx $good
  Write-Text (Join-Path $rk 'usage\ledger-2026-10-26.md') ($ledgerHdr + "| 22:10 | B | 013 | build one | sonnet | high | - | pass | tier: standard; learn: worked: x; rule: always cite the run id before saying verified [id:aa11] |`r`n| 22:20 | B | 013 | build two | sonnet | high | - | redo | tier: standard; learn: failed: y; rule: check gh auth status for the workflow scope first [id:bb22] |`r`n") $false
  Write-Text (Join-Path $rk 'knowledge\entries.jsonl') '' $false
  $rep = Join-Path $rk 'reply.txt'
  Write-Text $rep ('{"type":"lesson","tags":["ops"],"paths":[],"text":"Always cite the run id before saying verified.","source":"row aa11 \"always cite the run id before saying verified\""}' + "`n" + '{"type":"lesson","tags":["ci"],"paths":[],"text":"Check gh auth status for the workflow scope before briefing workflow edits.","source":"row bb22 \"check gh auth status for the workflow scope first\""}' + "`n") $false
  $o1 = (& powershell -NoProfile -ExecutionPolicy Bypass -File $kb learn -Root $rk -Date 2026-10-26 -StubReply $rep 2>&1 | Out-String)
  $o2 = (& powershell -NoProfile -ExecutionPolicy Bypass -File $kb learn -Root $rk -Date 2026-10-26 -StubReply $rep 2>&1 | Out-String)
  $n1 = 0; if ($o1 -match 'appended (\d+) candidate') { $n1 = [int]$Matches[1] }
  $cnt = @(Get-Content -LiteralPath (Join-Path $rk 'knowledge\entries.jsonl') | Where-Object { $_.Trim() }).Count
  St-Case 'M9 first learn appends the candidates' ($n1 -eq 2 -and $cnt -eq 2) 'appended 2, store 2' ('appended ' + $n1 + ', store ' + $cnt + ' :: ' + (Get-Trunc $o1 100))
  St-Case 'M9 second learn appends 0 (cursor)' ($o2 -match 'nothing to learn' -and $cnt -eq 2) 'nothing to learn, store still 2' (Get-Trunc $o2 120)
  $ep = Join-Path $rk 'knowledge\entries.jsonl'
  $e0 = @(Get-Content -LiteralPath $ep | Where-Object { $_.Trim() })
  $dup = $e0[0] -replace '"id":"C001"', '"id":"C900"' -replace '"injected":0', '"injected":2' -replace '"confirmations":1', '"confirmations":3'
  Write-Text $ep (($e0 -join "`r`n") + "`r`n" + $dup + "`r`n") $false
  $o3 = (& powershell -NoProfile -ExecutionPolicy Bypass -File $kb dedup -Root $rk 2>&1 | Out-String)
  $cnt3 = @(Get-Content -LiteralPath $ep | Where-Object { $_.Trim() }).Count
  $arch = Read-Text (Join-Path $rk 'knowledge\archive.jsonl')
  St-Case 'M9 dedup merges same text+source, archives with reason' ($cnt3 -eq 2 -and $arch -match '"reason":"dedup"' -and (Read-Text $ep) -match '"confirmations":4') 'store 2, archive reason dedup, counters summed (conf 4)' ('store ' + $cnt3 + ' :: ' + (Get-Trunc $o3 110))

  # ---- results
  Remove-Item -LiteralPath $tmp -Recurse -Force -ErrorAction SilentlyContinue
  $tot = $script:StR.Count
  $okn = @($script:StR | Where-Object { $_.Ok }).Count
  foreach ($r in $script:StR) {
    if (-not $r.Ok) { Write-Output ('MISS {0}: wanted [{1}] got [{2}]' -f $r.Case, $r.Want, $r.Got) }
    elseif ($verbose) { Write-Output ('ok   {0}: {1}' -f $r.Case, $r.Got) }
  }
  Write-Output ('selftest: {0}/{1} caught in {2:N1}s' -f $okn, $tot, ($sw.ElapsedMilliseconds / 1000.0))
  $script:StOk = ($okn -eq $tot)
}
