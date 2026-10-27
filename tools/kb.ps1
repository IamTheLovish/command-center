# kb.ps1 - knowledge store for the Command Center learning loop. ASCII only, PowerShell 5.1.
# Subcommands: seed | recall | render | credit | learn.  Store: knowledge\entries.jsonl (+ archive.jsonl, RULES.md, by-tag\).
param(
  [Parameter(Position = 0)][string]$Cmd = 'help',
  [string]$Root = 'D:\Command Center',
  [string]$Task = '', [string]$Tags = '', [string]$Paths = '', [int]$Top = 8,
  [string]$Id = '', [string]$Date = '', [int]$MaxTokens = 2500, [switch]$DryRun,
  [string]$StubReply = '', [switch]$Near
)
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'cc-lib.ps1')

$KDir = Join-Path $Root 'knowledge'
$EntriesPath = Join-Path $KDir 'entries.jsonl'
$ArchivePath = Join-Path $KDir 'archive.jsonl'
$Lanes = @('code', 'art', 'anim', 'perf', 'ci', 'balance', 'ops')
$Types = @('lesson', 'recipe', 'brief', 'anti', 'decision', 'codemap')

$LaneRules = @(
  @('code', '(?i)\bjava\b|\bcode\b|GameTest|handler|RenderLevelStage|isRtsOptimisedMap|refactor|Mode A|unit test|tests? first|lean-code|min_y|dimension'),
  @('art', '(?i)texture|block pack|silhouette|palette|laplacian|CC0|\bart\b|material|bark|stone|planks|tint'),
  @('anim', '(?i)animation|anim_lab|\bpose\b|\bclip\b|skeleton'),
  @('perf', '(?i)\bperf|frame|\bms\b|\blag\b|\btick|shadow|render|cull|pathfind|budget|\bFPS\b|profil'),
  @('ci', '(?i)\bCI\b|flake|stress|runner|workflow|merge|\bPR\b|gradle|mirror|GitHub|check_java|bat-ship|branch|claim|commit'),
  @('balance', '(?i)balance|\bT[12]\b|raid|economy|\bBAR\b|converter|\bTTK\b|bot ladder'),
  @('ops', '(?i)ledger|handoff|commander|agent|brief|lovish|skill|context|process|\bPID\b|pkill|blender|\blane|heavy|vault|auditor|usage|token|\bapi\b')
)
$AreaRules = @(
  @('shaders', '(?i)shader|oculus|skipOverlays|complementary'), @('pathfinding', '(?i)pathfind|navmesh'),
  @('worldgen', '(?i)worldgen|bedrock|min_y|dimension|floor y|\bores\b'), @('multiplayer', '(?i)multiplayer|\bmatch(es)?\b|server log'),
  @('texture', '(?i)texture|block pack|laplacian|CC0'), @('blender', '(?i)blender'), @('skills', '(?i)\bskills?\b'),
  @('ledger', '(?i)ledger'), @('git', '(?i)branch|worktree|claim|\bPR\b|commit|merge'), @('mirror-ci', '(?i)mirror'),
  @('flake', '(?i)flake'), @('bots', '(?i)\bbots?\b'), @('graveyard', '(?i)graveyard'), @('vfx', '(?i)\bvfx\b|projectile'),
  @('render', '(?i)render|overlay|RenderLevelStage'), @('browser', '(?i)browser|preview_start|tabs_create'),
  @('safety', '(?i)pkill|image name|\bkills\b|exfiltrat|secret'), @('agents', '(?i)\bagents?\b|subagent|brief'), @('review', '(?i)\breview|critic')
)
function Get-InferredTags([string]$text) {
  $o = New-Object System.Collections.ArrayList
  foreach ($r in $LaneRules) { if ($text -match $r[1]) { [void]$o.Add($r[0]) } }
  foreach ($r in $AreaRules) { if ($text -match $r[1] -and -not $o.Contains($r[0])) { [void]$o.Add($r[0]) } }
  if ($o.Count -eq 0) { [void]$o.Add('ops') }
  return @($o.ToArray() | Select-Object -First 6)
}
function Get-InferredPaths([string]$text) {
  $o = New-Object System.Collections.ArrayList
  $roots = 'tools|usage|command-center|auditor|skills|knowledge|api|briefs|claude|src|references|reference|janitor'
  foreach ($m in [regex]::Matches($text, '[A-Za-z0-9_.-]+(?:[\\/][A-Za-z0-9_.-]+)+|\b[A-Za-z0-9_-]+\.(?:md|ps1|py|json|jsonl|yml|java|csv)\b')) {
    $v = $m.Value.Replace('\', '/').Trim('.')
    if ($v.Length -lt 4 -or $v -match '^https?') { continue }
    $ok = ($v -match '\.(md|ps1|py|json|jsonl|yml|java|csv)$') -or ($v -match ('^(' + $roots + ')/'))
    if ($ok -and -not $o.Contains($v)) { [void]$o.Add($v) }
  }
  return @($o.ToArray() | Select-Object -First 4)
}
# ---- store io ----
function ConvertTo-JsonLine($o) {
  $j = $o | ConvertTo-Json -Compress -Depth 6
  return $j.Replace('\u0027', "'").Replace('\u003c', '<').Replace('\u003e', '>').Replace('\u0026', '&')
}
function Read-Jsonl([string]$p) {
  $out = New-Object System.Collections.ArrayList
  if (-not (Test-Path -LiteralPath $p)) { return @() }
  foreach ($ln in ([IO.File]::ReadAllLines($p, [Text.Encoding]::UTF8))) {
    if (-not $ln.Trim()) { continue }
    try { [void]$out.Add(($ln | ConvertFrom-Json)) } catch { Write-Output ('WARN bad json line skipped in ' + (Split-Path -Leaf $p)) }
  }
  return $out.ToArray()
}
function Write-Jsonl([string]$p, $list) {
  $lines = @($list | ForEach-Object { ConvertTo-JsonLine $_ })
  Write-Text $p ((($lines -join "`r`n")) + $(if ($lines.Count) { "`r`n" } else { '' })) $false
}
function Append-Jsonl([string]$p, $list) {
  $cur = Read-Text $p
  $add = (@($list | ForEach-Object { ConvertTo-JsonLine $_ }) -join "`r`n") + "`r`n"
  if ($cur.Length -gt 0 -and -not $cur.EndsWith("`n")) { $cur += "`r`n" }
  Write-Text $p ($cur + $add) $false
}
function New-Entry([string]$id, [string]$type, $tags, $paths, [string]$text, [string]$source, [string]$status, [int]$conf) {
  return [pscustomobject][ordered]@{
    id = $id; type = $type; tags = @($tags | Where-Object { $_ }); paths = @($paths | Where-Object { $_ }); text = $text; source = $source; status = $status
    injected = 0; helped = 0; hurt = 0; confirmations = $conf; last_used = $null
  }
}
function Get-Words([string]$s) { return @([regex]::Matches($s.ToLower(), '[a-z0-9_]{4,}') | ForEach-Object { $_.Value } | Sort-Object -Unique) }
function Get-Jaccard($a, $b) {
  if ($a.Count -eq 0 -or $b.Count -eq 0) { return 0.0 }
  $h = @{}; foreach ($x in $a) { $h[$x] = 1 }
  $inter = 0; foreach ($y in $b) { if ($h.ContainsKey($y)) { $inter++ } }
  return [double]$inter / ($a.Count + $b.Count - $inter)
}

# ---- seed ----
function Cmd-Seed {
  New-Item -ItemType Directory -Force -Path $KDir | Out-Null
  $have = @(Read-Jsonl $EntriesPath) + @(Read-Jsonl $ArchivePath)
  $texts = @{}; foreach ($e in $have) { $texts[$e.text] = 1 }
  $new = New-Object System.Collections.ArrayList
  $ln = 0; $mn = 0
  foreach ($e in $have) { if ($e.id -match '^L(\d+)$') { $ln = [Math]::Max($ln, [int]$Matches[1]) }; if ($e.id -match '^M(\d+)$') { $mn = [Math]::Max($mn, [int]$Matches[1]) } }
  $lessons = Split-Lines (Read-Text (Join-Path $Root 'command-center\lessons.md'))
  $section = ''
  foreach ($l in $lessons) {
    if ($l -match '^##\s+(.*)') { $section = $Matches[1]; continue }
    if ($l -notmatch '^-\s+\[([^\]]+)\]\s*(.*)$') { continue }
    $src = '[' + $Matches[1] + ']'; $txt = $Matches[2].Trim()
    if ($texts.ContainsKey($txt)) { continue }
    $conf = 0; $status = 'candidate'
    if ($txt -match 'HARD RULE') { $status = 'rule'; $conf = 3 }
    if ($txt -match '(?i)REPEAT\s*x?(\d+)') { $n = [int]$Matches[1]; if ($n -ge 1) { $status = 'rule'; $conf = [Math]::Max($conf, $n) } }
    $ln++
    $e = New-Entry ('L{0:D3}' -f $ln) 'lesson' (Get-InferredTags ($section + ' ' + $txt)) (Get-InferredPaths $txt) $txt ($src + ' lessons.md') $status $conf
    [void]$new.Add($e)
  }
  $mist = Split-Lines (Read-Text (Join-Path $Root 'command-center\mistakes-ledger.md'))
  foreach ($l in $mist) {
    $e = $null
    if ($l -match '^\|\s*(\d{4}-\d{2}-\d{2})\s*\|') {
      $p = @($l.Trim().Trim('|') -split '\|' | ForEach-Object { $_.Trim() })
      if ($p.Count -ge 6) {
        $rep = 0; if ($p[5] -match '(\d+)') { $rep = [int]$Matches[1] }
        $txt = $p[2] + "`n" + 'Rule: ' + $p[4]
        if ($texts.ContainsKey($txt)) { continue }
        $mn++
        $st = 'candidate'; if ($rep -ge 1) { $st = 'rule' }
        $e = New-Entry ('M{0:D3}' -f $mn) 'anti' (Get-InferredTags ($p[2] + ' ' + $p[3] + ' ' + $p[4])) (Get-InferredPaths ($p[2] + ' ' + $p[4])) $txt ('[gen-' + $p[1] + '] mistakes-ledger ' + $p[0]) $st $rep
      }
    } elseif ($l -match '^-\s+\[([^\]]+)\]\s*(.*)$') {
      $src = '[' + $Matches[1] + ']'; $txt = $Matches[2].Trim()
      $rep = 0
      if ($txt -match '(?i)REPEAT\s*x?(\d+)') { $rep = [int]$Matches[1] }
      $clean = ($txt -replace '\s*(\*\*)?REPEAT\s*x?\d+(\*\*)?\.?\s*$', '').Trim()
      if ($texts.ContainsKey($clean)) { continue }
      $mn++
      $st = 'candidate'; if ($rep -ge 1) { $st = 'rule' }
      $e = New-Entry ('M{0:D3}' -f $mn) 'anti' (Get-InferredTags $clean) (Get-InferredPaths $clean) $clean ($src + ' mistakes-ledger') $st $rep
    }
    if ($e) { [void]$new.Add($e) }
  }
  if ($new.Count -gt 0) { Append-Jsonl $EntriesPath $new.ToArray() }
  $all = @(Read-Jsonl $EntriesPath)
  Write-Output ('seed: added {0}; entries now {1} (rule {2}, candidate {3})' -f $new.Count, $all.Count, @($all | Where-Object { $_.status -eq 'rule' }).Count, @($all | Where-Object { $_.status -eq 'candidate' }).Count)
}

# ---- recall ----
$Stop = @('this', 'that', 'with', 'from', 'have', 'will', 'then', 'into', 'when', 'what', 'task', 'make', 'need', 'should', 'would', 'about', 'there', 'their', 'them', 'they', 'for', 'and', 'the')
function Cmd-Recall {
  if (-not $Task -and -not $Tags -and -not $Paths) { Write-Output 'ERR recall needs -Task "<text>" [-Tags a,b] [-Paths p] [-Top 8]'; exit 2 }
  $entries = @(Read-Jsonl $EntriesPath | Where-Object { $_.status -ne 'retired' })
  $tg = @($Tags -split '[,\s]+' | Where-Object { $_ } | ForEach-Object { $_.ToLower() })
  if ($tg.Count -eq 0 -and $Task) { $tg = @(Get-InferredTags $Task) }
  $ps = @($Paths -split ',' | Where-Object { $_.Trim() } | ForEach-Object { $_.Trim().Replace('\', '/').ToLower() })
  $kw = @(Get-Words $Task | Where-Object { $Stop -notcontains $_ })
  $scored = New-Object System.Collections.ArrayList
  foreach ($e in $entries) {
    $et = @($e.tags | ForEach-Object { "$_".ToLower() })
    $ov = 0; foreach ($t in $tg) { if ($et -contains $t) { $ov++ } }
    $pm = 0
    foreach ($p in $ps) {
      $hit = $false
      foreach ($ep in @($e.paths)) {
        $q = "$ep".Replace('\', '/').ToLower()
        if ($q -and ($p.StartsWith($q) -or $q.StartsWith($p))) { $hit = $true }
      }
      if ($hit) { $pm++ }
    }
    $hay = ($e.text + ' ' + ($et -join ' ') + ' ' + (@($e.paths) -join ' ')).ToLower()
    $kh = 0; foreach ($w in $kw) { if ($hay.Contains($w)) { $kh++ } }
    $score = 3 * $ov + 2 * $pm + $kh + ([double]$e.helped / ([double]$e.injected + 1))
    if ($score -gt 0) { [void]$scored.Add([pscustomobject]@{ E = $e; S = $score }) }
  }
  $sorted = @($scored | Sort-Object -Property @{ Expression = 'S'; Descending = $true }, @{ Expression = { [int]$_.E.confirmations }; Descending = $true } | Select-Object -First $Top)
  $out = New-Object System.Collections.ArrayList
  [void]$out.Add(('recall tags=[{0}] top {1} of {2} matches (put ids in ledger-add -Kb to get credit)' -f ($tg -join ','), $sorted.Count, $scored.Count))
  foreach ($x in $sorted) {
    $e = $x.E
    $t = ($e.text -replace '\s*[\r\n]+\s*', ' / ')
    $t = Get-Trunc $t 220
    $l1 = $t; $l2 = ''
    if ($t.Length -gt 110) { $cut = $t.LastIndexOf(' ', 110); if ($cut -lt 40) { $cut = 110 }; $l1 = $t.Substring(0, $cut); $l2 = $t.Substring($cut).Trim() }
    $need = 2; if ($l2) { $need = 3 }
    if (($out.Count + $need) -gt 25) { break }
    [void]$out.Add(('{0} {1} s={2} [{3}] {4}' -f $e.id, $e.status, ([math]::Round($x.S, 1)), (@($e.tags) -join ','), $e.source))
    [void]$out.Add('  ' + $l1)
    if ($l2) { [void]$out.Add('  ' + $l2) }
  }
  if ($sorted.Count -eq 0) { [void]$out.Add('  (no matching entries)') }
  $out | ForEach-Object { Write-Output $_ }
}

# ---- render ----
function Cmd-Render {
  $entries = @(Read-Jsonl $EntriesPath | Where-Object { $_.status -ne 'retired' })
  $rules = @($entries | Where-Object { $_.status -eq 'rule' })
  $prio = $Lanes + @('shaders', 'pathfinding', 'worldgen', 'multiplayer', 'texture', 'safety', 'agents', 'git')
  function Get-Primary($e) { $t = @($e.tags); foreach ($p in @('ops', 'ci', 'balance', 'perf', 'code', 'anim', 'art')) { if ($t -contains $p) { return $p } }; if ($t.Count) { return [string]$t[0] }; return 'ops' }
  $ranked = @($rules | Sort-Object -Property @{ Expression = { [int]$_.confirmations }; Descending = $true }, @{ Expression = { [int]$_.helped }; Descending = $true })
  $kept = New-Object System.Collections.ArrayList
  foreach ($r in $ranked) {
    [void]$kept.Add($r)
    $groups = @($kept | ForEach-Object { Get-Primary $_ } | Sort-Object -Unique)
    $lines = 4 + $kept.Count + (2 * $groups.Count) + 1
    if ($lines -gt 40) { [void]$kept.RemoveAt($kept.Count - 1) }
  }
  $by = @{}
  foreach ($r in $kept) { $g = Get-Primary $r; if (-not $by.ContainsKey($g)) { $by[$g] = New-Object System.Collections.ArrayList }; [void]$by[$g].Add($r) }
  $o = New-Object System.Collections.ArrayList
  [void]$o.Add('<!-- generated by tools\kb.ps1 render - do not edit -->')
  [void]$o.Add('# RULES (generated - do not edit)')
  [void]$o.Add(('Source: knowledge\entries.jsonl status=rule; showing {0} of {1}. Full tag lists: knowledge\by-tag\.' -f $kept.Count, $rules.Count))
  foreach ($g in $by.Keys | Sort-Object { $i = [array]::IndexOf($Lanes, $_); if ($i -lt 0) { 99 } else { $i } }, { $_ }) {
    [void]$o.Add('')
    [void]$o.Add('## ' + $g)
    foreach ($r in $by[$g]) { [void]$o.Add(('- {0}: {1}' -f $r.id, (Get-Trunc (($r.text -replace '\s*[\r\n]+\s*', ' / ')) 200))) }
  }
  Write-Text (Join-Path $KDir 'RULES.md') (($o -join "`r`n") + "`r`n") $false
  # by-tag
  $tags = @{}
  foreach ($e in $entries) { foreach ($t in @($e.tags)) { if (-not $tags.ContainsKey("$t")) { $tags["$t"] = New-Object System.Collections.ArrayList }; [void]$tags["$t"].Add($e) } }
  New-Item -ItemType Directory -Force -Path (Join-Path $KDir 'by-tag') | Out-Null
  foreach ($t in $tags.Keys) {
    $f = New-Object System.Collections.ArrayList
    [void]$f.Add('<!-- generated by tools\kb.ps1 render - do not edit -->')
    [void]$f.Add('# Entries tagged ' + $t + ' (' + $tags[$t].Count + ')')
    [void]$f.Add('')
    foreach ($e in ($tags[$t] | Sort-Object @{ Expression = { if ($_.status -eq 'rule') { 0 } else { 1 } } }, id)) {
      [void]$f.Add(('- {0} [{1}/{2}] {3} -- {4}' -f $e.id, $e.type, $e.status, (($e.text -replace '\s*[\r\n]+\s*', ' / ')), $e.source))
    }
    Write-Text (Join-Path $KDir ('by-tag\' + ($t -replace '[^\w-]', '_') + '.md')) (($f -join "`r`n") + "`r`n") $false
  }
  Write-Output ('render: RULES.md {0} lines ({1} rules shown of {2}); by-tag files: {3}' -f $o.Count, $kept.Count, $rules.Count, $tags.Count)
}

# ---- credit ----
function Cmd-Credit {
  if (-not $Id) { Write-Output 'ERR credit needs -Id <ledger id>'; exit 2 }
  $row = $null
  foreach ($r in (Get-LedgerRows $Root)) { if ($r.Id -eq $Id) { $row = $r } }
  if ($null -eq $row) { Write-Output "ERR no ledger row $Id"; exit 2 }
  if ($row.Class -eq 'running' -or $row.Class -eq 'pending') { Write-Output "ERR row $Id is not closed ($($row.Result)); close it first"; exit 2 }
  if ($row.Credited) { Write-Output "row $Id already credited; nothing to do"; return }
  if ($row.Kb.Count -eq 0) { Write-Output "row $Id has no Kb ids; nothing to credit"; return }
  $entries = @(Read-Jsonl $EntriesPath)
  $today = (Get-NowET).ToString('yyyy-MM-dd')
  $log = New-Object System.Collections.ArrayList
  foreach ($kid in $row.Kb) {
    $e = $entries | Where-Object { $_.id -eq $kid } | Select-Object -First 1
    if ($null -eq $e) { [void]$log.Add("  $kid not found (retired or unknown)"); continue }
    $e.injected = [int]$e.injected + 1
    $e.last_used = $today
    if ($row.Class -eq 'pass') { $e.helped = [int]$e.helped + 1; $e.confirmations = [int]$e.confirmations + 1 }
    elseif ($row.Class -eq 'redo') { $e.hurt = [int]$e.hurt + 1 }
    [void]$log.Add(('  {0}: injected {1} helped {2} hurt {3} conf {4}' -f $e.id, $e.injected, $e.helped, $e.hurt, $e.confirmations))
  }
  $keep = New-Object System.Collections.ArrayList
  $arch = New-Object System.Collections.ArrayList
  foreach ($e in $entries) {
    if ($e.status -eq 'candidate' -and [int]$e.confirmations -ge 3) { $e.status = 'rule'; [void]$log.Add("  PROMOTED $($e.id) candidate -> rule") }
    if ($e.status -eq 'rule' -and [int]$e.injected -ge 5 -and [int]$e.helped -eq 0) {
      $e.status = 'retired'
      $e | Add-Member -NotePropertyName retired -NotePropertyValue $today -Force
      [void]$arch.Add($e); [void]$log.Add("  RETIRED $($e.id) (injected $($e.injected), helped 0) -> archive.jsonl")
      continue
    }
    [void]$keep.Add($e)
  }
  Write-Jsonl $EntriesPath $keep.ToArray()
  if ($arch.Count -gt 0) { Append-Jsonl $ArchivePath $arch.ToArray() }
  [void](Update-LedgerRow $Root $Id @{ AppendNote = '[credited]' })
  Write-Output ("credit row $Id ($($row.Result)) kb=" + ($row.Kb -join ','))
  $log | ForEach-Object { Write-Output $_ }
}

# ---- learn cursor (M9: learn must never process the same ledger row or handoff twice) ----
$CursorPath = Join-Path $KDir 'learn-cursor.json'
function Get-RowKey($r) { if ($r.Id) { return [string]$r.Id }; return ($r.Date + '|' + $r.Time + '|' + (Get-Trunc $r.Assignment 40)) }
function Read-Cursor {
  $c = @{ rows = @(); handoffs = @() }
  if (Test-Path -LiteralPath $CursorPath) {
    try { $j = Read-Text $CursorPath | ConvertFrom-Json; $c.rows = @($j.rows | Where-Object { $_ }); $c.handoffs = @($j.handoffs | Where-Object { $_ }) } catch { }
  } else {
    $stP = Join-Path $KDir 'learn-state.json'
    if (Test-Path -LiteralPath $stP) { try { $c.handoffs = @((Read-Text $stP | ConvertFrom-Json).handoffs) } catch { } }
  }
  return $c
}
function Write-Cursor($c) {
  $o = [pscustomobject][ordered]@{ rows = @($c.rows | Select-Object -Unique); handoffs = @($c.handoffs | Select-Object -Unique) }
  Write-Text $CursorPath (($o | ConvertTo-Json -Compress -Depth 4)) $false
}
# learn-mark -Date d: mark every ledger row of that day with learn text as already processed (used once to seed the cursor)
function Cmd-LearnMark {
  $d = $Date; if (-not $d) { Write-Output 'ERR learn-mark needs -Date yyyy-MM-dd'; exit 2 }
  $c = Read-Cursor; $n = 0
  foreach ($r in (Get-LedgerRows $Root $d)) { if ($r.Note -match 'learn:\s*(.*)$') { $c.rows = @($c.rows) + @(Get-RowKey $r); $n++ } }
  Write-Cursor $c
  Write-Output ('learn-mark: {0} row(s) of {1} marked processed; cursor has {2} row(s), {3} handoff(s)' -f $n, $d, @($c.rows | Select-Object -Unique).Count, @($c.handoffs).Count)
}

# ---- dedup (M9): merge entries with the same normalized text and same source; -Near also merges learned candidates (C###, status candidate) with word-Jaccard >= 0.5 ----
function Get-NormText([string]$s) { return (($s.ToLower() -replace '\s+', ' ').Trim()) }
function Cmd-Dedup {
  $entries = @(Read-Jsonl $EntriesPath)
  $before = $entries.Count
  $today = (Get-NowET).ToString('yyyy-MM-dd')
  if (-not $DryRun -and $before -gt 0) {
    $bk = Join-Path $KDir ('entries.backup-' + $today + '.jsonl')
    $k = 1; while (Test-Path -LiteralPath $bk) { $k++; $bk = Join-Path $KDir ('entries.backup-' + $today + '-' + $k + '.jsonl') }
    Copy-Item -LiteralPath $EntriesPath -Destination $bk
    Write-Output ('backup: ' + $bk)
  }
  $keep = New-Object System.Collections.ArrayList
  $gone = New-Object System.Collections.ArrayList
  $byKey = @{}
  foreach ($e in $entries) {
    $key = (Get-NormText ([string]$e.text)) + '||' + (Get-NormText ([string]$e.source))
    $tgt = $null
    if ($byKey.ContainsKey($key)) { $tgt = $byKey[$key] }
    elseif ($Near -and $e.status -eq 'candidate' -and ([string]$e.id) -like 'C*') {
      $w = Get-Words ([string]$e.text)
      foreach ($k2 in $keep) { if ($k2.status -eq 'candidate' -and ([string]$k2.id) -like 'C*' -and (Get-Jaccard $w (Get-Words ([string]$k2.text))) -ge 0.5) { $tgt = $k2; break } }
    }
    if ($null -eq $tgt) { [void]$keep.Add($e); $byKey[$key] = $e; continue }
    foreach ($f in @('injected', 'helped', 'hurt', 'confirmations')) { $tgt.$f = [int]$tgt.$f + [int]$e.$f }
    if ($e.last_used -and ((-not $tgt.last_used) -or ([string]$e.last_used -gt [string]$tgt.last_used))) { $tgt.last_used = $e.last_used }
    $tgt.tags = @(@($tgt.tags) + @($e.tags) | Where-Object { $_ } | Select-Object -Unique)
    $tgt.paths = @(@($tgt.paths) + @($e.paths) | Where-Object { $_ } | Select-Object -Unique)
    if ($e.status -eq 'rule') { $tgt.status = 'rule' }
    $e | Add-Member -NotePropertyName reason -NotePropertyValue 'dedup' -Force
    $e | Add-Member -NotePropertyName merged_into -NotePropertyValue $tgt.id -Force
    $e | Add-Member -NotePropertyName archived -NotePropertyValue $today -Force
    [void]$gone.Add($e)
  }
  if (-not $DryRun -and $gone.Count -gt 0) {
    Write-Jsonl $EntriesPath $keep.ToArray()
    Append-Jsonl $ArchivePath $gone.ToArray()
  }
  Write-Output ('dedup{0}{1}: entries before {2}, after {3}, merged away {4}, archived to archive.jsonl with reason dedup' -f $(if ($Near) { ' (-Near)' } else { '' }), $(if ($DryRun) { ' (DRY RUN, nothing written)' } else { '' }), $before, $keep.Count, $gone.Count)
  foreach ($g in $gone) { Write-Output ('  {0} -> {1}' -f $g.id, $g.merged_into) }
}

# ---- learn ----
function Cmd-Learn {
  $d = $Date; if (-not $d) { $d = (Get-NowET).ToString('yyyy-MM-dd') }
  $stP = Join-Path $KDir 'learn-state.json'
  $cur = Read-Cursor
  $done = @($cur.handoffs)
  $items = New-Object System.Collections.ArrayList
  $nRows = 0
  $newRowKeys = New-Object System.Collections.ArrayList
  foreach ($r in (Get-LedgerRows $Root $d)) {
    if ($r.Note -match 'learn:\s*(.*)$') {
      $lt = ($Matches[1] -replace '[;\s]*\[credited\]\s*$', '').Trim()
      $rk = Get-RowKey $r
      if (@($cur.rows) -contains $rk) { continue }
      [void]$newRowKeys.Add($rk)
      $nRows++
      [void]$items.Add(('[row {0} gen-{1} {2}] {3} -> {4}. learn: {5}' -f $(if ($r.Id) { $r.Id } else { 'no-id' }), $r.Gen, $r.Result, (Get-Trunc $r.Assignment 120), $r.Result, $lt))
    }
  }
  $newH = @(); $hd = Join-Path $Root 'command-center\handoffs'
  if (Test-Path -LiteralPath $hd) { $newH = @(Get-ChildItem -LiteralPath $hd -Directory | Where-Object { $done -notcontains $_.Name } | Sort-Object Name) }
  $nH = 0
  foreach ($h in $newH) {
    $sd = Join-Path $h.FullName 'SELF-DIAGNOSIS.md'
    $src = $sd; if (-not (Test-Path -LiteralPath $sd)) { $src = Join-Path $h.FullName 'HANDOFF.md' }
    if (-not (Test-Path -LiteralPath $src)) { continue }
    $nH++
    $txt = (Read-Text $src) -replace '\s+', ' '
    [void]$items.Add(('[handoff {0} {1}] {2}' -f $h.Name, (Split-Path -Leaf $src), (Get-Trunc $txt 3000)))
  }
  $data = ($items -join "`n")
  if ($data.Length -gt 60000) { $data = $data.Substring(0, 60000) }
  $instr = @"
You extract reusable lessons for a game-dev Command Center. From the INPUT below propose at most 12 knowledge entries.
Output ONLY JSON lines (one JSON object per line, no prose, no code fences). Fields:
type (one of lesson|recipe|brief|anti|decision|codemap), tags (array: lanes code,art,anim,perf,ci,balance,ops plus area words), paths (array, may be empty),
text (max 2 lines, max 300 chars, imperative, specific), source (where it came from, e.g. "row ab12" or the handoff name, PLUS an exact verbatim quote copied from the INPUT in double quotes, at least 12 characters).
Only include entries a future session would act on and that a quote supports. Never include secrets.
INPUT:
"@
  $prompt = $instr + "`n" + $data
  Write-Output ('learn {0}: rows with Learn text={1}, new handoffs={2}, prompt chars={3} (~{4} tokens)' -f $d, $nRows, $nH, $prompt.Length, [int]($prompt.Length / 4))
  if ($DryRun) { Write-Output 'DRY RUN: no model call, nothing written.'; return }
  if ($items.Count -eq 0) { Write-Output 'nothing to learn from (cursor: every row and handoff already processed).'; return }
  $st = Get-State $Root
  $res = ''
  if ($StubReply) {
    $res = 'OK stub reply'
    $reply = Read-Text $StubReply
  } else {
    $pf = Join-Path $env:TEMP 'cc-kb-learn-prompt.txt'
    Write-Text $pf $prompt $false
    $off = Join-Path $Root 'api\offload.ps1'
    if (-not (Test-Path -LiteralPath $off)) { $off = Join-Path (Split-Path -Parent $PSScriptRoot) 'api\offload.ps1' }
    if ($st) { $env:CC_ACCT = [string]$st.acct }
    $old = $ErrorActionPreference; $ErrorActionPreference = 'Continue'
    try { $res = (& powershell -NoProfile -ExecutionPolicy Bypass -File $off -Model haiku -Task 'kb-learn' -PromptFile $pf -MaxTokens $MaxTokens 2>&1 | Out-String).Trim() } finally { $ErrorActionPreference = $old }
    Write-Output $res
    if ($res -notmatch '^OK\s') { Write-Output 'learn: api call failed; nothing appended, cursor not advanced.'; exit 1 }
    $outPath = ''
    if ($res -match '-> (.+?)(\s+WARN.*)?$') { $outPath = $Matches[1].Trim() }
    $reply = Read-Text $outPath
  }
  $norm = ($prompt.ToLower() -replace '\s+', ' ')
  $entries = @(Read-Jsonl $EntriesPath)
  $arch = @(Read-Jsonl $ArchivePath)
  $cn = 0; foreach ($e in ($entries + $arch)) { if ($e.id -match '^C(\d+)$') { $cn = [Math]::Max($cn, [int]$Matches[1]) } }
  $prop = 0; $drop = New-Object System.Collections.ArrayList; $added = New-Object System.Collections.ArrayList; $merged = 0
  foreach ($ln in (Split-Lines $reply)) {
    $s = $ln.Trim()
    if (-not $s.StartsWith('{')) { continue }
    $prop++
    try { $o = $s | ConvertFrom-Json } catch { [void]$drop.Add('bad json'); continue }
    $ty = [string]$o.type; $tx = [string]$o.text; $sr = [string]$o.source
    if ($Types -notcontains $ty) { [void]$drop.Add('bad type'); continue }
    if (-not $tx.Trim() -or $tx.Length -gt 400 -or (@($tx -split "\r?\n").Count -gt 2)) { [void]$drop.Add('bad text'); continue }
    if (-not $sr.Trim()) { [void]$drop.Add('no source'); continue }
    $qs = @([regex]::Matches($sr, '"([^"]{12,})"') | ForEach-Object { ($_.Groups[1].Value.ToLower() -replace '\s+', ' ') })
    if ($qs.Count -eq 0) { [void]$drop.Add('no quoted source'); continue }
    $okq = $false; foreach ($q in $qs) { if ($norm.Contains($q)) { $okq = $true } }
    if (-not $okq) { [void]$drop.Add('quote not in input'); continue }
    $tg = @($o.tags | ForEach-Object { "$_".ToLower() } | Where-Object { $_ })
    if ($tg.Count -eq 0) { [void]$drop.Add('no tags'); continue }
    $w = Get-Words $tx
    $dup = $null
    $ntx = Get-NormText $tx
    foreach ($e in @($entries) + @($added.ToArray())) { if ((Get-NormText ([string]$e.text)) -eq $ntx -or (Get-Jaccard $w (Get-Words $e.text)) -ge 0.6) { $dup = $e; break } }
    if ($dup) { $dup.confirmations = [int]$dup.confirmations + 1; $merged++; continue }
    $cn++
    [void]$added.Add((New-Entry ('C{0:D3}' -f $cn) $ty $tg @($o.paths | Where-Object { $_ }) $tx $sr 'candidate' 1))
  }
  if ($added.Count -gt 0 -or $merged -gt 0) {
    Write-Jsonl $EntriesPath (@($entries) + @($added.ToArray()))
  }
  $hs = @($done) + @($newH | ForEach-Object { $_.Name })
  $cur.rows = @($cur.rows) + @($newRowKeys.ToArray()); $cur.handoffs = $hs
  Write-Cursor $cur
  Write-Text $stP ('{"handoffs":[' + ((@($hs | Select-Object -Unique) | ForEach-Object { '"' + $_ + '"' }) -join ',') + ']}') $false
  Write-Output ('learn: proposed {0}, appended {1} candidate(s), merged {2} duplicate(s) into confirmations, dropped {3} ({4})' -f $prop, $added.Count, $merged, $drop.Count, ((@($drop.ToArray() | Group-Object | ForEach-Object { $_.Name + 'x' + $_.Count })) -join ', '))
  if ($st) {
    $tok = '-'; if ($res -match 'in=(\d+) out=(\d+) cost=\$([0-9.]+)') { $tok = "$($Matches[1]) in / $($Matches[2]) out, `$$($Matches[3])" }
    [void](Add-LedgerRow $Root @{ Assignment = "kb learn $d ($nRows rows, $nH handoffs)"; Model = 'haiku (api)'; Effort = 'low'; Tokens = $tok; Result = 'pass'; Note = "tier: chore; appended $($added.Count) candidates" })
  }
}

switch ($Cmd) {
  'seed' { Cmd-Seed }
  'recall' { Cmd-Recall }
  'render' { Cmd-Render }
  'credit' { Cmd-Credit }
  'learn' { Cmd-Learn }
  'dedup' { Cmd-Dedup }
  'learn-mark' { Cmd-LearnMark }
  default { Write-Output 'kb.ps1 <seed|recall|render|credit|learn|learn-mark|dedup> [options]  (see tools\README-cc.md)' }
}
