# send-joisco-pack.ps1 - lovish runs this himself (2026-10-27).
# Uploads the AI pack for Joisco as a SECRET gist under the signed-in gh account,
# then tags @Joisco on issue #35 with the link. Asks before posting anything.
# Usage: powershell -NoProfile -ExecutionPolicy Bypass -File "D:\Command Center\tools\send-joisco-pack.ps1"
param(
  [string]$Dir = 'D:\Command Center\kit\for-joisco-2026-10-27',
  [string]$Repo = 'IamTheLovish/beyond-and-tabs',
  [int]$Issue = 35
)
$ErrorActionPreference = 'Stop'
$pack = Join-Path $Dir 'BEYOND-AND-TABS-AI-PACK.md'
if (-not (Test-Path $pack)) { Write-Host "Pack not found: $pack"; exit 1 }
$files = @($pack, (Join-Path $Dir 'README.txt')) + @(Get-ChildItem (Join-Path $Dir 'skills\*.SKILL.md') | ForEach-Object { $_.FullName })
gh auth status 2>&1 | Out-Null
if ($LASTEXITCODE -ne 0) { Write-Host 'gh is not signed in. Run: gh auth login'; exit 1 }

Write-Host ("Will upload {0} files as a SECRET gist, then comment on {1} issue #{2} tagging @Joisco." -f $files.Count, $Repo, $Issue)
Write-Host 'The repo is public: the comment (and so the gist link) is visible to anyone.'
$ok = Read-Host 'Type YES to send'
if ($ok -ne 'YES') { Write-Host 'Cancelled. Nothing was sent.'; exit 0 }

$url = (gh gist create --desc 'Beyond and Tabs - AI working pack for Joisco (2026-10-27)' $files | Select-Object -Last 1)
if ($LASTEXITCODE -ne 0 -or -not $url) { Write-Host 'Gist upload failed. Nothing was posted on GitHub.'; exit 1 }
Write-Host "Gist: $url"

$body = "@Joisco - lovish's Claude working pack for your AI to analyse: skills, decisions D001-D039, rules, lessons, mistakes ledger, model routing, and state as of Oct 27. BEYOND-AND-TABS-AI-PACK.md has everything; the *.SKILL.md files install in Claude as-is. Snapshot of the Command Center, no secrets. $url"
gh issue comment $Issue -R $Repo -b $body
if ($LASTEXITCODE -ne 0) { Write-Host "Comment failed. Send him the gist link yourself: $url"; exit 1 }
Write-Host 'Sent. Joisco is tagged on #35.'
