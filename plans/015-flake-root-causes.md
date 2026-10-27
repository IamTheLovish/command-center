# 015 - flake root causes (bots T2 test, vanilla_path_*, mirror_images, unit_push)

- **Goal:** find and remove the causes of the GameTests that turn main red at random, by evidence from stress runs, without loosening any assertion into a guess.
- **Lane:** Lane A (CI, tests). Test files only, plus `gametest/ArenaReady.java`. No gameplay code, no bot tuning.
- **Branch:** one per fix, `claude/improve-015a-bots-t2-window`, `claude/improve-015b-pathing-arena`, `claude/improve-015c-mirror-arena` (015d is a verification only, no branch).
- **Claim:** `python3 tools/claim.py check flake gametest bots tier mirror pathing` then `python3 tools/claim.py take improve-015 --lane "Lane A" --branch claude/improve-015a-bots-t2-window --what "Flake root causes: bots T2 test, vanilla_path, mirror images (plan 015)"`. Release when the last PR merges.
- **Model / effort:** opus, xhigh (the evidence is statistical; each step ends in a decision from data, not a recipe).
- **Written against:** origin/main `bbbdac21`.
- **Drift check (run first):**
  `git fetch origin && git diff bbbdac21..origin/main --stat -- bar/src/main/java/com/solegendary/reignofnether/gametest/TierGateGameTests.java bar/src/main/java/com/solegendary/reignofnether/gametest/PathingBudgetGameTests.java bar/src/main/java/com/solegendary/reignofnether/gametest/PerfPushGameTests.java bar/src/main/java/com/solegendary/reignofnether/gametest/ArenaReady.java tools/known_flakes.txt .github/workflows/build.yml .github/workflows/flake-stress.yml`
  If any changed, STOP and report which. Also run `gh pr list --state open --json number,headRefName,title | ConvertFrom-Json` and note whether these are still open (they change what is a test bug and what is a game bug): #203 `claude/fix-extractor-footprint` (the bots' "no valid footprint over the patch"), #221 `claude/t2-pacing` (180 s research: moves every bot lab time by about a minute), #198 `claude/new-match-arena`, and the branch `claude/ci-self-heal` (auto-rerun + known-flake list; do NOT duplicate it, and do not edit `tools/known_flakes.txt` on this plan's branches: its push/vanilla_path lines only exist on that branch, main's file has just the bots line).

## Context (paths relative to `bar/src/main/java/com/solegendary/reignofnether/`)

**How red main is.** Last 60 push runs on main (Oct 23-26): 17 failure, 23 success, 20 cancelled (queue collapse, not red). The named failures of those 17 (check-run annotations, `... failed! <message>`): `bots_reach_tier_2_after_fielding_t1_units_and_not_before_minute_5` in 12 (runs 40390295545, 40390282834, 40386085495, 40371868540, 40226460747, 40226292150, 40067524235, 40067414549, 40062165059, 40041045817, 40040234054, 40030957358), `unit_push_neighbour_lookups_are_counted` 2 (40372095754, 40353770653), `vanilla_path_*` 2 (40401681056, 40353462816), `mirror_images_decoys_draw_fire_deal_nothing_and_fade` 1 (40390295545, job bar-tests (8)), `artillery_backs_out_of_its_dead_zone` 2 (40232859495, 40067524235; not in this plan, see Out of scope). Runs can show several.

**Fixes that already landed today and change the picture (verify, do not redo):** PR #239 (merge `cd37b45d`, Oct 26 12:21 PDT = 19:21 UTC; commit `0b711989` "Shard-1 flakes: per-test isolation") gave `Sys.force` per-holder holds and `Sys.lifetime` counters (`perf/Sys.java:127-142`, `:217-219`), a stone fence round the wall-detour arena (`gametest/PathingBudgetGameTests.java:193-205`, restored in `restore` at :213) and the diagnostic `ArenaReady.around(...)` appended to the chaser and detour failure messages. Both `unit_push_neighbour_lookups_are_counted` failures (main 5421b13f 15:53 UTC with 174 of 1600 lookups, main 5ba2a036 17:48 UTC with 696) are BEFORE that merge.

