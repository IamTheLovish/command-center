---
title: Overnight review - Beyond and Tabs + Command Center (Oct 26-27)
type: report
author: Command Center gen-013 (acct B)
snapshot: origin/main bbbdac21
---
# Overnight review, Oct 26-27

lovish (22:15): "use all our usage to think and process everything we have done for the game... check our code as well as our design plan... improve anything and everything... when tools could've been used and how we can make them autonomous... optimization... enhance command center... make yourself more intelligent the more sessions we work together."

Method: five read-only audits in parallel (code+security, performance, design, tools/CI, Command Center). The commander re-read the top claims of each in the code before acting. Safe fixes became PRs. Nothing is merged.

## Headline
1. **The engine is in good shape; the visible layer is the gap.** Packets are auth-checked, server-side fog is solid, targeting/pathing/bots are already grid-based. Animation, textures and buildings lag (6 art PRs stalled, 60+ units with no breathing or hit reaction).
2. **Three real security holes:** any player can type `/rts-fog disable` (a map hack) or `/bot remove`. Two different dev builds connect and silently mis-decode packets. -> PR (security), in flight.
3. **CI is red half the time on main (18 of 36 builds, Oct 23-26), nearly all from flaky tests.** The auto-rerun only works while a session watches. -> PR (CI self-heal), in flight.
4. **44 PRs are open.** #221/#222 (your first item on Oct 24) are still open. #223 and #224 (hero AI v1) merged today.
5. **Command Center rules are written but not enforced:** 59% of ledger rows had no account, no ledger exists for 10-24/25, 5 handoffs are missing, $0.41 of the $200 API credit is used. -> scripts being built tonight.

## PRs opened tonight (none merged - each needs your OK)
- #246 docs: stale facts every session reads first (NOTES.md factions, prototype JSON sheets, progress files, GeckoLib question).
- CI self-heal: BUILT, NOT PUSHED. 5 commits sit locally in D:\btc on branch claude/ci-self-heal:
  - auto-rerun of known flakes (ci-autorerun.yml + tools/flake_check.py, 13 unit tests);
  - timeouts on all 8 build.yml jobs;
  - mirror report */5 -> */15;
  - flake-stress summary fails when a test fails;
  - 2 flakes added with same-commit proof.
  GitHub refused the push: the PC's gh login lacks the `workflow` scope. To unblock, run `gh auth refresh -h github.com -s workflow` on the PC, then `cd D:\btc; git push -u origin claude/ci-self-heal`. A session can open the PR after that.
- Perf quick wins: night-source scan cache, knockback list leak, minimap 18 MB/s garbage, item-pickup query skip, population cache, plus shadow-pass and minimap timing so the next round can measure. (number pending)
- Security + state leaks: /rts-fog and /bot permissions, packet-table protocol hash, fallen heroes and temp blocks leaking between worlds, crash on attack orders at wrecks, permission walker test. (number pending)

## Findings worth acting on next (ranked, verified unless marked)
### Code and architecture
- R1 lifecycle registry: one place that resets per-match/per-world state. ~70 hand-written stop handlers, and `resetRTS` (rematch) misses several (capture points, bot brains, kills, hero progression). It stops a whole class of "state from last game" bugs.
- R2 one authority module: "who may command / see what" exists in 4+ disagreeing copies. One copy has no ally case, so allied workers walk to a building and never build (F9).
- F7 (medium confidence): attack/follow orders don't check fog. A modified client can track a unit through fog by id.
- F10: three 30-second timers each write the save synchronously on the server thread, causing a hitch mid-fight.
- R5: `drawHud` is one 1,785-line method, rebuilt every frame. Split it into panels.
- SkirmishGameTests.java is 15,357 lines that every lane edits. Split by topic.
### Performance (estimates, unmeasured)
- Biggest client cost: close-zoom unit bodies (38 ms at zoom 30) -> the instanced-units plan; quick win: lower detail zoom as armies grow.
- Shader shadow pass re-poses every unit and has never been measured (fixed in the perf PR).
- Server spikes: fog entity-tracking refresh is 16k calls every 10th tick; building sync sends ~27k packets once a second, almost all unchanged; fog re-rasterises 1,700 static buildings every fog tick; fixed timers line up on the same tick.
- Strategic zoom: one draw call per house icon. HUD selection strip rebuilt every frame.
- Unit move packets every 3 ticks (vanilla default): ~100k/s at 8v8. Measure first: nothing counts packets today.
- Hero AI hook: one hero per tick on UnitGrid/TargetScan/fog-visible queries costs about nothing.
### Design
- Animation is your stated top art priority, and a shared "life layer" (breath, weight shift, look-at, hit reaction) would lift 60+ units at once.
- Content is outrunning the art foundation: #211 (second T3, placeholder bodies) and #227 (Tier 4).
- No siege spec exists, though it is item 5 in your order; walls, #146 raids, #222 artillery and game enders need one doc.
- Multiplayer has never been tested over a real connection. Onboarding has no hero/possession step.
- The hero AI harness should reuse #133 (nightly bot ladder) instead of being built twice.
### Tools and CI
- Make the flake list data-driven (nightly scan of annotations), and fix the top flake (bots_reach_tier_2) at the root.
- A duplicate-work preflight as a command, not prose (cost 100-250k tokens twice in one night).
- A numeric art gate tool before art rounds (texture rounds r24-r26 cost ~1.5M tokens).
- Nightly perf/eyes trend instead of eyes after every merge (~20 runner-hours a week).
- A daily review digest plus a `lovish-ok` label that merges after checks (needs your OK).
- Test gaps: commands, network packets (fuzz), a fog-leak test, survival/items/worldmemory.
- Archive ~11 unreferenced tools; one repo-name helper (the slug is hard-coded in 11 files).

