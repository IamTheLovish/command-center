# prove-red.ps1 - show a new or changed GameTest red against the OLD game code before calling it "tests first".
# Builds throwaway/red-<Name> = origin/main + only the given test commits (refuses any commit that touches a file
# outside gametest/), pushes it and dispatches flake-stress on it. Prints the run id. The fix commits are never
# included, so a green result means the test does not reproduce the bug: strengthen it before going on.
# M19 (Oct 27, session 3): a "tests first" GameTest was pushed without a red run; review found it passes on main.
#
# Example:
#   powershell -NoProfile -File "D:\Command Center\tools\prove-red.ps1" -Name move-unloaded `
#     -Commits c240b1b1,e54b099e,8ca1dc50 -Tests "test:a_unit_shifted_along_the_wall"
param(
    [Parameter(Mandatory = $true)][string]$Name,
    [Parameter(Mandatory = $true)][string[]]$Commits,
    [string]$Tests = "",
    [string]$Shard = "",
    [string]$Focus = "",
    [int]$Runners = 4,
    [string]$RepoPath = "D:\BeyondAndTabs-Repo",
    [string]$GhRepo = "IamTheLovish/Beyond-and-Tabs",
    [string]$TestPathPattern = "/gametest/"
)
# Continue: PowerShell 5.1 turns a native command's stderr ("remote: ...") into a terminating error under Stop;
# every native call checks $LASTEXITCODE instead
$ErrorActionPreference = "Continue"
if ($Tests -eq "" -and $Shard -eq "") { Write-Output "FAIL give -Tests or -Shard"; exit 1 }
# a list given as one comma-joined string from bash
$list = @()
foreach ($c in $Commits) { $list += ($c -split ",") | Where-Object { $_ -ne "" } }

function Git-Out([string[]]$a) {
    $out = & git -C $RepoPath @a 2>$null
    if ($LASTEXITCODE -ne 0) { throw ("git " + ($a -join " ") + " failed") }
    return $out
}

Git-Out @("fetch", "-q", "origin") | Out-Null
foreach ($c in $list) {
    $files = Git-Out @("show", "--name-only", "--format=", $c)
    foreach ($f in $files) {
        if ($f -ne "" -and $f -notmatch [regex]::Escape($TestPathPattern)) {
            Write-Output ("FAIL commit " + $c + " touches " + $f + " (not a test file): the red run must not carry the fix")
            exit 1
        }
    }
}

$branch = "throwaway/red-" + $Name
$wt = Join-Path $env:TEMP ("prove-red-" + $Name + "-" + [guid]::NewGuid().ToString("N").Substring(0, 8))
Git-Out @("worktree", "add", "-q", "--detach", $wt, "origin/main") | Out-Null
try {
    foreach ($c in $list) {
        & git -C $wt -c user.name=IamTheLovish -c user.email=IamTheLovish@users.noreply.github.com cherry-pick $c 2>$null | Out-Null
        if ($LASTEXITCODE -ne 0) {
            & git -C $wt cherry-pick --abort 2>$null | Out-Null
            Write-Output ("FAIL cherry-pick of " + $c + " onto origin/main conflicts")
            exit 1
        }
    }
    $sha = (& git -C $wt rev-parse HEAD).Trim()
    & git -C $wt push -q -f origin ("HEAD:refs/heads/" + $branch) 2>$null | Out-Null
    if ($LASTEXITCODE -ne 0) { Write-Output ("FAIL push of " + $branch); exit 1 }
} finally {
    & git -C $RepoPath worktree remove --force $wt 2>$null | Out-Null
}

$args2 = @("workflow", "run", "flake-stress", "-R", $GhRepo, "-f", ("ref=" + $sha), "-f", ("runners=" + $Runners))
if ($Shard -ne "") { $args2 += @("-f", ("shard=" + $Shard)); if ($Focus -ne "") { $args2 += @("-f", ("focus=" + $Focus)) } }
else { $args2 += @("-f", ("tests=" + $Tests)) }
$before = Get-Date
$url = & gh @args2 2>$null
if ($LASTEXITCODE -ne 0) { Write-Output "FAIL gh workflow run"; exit 1 }
Write-Output ("PASS red run dispatched on " + $branch + " @ " + $sha.Substring(0, 8) + " (origin/main + " + $list.Count + " test commits): " + $url)
Write-Output "NEXT read the summary job's [Stress] annotation: the test must FAIL there. If it passes, the test does not reproduce the bug."
exit 0
