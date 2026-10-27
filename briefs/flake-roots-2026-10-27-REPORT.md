# Flake roots - report (2026-10-27)

Branch `claude/flake-roots` (worktree `D:\btf`), draft PR **#273** to main. Do not merge without lovish's OK.
origin/main d9fac5c6 merged in (73caa247). Every "fixed"/"verified" below has its run id. Flake-stress numbers are read
from the summary job's `[Stress]` annotation, not the job colour.

## Per target

### 1. `elder_druid_is_a_t2_worker` - STALE TEST CLAIM, NOT A PRODUCT BUG

- **Cause:** 66d0fdb3 (PR #253, "Remove builder and engineer abilities in all factions", Joisco's tester decision of
  2026-10-26) deleted the Elder Druid's `getAbilities`/`updateAbilityButtons` override on purpose and added
  `ac1_builders_and_engineers_have_no_abilities`, which names `ELDER_DRUID_UNIT` and asserts an EMPTY ability list.
  main then held two tests asserting opposite things; #253 trimmed the other mixed tests but missed this one. #253's own
  PR run 40452094789 was already red on it, and it was merged anyway.
- **Fix:** d434386c - the test asserts the current design (no ability of its own, the ability names in the message if
  one comes back). Every other check is unchanged (T2 worker, build power, health, faction, T3 lab, treant helper).
- **Proof:** PR run 40469588386 job `bar` green; shard-1 flake-stress 40469592779 **0 of 10 failed**, 40472451498
  **0 of 10 failed**.
- **For lovish:** the design change is Joisco's decision in #253, not a line in `design/LANES.md`. If the Elder Druid
  should keep Awaken Thicket, revert the ElderDruidUnit part of 66d0fdb3 and take the Elder Druid out of ac1 instead.

### 2. `the_snapshot_of_unloaded_chunks_loads_them_without_blocking_a_tick` - PRODUCT BUG, FIXED (test first)

- **Cause (read from the 1.20.1 bytecode):** a chunk loaded at ticket level 33 (FULL, not ticking - the capture's own
  ticket) keeps the block entities its features placed as pending `DUMMY` tags (`WorldGenRegion.setBlock`). Vanilla
  creates them on the first `getBlockEntity` of the position: its background save (`ChunkMap.processUnloads ->
  saveChunkIfNeeded -> ChunkSerializer.write -> LevelChunk.getBlockEntityNbtForSaving -> getBlockEntity`) or
  `postProcessGeneration` when the chunk turns ticking. The chunk packet lists only `LevelChunk.getBlockEntities()`. So a
  snapshot built before that save lacked them and the reference taken later had them: every red says `block entities
  (file only [], reference only [...])`, `file != live, reference = live`.
- **Test first:** 30656a7a, new class `FogSnapshotBlockEntityGameTests`,
  `the_snapshot_lists_block_entities_vanilla_has_not_created_yet` (a chest left in exactly that pending state, captured
  on the spot in the same tick so no save can come between). Red locally on 30656a7a: `does not list the chest at 5,
  -58, 5 whose block entity was still pending (listed: [0, -60, 0 minecraft:structure_block])`.
- **Fix:** f435354f - `FogChunkSnapshot.captureNow` creates the chunk's pending block entities before building the packet,
  as that save would. 220a6b47 adds the longest chunk build and the count created to the capture's log line.
- **Before:** main 40456368179; shard-1 stress 2 of 10 (40453430261), 1 of 10 (40452699161), all the block-entity
  mismatch.
- **After:** shard-1 stress 40469592779 0 of 10; 40472451498 1 of 10, a DIFFERENT failure: `a capture step took 63.6 ms
  (limit 50.0)`, see "Open" below. The new test 10 of 10 in both.

### 3. `stress_command_queue_executor_stays_in_budget` - f04a443b (previous session), verified as far as stress can

- **Cause:** main red 40447858037, `15 of 24 after 6375 ticks, no progress since tick 5175`, nine seconds after its batch
  began. About 35 progress lines a second in that window (one every 20 ticks), so ~700 ticks/s: the server was catching
  up, and the test's tick-counted "60 s" stall was ~1.7 s of wall time. f04a443b waits in wall-clock time like the other
  far-chunk tests.