## Command Center: what changed and what's coming
Done tonight:
- Finished boot, applied the 5 waiting auditor items, announced 14 changes.
- BUILT, TESTED and wired into COMMANDER.md (s0, boot, s3, s4, s8). The usage card is `tools\README-cc.md`.
  - `tools\cc.ps1`: boot with an automatic gen number and digest; ledger rows with clock time, account and gen filled in; closing rows; tally; branch-check (exit 1 = hands off); context %; handoff stub and verify; digest/review-diff via the API.
  - `tools\kb.ps1`, `tools\metrics.ps1`.
  - It caught a mistake on its first night: tonight's hand-typed log times ran an hour ahead of the clock.
- The learning loop is LIVE:
  - 54 seeded entries, plus 10 learned from tonight's agents.
  - 6 hard rules in RULES.md.
  - 26 of your decisions in `knowledge\decisions.md`.
  - Baseline: 91% first-try pass, 8.8% redo.
How it works (Claude can't be retrained, so the loop is better memory plus measurement):
- **Capture**: every agent ends with a 3-line LEARN footer. `ledger-close` stores the redo cause. A nightly haiku pass turns the day's LEARN lines into candidate entries.
- **Store**: `knowledge\entries.jsonl` (lessons, recipes, anti-patterns, briefs that worked, with tags and file paths), plus `knowledge\decisions.md` (your choices, in your words).
- **Recall**: `kb.ps1 recall -Task ... -Tags ...` puts only the relevant 8 entries into each brief, instead of every session reading everything.
- **Promote and prune**: an entry becomes a rule after 3 confirmations across 2 gens. It retires if injected 5 times and it never helped. A mistake repeated twice must get a script or hook.
- **Measure**: `metrics.ps1` tracks first-try pass rate, redo rate, tokens per assignment and repeat mistakes per week. That is the evidence that sessions are getting smarter.

## Needs your decision (batched)
0. (2 minutes, unblocks CI fix) Run `gh auth refresh -h github.com -s workflow` on the PC and approve in the browser. Without it no session can push workflow changes.
1. Hero AI: should a near-death hero break a hold/attack order to flee?
2. Hero auto-spend: random picks or a fixed build order; default on or off?
3. Lock alliances at match start (as BAR does)? Right now FFA enemies can `/ally` to share a win.
4. May #211 (placeholder T3 bodies) and #227 (Tier 4) ship before the animation/body work?
5. Siege spec: what's in scope, and who writes it?
6. GeckoLib/Photon in LANES.md: retire it in favour of the game's own systems (#162)?
7. Command Center hooks: block a 3rd heavy agent and `pkill -f` automatically (a PreToolUse hook)?
8. Nightly jobs on your PC (Task Scheduler): main-red watcher, flake digest, stale-PR sweep, auditor via API, about $3-6/night from the credit. OK?
9. A `lovish-ok` label that merges a green, reviewed PR, so you approve in one place?
10. Which repo/memory folder is current: `<old-account>` or `IamTheLovish`? (bac-memory skill disagrees with the rest.)
