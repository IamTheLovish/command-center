# Nightly jobs (D037) - tools\jobs
Windows Task Scheduler, tasks "CC <job>", run as lovish only while logged on. Every task calls launch.vbs -> run-job.ps1 -Job <name>.
| task | when | writes | model |
|---|---|---|---|
| CC main-red | every 30 min | notes\MAIN-RED.md (deleted when main is green) | haiku only if > 20 failure lines |
| CC ledger-tally | 02:00 | notes\LEDGER-TALLY.md (+ usage\metrics.*, kb learn if cursor) | haiku via kb learn |
| CC flake-digest | 02:30 | notes\FLAKES-<date>.md with a proposed known_flakes.txt diff | none |
| CC auditor | 03:00 | auditor\daily\<day>.md, auditor\advice\<day>-nightly.md (status: unread) | sonnet (api), normal call |
| CC stale-sweep | 07:00 | notes\STALE.md | none |
Also: notes\jobs\jobs.log (one line per run), notes\ALERTS.txt (failures, refusals), one ledger row per run (model "script" / "sonnet (api)").
- Pause everything: create an empty file `D:\Command Center\PAUSED` (jobs log "paused" and exit). Delete it to resume.
- Guardrails (run-job.ps1): SHA-256 of every job script, job-lib.ps1 and config.json vs hashes.json (mismatch = refuse + ALERT); static scan
  (no gh/git writes, no direct file writes); writes only under notes\, auditor\daily\, auditor\advice\, usage\; nightly model budget and
  $190 hard stop from api\spend-log.csv; per-job timeout kills the job's own PID tree; no retries.
- After you review a change to any job script, job-lib.ps1 or config.json: `powershell -NoProfile -ExecutionPolicy Bypass -File "D:\Command Center\tools\jobs\run-job.ps1" -Rehash`.
  Jobs cannot rehash themselves. Check state any time with `-Check`.
- Budget: config.json nightly_budget_usd (5), hard_stop_usd (190), claims_issue (91, the issue claim.py uses), timeouts_min per job.
- GitHub login: Task Scheduler cannot see the gh keyring login. gh jobs (main-red, flake-digest, stale-sweep) refuse with an ALERT until the
  Windows User env var CC_GH_TOKEN holds a token (best: a fine-grained read-only token: Actions, Pull requests, Issues, Contents, Metadata = read).
  run-job only hands it to those jobs as GH_TOKEN and never prints it. Set it once from PowerShell: `[Environment]::SetEnvironmentVariable('CC_GH_TOKEN','<token>','User')`.
- Install: `powershell -NoProfile -ExecutionPolicy Bypass -File "D:\Command Center\tools\jobs\install-jobs.ps1"`. Uninstall: `uninstall-jobs.ps1` (same folder). Run one now: `schtasks /Run /TN "CC main-red"`.