- **Proof:** shard-1 stress 40453430261 (f04a443b), 40469592779 and 40472451498 (this branch): **0 of 10 failed** each.
  Caveat: main's shard-1 stress 40452699161 was also 10 of 10, so stress does not reproduce the slow-worldgen condition;
  the proof is the mechanism in the log, not a before/after rate.

### 4. `bots_reach_tier_2_after_fielding_t1_units_and_not_before_minute_5` - NOT CHANGED: plan 015's STOP applies

- Plan 015 step 2 runs only after #203 (extractor footprint) and #221 (T2 pacing) are merged or closed, and says to wait
  for lovish's word if either is open and the baseline is not 0. Both are open; main flake-stress 40452701845 is 2 of 10.
- **Evidence for lovish:** in both failing medium samples (main CI 40456368179 and stress 40452701845) the piglin medium
  bot never places its Hoglin Stables, the Flame Sanctuary's T1 requirement (`TierGate.t1LabFor`): `[T2Snap] ...
  t1req 0/0` all game, `blk hoglin_stables: no valid site within 32 blocks of ...` from minute 7 to 14, pool past 7000
  metal, `t2lab 0/0`. That is site search on the test's generated ground (plan 015's H1), not the 15-minute window. The
  wind column is identical in every sample (H3 out). The other red in 40452701845 is setup: `no dry ground for three
  bot bases near x=1508 (8 lines x 16 steps tried)`. PR runs 40469588386 and the b59a9654 run were red on this test too.

### 5. `ac2_a_guard_follows_its_ward_to_the_next_site_and_helps_there` - diagnosis in, cause NOT proven

- Reds: main 40441586228; shard-1 stress 3 of 10 (40453430261), 1 of 10 (40452699161). Always `B never helped A on the
  first site: guarding false`, A and B idle on their spawn cells with no target.
- In the 40453430261 sample the batch started 05:23:53 and failed 05:23:55: its 370 ticks ran in about 2 s, the server
  catching up. A worker drops a site it gets no closer to after 300 game ticks (`BuildRepairGoal.GIVE_UP_TICKS`). That
  fits, but is not proven.
- Diagnosis: e1b06322 (the reviewed uncommitted edit: when B's guard ended, B's order then, ticking state) and b59a9654
  (when A took and left site 1, ticks against wall-clock ms). No reproduction since: 0 of 10 in 40469592779, 40472451498.

## Open

- **Long capture steps after f435354f:** 2 of 20 samples (43.5 ms in 40469592779, 63.6 ms in 40472451498, the second over
  the 50 ms limit) against at most 3.3 ms in the 20 samples before (40453430261, 40452699161). The "before" runs predate
  main's #252-#262 merges, so this does not isolate my change; no GC pause of 50 ms or more was logged near the long
  step; creating a pending block entity is a few object allocations. 220a6b47 logs the longest chunk build so the next
  long step can be attributed.

## New flakes / problems seen (not mine)

- `bar-tests (5)` of PR run 40469588386 (job 122075675704) crashed in mod loading: `NullPointerException ...
  ResourceCostConfigEntry.getWood() is null` in COMMON_SETUP; no test ran, the same jar started on the other 8 shards.
- `the_budgeted_snapshot_equals_the_one_tick_capture` 1 of 10 in 40469592779 (`heightmaps of [22, 52]; file != live,
  reference != live`), 1 of 10 in 40472451498 (light of [22, 52] and neighbours), 1 of 10 on main 40452699161 (light).
  It runs right after `stress_8v8` in the same area. File is `FogSnapshotGameTests.java` (Joisco's #272), not touched.
- `vanilla_path_melee_chaser_runs_down_a_walking_target` 1 of 10 in 40469592779: `around()` shows the chaser under
  `effect.minecraft.slowness 1` (chaser speed 0.175 vs runner at 60% of base) - a lead for plan 015 B.
- `stress_target_scans_idle_standoff_and_a_brawl` 1 of 10 in 40469592779: `3 of 300 standoff units picked a target`.
- `capture_bounded_when_barrier_hangs` 5 of 10 (40469592779), 4 of 10 (40472451498); `ac1_shift_queued_...` 1 of 10
  (40472451498). Both are Joisco's #272.
- `tools/check_shards.py` fails on main: `SHARD_8: entry 'test:men' names no test` (#253 deleted the mending tests).
  Needs a `.github/workflows/build.yml` edit, which this session may not make.
