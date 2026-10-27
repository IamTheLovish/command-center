<#
  ci-status.ps1 - read-only GitHub Actions load for both 20-runner pools, from lovish's PC.
  Uses the public GitHub API anonymously (both repos are public): no token, no writes. Limit: 60 calls/hour per IP,
  and one call costs ~1 + active runs. Prints one line per pool plus the calls left.
  Run: powershell -NoProfile -ExecutionPolicy Bypass -File "D:\Command Center\tools\ci-status.ps1" [-Detail]
#>
param([switch]$Detail)
$h = @{ 'User-Agent'='cc-status'; 'Accept'='application/vnd.github+json' }
foreach ($r in 'IamTheLovish/beyond-and-tabs','ILovishThe/beyond-and-tabs-ci') {
  try {
    $runs = @()
    foreach ($s in 'in_progress','queued') { $runs += (Invoke-RestMethod "https://api.github.com/repos/$r/actions/runs?status=$s&per_page=50" -Headers $h).workflow_runs }
    $run = 0; $q = 0; $lines = @()
    foreach ($w in $runs) {
      $jobs = (Invoke-RestMethod "https://api.github.com/repos/$r/actions/runs/$($w.id)/jobs?per_page=100&filter=latest" -Headers $h).jobs
      $a = @($jobs | Where-Object status -eq 'in_progress').Count; $b = @($jobs | Where-Object { $_.status -in 'queued','waiting','pending' }).Count
      $run += $a; $q += $b
      if ($Detail) { $lines += "    $($w.name) [$($w.head_branch)] running=$a queued=$b" }
    }
    "$r : runs=$($runs.Count) jobs running=$run queued=$q free=$([math]::Max(0,20-$run))/20"
    $lines
  } catch { "$r : ERR $($_.Exception.Message)" }
}
"anon GitHub calls left this hour: " + (Invoke-RestMethod 'https://api.github.com/rate_limit' -Headers $h).rate.remaining
