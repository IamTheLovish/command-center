## Purpose
Building subsystem: placement, construction and per-faction building logic for the Reign of Nether RTS, plus the research tree. Covers ghost/placement previews, server-side construction progress, biome-adaptive palettes, merged and custom buildings.

## Key classes
- `building/BuildingPlacement.java` (~2009) [OVER 1000] - per-building state: blocks, construction progress, build queue, ownership
- `building/BuildingServerEvents.java` (~1279) [OVER 1000] - server-side placement validation, construction start, tick, save/load
- `building/BuildingClientEvents.java` (~1202) [OVER 1000] - client selection, ghost placement preview, building render hooks
- `building/BiomePalette.java` (~771) - per-faction, per-biome block substitution applied at placement
- `building/buildings/placements/ProductionPlacement.java` (~725) - production building placement (name-based)
- `building/custombuilding/CustomBuildingMenu.java` (~686) - custom building menu UI (name-based)
- `building/PartRenderClientEvents.java` (~664) - client render of building parts (name-based)
- `building/custombuilding/CustomBuilding.java` (~585) - custom building definition (name-based)
- `building/merge/MergedBuildings.java` (~566) - merging adjacent buildings (name-based)
- `building/FactionAura.java` (~524) - faction aura effect (name-based)
- `building/BuildingValidators.java` (~469) - placement validity checks (name-based)
- `building/gameender/GameEnderPlacement.java` (~465) - Game Ender building placement (name-based)
- `building/BuildingGrid.java` (~381) - spatial grid over placed buildings (name-based)
- `building/BuildingClientboundPacket.java` (~369) - server-to-client building sync packet (name-based)

## Entry points and events
- Server tick: `BuildingServerEvents.onServerTick` / `onWorldTick` (TickEvent)
- Server lifecycle: `loadBuildingsAndNetherZones` (ServerStartedEvent), `onServerStopping`, `onPlayerJoin`
- Block/world events: `onPlayerBlockBreak`, `onExplosion`, `onCropTrample`, `onLivingSpawn`
- Client render: `BuildingClientEvents.onRenderLevel` (RenderLevelStageEvent), `onRenderOverLay` (RenderGuiOverlayEvent)
- Packets (13 files): `BuildingServerboundPacket`, `BuildingClientboundPacket`, `BuildingBatchServerboundPacket`, `BuildingHoverServer/ClientboundPacket`, `BuildingProductionServer/ClientboundPacket`, `BlueprintClientboundPacket`, `FogBuildingClientboundPacket`, `CustomBuildingServer/ClientboundPacket`, `ResearchServer/ClientboundPacket`
- Commands: none seen in dossier

## Server vs client
- Server-only: `BuildingServerEvents`, `FactionAuraServerEvents`, `custombuilding/CustomBuildingServerEvents`, `gameender/GameEnderServerEvents`, `research/ResearchServerEvents`, `StewardServerEvents`
- Client-only: `BuildingClientEvents`, `PartRenderClientEvents`, `WindmillRenderClientEvents`, `ScaffoldRenderClientEvents`, `BuildingLineClientEvents`, `BuildingAmbienceClientEvents`, `custombuilding/CustomBuildingClientEvents`, `StatueRenderClientEvents`, `PatchQuickBuildClientEvents`
- Shared logic (both sides): `BuildingPlacement`, `BiomePalette`, `BuildingGrid` (name-based)

## Data flow
- Imports most from: `resources` (359), `keybinds` (209), `unit` (136), `api` (89), `registrars` (43), `util` (39), `ability` (38), `hud` (35), `tutorial` (30), `faction` (24)
- Imported by: `unit` (156), `ability` (59), `gametest` (52), `hud` (26), `mixin` (13), `commands` (11), `bot` (9), `resources` (9), `survival` (8), `items` (7)
- Heaviest external coupling is to `unit` (both directions) and `ability`.

## Instrumentation and tests
- Instrumentation ids: BUILDINGS, BUILDING_BOXES, BUILDING_DECOR, BUILDING_PARTS, WORLD_MARKERS
- GameTest classes (by import count): SkirmishGameTests (379), BrassworksGameTests (43), BigUnitGameTests (28), BiomeBaseGameTests (13), BotGameTests (13), DefenceGameTests (13), RegressionGameTests (13), TierGateGameTests (13)