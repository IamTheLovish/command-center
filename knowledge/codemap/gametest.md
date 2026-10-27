# Codemap: gametest
sha: bbbdac21 (bbbdac211d7d355181c00da37dc416b82fa04ff9)   date: 2026-10-27   source: dossier of bar/ at that sha + traps from review/plans/lessons/AGENTS
drift: `git -C D:\btr diff bbbdac21..origin/main --stat -- bar/src/main/java/com/solegendary/reignofnether/gametest`

## Purpose
Headless Forge GameTest suites (run via runGameTestServer) covering buildings, commands, big units, heroes, bots, economy and more for the RTS mod. Each suite uses unique owners and the shared `gametest_arena` template.

## Key classes
- `gametest/SkirmishGameTests.java` (15358 lines) [OVER 1000] - core smoke tests: blueprint loading, patch stamping, wrecks, economy, combat, bots (name-based plus heads)
- `gametest/CommandQueueGameTests.java` (1233 lines) [OVER 1000] - command pipeline tests: shift-queue cap, order replacement, fire state, packet handling
- `gametest/BigUnitGameTests.java` (1228 lines) [OVER 1000] - big units and game enders: charge stages, Ward Spire interception, T2/T3 beasts
- `gametest/HeroGameTests.java` (1088 lines) [OVER 1000] - hero slice 2: lab training, XP, boons, ability ranking and casting
- `gametest/MatchLifecycleCases.java` (1062 lines) [OVER 1000] - match lifecycle cases (name-based)
- `gametest/DuelGameTests.java` (1055 lines) [OVER 1000] - duel tests (name-based)
- `gametest/CombatEngineerGameTests.java` (1012 lines) [OVER 1000] - combat engineer tests (name-based)
- `gametest/TargetScanGameTests.java` (956 lines) - target scanning tests (name-based)
- `gametest/WorldMemoryGameTests.java` (833 lines) - world memory tests (name-based)
- `gametest/MergedBuildingGameTests.java` (817 lines) - merged building tests (name-based)
- `gametest/BiomeBaseGameTests.java` (813 lines) - biome base tests (name-based)
- `gametest/BrassworksGameTests.java` (799 lines) - Brassworks faction tests (name-based)
- `gametest/RealmMapGameTests.java` (790 lines) - realm map tests (name-based)
- `gametest/BuildingGridGameTests.java` (743 lines) - building grid tests (name-based)
- `gametest/GameTestShards.java` (?) - holds the only @SubscribeEvent in the area (role unknown, file not in dossier heads)

## Entry points and events
- `@GameTest` methods are the entry points; each suite is a `@GameTestHolder(ReignOfNether.MOD_ID)` class
- `GameTestShards.java` contains one `@SubscribeEvent` handler (details ?)
- Commands and packets: none seen in the dossier for this area (packet files list empty)
- Tests drive `UnitServerEvents.addActionItem` and the command queue directly, not via real packets

## Server vs client
- Server-side: all suites run on the dedicated GameTest server (`./gradlew runGameTestServer`); they use ServerLevel and server resource manager
- Client-side: none seen; no client classes in this area

## Data flow
- Imports from unit (248), building (241), registrars (67), resources (59), ability (39), faction (37), hero (30), player (29), maps (28), match (17)
- Imported by: mixin (1 file)
- Tests read structures from data/ and build blueprints via `BuildingBlockData`

## Instrumentation and tests
- Instrumentation ids: ATTACKER, ATTACK_MOVE, BUILDING_SCAN, ENTITY_SCAN, IDLE_AGGRO, PUSH_SCAN, RETARGET, TARGET_GRID, UNIT_GRID
- GameTest classes: 27 suites (121 files, 49376 lines total in gametest/); see Key classes for the largest

## TRAPS (source tag in brackets: REV overnight-review, LES lessons.md, AGM AGENTS.md, P0xx plans, RUL RULES.md)
- SkirmishGameTests.java is 15,357 lines that every lane edits; split by topic (REV).
- New GameTests go in their own class and in NO shard list (they land in shard 1); tools/check_shards.py fails on duplicates (AGM s4, P011).
- flake-stress jobs finish green even when tests fail: read the summary "[Stress]" annotation (LES gen-011).
- A test failing right after a shard re-cut is a neighbour problem (arenas sit beside batch neighbours): move it, do not retry (AGM s4).
- Load far chunks with GameTestChunks.hold; never setChunkForced/getChunk on ungenerated chunks; poll with bounds, not fixed ticks (AGM s4).
- Known flakes: tools/known_flakes.txt; do not paper over - fix and remove (AGM s4).
