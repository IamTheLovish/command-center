# 013 - server tick spikes (fog tracking refresh, building sync, aligned timers)

- **Goal:** remove the every-10/20-tick server spikes of a late 450+ unit match by counting first, then sending only what changed and putting the periodic timers on different ticks.
- **Lane:** Lane A (performance). Post on issue #35 before editing `fogofwar/FogOfWarServerEvents.java` (fog is shared with Lane C).
- **Branch:** `claude/improve-013-server-tick-spikes`
- **Claim:** `python3 tools/claim.py check server tick spikes fog building sync` then `python3 tools/claim.py take improve-013 --lane "Lane A" --branch claude/improve-013-server-tick-spikes --what "Server tick spikes: net counters, building sync deltas, fog refresh spread, timer phases (plan 013)"`. Release when the last PR merges.
- **Model / effort:** opus, xhigh (touches fog of war visibility latency and tick timing).
- **Written against:** origin/main `bbbdac21`.
- **Drift check (run first):**
  `git fetch origin && git diff bbbdac21..origin/main --stat -- bar/src/main/java/com/solegendary/reignofnether/fogofwar/FogOfWarServerEvents.java bar/src/main/java/com/solegendary/reignofnether/building/BuildingServerEvents.java bar/src/main/java/com/solegendary/reignofnether/building/BuildingClientboundPacket.java bar/src/main/java/com/solegendary/reignofnether/unit/UnitServerEvents.java bar/src/main/java/com/solegendary/reignofnether/unit/UnitSyncBatcher.java bar/src/main/java/com/solegendary/reignofnether/perf bar/src/main/java/com/solegendary/reignofnether/mixin/fogofwar`
  If any changed, STOP and report which. (Open perf PR #247 `claude/perf-quick-wins` edits `UnitServerEvents.java` (queue population) and `UnitClientEvents.java`; it must not touch lines 100-112 or 250-265. If it does, STOP.) Plan 014 (save hitch) touches `UnitServerEvents.java:265-270` and `BuildingServerEvents.java:185-200`: do not do both at once.

## Context (paths relative to `bar/src/main/java/com/solegendary/reignofnether/`)

Verified on bbbdac21. Numbers below the "audit" label are from the Oct 26 overnight audit and are NOT yet measured by us: step 1 produces the real ones.

**Spike A - fog entity-tracking refresh.** `fogofwar/FogOfWarServerEvents.java:513-520` (`worldTick`): every `UPDATE_TICKS = 10` ticks (line 110) it calls `updatePlayerBrightChunks()` then `refreshEntityTracking()`. `refreshEntityTracking` (lines 755-769):
```java
for (LivingEntity le : UnitServerEvents.getAllUnits()) {
    if (le.level() != serverLevel) continue;
    Object te = tracked.get(le.getId());
    if (te instanceof ...TrackedEntityInvoker inv)
        inv.reignofnether$updatePlayers(fogged);
}
```
i.e. every unit x every fogged player, in one tick, every 10 ticks (audit: ~16k `updatePlayers` calls at 450 units x 8 players; calls per second = units x players x 2). Why it exists (javadoc 749-754): vanilla re-decides tracking only when an entity or player changes chunk section, so a still enemy would not appear when a friendly walks up. `applyVision` (lines 684-747) already computes whether a player's vision changed: `prevSent == null || !prevSent.equals(sent) || !masksEqual(prevEdge, edge)` at line 735.

**Spike B - building sync.** `building/BuildingServerEvents.java:1037-1044`: every `BUILDING_SYNC_TICKS_MAX = 20` ticks (line 144) every building calls `BuildingClientboundPacket.syncBuilding(originPos, blocksPlaced, partialBlocksDestroyed, ownerName, scenarioRoleIndex, mergeEnabled, MergedBuildings.SERVER.anchorOf(building))`, which goes through `sendFiltered` (`building/BuildingClientboundPacket.java:54-63`): `findBuilding` once per call, then for EVERY online player `FogOfWarServerEvents.canPlayerSeeBuilding` and one `PacketHandler.INSTANCE.send` each. Audit: ~27k packets per second at 1,700 buildings, most carrying unchanged values. The unit equivalent was already fixed: `unit/UnitSyncBatcher.java` (header comment lines 25-60: one packet per player per sync, delta against a per-player snapshot, a full refresh every N syncs staggered by unit id, snapshots dropped when a player starts/stops tracking).

**Spike C - aligned timers.** All of these start with their counter at its maximum and so fire on the same ticks: `unit/UnitServerEvents.java:108` (`UNIT_SYNC_TICKS_MAX = 20`, counter line 109) and `:257` (`getTickCount() % 20 == 0`, the chunk loader), `building/BuildingServerEvents.java:144` (20) and `:1099` (`% 10`), `fogofwar/FogOfWarServerEvents.java:110` (10), `building/Blueprints.java:65` (`SWEEP_TICKS = 10`), `building/BuildingReclaim.java:45` (`STEP_TICKS = 10`), `building/FactionAuraServerEvents.java:52` (`PASS_TICKS = 10`), `building/StewardServerEvents.java:35` (`PERIOD_TICKS = 20`), `hero/PossessionServer.java:862` (`% 10`), `ability/abilities/AwakenThicket.java:174` (`% 20`), `attackwarnings/AttackWarningServerEvents.java:19` (10). Per-entity `le.tickCount % 20` timers (BotGameEnders, Heat, MachineRepair, FactionHero) are NOT aligned (they depend on each entity's age): leave them.

**Measuring tools that exist:** `perf/Sys.java` (server sections, `[Sys]` line every 10 s while the server is slow, in a lag capture or `/rts-perf`; each section reports self ms, worst tick and calls per tick; new section ids go at the end of the list, `SECTIONS` at line 63 and `NAMES` at 65-69 must be extended together), `perf/SysReport.java` (pure line formatter, JUnit-tested by `bar/src/test/java/.../perf/SysTimerTest.java`), `perf/ServerTickProfile.java` (`/rts-perf <seconds>`, op only, p50/p95/max). The load test: `gametest/SkirmishGameTests.java:2323` `stress_8v8_server_systems_stay_in_budget` (batch `stress_8v8`, 8 owners; it does not register buildings and has no players, so it exercises neither building sync nor fog). That file is about 15,358 lines: do NOT add to it.

**Conventions to follow:** `unit/UnitSyncBatcher.java` for per-player delta snapshots; `perf/SysTimerTest.java` for pure-class JUnit style; a new `[Sys]` section is added exactly as `PUSH_SCAN` (id 21) was: constant, name, `Sys.begin/end` around the work.

**Hard rules (all apply):**
1. Tests first, red on main. For pure helpers: a JUnit table test with a throwing skeleton first. For behaviour: a GameTest that fails on main.
2. Client code must not leak into server code (`python3 tools/check_server_client_imports.py`).
3. Fog of war: a player never gets information the fog hides. Delta sync must re-send a building/unit in full when it BECOMES visible to a player. Visibility latency after a vision change must stay <= 10 ticks (today's worst case).
4. Oculus: nothing rendered here.
5. No file crosses 1,000 lines: `BuildingServerEvents.java`, `UnitServerEvents.java`, `FogOfWarServerEvents.java` are over; net change in each must be <= 0 (move code out to new files). New GameTests in a new class.
6. `python3 tools/check_java.py` 0 structural errors; `bash tools/prepush.sh` before every push.
7. New GameTests: 10-run flake-stress, read the `[Stress]` annotation, not the job colour (commands in PR template). No assertion on tick counts or timings that depend on load: use bounded polls and structural counts (packets sent, calls made), never milliseconds.
8. No gameplay numbers change. Commit by explicit path, identity `git -c user.name=IamTheLovish -c user.email=IamTheLovish@users.noreply.github.com commit`, trailers as given; never push `main`, never force push.

## Steps

### Step 1 - count first (PR 1, no behaviour change)
1a. Pure class `perf/NetCount.java` (no Minecraft imports): categories `BUILDING_SYNC, UNIT_SYNC, FOG_CHUNKS, PLAYER_CHUNKS, OTHER`; `add(category, bytes)`, `snapshotAndReset()` returns packets and bytes per category, `format()` returns `[Net] 10 s: buildingSync 2700 pkts 0.9 MB | unitSync ...` (categories with 0 packets omitted). Write `bar/src/test/java/.../perf/NetCountTest.java` FIRST (skeleton throws, RED; then GREEN): adds across categories, reset, formatting incl. empty window and MB/KB rounding.
1b. Hook it, only while `Sys.isMeasuring()` (bytes need an encode, so never in normal play): `BuildingClientboundPacket.sendFiltered` (after the visibility test, per packet sent), the send in `UnitSyncBatcher`, `FogChunksClientboundPacket.send`, `PlayerChunksClientboundPacket.send` (called from `FogOfWarServerEvents.java:523`). Print `NetCount.format()` next to the `[Sys]` line in `Sys.report()`.
1c. Add `[Sys]` sections `BUILDING_SYNC` (around the `onWorldTick` building loop) and `FOG_TRACKING` (around `refreshEntityTracking`); extend `Sys.SECTIONS` and `NAMES`, add both to the `SysTimerTest` name-count assertion if it has one.
1d. Per-slot profile: in `perf/ServerTickProfile.java` also keep mean tick ms by `tickCount % 20` and print it in the `/rts-perf` summary as `slots: s0 12.1 | s1 3.0 | ...` (top 5 slots). This proves or disproves the alignment (Spike C) before anything moves.
GATE 1: `python3 tools/check_java.py` 0 errors; `NetCountTest` green in CI; a GameTest run prints a `[Sys]` line containing `buildingSync` and `fogTracking` (use the existing 8v8 stress log: `gh run view <id> --log` is large, use the check-run annotations of the `bar` job and look for `[Sys]`). Put the first real numbers (from `/rts-perf 60` run by lovish at minute 15+ with 450+ units: executor cannot run the client, ask for it in the PR) in the PR body: calls/s of `updatePlayers`, packets/s and MB/s of building sync, worst slot.

### Step 2 - building sync sends only what changed (PR 2)
2a. Pure `building/SyncDelta.java` (no Minecraft imports): `SyncDelta<K>` keeps per key a `long version` bump when a caller passes a new value tuple (`set(key, int[] fields)` or a hash) and per viewer a map key -> last version sent; `boolean dueFor(viewer, key, nowTick)` is true when the viewer never got it, the version differs, or `nowTick - lastFull(viewer,key) >= FULL_REFRESH_TICKS (200)` staggered by `key.hashCode() % 20`; `forgetViewer`, `forgetKey`. JUnit `SyncDeltaTest` FIRST (skeleton RED): unchanged -> not due twice in a row; changed -> due once; new viewer -> due for all; full refresh staggers; `forgetViewer` re-sends everything.
2b. Extract the loop at `BuildingServerEvents.java:1037-1044` into `building/BuildingSync.java` (`static void pass(ServerLevel, Collection<ServerPlayer> viewers, BiConsumer<ServerPlayer, BuildingClientboundPacket> sender)`), so a GameTest can drive it with fake viewers and a counting sender. For each building: build the tuple (`blocksPlaced`, `partialBlocksDestroyed` rounded, `ownerName`, `scenarioRoleIndex`, `mergeEnabled`, merge anchor), then for each viewer that `FogOfWarServerEvents.canPlayerSeeBuilding(sp, b)` AND `dueFor` -> send. A building that becomes visible (visible now, not visible at the last pass) is treated as never sent (clear that viewer's entry when the test says not visible). On `BuildingServerEvents` remove/destroy, `forgetKey`; on player disconnect `forgetViewer`. Register the new state with the lifecycle registry if plan 011 has merged (`LifecycleScanTest` will fail otherwise), else add it to that plan's allow-list notes in the PR.
2c. GameTest first (new class `gametest/SyncSpikeGameTests.java`, own batch `sync_spike`): 40 registered buildings, 4 fake viewers (see `gametest/AudienceGameTests.java` for fake players and `FogOfWarServerEvents.recomputeVisionFor`), a counting sender. Assert (structural, no timing): pass 1 sends one packet per (visible building, viewer); pass 2 with nothing changed sends 0; after changing one building's `blocksPlaced` pass 3 sends exactly its visible viewers; after a viewer's vision gains a building pass 4 sends that building to that viewer only; after 10 more passes with nothing changed the staggered full refresh sends each building to each viewer exactly once per 200 ticks. On main (before 2b) pass 2 sends the full count: RED.
GATE 2: `gh workflow run flake-stress.yml -f ref=claude/improve-013-server-tick-spikes -f tests="test:<name>" -f runners=10` on each new test (comma-separate them), then read the `[Stress]` annotation (PR template): `10 runners; 0 with any failure`. In CI the `[Net]` line of the stress run shows buildingSync packets per 10 s down by more than 90% against the step-1 baseline (copy both numbers into the PR; if it is not, say so and stop).

### Step 3 - fog tracking refresh without the full cross product (PR 3)
3a. Measure the real cost from the `[Sys] fogTracking` row of step 1 before changing anything. If it is under 0.5 ms per tick averaged (calls spread over the 10-tick period), STOP and report: nothing to fix.
3b. Design (decided): keep today's period (10) and today's latency bound. (i) `applyVision` returns `boolean changed` (the condition at line 735); collect the UUIDs of players with `changed` in a set for this pass. (ii) For a changed player: run `updatePlayers(List.of(player))` for every unit THIS tick (same latency as today, but 1 player, not all). (iii) For all fogged players unchanged: only units that moved to another BLOCK since their last refresh (cache `Int2LongOpenHashMap id -> BlockPos.asLong()`, cleared for ids that left `getAllUnits`, registered with lifecycle) get `updatePlayers(unchangedFogged)`, and those are spread by `id % 10 == tickCount % 10` over the ten ticks between passes ONLY IF the step-1 worst-slot number shows the pass is still a spike; otherwise run them in the pass. Never skip a unit for longer than 10 ticks.
3c. GameTest first (`SyncSpikeGameTests`): (a) a still enemy in range of a player who then walks a friendly next to it is tracked by that player within 10 ticks (the javadoc case at lines 749-754; this must stay green); (b) the number of `updatePlayers` calls in a pass with no vision change and no unit movement is 0 (count with a test hook `FogOfWarServerEvents.refreshCallsForTests`); (c) with one of 4 players changed, calls == units. RED on main for (b) and (c).
GATE 3: flake-stress the new tests: 0 failures in 10; `[Sys] fogTracking` in the CI stress log is lower than the step-1 baseline; lovish re-runs `/rts-perf 60` (listed in "Numbers for lovish").

### Step 4 - timer phases (PR 4)
4a. Pure `perf/TickPhase.java`: `static boolean due(long tick, int period, int phase)` = `tick % period == phase`; constants `UNIT_SYNC (20, 0)`, `FOG (10, 5)` (fires at residues 5 and 15 mod 20), `BUILDING_SYNC (20, 10)`, `CHUNK_LOADER (20, 17)`, `BLUEPRINT_SWEEP (10, 2)`, `RECLAIM_STEP (10, 8)`, `FACTION_AURA (10, 3)`, `STEWARD (20, 14)`. Residues mod 20 then are: period 20 {0, 10, 17, 14}; period 10 {5,15, 2,12, 8,18, 3,13}: all distinct. Adjust residues in the file if the step-1d slot profile shows a different heavy slot; the only rule is that every residue mod 20 used by any entry is unique. JUnit `TickPhaseTest` FIRST: the table computes every entry's residues mod 20 (a period-10 entry has two) and asserts all of them are pairwise distinct across entries. RED against a skeleton, then GREEN.
4b. Replace each counter with `TickPhase.due(server.getTickCount(), P, phase)` (one at a time, keeping its logic). Where a counter is also a "time since" value, keep the counter and only change its INITIAL value.
GATE 4: `TickPhaseTest` green; the `/rts-perf` slot line (step 1d) from a CI stress run shows the heaviest slot is no longer more than 2x the mean slot (copy numbers into the PR); all shards green (`python3 tools/ci_wait.py --pr <N>` prints GREEN).

## Out of scope
Fog rasterisation (`updatePlayerBrightChunks`, `coveredFor`, `rasterizeCircle`): a separate cost, not touched here; unit sync (`UnitSyncBatcher` is already delta); save timers (plan 014); client-side cost; any gameplay number; moving the per-entity timers.

## STOP conditions
- Drift check shows changes, or #247 touches the lines named above.
- Step 3a shows the fog refresh is cheap: report, skip step 3.
- A fog GameTest shows an enemy appearing later than 10 ticks after your change: revert step 3 and report.
- You need a real `ServerPlayer` and AudienceGameTests has no way to fake one: report instead of inventing one.
- CI red you cannot explain after one fix attempt; the same test red on main (`tools/known_flakes.txt`).

## Done criteria
- `[Net]` and the two `[Sys]` sections exist and are tested; baseline and after numbers are in the PRs.
- Building sync: unchanged buildings are not re-sent; newly visible ones are; full refresh every 200 ticks staggered.
- Fog refresh: no full unit x player pass unless vision changed; latency <= 10 ticks proven by a GameTest.
- Timers sit on distinct residues, proven by `TickPhaseTest`.
- Overlap check: `claude/plans/INDEX.md` (a Project doc) may list an older "FoW rasterise" perf item. This plan supersedes its refresh part; the rasterise part stays open. Say which in the PR.

## PR body template
```
## What
<one sentence: which step>

## Why
Server tick spikes every 10/20 ticks at 450+ units (audit: ~16k updatePlayers calls and ~27k building packets per second, unmeasured until PR 1).

## Evidence
- Baseline [Sys]/[Net] lines (run <id>): <paste>
- After (run <id>): <paste>
- Red commit <sha> -> green commit <sha>
- Flake-stress run <id>, [Stress] annotation: "10 runners; 0 with any failure", "<test>: failed 0, passed 10"
  read it with: gh run view <id> --json jobs --jq '.jobs[]|select(.name=="summary")|.databaseId'
  then: gh api repos/IamTheLovish/Beyond-and-Tabs/check-runs/<jobid>/annotations --jq '.[].message'

## Numbers for lovish
- Please run `/rts-perf 60` at minute 15+ with 450+ units before and after and paste the p95/max and the slot line.
- Fog: appearance latency after a vision change is unchanged (<= 10 ticks).

Do not merge without lovish's OK
```

## Return format (max 200 words)
PR number(s); per GATE the command and one-line result; the baseline vs after numbers (packets/s, updatePlayers calls/s, worst slot ms); anything you stopped on. Nothing else.
