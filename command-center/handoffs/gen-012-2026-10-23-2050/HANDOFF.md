# Handoff - gen-012 → gen-013
Date/time: 2026-10-23 20:50 ET · Account: B (Claude Code on lovish's PC, API credit) · Estimated context used at handoff: ~20%

## Goal lovish is driving toward
"let claude code do everything" (Oct 23 04:31). The brief was D:\Command Center\briefs\cc-perf-2026-10-23.md (the four late-game lag fixes). Then (~16:40): "keep working on the tasks until you run out of the $200 you dont need me to constantly check your work". North star: D:\Command Center\references\north-star-2026-10-21.md (animation is the widest gap).

## Done this generation (all merged on main, logged on #150)
- #174: main red since 04:37 -> green (T2 bot dry-base scan, ruff, plan 008 JUnit core). Mode A pass.
- #208: server log spam. 1 stack trace per dropped connection instead of 78,376 in 30 s.
- #212: eyes overlays (scene 18) samples crowd zoom 60 and reports buildingDecor/worldMarkers (it couldn't measure #202 before).
- #213: known_flakes adds bots_reach_tier_2 and artillery_fires_over_a_wall (each failed and passed on the same commit).
- #215: bots no longer re-lay an extractor site their workers can't reach (BotSiteWatch matched patches by 3D distance from a raised site's centre). Root of the T2 flake; stress 0/5 vs main 1/5.
- #207 (item 4): unit vanilla push via UnitGrid, each entity's own doPush kept (TitanMass etc.). Saving NOT measured (~2-3 ms/tick at 450 units, extrapolated).
- #202 (items 1+3, part of 2): eyes with shaders, 505 units: crowd zoom 60 unitBodies 22.29 -> 1.20 ms (icons +2.28), buildingDecor 2.08 -> 0.00, worldMarkers 3.73 -> 2.22; zoom 30 unchanged.
- #214 (item 2): worldMarkers crowd zoom 2.22 -> 1.42 ms, close 3.53 -> 2.65 ms. Target < 1 ms NOT met.
- PC toolchain: Python 3.12 (+ python3.exe copy), JDK 17 Temurin, ruff 0.16.9; gh uses GH_TOKEN from Git Credential Manager (helper: the scratchpad env.sh pattern, never echo it); D:\tmp created for merge_pr.py.
- Report: D:\Command Center\briefs\cc-perf-2026-10-23-REPORT.md (its summary row for item 2 still says "batching PR in progress": an edit was refused at 20:50, so fix it to the #214 numbers above). Ledger lines in usage\ledger-2026-10-23.md; the gen-012 lines stamped 21:00-22:00 had a wrong clock (see the 20:50 correction line).
- Vault inbox: 20261023-1825-benchmark-must-sample-where-the-change-acts.md, 20261023-2200-flake-that-moves-with-the-test-count.md (the filename's time is the same clock error; it was written ~20:30).

## In flight
- Nothing running. All worktrees removed except D:\BeyondAndTabs-Fix (branch claude/fix-extractor-footprint, PR #203, parked).
- #203 (draft, claim fix-extractor-footprint until 2026-10-24T08:00Z): metal patches near water refuse extractors (ground_not_flat, players too). MetalPatches.stamp ~209-275 left wet pads. Fixes cut refusals from 8/48 to 1-5 per map; the head commit raises an island in open water, which needs lovish's OK. Next step: log the stamp branch and fluids around a refused patch.

## Decisions made
- lovish 16:35: "auto merge whatever is needed for the next five hours" (window ends ~21:35 ET Oct 23). Merges still went through green CI + Mode A. After 21:35, ask again before merging.
- Commander (gen-012): continued #202 and #203 as the successor of the earlier PC session that opened them; took item 4 without target selection (#119 owns it); held #203's island fallback for lovish.
- The auto-mode classifier refused (a) closing another session's PR (#199) and (b) a report edit at 20:50 ("Merge Without Review"). Neither was worked around.

## Open questions for lovish
1. #203: OK to raise a small dry pad in open water where a metal patch has no dry ground, or should the patch move further away?
2. #199 is superseded by #174. Close it (permission refused to close another session's PR).
3. Merging after 21:35 ET: may sessions keep merging green + Mode A PRs while working through the credit?

## Repo / worktree / branch
D:\BeyondAndTabs-Repo on main (294cd47 or later; fetch). Its fetch refspec covers only main, so use `git ls-remote` to see other branches. Run prepush's check_java in batches: `git ls-files 'bar/src/main/java/*.java' 'mod/src/main/java/*.java' 'engine/src/*.java' | xargs -n 400 python3 tools/check_java.py`. `animation lab data` fails on this PC on main too.

## Next 3 actions (in order)
1. Fix the report's item 2 row (see above) and ask lovish questions 1-3.
2. Item 2 remainder: split FrameParts MARKERS_RANGE further (markersRange ~0.8 ms with cheap loops) and find the cost; eyes overlays shaders run for before/after (plain lane crashes: Oculus wants Sodium, PR #135).
3. Measure #207's saving: a server profile at ~450 units (PerfAuto / [Sys]) on main vs before fb82fade. Then the north star's animation work (check Joisco's #194 vs #162 before touching effects).
