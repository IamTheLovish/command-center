# 014 - save hitch (synchronous saves on the server thread, three timers plus every research change)

- **Goal:** no server tick pays for more than one module's save, repeated saves of unchanged data stop, and a research change no longer forces a disk write on its own tick, without making a crash lose meaningfully more than today.
- **Lane:** Lane A (performance, persistence). Post on issue #35 before editing `UnitServerEvents.java` / `BuildingServerEvents.java` (shared).
- **Branch:** `claude/improve-014-save-hitch`
- **Claim:** `python3 tools/claim.py check save hitch getDataStorage persistence` then `python3 tools/claim.py take improve-014 --lane "Lane A" --branch claude/improve-014-save-hitch --what "Save scheduler: staggered, coalesced SavedData writes (plan 014)"`. Release when the last PR merges.
- **Model / effort:** sonnet, high (size M; the scheduler is a pure class, the wiring is mechanical). Not gameplay timing, not fog.
- **Written against:** origin/main `bbbdac21`.
- **Drift check (run first):**
  `git fetch origin && git diff bbbdac21..origin/main --stat -- bar/src/main/java/com/solegendary/reignofnether/unit/UnitServerEvents.java bar/src/main/java/com/solegendary/reignofnether/building/BuildingServerEvents.java bar/src/main/java/com/solegendary/reignofnether/resources/ResourcesServerEvents.java bar/src/main/java/com/solegendary/reignofnether/research/ResearchServerEvents.java bar/src/main/java/com/solegendary/reignofnether/player/PlayerServerEvents.java bar/src/main/java/com/solegendary/reignofnether/match/MatchOutcome.java`
  If any changed, STOP and report which. Open PRs #247 (perf-quick-wins) and #248 (security-state-fixes) both edit `UnitServerEvents.java`; #248 also edits the hero-save path (`saveFallenHeroUnits`). Rebase after they merge; do not start step 2 before #248 is merged or closed. Plan 013 step 4 touches `UnitServerEvents.java:108/257` and `BuildingServerEvents.java:144`: do not run both plans at once.

## Context (paths relative to `bar/src/main/java/com/solegendary/reignofnether/`)

**What the code does today (verified on bbbdac21).** Every save method ends with `data.save()` (which is just `setDirty()`, e.g. `research/ResearchSaveData.java` `public void save() { this.setDirty(); }`) and then `level.getDataStorage().save()`, which writes EVERY dirty SavedData in the world to disk now, on the server thread:
- `unit/UnitServerEvents.java:265-271` (timer `SAVE_TICKS_MAX = 600`, line 249) calls `saveGatherTargets` (`:315-335`, ends `data.save(); level.getDataStorage().save();` at 332-333; walks every unit).
- `building/BuildingServerEvents.java:185` (`SAVE_TICKS_MAX = 600`), `:188-200` calls `saveBuildings(level)` (`:202-258`, builds NBT for every building, dedupes, `buildingData.save(); level.getDataStorage().save();` at 256-257) and `saveNetherZones(level)` (`:260-268`, its own `getDataStorage().save()` at 265, plus an INFO log line each time).
- `resources/ResourcesServerEvents.java:143` (`SAVE_TICKS_MAX = 600`), `:157-164` calls `saveResources` (`:81-128`; for every resource owner it walks ALL units, O(owners x units); `data.save(); serverLevel.getDataStorage().save();` at 126-127).
- `player/PlayerServerEvents.java:204` declares `SAVE_TICKS_MAX = 1200` and `saveTicks` but the stop handler at 206-209 is the only user I found: check whether the 1200 timer is dead code before touching it.
- `research/ResearchServerEvents.java:24-34` `saveResearch()` writes straight away, and it is called from `addResearch` (:82), `removeResearch` (:88), `removeAllResearch` (:60), `removeAllResearchFor` (:65), `match/MatchOutcome.java:123`, `player/PlayerServerEvents.java:1410` (`saveAll`).
Three 600-tick timers that all start at 0 on server start therefore hit the same tick (and with `UNIT_SYNC` etc. from plan 013) and each `getDataStorage().save()` rewrites the files the previous call had already written only if dirty, but every `data.save()` re-marks its module dirty, so every module is rewritten every 30 s whether it changed or not. Each rewrite is `NbtIo.writeCompressed` (gzip) on the server thread.
**The comment that already calls this wrong:** `unit/UnitServerEvents.java:298-303`, javadoc of `saveFallenHeroUnits(level, flush)`: "`flush` writes every dirty save file to disk now: right for the server stopping, wrong on each hero death mid-fight (a synchronous disk write of all the world's saved data on the server thread) - there the data is only marked dirty and Minecraft's autosave / the stop writes it." That is the precedent: mark dirty, no flush.

