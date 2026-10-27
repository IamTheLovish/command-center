# Codemap: unit
sha: bbbdac21 (bbbdac211d7d355181c00da37dc416b82fa04ff9)   date: 2026-10-27   source: dossier of bar/ at that sha + traps from review/plans/lessons/AGENTS
drift: `git -C D:\btr diff bbbdac21..origin/main --stat -- bar/src/main/java/com/solegendary/reignofnether/unit`

## Purpose
Unit entity system for the RTS: unit types (villagers, piglins, monsters, tide/storm/brass units), their interfaces, AI goals, pathfinding, modelling/animation, and unit command/packet plumbing.
Largest area in the mod by line count (106377 lines across 648 files); most logic lives in `unit/units/` and `unit/modelling/`.

## Key classes
- `unit/UnitClientEvents.java` (~2183) [OVER 1000] - client-side selection, command issuing, render hooks
- `unit/UnitServerEvents.java` (~1344) [OVER 1000] - server ticks, unit join/leave/death, formation moves, command queue adapters
- `unit/interfaces/Unit.java` (~1176) [OVER 1000] - default-method interface giving units shared attributes, tick, item pickup, save data
- `unit/modelling/animations/MarauderAnimations.java` (~917) - marauder animation definitions
- `unit/modelling/animations/WildfireAnimations.java` (~872) - wildfire animation definitions
- `unit/units/monsters/WretchedWraithUnit.java` (~844) - wretched wraith unit (name-based)
- `unit/units/villagers/RoyalGuardUnit.java` (~816) - royal guard unit (name-based)
- `unit/units/piglins/WildfireUnit.java` (~732) - wildfire unit (name-based)
- `unit/UnitActionItem.java` (~728) - queued unit action item (name-based)
- `unit/units/villagers/EnchanterUnit.java` (~660) - enchanter unit (name-based)
- `unit/support/SupportBrain.java` (~658) - support unit AI brain (name-based)
- `unit/interfaces/AttackerUnit.java` (~620) - attacker-unit interface (name-based)
- `unit/goals/GatherResourcesGoal.java` (~596) - resource gathering AI goal (name-based)
- `unit/units/tide/LeviathanUnit.java` (~650) - leviathan unit (name-based)
- `unit/units/storm/CelestialDragonUnit.java` (~643) - celestial dragon unit (name-based)

## Entry points and events
- `UnitClientEvents` - 21 `@SubscribeEvent` handlers (includes `onRenderLevel` and `onEntityMount`)
- `UnitServerEvents` - 20 `@SubscribeEvent` handlers (`onServerTick`, `onServerStopping`, `onServerStarted`, `onEntityJoin`, `onEntityLeave`, `onLivingDeath`, `onDropItem`, `onFormationDispatchTick`)
- Packets (16 in `unit/packets/` plus `unit/reactions/ReactionClientboundPacket.java`), e.g. `UnitActionServerboundPacket`, `UnitSyncClientboundPacket`, `UnitPathClientboundPacket`
- Command: `rts-veteran`
- Other `@SubscribeEvent` files: `UnitKills`, `PathfinderWorkerPool`, `UnitQueueSync`, `MomentumServerEvents`, `DragonRaiseServerEvents`, `VeterancyServerEvents`, `TargetScan`, `T3ServerEvents`, `PatrolServerEvents`, `NonUnitServerEvents`

## Server vs client
- Server-only (by name and dossier): `UnitServerEvents`, `*ServerEvents` classes, `UnitSyncServerboundPacket` handling, `saveFallenHeroUnits`/`saveGatherTargets`
- Client-only (by name): `UnitClientEvents` (selection, rendering, mouse input)
- Shared: `interfaces/Unit`, unit classes, packets

## Data flow
- Imports from other packages: `building` (622), `resources` (597), `ability` (396), `registrars` (367), `keybinds` (144), `hud` (131), `util` (82), `research` (49), `fogofwar` (48), `alliance` (40)
- Imported by: `ability` (154), `gametest` (72), `building` (56), `mixin` (34), `hud` (24), `hero` (19), `entities` (14), `items` (13), `research` (12), `blocks` (10)

## Instrumentation and tests
- FrameParts/Sys ids: ATTACKER, ATTACK_MOVE, AUTO_CASTER, BUILDING_SCAN, CHUNK_LOADER, COMMAND_QUEUES, ENTITY_SCAN, IDLE_AGGRO, MOUNT_SCAN, NEUTRAL_AGGRO, PATHFINDER, PUSH_SCAN, REACTIONS, RETARGET, SEPARATION, STUCK_NUDGE, TARGET_GRID, UNIT, UNIT_GRID, UNIT_OVERLAYS, UNIT_SYNC, UNIT_TICK, UNSTICK
- GameTest classes (by import count): SkirmishGameTests (387), BigUnitGameTests (35), BrassworksGameTests (32), OrdersObeyGameTests (17), T3RoleGameTests (16), CommandQueueGameTests (15), CombatEngineerGameTests (14), BigUnitFeelGameTests (11)

## TRAPS (source tag in brackets: REV overnight-review, LES lessons.md, AGM AGENTS.md, P0xx plans, RUL RULES.md)
- F7: ATTACK/FOLLOW/entity-ability orders (UnitActionItem ~383-396, 434-439, 557-562) do not check fog; a modified client can target through fog by id (REV F7, P012).
- UnitActionItem and BuildingServerEvents are already long: plan 012 demands net change <= 0 lines there (P012).
- New UnitAction enum values go at the END of the enum (AGM s4).
- Unit damage bypasses vanilla: LivingEntityMixin.actuallyHurt; BOTH LivingHurtEvent and LivingDamageEvent fire; Ward/Lantern Dome/Brass shield rely on the hurt event (AGM s4).
- Per-match state not reset on rematch: UnitKills dirty/ids/counts (stop handler clears only dirty), kills, bot brains (REV R1, P011).
- Never hand-edit unit/modelling/models/gen/ - change the generator in tools/ and re-export (AGM s7).
- Entity flags (isInWater, on-ground) refresh on the entity OWN next tick, not on teleportTo; wait 1-2 ticks in tests (AGM s4).
- Units autocast by default; tests counting energy/cooldowns must AutocastState.setAll(unit,false) (AGM s4).
- Cost hot spots: close-zoom bodies 38 ms at zoom 30; move packets every 3 ticks ~100k/s at 8v8 (REV perf; instanced-units plan).
- UnitServerEvents is edited by perf PR #247 and security PR #248 - rebase, do not redo (P011, P013, P014).
