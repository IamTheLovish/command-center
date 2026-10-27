# setup-cc-ci.ps1 - lovish runs this once (Oct 27 03:30: "we have runners on github to run the test").
# Makes D:\Command Center a PRIVATE GitHub repo (allow-listed folders only, secret scan first) and adds a Windows runner
# workflow that runs the tests on every push. Doubles as the off-PC backup gen-013 recommended.
# Usage: powershell -NoProfile -ExecutionPolicy Bypass -File "D:\Command Center\tools\setup-cc-ci.ps1"
param([string]$Owner = 'IamTheLovish', [string]$Name = 'command-center')
$ErrorActionPreference = 'Stop'
$R = Split-Path -Parent $PSScriptRoot
Set-Location -LiteralPath $R
$auth = (gh auth status 2>&1 | Out-String)
if ($auth -notmatch "workflow") {
  Write-Host 'gh needs the workflow scope to push a workflow file. A browser window will open to approve it.'
  gh auth refresh -h github.com -s workflow
  if ($LASTEXITCODE -ne 0) { Write-Host 'Scope not granted: stopped, nothing pushed.'; exit 1 }
}
if (-not (Test-Path -LiteralPath (Join-Path $R '.git'))) { git init -b main | Out-Null }
Copy-Item -LiteralPath (Join-Path $R 'guards\cc-repo\gitignore.txt') -Destination (Join-Path $R '.gitignore') -Force
New-Item -ItemType Directory -Force -Path (Join-Path $R '.github\workflows') | Out-Null
Copy-Item -LiteralPath (Join-Path $R 'guards\cc-repo\cc-tests.yml') -Destination (Join-Path $R '.github\workflows\cc-tests.yml') -Force
$paths = @('.gitignore', '.github', 'tools', 'skills', 'guards', 'command-center', 'knowledge', 'plans', 'briefs') | Where-Object { Test-Path -LiteralPath (Join-Path $R $_) }
git add -- $paths
# secret scan of exactly what is staged; abort on any hit
$staged = @(git diff --cached --name-only)
$rx = 'sk-ant-[A-Za-z0-9_-]{10,}|gh[pousr]_[A-Za-z0-9]{20,}|github_pat_[A-Za-z0-9_]{20,}|AKIA[0-9A-Z]{16}|-----BEGIN [A-Z ]*PRIVATE KEY'
$hits = @()
foreach ($f in $staged) { $p = Join-Path $R $f; if ((Test-Path -LiteralPath $p) -and (Select-String -LiteralPath $p -Pattern $rx -Quiet)) { $hits += $f } }
if ($hits.Count -gt 0) { git reset -q; Write-Host 'Possible secret in:'; $hits | ForEach-Object { Write-Host ('  ' + $_) }; Write-Host 'Stopped, nothing committed.'; exit 1 }
Write-Host ('Staged {0} files. Committing.' -f $staged.Count)
git commit -q -m "Command Center: tools, skills, guards, knowledge + Windows test runner"
$exists = $true
gh repo view "$Owner/$Name" --json name 2>$null | Out-Null
if ($LASTEXITCODE -ne 0) { $exists = $false }
if (-not $exists) {
  gh repo create "$Owner/$Name" --private --source $R --remote origin --push
} else {
  if (-not (git remote 2>$null | Select-String -SimpleMatch 'origin' -Quiet)) { git remote add origin ("https://github.com/$Owner/$Name.git") }
  git push -u origin main
}
if ($LASTEXITCODE -ne 0) { Write-Host 'Push failed (see above).'; exit 1 }
Write-Host ("Done. Private repo: https://github.com/$Owner/$Name  -  tests: https://github.com/$Owner/$Name/actions")