### A. bots_reach_tier_2_after_fielding_t1_units_and_not_before_minute_5 (`gametest/TierGateGameTests.java:404-518`, alone in `SHARD_9` of `.github/workflows/build.yml:55`)
- Window: `BOT_T2_MINUTES = 15` (:384), so the test ends at game minute 15; it needs each of the hard, medium, easy bot to have its T2 lab finished by then (`labDone`, :459-460).
- Messages seen: "medium never finished its T2 lab (research done 8:23, at 14:59)" (4 runs), "easy never finished its T2 lab (research done 10:01..14:41, at 14:59)" (6), "easy never finished the Tier 2 research (started 14:01 / 13:07)" (2). The research itself is done early; the LAB is what is late or never.
- The CI notices say why. `[T2Snap]` lines of the failing run 40390295545 (job id 121816260113, annotations): medium: `flame_sanctuary: no valid site within 32 blocks of 1615, 73, 636`, later `energy_converter_nether: no valid site within 32 blocks`; easy: `metal_extractor_dark: no valid footprint over the patch at 1524, 61, 6..`, `wind_generator_dark: no build progress for 45 s at 1594, 62, 822, cancelled`; hard: `metal_extractor: no build progress for 45 s at 1514, 78, 575`. The base sites sit at heights 61-83 on generated terrain around x+1500 (`SkirmishGameTests.soakAnyRow(level, x+1500, z, 3)` at TierGateGameTests:412, defined at SkirmishGameTests:1594 - it looks for DRY rows, not FLAT ones).
- The passing runs are close to the edge: `[T2Timing]` easy lab at 11:22, 12:20, 12:35, 11:48, 13:02, **14:36** (run 40372095754, 23 s before the cap), medium 9:49-10:44, hard 8:34-9:39 (runs 40401681056, 40395268052, 40390295545, 40386173420, 40386085495, 40377109655, 40372095754). So the easy bot's lab time has a right tail that crosses 14:59 when it loses minutes to site-search or build-progress failures.
- Hypotheses, in order: **H1** the test's wilderness bases make the bots' site search and extractor footprint fail (real matches play on a prepared flat arena, `claude/new-match-arena` shifts it to fresh ground; the open PR #203 fixes the extractor "no valid footprint" for bots and players, which is exactly this message); **H2** the 15-minute window leaves no margin once H1 costs a minute or two; **H3** the per-minute wind multiplier (`[T2Snap] ... (wind x0.59)` etc.) shifts the energy the bots can spend: compare the wind column of a failing and a passing run before believing it (in run 40390295545 all three bots saw 0.59, 1.08, 1.14, 1.34, 0.90, 1.26, 0.44, 0.49, 1.03, 0.70, 0.85, 0.88, 1.22, 1.43 per minute; if every run has the same sequence, H3 is out). Related coupling: #221 makes research 180 s, which moves every lab time later by about a minute and would turn a 30% flake into a certain failure.
- `tools/t2_gate_sim.py` is the existing pure simulation of the gate; it does not model terrain, so it cannot answer H1.

### B. vanilla_path_* (`gametest/PathingBudgetGameTests.java`)
- `vanilla_path_wall_detour_beyond_the_short_search_still_arrives` (:183-): run 40401681056 on main bbbdac21 (AFTER #239): "did not get round the wall in 420 ticks (4.54 from its spot, at x 11.53 z 8.59, nav done true; speed 0.250, moving 0.000, in water false ... ahead [1: Block{minecraft:water}[level=7] / air / below stone] [2: water level=5] [3: water level=4], near [])". The new `around()` text names it: **flowing water in the arena's pocket**, 1-3 blocks ahead of the unit at feet height, so the vanilla pathfinder (water is a malus for a land mob) ends its path ("nav done true") at the edge of the water. The fence (:193-205) only stones x/z -1 and 16 at y 2-4; `SkirmishGameTests.openGround` (:5058-5074) clears y 2-4 and turns a FallingBlock at y 5 to stone, nothing else. The arena is cut into the ground at y = -61 (`ArenaReady.java:34-45` javadoc: ocean at 63, caves and aquifers below); water from a cave or aquifer cell at y >= 5 over the pocket (or beside it at y 1 or 5) pours into the air that was just made. Whether it appears depends on the slot the batch gave the test, which is why it passes most of the time.
- `vanilla_path_melee_chaser_runs_down_a_walking_target` (:70-120): run 40353462816 (main dd262f02, before #239): chaser 4.32 apart after 306 ticks, `nav done false`, target moved 14.43 (it reached its spot), both `entity-ticking true`, at y -58. No cause in the message (the `around()` diagnostic did not exist). The `ArenaReady.pad` javadoc (:34-45) documents the likely family: arenas are ~21 blocks apart, inside a Vindicator's aggro range, so on the arena floor a neighbour test's units can crowd and knock a test's units about; and the terrain around the pocket is generated. Treat as the same family until `around()` says otherwise.

### C. mirror_images_decoys_draw_fire_deal_nothing_and_fade (`gametest/SkirmishGameTests.java:9683-`)
- Run 40390295545 (job bar-tests (8), after #239's merge time): "the decoys did not last half their lifetime: 0; last shatter: Jade Guard ... at 148, -58, 196 by inWall (eyes in Block{minecraft:gravel} at 148, -57, 196, feet at 148.50/-58.00/196.50, chunk loaded true) (tick 683)". Eyes at y -57 is template y 3, inside the cleared pocket (y 2-4), so gravel got INTO the pocket. `openGround`'s comment (:5065-5069) records the same bug from Oct 21-22 and its partial fix (only a FallingBlock directly at y 5 is stoned). Gravel/sand at y 6 or more over an air cell at y 5, or beside the pocket, is not covered. Cause not proven; the test calls `openGround` at :9687.

### D. unit_push_neighbour_lookups_are_counted (`gametest/PerfPushGameTests.java:76-100`)
Both failures predate #239 (see above) and the 174 case is the very bug #239 fixed (a shared measuring flag switched off by another test). The 696 case (43% of the 1600 lookups; threshold `UNITS*40/2 = 800`) is not obviously the same: after #239 the test holds its own `Sys.force(hold, true)`, but `Sys.begin` also returns 0 (no count) whenever `Thread.currentThread() != serverThread` or measuring is off (`perf/Sys.java:97-99`), and units that die or never tick count fewer. Treat as FIXED unless step 1 shows otherwise.

**Conventions to follow:** `gametest/ArenaReady.java` (`pad`, `whenTicking`, `around`, `describe`) is the toolbox for tests whose units move or fight: a glass pad in the sky takes the terrain and the neighbours out. Exemplars of tests that use it: grep `ArenaReady.pad(` (each caller takes its own height, 11 or more apart from the rest; pick a free one by reading ALL the callers (`git grep -n "ArenaReady.pad(" origin/main -- bar/src/main/java`; heights seen in the first 10 hits: 135, 140, 152, 164, 176, 188, 248, 260, 301) and the javadoc at :34-45). AGENTS.md "Writing GameTests": judge where units END UP with a bounded poll, never at one fixed tick; "a flake is a bug - fix it (or make its failure message diagnostic)".

**Hard rules (all apply):**
1. Tests first / red on main does not fit a flake; instead each fix needs BEFORE evidence (a stress run on main that fails or an `around()` text that names the cause) and AFTER evidence (a stress run with 0 failures at the same runner count).
2. No assertion is loosened into a guess. Moving a test onto a pad, flattening its ground or widening a window whose length was only a budget are allowed; changing what is asserted is not.
3. Client code must not leak into server code (`python3 tools/check_server_client_imports.py`). Fog of war and Oculus: not touched.
4. No file crosses 1,000 lines: `SkirmishGameTests.java` is about 15,358 lines and `TierGateGameTests.java` is 555: change `SkirmishGameTests` by net <= 0 lines (move the mirror test's setup into `ArenaReady` or a call to a helper, do not add a block), put new helpers in `ArenaReady.java` (check it stays under 1,000).
5. `python3 tools/check_java.py` 0 structural errors; `bash tools/prepush.sh` before every push.
6. Stress runs are read from the `[Stress]` annotation, not the job colour (commands in each step).
7. Commit by explicit path, identity `git -c user.name=IamTheLovish -c user.email=IamTheLovish@users.noreply.github.com commit`, trailers as given; never push `main`, never force push.

## Steps

### Step 1 - baseline on main (no code, about 40 CI minutes of runners; do it first)
```
gh workflow run flake-stress.yml --repo IamTheLovish/Beyond-and-Tabs -f ref=main -f shard=9 -f runners=10 -f focus=bots_reach_tier_2
gh workflow run flake-stress.yml --repo IamTheLovish/Beyond-and-Tabs -f ref=main -f shard=1 -f runners=6 -f focus=vanilla_path,unit_push
gh workflow run flake-stress.yml --repo IamTheLovish/Beyond-and-Tabs -f ref=main -f shard=8 -f runners=6 -f focus=mirror_images
```
(`shard=` repeats a whole CI shard so a test keeps its batch neighbours; `tests=test:<name>` runs it alone, where the neighbour flakes cannot show.) Read each: `gh run list --workflow flake-stress.yml --limit 3 --json databaseId,status`; then `gh run view <id> --json jobs --jq '.jobs[]|select(.name=="summary")|.databaseId'` and `gh api repos/IamTheLovish/Beyond-and-Tabs/check-runs/<jobid>/annotations --jq '.[].message'`. For the failing samples pull the `around()` / `[T2Snap]` text from that sample's job annotations the same way.
Write the numbers into the PR bodies: failures per test of N. Decide per test with this table:
- 0 failures in all: the cause is rare or fixed; say so, change nothing for that test, go to the next.
- bots >= 2 of 10: continue with step 2.
- vanilla_path wall-detour fails and `around()` shows water: step 3. Chaser fails: read its `around()` text and put the finding in the PR (water, neighbour units, block ahead, or nothing).
- mirror fails: step 4.
- unit_push 0 of 6: it is FIXED by #239; write one line in the final report, nothing else.
GATE 1: three `[Stress]` annotations quoted (runners, failures per test) in the first PR.

### Step 2 - bots test (PR 015a). Only after #203 and #221 are merged or closed (check at drift time; if either is open and the baseline of step 1 is not 0, wait for lovish's word: report both numbers and stop)
2a. Diagnose, no behaviour change: in `TierGateGameTests` log once per base at the start `[T2Terrain] <name> height range <min>..<max> over 96x96, wet columns <n>` (use `level.getHeight(Heightmap.Types.MOTION_BLOCKING_NO_LEAVES, x, z)` on a 12-block grid; no new dependency). Dispatch step 1's bots command on that branch (ref = the branch). Compare `[T2Terrain]` of failing and passing samples, and the `[T2Snap]` wind column of one failing and one passing sample.
2b. Pick the fix by what 2a shows, one of:
 - Rough ground separates failing from passing samples (H1): build the bases on flat ground. Before `startRTSBot`, for each start build a plateau of 100x100 at the start's height (stone 3 deep, grass top, 24 blocks of air above, water replaced), as a helper `ArenaReady.flatBase(level, centre, radius)`, restore NOT needed (x+1500 is the test's own far ground, as today). Same assertions, same 15 minutes.
 - Ground is the same in failing and passing samples but the easy lab time spreads over 11:20-14:40 (H2): then the budget is the problem: raise `BOT_T2_MINUTES` to 20 (it only feeds `BOT_T2_TICKS` and the timeout), and keep every assertion. State the new margin from 10 samples: the slowest lab time must end at least 3 minutes before the cap.
 - The wind sequence differs between failing and passing samples (H3): STOP, report with both sequences; this is a game-design question for lovish (the bots' energy plan under calm wind), not a test fix.
GATE 2: after the fix, step 1's bots command on the PR branch: `10 runners; 0 with any failure` and `bots_reach_tier_2_after_fielding_t1_units_and_not_before_minute_5: failed 0, passed 10`. If not 0, do NOT merge: report the new messages.

### Step 3 - pathing arenas (PR 015b)
3a. `ArenaReady.sealed(helper)`: after `openGround`, put stone on the whole lid (template y 5 over x/z 0..15, not only a FallingBlock) and make a fluid scan of the pocket x/z -1..16, y 1..5: any fluid block becomes stone (y 1 and 5) or air (y 2-4, inside), counting how many were found; return the count.
3b. Use it in the two `vanilla_path_*` tests that stay on the arena floor (detour and chaser) right after `openGround`, and append `fluid cells removed: <n>` to the failure text.
3c. If step 1's chaser failure showed neighbour units or terrain (not water): instead move the chaser and shooter tests onto `ArenaReady.pad(helper, <free height>)` and offset their coordinates by the pad's return value (the pad is already air above and glass below).
GATE 3: step 1's shard=1 command on the branch: `vanilla_path_...: failed 0, passed 6` for all three tests; and a unit run of the fluid scan: a GameTest `sealed_arena_has_no_fluid_after_openGround` that places a water source at y 5 over the pocket's middle, calls openGround + sealed, ticks 20 and asserts no fluid in the pocket (RED on main because `sealed` does not exist; GREEN after).

### Step 4 - mirror images (PR 015c)
4a. Diagnose first, 6 samples of `-f shard=8`: on failure append to the message the block column at the shatter x/z from y -61 to -50 and the count of `FallingBlockEntity` within 8 blocks.
4b. If a fall from above is shown: use `ArenaReady.sealed` (step 3a) in the mirror test; if the gravel is not from above: use `ArenaReady.pad`. Net change in `SkirmishGameTests.java` <= 0.
GATE 4: `mirror_images_decoys_draw_fire_deal_nothing_and_fade: failed 0, passed 6` (shard 8, 6 runners).

## Out of scope
`artillery_backs_out_of_its_dead_zone` (two failures, "never hit the target (moved at most 4.6) 8.6 blocks away (dead zone 8.0)... nav done true, path none": probably a game-or-test question on the artillery's set-up time, which the open PR `claude/artillery-nerf` #222 changes; list it in the report as the next candidate); `tools/known_flakes.txt` and the auto-rerun (the `claude/ci-self-heal` branch); bot AI, tier gate numbers, pathfinding code; changing the shard layout.

## STOP conditions
- Drift check shows changes; #203 or #221 open at step 2 with a non-zero baseline.
- Step 1 shows a different test failing in the stress runs (not on this list): report it by name with its message; do not fix it in this plan.
- A fix makes another test in the same shard fail (`gh run view` of the PR's CI): revert that step, report.
- Wind (H3) or a game bug is the cause: report, do not change game code.

## Done criteria
- Per test, one of: fixed with 0 failures of N in a stress run at the same shard/runner count as the baseline; or shown already fixed (push); or reported as a game-design question with the evidence.
- No assertion changed except the window length (015a option 2) with its margin stated.
- `SkirmishGameTests.java` not longer than before.

## PR body template (one per PR)
```
## What
<the test, the root cause in one sentence, the fix>

## Evidence
- Before (main bbbdac21): flake-stress run <id>: [Stress] "<runners>; <n> with any failure", "<test>: failed X, passed Y"; the failing message / around() text: <paste>
- After (this branch): flake-stress run <id>: "<test>: failed 0, passed N"
  read with: gh run view <id> --json jobs --jq '.jobs[]|select(.name=="summary")|.databaseId'
  then: gh api repos/IamTheLovish/Beyond-and-Tabs/check-runs/<jobid>/annotations --jq '.[].message'

## Numbers for lovish / questions
- <only if a game question came up, e.g. wind under calm spells>

Do not merge without lovish's OK
```

## Return format (max 250 words)
Per test: baseline failures of N, cause (proven / hypothesis), PR number, after failures of N. Then the list of tests still flaky. Nothing else.
