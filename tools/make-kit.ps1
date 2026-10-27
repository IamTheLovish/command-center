# make-kit.ps1 - rebuild D:\Command Center\kit (handoff kit for new sessions) from the live files. ASCII, PS 5.1.
param([string]$Root = "D:\Command Center")
$ErrorActionPreference = 'Stop'
$kit = Join-Path $Root 'kit'
if (-not (Test-Path $kit)) { New-Item -ItemType Directory -Path $kit | Out-Null }
# keep START-HERE.md (hand-written); clear everything else
Get-ChildItem $kit -Force | Where-Object { $_.Name -ne 'START-HERE.md' } | Remove-Item -Recurse -Force
function CopyIf($src, $dstRel) {
  $s = Join-Path $Root $src
  if (Test-Path $s) {
    $d = Join-Path $kit $dstRel
    $dir = Split-Path $d -Parent
    if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
    Copy-Item $s $d -Recurse -Force
    "copied  $src"
  } else { "missing $src" }
}
CopyIf 'command-center\COMMANDER.md'        'COMMANDER.md'
CopyIf 'command-center\model-routing.md'    'model-routing.md'
CopyIf 'command-center\HANDOFF-TEMPLATE.md' 'templates\HANDOFF-TEMPLATE.md'
CopyIf 'command-center\SELF-DIAGNOSIS-TEMPLATE.md' 'templates\SELF-DIAGNOSIS-TEMPLATE.md'
CopyIf 'command-center\mistakes-ledger.md'  'reference\mistakes-ledger.md'
CopyIf 'command-center\lessons.md'          'reference\lessons.md'
CopyIf 'knowledge\RULES.md'                 'RULES.md'
CopyIf 'knowledge\decisions.md'             'decisions.md'
CopyIf 'knowledge\entries.jsonl'            'knowledge\entries.jsonl'
CopyIf 'knowledge\codemap'                  'codemap'
CopyIf 'tools\README-cc.md'                 'tools\README-cc.md'
CopyIf 'tools\jobs\README.md'               'tools\jobs-README.md'
CopyIf 'tools\install-gate-hook.md'         'tools\install-gate-hook.md'
CopyIf 'usage\metrics.md'                   'reference\metrics.md'
CopyIf 'reference\reddit-research-and-guardrails.md' 'reference\guardrails.md'
CopyIf 'references\north-star-2026-10-21.md' 'reference\north-star.md'
# newest handoff
$h = Get-ChildItem (Join-Path $Root 'command-center\handoffs') -Directory | Sort-Object Name | Select-Object -Last 1
if ($h) {
  New-Item -ItemType Directory -Path (Join-Path $kit 'handoff') -Force | Out-Null
  Get-ChildItem $h.FullName -Filter *.md | ForEach-Object { Copy-Item $_.FullName (Join-Path $kit "handoff\$($_.Name)") }
  "copied  handoff $($h.Name)"
}
# queued briefs + plans
foreach ($p in @('briefs\hero-ai-QUEUED-2026-10-27.md','briefs\overnight-review-2026-10-26.md')) { CopyIf $p ("briefs\" + (Split-Path $p -Leaf)) }
if (Test-Path (Join-Path $Root 'plans')) { CopyIf 'plans' 'plans' }
# manifest + zip
$stamp = (Get-Date).ToString('yyyy-MM-dd HH:mm')
$files = Get-ChildItem $kit -Recurse -File | ForEach-Object { $_.FullName.Substring($kit.Length + 1) }
Set-Content (Join-Path $kit 'MANIFEST.txt') (@("kit built $stamp from $Root (gen source: $($h.Name))") + $files) -Encoding ASCII
$zip = Join-Path $Root 'kit.zip'
if (Test-Path $zip) { Remove-Item $zip -Force }
Compress-Archive -Path (Join-Path $kit '*') -DestinationPath $zip
"kit: $($files.Count) files -> $kit ; zip -> $zip"
