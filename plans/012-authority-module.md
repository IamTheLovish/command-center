# 012 - authority module ("who may command", "what is the relationship", "may target through fog")

- **Goal:** one pure, table-tested rules class answers "relationship", "may command" and "may target" for every server caller, the ally/sandbox/neutral disagreements are fixed (F9) and a modified client can no longer order an attack or follow on a unit it cannot see (F7).
- **Lane:** Lane A (server rules, security). Post on issue #35 before editing `unit/UnitActionItem.java` or `unit/goals/*` (shared with Lane C).
- **Branch:** `claude/improve-012-authority-module`
- **Claim:** `python3 tools/claim.py check authority relationship mayCommand fog target` then `python3 tools/claim.py take improve-012 --lane "Lane A" --branch claude/improve-012-authority-module --what "AuthorityRules: one relationship/mayCommand/mayTarget, fog check on entity-target orders (plan 012)"`. Release when the last PR merges.
- **Model / effort:** opus, xhigh (step 3 touches fog of war and what a player may do). Steps 1, 2, 4 are sonnet-sized but one session does all four so the table stays consistent.
- **Written against:** origin/main `bbbdac21`.
- **Drift check (run first):**
  `git fetch origin && git diff bbbdac21..origin/main --stat -- bar/src/main/java/com/solegendary/reignofnether/network/PacketAuth.java bar/src/main/java/com/solegendary/reignofnether/network/Audience.java bar/src/main/java/com/solegendary/reignofnether/unit/UnitActionItem.java bar/src/main/java/com/solegendary/reignofnether/unit/packets/UnitActionServerboundPacket.java bar/src/main/java/com/solegendary/reignofnether/building/BuildingServerEvents.java bar/src/main/java/com/solegendary/reignofnether/unit/UnitServerEvents.java bar/src/main/java/com/solegendary/reignofnether/unit/goals bar/src/main/java/com/solegendary/reignofnether/util/MiscUtil.java bar/src/main/java/com/solegendary/reignofnether/alliance bar/src/main/java/com/solegendary/reignofnether/unit/Concealment.java`
  If any changed, STOP and report which. (Open PR #248 touches `UnitServerEvents.java` only for state clearing; a rebase there is fine, read the diff to be sure it does not touch lines 447-496.)

## Context (paths relative to `bar/src/main/java/com/solegendary/reignofnether/`)

Verified on bbbdac21. The same two questions are answered in six places that disagree:

| # | Where | Rule it implements |
|---|-------|--------------------|
| A | `network/PacketAuth.java:38-52` `mayActFor(sender, owner)` | sender equals owner, OR sender is a sandbox player, OR `AlliancesServerEvents.canControlAlly(sender, owner)` (= allied AND `owner` is in `playersWithAlliedControl`, `alliance/AlliancesServerEvents.java:26-29`). `:55-61` `mayControl`: a unit by A; a non-unit only with the control-all-mobs cheat. |
| B | `unit/UnitActionItem.java:187-194` `mayCommand(level, issuer, unit, sandboxOwner)` | null issuer (the server) or sandbox issuer or same owner: yes; else client: ally control or cheat; server: `canControlAlly || canControlAllMobs`. The cheat applies to UNITS here, but not in A. |
| C | `unit/UnitActionItem.java:640-643` (building abilities) | building owner equals issuer, or sandbox, or `canControlAlly`. Same as A without the null case. |
| D | `ability/AbilityServerboundPacket.java:55-62` | exact owner only. This is intentional: it ranks up a hero's ability with the OWNER's skill points. Keep it. NOT a duplicate: write it into the table as `ownerOnly`. |
| E | `building/BuildingServerEvents.java:920-926` `getUnitToBuildingRelationship` | `OWNED` if equal, else `HOSTILE`. No ally case, no neutral case. Used by `unit/goals/BuildRepairGoal.java:101` (`!= HOSTILE`) and `:224` (`rs == OWNED \|\| bridge`), `ReturnResourcesGoal.java:92`, `CallToArmsGoal.java:45`. |
| F | `unit/UnitServerEvents.java:483-496` `getUnitToBuildingRelationship` and `:455-481` `getUnitToEntityRelationship` | building: equal -> OWNED, blank -> NEUTRAL, allied -> FRIENDLY, else HOSTILE. Entity: allied first -> FRIENDLY, SAME owner -> FRIENDLY (not OWNED), blank -> NEUTRAL, else HOSTILE. Only caller of the building version: `util/MiscUtil.java:586`. |
| G | `util/MiscUtil.java:660-669` `getClientsideRelationship` | CLIENT copy using `AlliancesClient.isAllied`. Stays client code; it may share the pure function. |

`network/Audience.java:80-92` already has a pure `Facts` interface (`allied`, `commandersOf`, `spectator`, `mayCommand`) and `Audience.mayKnow(ServerPlayer, Entity)` (`:197-199`: own side OR fog-visible OR spectator). Reuse that for the fog check; do not write a second fog predicate. `Audience` itself imports Minecraft, so the new rules class must be separate and import-free.

**F9 (the bug, my reading of the finding):** with allies A and B, a worker owned by A and an unfinished building owned by B, `BuildingServerEvents.getUnitToBuildingRelationship` returns HOSTILE (E has no ally case), so `BuildRepairGoal.java:224` (`rs == OWNED`) never lets the worker build, and `:101` never auto-repairs it. The code at `:101` (`!= HOSTILE`) shows the intent was that allies are not hostile. If your reading of F9 differs, STOP and ask.

**F7 (the leak):** `unit/UnitActionItem.java:383-396` (ATTACK), `:434-439` (FOLLOW) and `:557-562` (entity-targeted abilities) call `Concealment.isHiddenFrom` (`unit/Concealment.java:41-48`: cloaked / thicket / burrowed / submerged targets) but never ask the fog. A modified client can send the id of an enemy unit standing in fog, and `CommandQueues.issue` runs it. The packet entry is `unit/packets/UnitActionServerboundPacket.java:150-169` (`accept`): it checks `PacketAuth.mayActFor`, filters ids with `PacketAuth.controllableIds`, then `CommandQueues.issue`. The target id is `unitId` (a single entity id; `<= 0` or `-1` means none).

**Convention / exemplars:** pure rules + Facts interface: `network/Audience.java:63-145`; its GameTest: `gametest/AudienceGameTests.java`. JUnit source-text and table tests: `bar/src/test/java/com/solegendary/reignofnether/building/production/PopulationRulesTest.java` (table-driven, written from the rule). Fog test helper for server tests: read `gametest/AudienceGameTests.java` first for how it fakes fog.

**Hard rules (all apply):**
1. Tests first, red on main, for every behaviour change; the pure table (step 1) characterises TODAY's behaviour first (green), then the fix changes the rows that are wrong (red -> green).
2. Client code must not leak into server code: `python3 tools/check_server_client_imports.py` passes. The new class lives in `network/` and imports only `unit.Relationship` (a plain enum).
3. Fog of war: a player must not learn about, or act on, what the fog hides. Step 3 is exactly that rule.
4. Oculus: nothing here renders. (Rule noted, not touched.)
5. No file crosses 1,000 lines: `UnitActionItem.java` and `BuildingServerEvents.java` are already long, your net change in each must be <= 0 lines (you delete the duplicates). New GameTests go in a new class `gametest/AuthorityGameTests.java`.
6. `python3 tools/check_java.py` 0 structural errors; `bash tools/prepush.sh` before every push.
7. New GameTests: 10-run flake-stress, read the `[Stress]` annotation, not the job colour (commands in the PR template).
8. Commit by explicit path, identity `git -c user.name=IamTheLovish -c user.email=IamTheLovish@users.noreply.github.com commit`, trailers as given. Never push `main`, never force push.

## Steps

### Step 1 - pure rules class, table-driven JUnit (PR 1; no behaviour change)
1a. Create `network/AuthorityRules.java` (no Minecraft imports):
```java
public final class AuthorityRules {
    public interface Facts {
        boolean allied(String a, String b);        // AlliancesServerEvents.isAllied
        boolean sandbox(String player);            // SandboxServer.isSandboxPlayer
        boolean alliedControl(String owner);       // playersWithAlliedControl.contains(owner)
        boolean controlAllMobs(String player);     // NonUnitServerEvents cheat
    }
    public static Relationship relationship(String a, String b, Facts f);   // blank either -> NEUTRAL; equal -> OWNED; allied -> FRIENDLY; else HOSTILE
    public static boolean mayCommand(String sender, String owner, Facts f); // = row A: equal || sandbox(sender) || (allied && alliedControl(owner)); null -> false
    public static boolean mayCommandEntity(String sender, String unitOwnerOrNull, Facts f); // unit: mayCommand; non-unit (null owner): controlAllMobs
    public enum TargetCheck { OK, HIDDEN_BY_COVER, IN_FOG }
    public static TargetCheck checkTarget(boolean ownSide, boolean concealedFromIssuer, boolean visibleToIssuer);
    public static boolean ownerOnly(String sender, String owner);           // row D
}
```
`checkTarget`: `ownSide` -> OK; else `concealedFromIssuer` -> HIDDEN_BY_COVER; else `!visibleToIssuer` -> IN_FOG; else OK. (Cover is checked before fog because the existing code turns a hidden target into a move order; keep that.)
Write `bar/src/test/java/com/solegendary/reignofnether/network/AuthorityRulesTest.java` FIRST, a table of `(a, b, allied, sandbox, alliedControl, cheat) -> expected` rows for every function: same owner, ally with and without shared control, ally of the wrong direction (control is granted by the OWNER: `alliedControl(owner)`, not the sender), enemy, blank vs blank, blank vs owner, sandbox sender, sandbox owner (a sandbox OWNER gives nobody control), null inputs, cheat on a unit vs on a non-unit. Commit it with a skeleton throwing `UnsupportedOperationException("skeleton")` -> RED, then implement -> GREEN.
GATE 1a: `python3 tools/ci_wait.py --pr <N>` first push prints RED naming `AuthorityRulesTest`; after implementation GREEN and the `JUnit summary` count is up by the table size.
1b. Add the `LIVE` Facts in a Minecraft-side class `network/AuthorityFacts.java` (like `Audience.LIVE`, lines 148-171) reading `AlliancesServerEvents`, `SandboxServer`, `NonUnitServerEvents`. No call site changes yet.
GATE 1b: `python3 tools/check_java.py` prints 0 structural errors; `python3 tools/check_server_client_imports.py` passes.

### Step 2 - F9, red GameTest first (PR 2)
2a. In `gametest/AuthorityGameTests.java` write `allied_worker_builds_an_allied_site`: two seats A and B allied (`AlliancesServerEvents.addAlliance`), a worker owned by A, an unbuilt building owned by B (use the helpers in `gametest/BlueprintGameTests.java` or `SkirmishGameTests` for placing a site; read one first), order `BUILD_REPAIR` via `CommandQueues.issue(level, "A", UnitAction.BUILD_REPAIR, ...)`, poll (bounded, every 5 ticks up to 400) until `getBlocksPlaced()` rises. RED on main (never rises). Second test `allied_worker_does_not_build_an_enemy_site` (enemy owner, never rises: GREEN before and after, the guard). Third: `neutral_owner_building_is_not_buildable_by_a_player_worker` if a blank-owner building exists in the helpers; otherwise skip and say so in the PR.
2b. Fix: `BuildingServerEvents.getUnitToBuildingRelationship` returns `AuthorityRules.relationship(unitOwner, buildingOwner, LIVE)`; `BuildRepairGoal.java:224` accepts `OWNED` or `FRIENDLY` (allies build and repair each other's sites; `ReturnResourcesGoal.java:92` and `CallToArmsGoal.java:45` stay `OWNED` only: do not let allies drop resources at, or be called to, each other's buildings). 
GATE 2: flake-stress both tests, 10 runners: `allied_worker_builds_an_allied_site: failed 0, passed 10`. This changes gameplay (allies can finish each other's sites). List it under "Numbers for lovish".

### Step 3 - F7: fog check on entity-target orders (PR 3; opus xhigh)
Where: `UnitActionServerboundPacket.accept` (lines 150-169), NOT `UnitActionItem`. Reason: `UnitActionItem.action` also runs for bot orders, queued orders resuming later and autocasts, which have no `ServerPlayer` and must not be fogged; only packets are untrusted.
3a. RED GameTests first (`AuthorityGameTests`): `attack_order_on_a_unit_in_fog_is_refused` (fog enabled for the sender, enemy unit outside the sender's vision: call `UnitActionServerboundPacket.accept(player, name, UnitAction.ATTACK, enemyId, new int[]{myUnitId}, ...)`, assert the unit has no attack target and `accept` returned false or the queue is empty); the same for `FOLLOW`; `attack_order_on_a_visible_enemy_still_works`; `attack_order_on_an_ally_in_fog_is_not_blocked` (own side); and a spectator/sandbox sender is not blocked. Read `gametest/AudienceGameTests.java` for how it puts a player and fog in place; if the test cannot get a fogged `ServerPlayer`, split the decision into `AuthorityRules.checkTarget` (already covered by the step 1 table) and test the packet path with `FogOfWarServerEvents` enabled via the same helper AudienceGameTests uses; if neither exists, STOP and report (do not invent a fake player).
3b. Implement between `controllableIds` (line 159) and `CommandQueues.issue` (line 163): if `unitId > 0`, look the entity up (`player.serverLevel().getEntity(unitId)`); if it exists and `!Audience.mayKnow(player, entity)` (this already returns true for own side, visible, spectator) -> log once a second per player (`PacketAuth.allowLogged` style, see line 123) and `return false` for the entity-target actions: `ATTACK`, `FOLLOW`, and any action whose ability has `canTargetEntities` (look the ability up the way `UnitActionItem.java:557` does). Do NOT touch any other action (`RECLAIM`, building orders, ...): they carry positions or own-side ids. List in the PR any other action you see that uses `unitId` as a foreign entity. Order of checks in the final code: cover (existing, in `UnitActionItem`) is unchanged.
3c. Gameplay question for lovish, put in the PR body, do not decide alone: "an order on a unit that has just stepped into fog is refused (the click does nothing). BAR lets you keep an attack order on a target that leaves line of sight and the unit chases its last known position. Do you want: (a) refuse (this PR); (b) accept if the target was visible to the sender within the last 20 ticks (a grace window, needs a per-player 'last seen' map)?" Default shipped: (a). In-flight chases (a unit already ordered that loses sight) are NOT changed by this PR.
GATE 3: flake-stress the new tests, 10 runners, 0 failures; the existing `orders_obey` and `audience_*` batches still green in the PR's CI run.

### Step 4 - delete the duplicates (PR 4)
Point each caller at `AuthorityRules` + `AuthorityFacts.LIVE`: `PacketAuth.mayActFor` (both overloads) and `mayControl` delegate; `UnitActionItem.mayCommand` delegates (keep the null-issuer fast path and the client branch, line 190-191, which uses `AlliancesClient`); `UnitActionItem.java:640-643` uses `mayCommand`; delete `UnitServerEvents.getUnitToBuildingRelationship` (`:483-496`) and repoint `MiscUtil.java:586` to `BuildingServerEvents.getUnitToBuildingRelationship`; `UnitServerEvents.getUnitToEntityRelationship` keeps its OWNED-vs-FRIENDLY quirk (same owner -> FRIENDLY): implement it as `relationship(...)` then map `OWNED -> FRIENDLY`, with a comment saying why; `MiscUtil.getClientsideRelationship` calls the pure function with a client `Facts`. Cheat-on-units difference between A and B: keep A's (packets), i.e. the control-all-mobs cheat does not command UNITS owned by others; flag in the PR as a behaviour change only for CommandQueues' internal callers (they only see ids that passed `controllableIds` already).
GATE 4: `git grep -n -E 'canControlAlly\(' origin/<branch> -- bar/src/main` shows calls only in `AuthorityFacts`, `AlliancesServerEvents` and `AlliancesClient`; `git diff --stat origin/main` shows net deletions in `UnitActionItem.java` and `UnitServerEvents.java`; the whole shard set is green (`python3 tools/ci_wait.py --pr <N>` prints GREEN).

## Out of scope
Changing the alliance system; hero-role (`HeroRoles`) rules in `Audience.onSide`; the client-side HUD relationship colours; hiding units from the minimap; grace windows (open question 3c); packets other than `UnitActionServerboundPacket` (list any you notice that take an entity id in the PR, do not fix them).

## STOP conditions
- Drift check shows changes; or PR #248 changes lines 447-496 of `UnitServerEvents.java`.
- Your reading of F9 or F7 does not match the code you see.
- A pre-existing GameTest goes red after step 2b or 4 (most likely both-blank owners: today E returns OWNED for two blank owners; the new rule says NEUTRAL; if that is the cause, keep `equal -> OWNED` before the blank check in `relationship` and say so).
- No way to get a fogged `ServerPlayer` into a GameTest (3a).
- CI red you cannot explain after one fix attempt; the same test red on main (check `tools/known_flakes.txt`).

## Done criteria
- `AuthorityRules` + table test green; `AuthorityFacts.LIVE` is the only place that reads alliances/sandbox/cheat for authority.
- F9: an allied worker builds and repairs an allied site; an enemy worker still does not.
- F7: a fogged enemy cannot be ordered attacked / followed / targeted by ability through the packet; visible, own-side and spectator targets still work.
- The duplicates in `UnitServerEvents`, `UnitActionItem:640-643`, `PacketAuth` are gone or delegate; `AbilityServerboundPacket` is documented as `ownerOnly` and unchanged.

## PR body template
```
## What
<one sentence: which step>

## Why
"May command" and "relationship" existed in six versions that disagreed (allies/sandbox/neutral); allied workers could not build; entity-target orders ignored the fog.

## Evidence
- Red commit <sha>, CI run <id>: <test> failed with <message>; green commit <sha>, CI run <id>
- Flake-stress run <id>, [Stress] annotation: "10 runners; 0 with any failure", "<test>: failed 0, passed 10"
  read it with: gh run view <id> --json jobs --jq '.jobs[]|select(.name=="summary")|.databaseId'
  then: gh api repos/IamTheLovish/Beyond-and-Tabs/check-runs/<jobid>/annotations --jq '.[].message'

## Numbers for lovish / questions
- (step 2) allies can now finish and repair each other's sites: ok?
- (step 3) an order on a unit that just entered fog is refused. Keep (a) or add a 20-tick grace (b)?

Do not merge without lovish's OK
```

## Return format (max 200 words)
PR number(s); per GATE the command and one-line result; the list of lovish questions; any packet you found with the same fog hole (name only). Nothing else.
