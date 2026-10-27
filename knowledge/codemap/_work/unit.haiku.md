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