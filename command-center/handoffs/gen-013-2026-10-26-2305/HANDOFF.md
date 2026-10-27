# Handoff - gen-013 -> gen-014
Date/time: 2026-10-26 23:05 ET. Account: B (claude.ai cloud session linked to lovish's PC). Estimated context used at handoff: ~32%. Computed ledger counts are in _stub-HANDOFF.txt next to this file.
Reason: lovish 23:05: "wrap it up and finish the analysis we will continue it tomorrow".

## Goal lovish is driving toward
1. The overnight special task (22:15): use the usage to review everything (code, design plan, tools and autonomy, optimisation, Command Center). He added at 22:18: "make yourself more intelligent the more sessions we work together".
2. Hero AI, queued for Oct 27: D:\Command Center\briefs\hero-ai-QUEUED-2026-10-27.md. Research is done: project doc claude/hero-ai-research-2026-10-26.md.

## Done this generation
- Boot finished. Advice 2238-b applied (5/5). 14 changes announced. Off-load works ($0.43/$200). OmniRoute is down because its gateway isn't running.
- 5 read-only audits done, and the commander verified their top claims in code. The report is D:\Command Center\briefs\overnight-review-2026-10-26.md (also project doc claude/overnight-review-2026-10-26.md).
- Command Center scripts built, tested and wired into COMMANDER.md (s0, boot, s3, s4, s8):
  - tools\cc.ps1, cc-lib.ps1, kb.ps1, metrics.ps1 and README-cc.md.
  - knowledge\: 64 entries, RULES.md (6 rules), decisions.md (26).
  - usage\metrics.md: baseline 91% first-try pass, 8.8% redo.
- PR #246 (docs refresh, 6 md files) is OPEN, not merged.
- Hero AI brief corrected: #224 and #223 are already merged, #221 and #222 are still open, 44 PRs are open.

## In flight at handoff
These are background agents in the gen-013 cloud session and may finish after this was written. Their ledger rows are marked "handed-off".
1. **Perf quick wins.**
   - Branch claude/perf-quick-wins, worktree D:\btp, opus xhigh.
   - Scope: NightUtils cache, knockbackIgnoreIds leak, minimap array reuse, ItemEntity query skip, population cache, UNIT_SHADOW + minimap timing.
   - Tests first, then a 10-run stress.
2. **Security + state leaks.**
   - Branch claude/security-state-fixes, worktree D:\bts, opus xhigh.
   - Scope:
     - /rts-fog and /bot permissions;
     - packet-table protocol hash;
     - clear fallenHeroes, savedTargetResources and tempBlocks at stop;
     - ClassCastException on non-living targets;
     - DEBUG checks moved after auth;
     - a command-permission walker test.
3. **Plans 011-017 + reconcile of 004-010.**
   - Plans are written to D:\Command Center\plans\, with D:\Command Center\plans\INDEX-update-2026-10-26.md.
   - 011 lifecycle registry, 012 authority module + fog-target check, 013 server tick spikes + packet counter, 014 save hitch, 015 flake root causes, 016 HUD panels, 017 strategic icon batching.

For each one:
- Check `gh pr list --head <branch>` and the folder.
- Review with architecture-deepening Mode A.
- Close the ledger row with cc.ps1.
- Upload the plans to project claude/plans/ and update INDEX.md there.

## Blocked
CI self-heal is not pushed. Its 5 commits are local in D:\btc on branch claude/ci-self-heal, because the PC's gh token lacks the `workflow` scope.
1. lovish runs `gh auth refresh -h github.com -s workflow`.
2. Then `cd D:\btc; git push -u origin claude/ci-self-heal`.
3. Open the PR. Its body is in the report and the ledger.
4. Retake the claim on #91, which was released by mistake.

## Decisions made
- Held for lovish (report questions 7-9): hooks (E4), Task Scheduler nightly jobs, the merge-authority table (E9), and lovish-ok label merges.
- Read-only snapshot worktree D:\btr at origin/main bbbdac21. Remove it when no longer needed: `git worktree remove D:\btr`.
- The classifier refused attaching the repo to the cloud container, so agents worked on the PC via Desktop Commander.

## Open questions for lovish
The report's "Needs your decision" list, items 0-10:
- 0. gh workflow scope
- 1-2. hero flee vs orders; auto-spend
- 3. lock alliances
- 4. placeholder bodies in #211/#227
- 5. siege spec scope
- 6. GeckoLib
- 7. hooks
- 8. nightly jobs
- 9. lovish-ok label
- 10. which repo/memory folder

## Repo / worktrees / branches
- D:\BeyondAndTabs-Repo: main is 149 behind; fetch first.
- D:\btr: read-only snapshot.
- D:\btd: #246.
- D:\btc: CI work, unpushed.
- D:\btp: perf.
- D:\bts: security.
- D:\BeyondAndTabs-Fix: #203, parked by gen-012.

## Known bug
`kb.ps1 learn` is not idempotent. gen-013 ran it twice on 10-26 and the second run appended 10 candidates again (likely duplicates of the first run).
1. Dedup knowledge\entries.jsonl by source and text.
2. Make learn skip rows and handoffs it has already processed (a cursor file).

## Next 3 actions (in order)
1. Boot with `cc.ps1 boot -Acct <A|B>`. Collect the 3 in-flight results, verify them and close their rows. Put the decision list to lovish. Push the CI branch once the workflow scope is granted.
2. Hero AI v2 from the research doc. PR 1 extends the merged HeroBot with OrderLock, Perception (fog filter), FightEval and DecisionLog. Tests: move not overridden, hold respected, retreat threshold, target pick, no tower chase, combo order. Get #133 reviewed for the harness.
3. Execute plans 015 (flake roots; main is red 50% of the time), then 013 (tick spikes), then 011 (lifecycle registry). Then the analysis follow-ups: a siege spec draft and the shared humanoid life-layer plan (animation is the north star's widest gap).

## Update after handoff (gen-013, 23:1x)
- Plans 011-017 DONE in D:\Command Center\plans\, with INDEX-update-2026-10-26.md (reconcile + ranked order: 015 > 012 > 011 > 017 > 013 > 014 > 016). Not yet uploaded to the project's claude/plans/; do that at boot.
  - Corrections: unit_push flake is probably fixed by #239. Main was really 17 red / 23 green / 20 cancelled. The bots T2 flake is 12 of 17 reds (site search on rough ground + 15-minute window).
- Perf PR = #247 (DRAFT, open). Security PR = #248 (DRAFT, open). Their agents were still running CI/stress at the time of writing. Verify their final reports/CI, review with Mode A, then mark them ready for lovish.
- #247 perf: FINAL. Ready for review (not draft), head 70c1dfb2. CI verified by the commander: 13 success, 2 skipped. Stress 10/10 for all 6 new tests. Items A-E done; M1/M2 (UNIT_SHADOW + minimap timing) dropped because #216/#165/#162 edit the same FrameParts lines, so redo them after those merge. Still needed: Mode A review, then lovish's OK. The claim on #91 is held until merge. The commits use the Claude identity, not IamTheLovish (AGENTS.md); check whether that matters before merge.
- #248 security: FINAL, ready for review (not draft), head cf51473e. CI checked by the commander: 13 success, 2 skipped (after one rerun of 2 unrelated failures: stress_command_queue_executor_stays_in_budget, ac2_a_guard_follows_its_ward - candidate flakes for plan 015). Stress: 10/10 on all 6 new tests. F1, F2, F3, F4, F5, F8, F20 and R3 step 1 all done; the claim is released. Merge order: #247 and #248 merge cleanly together. #228 must switch to PacketHandler.register(...) after #248 merges, or startup throws. #209 (Joisco) protocol text goes in front of the hash. Needs Mode A review, then lovish's OK. Commits use the Claude identity.
- All gen-013 background agents have now finished. Nothing is running.

## Commander's extra suggestions (offered to lovish 23:58, not yet decided)
1. Set one dated milestone, a first outside playtest (e.g. 4v4 with bots plus 2-3 friends over a real connection). Rank everything by whether it blocks that.
2. Measure before more perf work: one /rts-perf baseline at 15 min with 450+ units on main. Nothing has been measured at scale yet.
3. Weekly PR triage hour: 44 open PRs are causing conflicts (#247 lost 2 items to #216/#165/#162). Close stale ones, merge greens, cap open PRs per lane.
4. Back up D:\Command Center (scripts, knowledge, ledgers) to a private git repo with no secrets. Today it exists only on one disk.
5. A short weekly playtest by lovish with notes -> playtest-intake -> knowledge loop. Feel can't be judged by agents.
6. Commit identity: decide Claude vs IamTheLovish author before merging #246-#248.

- Codemap DONE (knowledge\codemap\, 19 areas at bbbdac21, entries C021-C039 status rule). TODO: make kb.ps1 render skip type=codemap so RULES.md stays behaviour-only, then render. Wait for the gate agent, which is editing kb.ps1. offload.ps1 breaks on a multi-line -Prompt; fix it. Kit + START-HERE: kit\, kit.zip, project doc claude/command-center-START-HERE.md. Decisions D028-D039 recorded (lovish answers 00:21).

- 00:3x: Joisco MERGED #246 + #247 at 03:20Z (no Mode A on #247; the gate flagged it). #248 is still OPEN. Gates DONE and wired into COMMANDER s0b + boot-done (selftest 38/38). Hook (tools\install-gate-hook.md) is approved by lovish (D036) but NOT installed: it was only stdin-tested, and a parallel PC session is live, so install it at next boot and test it with one harmless Agent call. Nightly-jobs agent was still running at this point.

- 00:47 lovish 'merge all green prs': MERGED #251 and #248 (#246/#247 were merged earlier by Joisco). Not merged: #136 (conflicts), 11 green DRAFTS (authors marked not ready - ask lovish), the rest have red or pending checks. #228 must switch to PacketHandler.register now that #248 is in. Main was already red before the merges (stress_command_queue_executor_stays_in_budget, run 40447858037, not on the flake list): check main CI first at boot.
- Nightly jobs installed (tools\jobs, README). main-red, flake-digest and stale-sweep are BLOCKED until lovish sets the User env var CC_GH_TOKEN (a read-only fine-grained token; README has the one-liner). auditor and ledger-tally run. auditor\advice\2026-10-26-nightly.md is unread (test run); the 03:00 run overwrites it.

- 00:5x (lovish: 'lets use it and start on some projects', 'just do it here'):
  - offload.ps1 FIXED for opus/fable: adaptive thinking fallback. Opus calls work.
  - 3 API drafts written for 0.72 USD: briefs\siege-spec-DRAFT-, hero-ai-v2-DESIGN-DRAFT-, life-layer-PLAN-DRAFT-2026-10-27.md. Review them, then upload to project claude/ and send the siege taste questions to lovish.
  - report-lint over-flags design docs: balance numbers read as perf, numbered steps read as questions. Tune it and add fixtures.
  - kb recall surfaced generic entries, not alliance-specific ones: improve path/tag scoring.
  - IN FLIGHT: 2 opus xhigh agents, claude/lock-alliances (D:\bta, ledger 223d) and claude/flake-roots (D:\btf, ledger 4304). Both commit as IamTheLovish and must run gate start/done.
  - Boot gate: nightly advice applied, boot-done PASS.
