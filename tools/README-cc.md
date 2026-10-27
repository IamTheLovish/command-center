# cc tools - usage card
Run: `powershell -NoProfile -ExecutionPolicy Bypass -File "D:\Command Center\tools\cc.ps1" <cmd> ...` (every script takes `-Root`, default D:\Command Center). Time is America/New_York from the system clock; acct and gen come from `usage\state.json`.

| cmd | what it does |
|---|---|
| `boot -Acct A\|B [-DryRun]` | next gen = max(handoff folders, ledger gens, state) + 1 under `usage\.cc.lock`; writes state.json; prints a 40-line digest |
| `ledger-add -Assignment -Model -Effort -Tier [-Owns] [-Kb ids]` | appends a running row to today's ledger, prints the 4-hex id (also stored as `[id:xxxx]` in the note) |
| `ledger-close -Id -Result pass\|redo\|escalated [-Tokens] [-Note] [-Cause c] [-Learn "worked: / failed: / rule:"]` | rewrites that row in place |
| `tally [-Date yyyy-MM-dd\|all]` | per-model rows/pass/redo/esc/running/tokens |
| `branch-check -Pr N \| -Branch b` | gh + ledger; exit 1 BLOCKED (touched <2h or boot-row owner), exit 2 UNKNOWN (gh failed) |
| `ctx [-Window 200000]` | context % of the newest Claude Code session |
| `handoff-stub` / `handoff-verify` | create gen folder from templates with computed counts; PASS only when no TODO, no running rows, mistakes-ledger touched |
| `advice-done <file>` | advice status -> applied gen-NNN, adds an Unannounced line |
| `digest <path\|glob> [-Q q]`, `review-diff -Pr N` | haiku / sonnet via api\offload.ps1, each logs its own ledger row with cost |

Knowledge loop (`tools\kb.ps1`, store in `knowledge\`):
- `seed` converts lessons.md + mistakes-ledger.md into entries.jsonl (idempotent).
- `recall -Task "..." [-Tags a,b] [-Paths p] [-Top 8]` prints at most 25 lines; paste the ids into `ledger-add -Kb`.
- `credit -Id <ledger id>` after the row is closed: injected++, helped++ and confirmations++ on pass, hurt++ on redo; candidate -> rule at confirmations >= 3; rule retired to archive.jsonl at injected >= 5 and helped 0. Each row is credited once.
- `render` writes RULES.md (rules only, <= 40 lines) and by-tag\*.md. `learn [-Date] [-DryRun]` asks haiku for candidate entries from `-Learn` text and new handoffs; drops entries whose quote is not in the input.
- `metrics.ps1` writes usage\metrics.csv and metrics.md from all ledgers.

Gates (gen-013 mistakes, Oct 26-27; `gate-lib.ps1`, no model calls, ~1-3 s, one gh call per data type, 10 min cache of the open-PR list and `gh auth status` in `%TEMP%\cc-gate-cache.json`; PR views are always live). Output = one line per check (PASS/WARN/FAIL + reason) and a `GATE ...` verdict line; exit 0 or 1; each run adds a ledger row (`-NoLog` to skip); `-Verbose` shows detail lines.
- `gate start -Task "..." [-Pr N] [-Branch b] [-Files f1,f2] [-EditsWorkflows] [-Heavy] [-NewPr] [-AllowOverlap "reason"] [-Override "lovish quote"]` (= `preflight`): boot_complete, live PR state (OPEN/MERGED + date), branch-check, open-PR file overlap, `workflow` token scope, heavy cap, PR pile-up (WARN >20, FAIL >40 or no PR triage row today), overlapping plans in `plans\`, and it prints the exact commit identity from AGENTS.md. Run it before every assignment.
- `gate done -Pr N [-Report file]` (= `accept` + `report-lint`): CI green and complete; new `@GameTest` needs stress evidence; `reviews\pr-N-modeA.md` with `VERDICT: PASS`, `REVIEWER: name [id:xxxx]`, `SHA: <head sha>` written after the head commit and by someone other than the builder (ledger row `owns: #N`); every commit authored as the AGENTS.md identity; PR body "Do not merge without lovish's OK". Writes `evidence\pr-N.json`. Run it before telling lovish anything is done or ready.
- `report-lint <file>`: flags verified/measured/fixed/confirmed/tested/done with no evidence in the same bullet (a PR number counts only if `evidence\pr-N.json` is PASS for the PR's current head), unlabelled perf numbers (a heading or bullet saying "estimate" suppresses; the suppressed count is printed), more than 5 numbered questions. Known gaps: quotes, `code` and short "Done tonight:" lead-in lines are skipped; the heading label suppresses every number under it.
- `ledger-lint [-Date d]`: rows without `[id:]` (hand-typed), times after the file's mtime or out of order, acct/gen `?`, rows running after 12 h.
- `boot` now writes `boot_complete=false`; `boot-done [-Force]` sets it true only when no advice is unread and nothing is left under Unannounced. `preflight` FAILs while it is false.
- `gate-selftest [-Verbose]`: replays every real mistake against `tools\gate-fixtures\` with stubbed gh data (offline, seconds) and prints `n/n caught`. Any change to gate-lib.ps1, gate-selftest.ps1 or cc.ps1 must keep it at n/n.
- RULE: every new mistakes-ledger entry needs a new fixture case in `gate-selftest.ps1` (and fixture data in `gate-fixtures\` if it needs gh data) before the entry can be closed, so the gate grows with each mistake.
- Hook (not installed): `install-gate-hook.md` + `gate-hook.ps1`.
- kb: `kb.ps1 learn` keeps `knowledge\learn-cursor.json` (processed ledger rows and handoff folders) and never re-sends them; `kb.ps1 learn-mark -Date d` seeds it; `kb.ps1 dedup [-Near] [-DryRun]` backs up to `entries.backup-<date>.jsonl`, merges same normalized text + source (counters summed, oldest id kept) and archives the rest with reason `dedup`; `-Near` also merges learned `C###` candidates with word overlap >= 0.5.

Session loop: `boot` -> `kb recall` -> `ledger-add -Kb ids` -> work -> `ledger-close -Learn "..."` -> `kb credit` -> `handoff-stub` -> fill TODOs -> `handoff-verify` -> `kb learn` + `kb render`.
Rules: ASCII only, PowerShell 5.1 (no `?:`, `??`, `&&`, `||`); never stop processes by image name; the API key is read only inside api\offload.ps1.

Added Oct 27 (session 3, D040-D042):
- `ctx [-Session id] [-CtxDir d]` reads the REAL context % that `statusline-ctx.ps1` writes per session (lists every session updated in the last 12 h without -Session); the old transcript estimate is only the fallback.
- `handoff-lint <HANDOFF.md>`: <= 10 KB, exactly one `## RESUME HERE`, no "Update after handoff" blocks, a "Dead ends / ruled out" section. handoff-verify runs it.
- `question-guard.ps1` (Stop hook): blocks once when a reply ends in a typed question. Off switch: `%LOCALAPPDATA%\CommandCenter\hooks-off\question-guard`.
- `install-guards.ps1` (lovish runs): tests first (`test-ctx-qguard.ps1`, gate-selftest), then statusline + question-guard + gate hook into `%USERPROFILE%\.claude\settings.json` with a backup; `-Uninstall` removes them. Asks before setting CurrentUser RemoteSigned.
- GitHub merge gate: `guards\github\` (required `mode-a` status from a review comment for the head sha; lovish switches it on).
- Session chain: `usage\sessions.md` + `command-center\NEXT-SESSION-PROMPT.md` (command-center skill, "Session chain").
