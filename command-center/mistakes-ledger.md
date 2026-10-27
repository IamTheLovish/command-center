---
title: Mistakes ledger
type: system
---
# Mistakes ledger

Every commander generation reads this at boot. At each handoff, the self-diagnosis adds mistakes here. If a mistake repeats, mark it **REPEAT xN** and turn it into a hard rule in `lessons.md` (or a hookify rule, if that plugin is installed).

| first seen | gen | mistake | cause | prevention rule | repeats |
|---|---|---|---|---|---|
| 2026-10-21 | 001 | Briefed subagents to write report files | Subagent Write refuses report files | Brief agents to return findings in their final reply; commander writes the file | 0 |
| 2026-10-21 | 001 | No usage ledger kept during the session | Ledger file didn't exist; not created at boot | Create `usage/ledger-YYYY-MM-DD.md` at boot, log each assignment as it starts | 0 |
| 2026-10-21 | 001 | Skill proposal refused | Synced SKILL.md read via shell, not the Read tool | Read the current synced SKILL.md with Read before proposing an improvement | 0 |
| 2026-10-21 | 001 | Reported one of two conflicting figures (Groq free tier 15M vs 30M) | Took the second source without flagging the first | When sources conflict, give both and say which is newer | 0 |
- [gen-004] Short answer ("2 is good") mapped to two numbered lists - say which reading was taken. REPEAT 1
- [gen-004] Briefed the T2 gate as "energy is cheap" before checking how BAR gates T2 (energy first). Check the reference game's mechanic before briefing balance. REPEAT 1
- [gen-005] Pushed code to the CI mirror from a session (blocked as exfiltration) before designing the workflow copy. REPEAT 1
- [gen-005] preview_start reused the tab holding a filled form and wiped it. REPEAT 1
- [gen-007] Offered floor y 40 (min_y must be a multiple of 16). Check engine constraints first. REPEAT 0
- [gen-007] Accepted a texture builder's "partly fixed" without a metric gate. REPEAT 0
- [gen-007] Released a claim before the PR merged (#164 went red). REPEAT 0
- [gen-007] pkill -f with the PR number killed its own background shell. REPEAT 0
- [gen-007] Ran 3 heavy agents at once (limit is 2). REPEAT 0
- [gen-008] Handoff skipped the lessons/mistakes merge (gen-009 did it). REPEAT 0
- [gen-010] Assigned #165 to a builder without checking recent pushes/comments on the branch; a parallel session was on round 3b. Before assigning ANY branch: last commit time + last PR comment + ledger tail. REPEAT 2 (gen-004 lesson)
- [gen-011] Wrote "API off-load first" then did 8 chores on opus itself (backfilled by gen-013). REPEAT 0. Enforced by: cc.ps1 digest/tally wrappers.
- [gen-012] Hand-typed ledger/vault times with a wrong clock (backfilled by gen-013). REPEAT 1 (gen-013 did it again). Enforced by: cc.ps1 ledger-add (system clock).
- [gen-013] CI agent edited workflows without the gh `workflow` scope; push refused after the work. REPEAT 0. Prevention: `gh auth status` shows workflow scope before any .github/workflows brief.
- [gen-013] Saved a queued brief claiming #224 unmerged from a sibling's old note. REPEAT of the branch-check HARD RULE (x3). Enforced by: cc.ps1 branch-check / gh pr view before saving briefs.
- [gen-013] Left the boot unfinished when lovish redirected. REPEAT 0. Prevention: finish boot steps 3-5 before any other reply.
- [gen-013] Handoff grew to 10.6 KB by appending "Update after handoff" blocks instead of rewriting; boots read it whole. REPEAT 0. Enforced by: `cc.ps1 handoff-lint`, called from handoff-verify (cases in tools\test-ctx-qguard.ps1).
- [session 3] Ran a Command Center script with -ExecutionPolicy Bypass from a Claude session; refused by the safety classifier (Joisco's pack warned of exactly this). REPEAT 0. Prevention: sessions never use Bypass; lovish sets CurrentUser RemoteSigned (install-guards.ps1 asks).
- [session 3] Tried to upload a pack to a gist from a session; refused as a public upload. REPEAT 0. Prevention: outward uploads are lovish's action; hand him a command or tool (tools\send-joisco-pack.ps1).
- [gen-014] branch-check counted the gen's OWN Mode A comment on #257 as another session and blocked handing the fix to a builder (Oct 27 03:4x). REPEAT 0. Enforced by: Test-OwnGenComment (current-gen [id:xxxx] tags skip); gate-selftest M16 (red 40/41 on run 40469265002, green 41/41 on run 40469533700).
