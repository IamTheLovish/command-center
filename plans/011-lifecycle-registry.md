# 011 - lifecycle registry (one place that resets per-match and per-world state)

- **Goal:** every static mutable collection on the server side is cleared by one registry call from `resetRTS` (rematch) and from server stop, and a JUnit scan fails the build for any new one that is neither registered nor allow-listed.
- **Lane:** Lane A (server state, CI). Post on issue #35 before touching `player/PlayerServerEvents.java` (shared file).
- **Branch:** `claude/improve-011-lifecycle-registry`
- **Claim:** `python3 tools/claim.py check lifecycle registry resetRTS` then `python3 tools/claim.py take improve-011 --lane "Lane A" --branch claude/improve-011-lifecycle-registry --what "LifecycleRegistry: one reset/stop call for per-match state (plan 011)"`. Release it when the last PR merges.
- **Model / effort:** sonnet, high (size M, 3+ PRs). Not gameplay timing, not fog.
- **Written against:** origin/main `bbbdac21`.
- **Drift check (run first):**
  `git fetch origin && git diff bbbdac21..origin/main --stat -- bar/src/main/java/com/solegendary/reignofnether/player/PlayerServerEvents.java bar/src/main/java/com/solegendary/reignofnether/registrars/ServerEventRegistrar.java bar/src/main/java/com/solegendary/reignofnether/startpos/CapturePointServerEvents.java bar/src/main/java/com/solegendary/reignofnether/bot/BotServerEvents.java bar/src/main/java/com/solegendary/reignofnether/unit/UnitKills.java bar/src/main/java/com/solegendary/reignofnether/hero/HeroProgression.java bar/src/main/java/com/solegendary/reignofnether/building/BuildingReclaim.java bar/src/main/java/com/solegendary/reignofnether/unit/UnitServerEvents.java`
  If any of these changed, STOP and report which, with the diff stat. (Exception: open PR #248 `claude/security-state-fixes` edits `UnitServerEvents.java`; see "Do not redo".)

## Context (paths relative to `bar/src/main/java/com/solegendary/reignofnether/`)

**The problem, verified.** A rematch calls `PlayerServerEvents.resetRTS(boolean hardReset)` (`player/PlayerServerEvents.java:1262-1344`), itself called from `matchstart/MultiplayerLobby.java:494`. It clears state by hand, one line per module, e.g. lines 1264-1284:
```java
ResignVoteServerEvents.clear();
MultiplayerLobby.onReset();
lastBeaconTicksSent.clear();
...
com.solegendary.reignofnether.mana.WardServerEvents.clearAll();
com.solegendary.reignofnether.ability.abilities.LeyLink.clearAll();
```
Server stop is the same idea spread over about 72 files that each have their own `@SubscribeEvent ... onServerStopping(ServerStoppingEvent)` (e.g. `mana/WardServerEvents.java:246-249` just calls `clearAll()`).

Modules with static collections that `resetRTS` does NOT clear (read each before editing; lines on bbbdac21):
- `startpos/CapturePointServerEvents.java:115-120`: `points`, `hired`, `recruits`, `badRecruitWarned` (cleared only at stop, lines 380-385).
- `bot/BotServerEvents.java:31-33`: `brains`, `thinkFailures` (cleared at stop, line 112; a missing brain is rebuilt from world state for any bot in `rtsPlayers`, line 47, so clearing on reset is safe).
- `unit/UnitKills.java:34-36`: `dirty`, `ids`, `counts` (stop handler line 117 clears only `dirty`).
- `hero/HeroProgression.java:184-186`: `scratch` (harmless) and `holdCarry` (hero id -> fractional XP). It has NO stop handler at all.
- `building/BuildingReclaim.java:47`: `active` (cleared at stop, line 168).

**Second defect: `getAllUnits()` hands out the live list.** `unit/UnitServerEvents.java:209-211` returns `allUnits`; `resetRTS` line 1291 does `UnitServerEvents.getAllUnits().removeIf(...)` from outside, which skips `allUnitsModCount++` (bumped only at `UnitServerEvents.java:282, 522, 564`). `player/PlayerPanelServerEvents.java:196-203` caches army totals on `getAllUnitsModCount()` AND `units.size()`, so a removal that shrinks the list is caught by the size check; a removal followed by an add inside the 1.5 s cache window is not. Fix: add `UnitServerEvents.removeUnitsIf(Predicate<LivingEntity>)` that removes and bumps the counter, and call it from line 1291.

**Do NOT redo what open PR #248 (branch `claude/security-state-fixes`) already fixes:** `HeroServerEvents.fallenHeroes`, `UnitServerEvents.savedTargetResources`, `BlockServerEvents` temporary blocks (it also adds `gametest/WorldStopGameTests.java`, reuse its approach once merged). If #248 has not merged, leave those three alone and allow-list them with `# fixed in PR 248`. After it merges, `git fetch` and rebase before step 2.

**Convention to follow (exemplar):** `bar/src/test/java/com/solegendary/reignofnether/perf/RenderStageGateTest.java` is a JUnit test that reads Java source as text (`Path.of("src/main/java/com/solegendary/reignofnether/...")`, falling back to `bar/src/main/...` when run from the repo root) and asserts a rule, because JUnit cannot load Minecraft classes. Use the same method for the scan. Server event classes are registered in `registrars/ServerEventRegistrar.java:47-120` (`vanillaEventBus.register(X.class)`).

**Hard rules (all apply):**
1. Tests first, red on main: each PR's first commit is the failing test, pushed and seen red in CI before the fix commit.
2. Client code must not leak into server code: `python3 tools/check_server_client_imports.py` passes (part of prepush). The registry package imports nothing from `net.minecraft.client`.
3. Fog of war and Audience rules are untouched; no packet changes.
4. No file crosses 1,000 lines. `PlayerServerEvents.java` is already far over: your net change there must be <= 0 lines. New classes stay small.
5. `python3 tools/check_java.py` reports 0 structural errors; run `bash tools/prepush.sh` before every push.
6. Any new GameTest: 10-run flake-stress and read the `[Stress]` annotation, not the job colour (commands in the PR template). New GameTests go in their own class and in no shard list (they land in shard 1).
7. Commit by explicit path (never `git add -A` / `git add .`), identity `git -c user.name=IamTheLovish -c user.email=IamTheLovish@users.noreply.github.com commit`, end each commit message with the trailers your session gives you. Never push `main`, never force push. Push at the first working commit.

## Design (decided, do not redesign)

`lifecycle/LifecycleRegistry.java` - pure Java, NO Minecraft imports, so JUnit can load it:
```java
public final class LifecycleRegistry {
    public record Reset(boolean hard, boolean keepWorld) { }      // keepWorld = sandbox or scenario (resetRTS line 1270)
    public interface Module {
        String name();
        default void onMatchReset(Reset r) { }
        default void onWorldStop() { }
        static Module of(String name, java.util.function.Consumer<Reset> onReset, Runnable onStop) { /* null-safe */ }
    }
    public static void register(Module m);                 // duplicate name -> IllegalStateException
    public static void matchReset(Reset r);                // registration order; a throwing module goes to errorSink, the rest still run
    public static void worldStop();                        // reverse registration order, same isolation
    public static java.util.List<String> names();
    public static java.util.function.BiConsumer<String, Throwable> errorSink = (n, t) -> t.printStackTrace();
    static void clearForTests();
}
```
`lifecycle/LifecycleBootstrap.java` (Minecraft side): `public static void registerAll()` with one line per migrated module, e.g. `LifecycleRegistry.register(Module.of("capturePoints", r -> CapturePointServerEvents.resetMatch(), CapturePointServerEvents::clearForStop));`, and it sets `errorSink` to `ReignOfNether.LOGGER.error`. Called once, first line of `ServerEventRegistrar.registerServerEvents()`.
`lifecycle/LifecycleServerEvents.java`: `@SubscribeEvent onServerStopping(ServerStoppingEvent)` calls `LifecycleRegistry.worldStop()`; registered next to the others in `ServerEventRegistrar`.
Module methods are plain `static` methods on the existing class; reuse the existing clearing body (e.g. `WardServerEvents.clearAll()`), rename nothing.

## Steps

### Step 1 - registry, scan test, allow-list (PR 1)
1a. Write `bar/src/test/java/com/solegendary/reignofnether/lifecycle/LifecycleRegistryTest.java` first (JUnit 5, table style): (i) `matchReset` calls modules in order with the same `Reset`; (ii) `worldStop` calls them in reverse; (iii) a throwing module does not stop the others and the sink gets its name; (iv) a duplicate name throws; (v) `clearForTests` empties it. Commit it with a skeleton `LifecycleRegistry` whose methods throw `UnsupportedOperationException("skeleton")` so CI shows RED for the right reason. Push, then implement.
GATE 1a: `python3 tools/ci_wait.py --pr <N>` after the first push prints RED naming `LifecycleRegistryTest` with `skeleton`; after the implementation commit it prints GREEN and the `JUnit summary` notice count is 5 higher.
1b. Write `LifecycleScanTest.java` (same package) modelled on `RenderStageGateTest`. Walk `src/main/java/com/solegendary/reignofnether` (fallback `bar/src/main/java/...`); skip file names ending `ClientEvents.java` or `Client.java`, files importing `net.minecraft.client`, and the directories `gametest/` and `mixin/`. In each remaining file find (multiline) fields matching
`^\s*(public |private |protected )?static (final )?[\w.<>, ?\[\]]*?(Map|List|Set|Deque|Queue|Collection|ArrayList|HashMap|HashSet)\b[\w.<>, ?\[\]]*?\s+(\w+)\s*=\s*new\b` plus fastutil `Int*/Long*` Set/List/Map. A hit `Class.field` passes only if the class simple name occurs in `lifecycle/LifecycleBootstrap.java` OR the line `Class.field` / `Class.*` is in `bar/src/test/resources/lifecycle-allowlist.txt`. The failure message lists every unregistered hit with file and line. Also fail on allow-list lines that match nothing.
Generate the first allow-list by running the scan with an empty list and copying the failure list in, grouped with `# reason` comments: `# pure caches / scratch lists`, `# registry data loaded at startup`, `# fixed in PR 248`. Do NOT allow-list the five modules in Context: they are registered in step 2.
GATE 1b: with an empty allow-list the test is RED listing the fields (put the count in the PR; a rough scan on bbbdac21 found about 110-330 candidates depending on the filter); with the generated list it is GREEN; `python3 tools/check_java.py` prints 0 structural errors.
1c. Add `UnitServerEvents.removeUnitsIf(Predicate<LivingEntity>)` and use it at `PlayerServerEvents.java:1291`. Test first in a new GameTest class `gametest/LifecycleResetGameTests.java` (JUnit cannot load `UnitServerEvents`): spawn two units, record `getAllUnitsModCount()`, call `resetRTS(true)`, assert the count changed. Red on main, then fix.
GATE 1c: flake-stress per the PR template shows `10 runners; 0 with any failure` and `<test>: failed 0, passed 10`.

### Step 2 - migrate modules, a few per PR
For each module: (a) add a line to `LifecycleResetGameTests` that fails on main (fill the module's state, call `PlayerServerEvents.resetRTS(false)` or `LifecycleRegistry.worldStop()`, assert empty); (b) add its `Module.of(...)` line to `LifecycleBootstrap`; (c) delete the class's own `onServerStopping` handler if it only cleared; (d) delete its line from `resetRTS`; (e) delete its allow-list entry.
First PR = the five known gaps: `CapturePointServerEvents` (on match reset clear `hired`, `recruits`, `badRecruitWarned`; keep `points` unless a rematch re-stamps sites - read `stampFor` at line 286 and `onServerTick` at line 388 first; on world stop clear all four), `BotServerEvents` (`brains`, `thinkFailures`), `UnitKills` (`dirty`, `ids`, `counts`), `HeroProgression.holdCarry`, `BuildingReclaim.active`. Then 3-5 modules per PR from the allow-list, smallest first. A module that must survive a rematch in sandbox/scenario checks `Reset.keepWorld()`.
If a module's semantics are unclear (per match or per world?), do not guess: leave it allow-listed with `# unclear: ask` and list it in the PR.
GATE 2 (each PR): `bash tools/prepush.sh` ends with no failures; `python3 tools/ci_wait.py --pr <N>` prints GREEN; `LifecycleScanTest` green; allow-list shorter than before.

### Step 3 - resetRTS iterates the registry (last PR)
Replace the hand-written module clears in `resetRTS` with one call `LifecycleRegistry.matchReset(new LifecycleRegistry.Reset(hardReset, isSandboxOrScenario))` where `MatchRoster.clearLive()` stands (line 1272). Keep in place anything that kills entities, destroys buildings, sends packets or changes game modes (lines 1286-1311, 1315-1321, 1323, 1332-1335, 1339-1341): those are match actions, not state clears.
GATE 3: `git diff --stat origin/main -- bar/src/main/java/com/solegendary/reignofnether/player/PlayerServerEvents.java` shows more deletions than insertions; the rematch GameTest passes 10 of 10 in flake-stress; the allow-list keeps only `# pure caches` and `# registry data` groups.

## Out of scope
Changing what any module stores; saving data (plan 014); renaming classes; client-side state; the three items PR #248 fixes; making `getAllUnits()` unmodifiable (only `removeUnitsIf` now).

## STOP conditions (report, do not push on)
- The drift check shows changes.
- A module you register makes an unrelated GameTest go red: revert that module, allow-list it `# unclear: ask`.
- A static collection owned by a Mixin class (cannot be reached): allow-list with reason and list in the PR.
- CI red for a reason you cannot explain after one fix attempt, or the same test is red on main (check `tools/known_flakes.txt` first).

## Done criteria
- `LifecycleRegistry`, `LifecycleBootstrap`, `LifecycleServerEvents` exist; `LifecycleRegistryTest` and `LifecycleScanTest` green.
- A rematch clears CapturePoint hired/recruits, Bot brains, UnitKills, HeroProgression.holdCarry, BuildingReclaim.active (GameTest proves it).
- `resetRTS` removes units through `removeUnitsIf` and calls the registry, and is shorter than before.
- The allow-list lists only intentional exceptions, each with a reason.

## PR body template
```
## What
<one sentence: which step / which modules>

## Why
Rematch (resetRTS) left <list> alive; server stop used ~72 separate handlers. One registry, one scan test.

## Evidence
- Red commit <sha>, CI run <id>: <test> failed with <message>
- Green commit <sha>, CI run <id>
- Allow-list size: before <n>, after <m>
- Flake-stress (GameTests): run <id>; [Stress] annotation: "10 runners; 0 with any failure", "<test>: failed 0, passed 10"
  read it with: gh run view <id> --json jobs --jq '.jobs[]|select(.name=="summary")|.databaseId'
  then: gh api repos/IamTheLovish/Beyond-and-Tabs/check-runs/<jobid>/annotations --jq '.[].message'

## Numbers for lovish
none (no gameplay numbers changed)

Do not merge without lovish's OK
```

## Return format (max 200 words)
PR number(s); for each GATE the command run and its one-line result; allow-list size before/after; anything left as `unclear: ask`; `resetRTS` lines before/after. Nothing else.