**What Minecraft 1.20.1 does (I read the bytecode of `server-1.20.1-...-srg.jar` with `javap -c -p`, jar at `D:\BeyondAndTabs-Server\libraries\net\minecraft\server\1.20.1-20230612.114412\`; the cloud executor has no Minecraft classpath, so trust this and verify with the GameTest in step 1c):**
- `SavedData.save(File)` (SRG `m_77757_`) first tests `isDirty()`; if dirty it builds the NBT (`save(CompoundTag)`), adds the data version, calls `NbtIo.writeCompressed(tag, file)` straight into the target file (NO temp file + rename: a crash mid-write can truncate the file), then `setDirty(false)`.
- `DimensionDataStorage.save()` (SRG `m_78151_`) loops over every cached SavedData and calls that. It is called from the `ServerLevel` save path (one call site in `ServerLevel`'s bytecode), i.e. from vanilla autosave and from the stop.
- `MinecraftServer` contains the literal 6000: vanilla autosaves every 6000 ticks (5 minutes) while players are on.
So "setDirty() and let vanilla save" means: our data reaches disk at most every 5 minutes and on a clean stop, versus 30 seconds today; on a crash or kill we would lose up to 5 minutes of building progress / resources. Fewer writes also means a smaller window in which a crash corrupts a half-written file.

**Hard rules (all apply):**
1. Tests first, red on main: the scheduler is pure, so JUnit with a throwing skeleton first; the wiring gets one GameTest that fails on main.
2. Client code must not leak into server code (`python3 tools/check_server_client_imports.py`).
3. Fog of war: not touched.
4. No file crosses 1,000 lines. `UnitServerEvents.java`, `BuildingServerEvents.java`, `PlayerServerEvents.java` are over: net change <= 0 in each (you delete timer fields and replace calls). New classes are small. New GameTests in a new class `gametest/SaveSpreadGameTests.java`.
5. `python3 tools/check_java.py` 0 structural errors; `bash tools/prepush.sh` before every push.
6. New GameTests: 10-run flake-stress and read the `[Stress]` annotation, not the job colour (commands in the PR template). No assertion on milliseconds or on a tick count that depends on server load: poll with a bound.
7. Crash safety is a requirement, not a nice-to-have: a clean stop and every match-end / reset / defeat path still flush synchronously (they call the `...Now` variants).
8. Commit by explicit path, identity `git -c user.name=IamTheLovish -c user.email=IamTheLovish@users.noreply.github.com commit`, trailers as given; never push `main`, never force push.

## Design (decided; the one open choice is a lovish question, below)

`persistence/SaveScheduler.java` - pure Java, no Minecraft imports:
```java
public final class SaveScheduler {
    public record Module(String name, int minIntervalTicks, int phaseTicks, Runnable flush) { }
    public void register(Module m);
    public void request(String name);            // "I changed": coalesces any number of calls into one pending flag
    public void markUnconditional(String name);  // for state that always changes (resources): wanted every interval
    public String next(long nowTick);            // the ONE module to flush this tick, or null: wanted, not flushed within minIntervalTicks, (nowTick % 20 == phase % 20), at most one per tick, oldest request first
    public void flushed(String name, long nowTick);
    public void flushNow(String name, long nowTick);   // runs flush at once, clears the pending flag, resets the interval
    public void flushAll(long nowTick);                // stop / reset: every module with a pending flag
}
```
Wiring class `persistence/SaveServerEvents.java` (name contains `Server`, registered in `registrars/ServerEventRegistrar.java:47-120` like the others): one `@SubscribeEvent onServerTick(END)` that calls `next(tickCount)` and runs that module's flush; `onServerStopping` calls `flushAll` (after the existing stop handlers' own saves, which stay).
Module settings (ticks): buildings (min 600, phase 3, request on checksum change, see step 3), gatherTargets (600, phase 7, unconditional), resources (1200, phase 11, unconditional), research (20, phase 15, request-driven), nether zones (inside buildings' flush), rtsPlayers unchanged (event-driven today).

**Lovish question (put in the PR, do not decide alone):** vanilla-only would mean a crash loses up to 5 minutes; this design keeps 30 s for buildings / targets and 60 s for resources and only removes the pile-up and the rewrites of unchanged data. Which does he want? Shipped default: this design.

## Steps

### Step 1 - measure and pin vanilla semantics (PR 1, no behaviour change)
1a. `perf/Sys.java`: new section `SAVE` (id at the END of the list; extend `SECTIONS` and `NAMES`, line 63-69), wrap each of the five save calls in `Sys.begin(Sys.SAVE)` / `Sys.end`, and log `[Save] <module> <ms> ms, <n> objects` at INFO whenever a save takes more than 5 ms (use `System.nanoTime`; this is a log line, not an assertion).
1b. JUnit `SaveSchedulerTest` (pure) written FIRST against a throwing skeleton (RED), then implemented (GREEN): over a simulated 7,200 ticks with the module settings above, (i) no tick runs more than one flush; (ii) 100 `request("research")` calls inside one interval produce exactly one flush; (iii) a module with no request is never flushed (except unconditional ones, once per interval); (iv) `flushNow` runs at once and resets the interval; (v) `flushAll` flushes exactly the pending modules; (vi) two modules that are both due are flushed on consecutive eligible ticks, oldest first, never together.
1c. GameTest (new class, own batch not needed): `saved_data_semantics_hold`: create a `ResearchSaveData` via `ResearchSaveData.getInstance(level)`, call `save()` (so `isDirty()` is true), call `level.getDataStorage().save()`, assert `isDirty()` is false; call `save()` twice, assert still one dirty flag (this pins "dirty is a flag, repeated requests are free"). It must pass on main; it documents the semantics the design relies on.
GATE 1: `NetCount`-style: CI green; the `[Save]` lines appear in the 8v8 stress or any GameTest log (check-run annotations of job `bar`); `SaveSchedulerTest` count in the `JUnit summary` notice rises by 6; flake-stress of `saved_data_semantics_hold` (10 runners): `10 runners; 0 with any failure`.

### Step 2 - the scheduler replaces the three timers (PR 2)
Replace the timers at `UnitServerEvents.java:249-271`, `BuildingServerEvents.java:185-199`, `ResourcesServerEvents.java:143-164` by registrations in `SaveServerEvents` (each module's `flush` is its existing `saveX(level)` method, unchanged internally). Delete the three `SAVE_TICKS_MAX` / `saveTicks` fields and tick blocks. Keep every other caller of `saveBuildings`, `saveGatherTargets`, `saveResources` (stop, reset, `PlayerServerEvents.saveAll` line 1403-1411, `CustomBuildingServerEvents.java:91`, `BuildingServerEvents.java:386/573`) calling the method directly: those are the synchronous `...Now` paths.
GameTest first (`SaveSpreadGameTests`): `saves_are_spread_across_ticks`: register counting flushes in the real `SaveServerEvents` is not testable headless, so test the wiring structurally: assert `SaveServerEvents.registeredNames()` equals {buildings, gatherTargets, resources, research}, assert the three old fields are gone by a JUnit source scan (modelled on `perf/RenderStageGateTest`: the three files no longer contain `SAVE_TICKS_MAX`). RED on main (fields present), GREEN after.
GATE 2: `python3 tools/ci_wait.py --pr <N>` prints GREEN; `git diff --stat origin/main` shows net deletions in the three big files; the `[Save]` lines (step 1a) from the stress log show the three saves on different ticks (log the server tick in the `[Save]` line to prove it).

### Step 3 - stop rewriting unchanged data; research coalesced (PR 3)
3a. Buildings: before `saveBuildings`, compute a cheap checksum over `getBuildings()` (count, sum of `getBlocksPlaced()`, sum of `Double.hashCode(partialBlocksDestroyed)`, hash of owner names and `isBuilt`); if it equals the last saved one and nothing called `request("buildings")`, skip the save and the log line. Pure helper `persistence/ChangeGate.java` (JUnit table first: same input -> skip, one field changed -> save).
3b. Research: `saveResearch()` becomes `SaveScheduler.request("research")` (flush within 20 ticks, one write for any number of changes); add `saveResearchNow()` (the current body) and use it ONLY at `match/MatchOutcome.java:123` and `player/PlayerServerEvents.java:1410` (match end / reset must persist immediately). Keep the method name `saveResearch()` so no other caller changes.
3c. Resources: replace the per-owner walk over all units (lines 87-125) by one pass over `UnitServerEvents.getAllUnits()` accumulating held food/wood/ore/emerald into a `Map<String,int[]>`; same saved values (JUnit cannot load the class, so the GameTest `saved_resources_include_unit_held_items` fills two workers with items for two owners, calls `saveResources`, and compares `ResourcesSaveData.resources` against the expected totals: green on main AND after, a guard written first).
GATE 3: flake-stress the new GameTests (10 runners, `[Stress]` annotation: `<test>: failed 0, passed 10`); `ChangeGateTest` green; CI shows fewer `[Save] buildings` lines than step 2 in the same stress log (copy both counts into the PR).

## Out of scope
Asynchronous writes (snapshot the NBT on the server thread, gzip + write on a worker with temp-file + rename: the real fix for both the hitch and corruption, but a separate, riskier plan); changing what is saved; vanilla's own autosave; `RTSPlayerSaveData` timing beyond the dead-code check; map data (`MapBuilder`).

## STOP conditions
- Drift check shows changes; #248 not merged when you reach step 2.
- `saved_data_semantics_hold` fails on main (my reading of `SavedData` is wrong): report with the failure text and stop.
- Any pre-existing GameTest about persistence/reload goes red: revert that step, report.
- You find a save path that does not go through the five methods above (grep `getDataStorage().save()`: also `CustomBuildingServerEvents.java:124`, `ScenarioServerEvents.java:60`, `StartPosServerEvents.java:244`, `SurvivalServerEvents.java:74`, `TutorialServerEvents.java:79`): leave them synchronous, list them in the PR.
- CI red you cannot explain after one fix attempt; same test red on main (`tools/known_flakes.txt`).

## Done criteria
- No server tick runs two module saves from the periodic path; research changes cost one coalesced write; unchanged buildings are not re-written.
- Stop, reset, match end and defeat still flush synchronously (existing tests green).
- `resources` save is one pass over units.
- The `[Save]` log lines exist and show the before/after in the PR.

## PR body template
```
## What
<one sentence: which step>

## Why
Three 600-tick timers + every research change wrote all dirty SavedData synchronously on the server thread (UnitServerEvents.java:298-303 already calls that wrong mid-fight).

## Evidence
- Before: [Save] lines (run <id>): <paste>; After (run <id>): <paste>
- Red commit <sha> -> green commit <sha>
- Flake-stress run <id>, [Stress] annotation: "10 runners; 0 with any failure", "<test>: failed 0, passed 10"
  read it with: gh run view <id> --json jobs --jq '.jobs[]|select(.name=="summary")|.databaseId'
  then: gh api repos/IamTheLovish/Beyond-and-Tabs/check-runs/<jobid>/annotations --jq '.[].message'

## Numbers for lovish / questions
- Crash window: buildings/targets 30 s (unchanged), resources 60 s (was 30 s), research <= 1 s. Or vanilla-only (5 min)?

Do not merge without lovish's OK
```

## Return format (max 200 words)
PR number(s); per GATE the command and one-line result; before/after `[Save]` numbers; the list of save paths left synchronous. Nothing else.
