# Codemap: building
sha: bbbdac21 (bbbdac211d7d355181c00da37dc416b82fa04ff9)   date: 2026-10-27   source: dossier of bar/ at that sha + traps from review/plans/lessons/AGENTS
drift: `git -C D:\btr diff bbbdac21..origin/main --stat -- bar/src/main/java/com/solegendary/reignofnether/building bar/src/main/java/com/solegendary/reignofnether/research`

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

## TRAPS (source tag in brackets: REV overnight-review, LES lessons.md, AGM AGENTS.md, P0xx plans, RUL RULES.md)
- Server sync loop (BuildingServerEvents ~1037-1044) sends ~27k mostly unchanged packets/s; plan 013 adds SyncDelta/BuildingSync; delta must re-send in full when a building BECOMES visible (REV perf, P013).
- getUnitToBuildingRelationship has no ally case: allied workers walk to an ally building and never build (REV F9, P012).
- Fog re-rasterises ~1,700 static buildings every fog tick (REV perf).
- A structure naming an id no mod registers loads as AIR; BuildingBlockModGameTests fails on it. Never copy Macaw/Chipped assets (AGM s4).
- gen_lab_levels.py must reproduce L2/L3 .nbt byte for byte; BuildingParts.java anchors must match tools gen_structures.py rig rows (AGM s4, check_parts.py).
- Client overlay handlers (BuildingClientEvents, PlacementGridClientEvents) must return on ShaderPacks.skipOverlays() (LES gen-005).
- PopulationRules is a pure class tested by JUnit (no world); keep rules there, do not mock the world (AGM s4).
- Temp blocks / saved targets leaked between worlds - fixed in PR #248 (REV, P011).
