## Purpose
Fog of war (per-player vision gating of chunks, entities, and blocks) and ground memory (persistent scorch/crater decals on terrain, synced per chunk). Also pre-game chunk snapshots served to dark players.

## Key classes
- `fogofwar/FogOfWarServerEvents.java` (901 lines) [OVER 1000]? no - 901 lines - server-side per-player vision tiers, fog gating for chunks/entities/blocks
- `worldmemory/GroundMemoryServer.java` (547 lines) - server stamps scorch/craters from blasts, syncs cells to viewers
- `fogofwar/FogChunkSnapshot.java` (509 lines) - disk-backed pre-game chunk snapshots for dark players
- `worldmemory/GroundMemoryClient.java` (407 lines) - client field copies, decay, and per-region decal mesh build/draw
- `fogofwar/FogOfWarClientEvents.java` (377 lines) - client-side fog rendering events
- `worldmemory/GroundMemory.java` (341 lines) - per-chunk scar field and lazy decay
- `worldmemory/ScarRegionMesh.java` (310 lines) - vertex buffer for one 64x64 scar region
- `fogofwar/FogRemesh.java` (275 lines) - fog remesh handling (name-based)
- `worldmemory/DecayParams.java` (210 lines) - decay parameters, defaults and config
- `worldmemory/GroundMemoryClientboundPacket.java` (129 lines) - ground memory sync packet
- `worldmemory/GroundSurface.java` (118 lines) - ground surface sampling (name-based)
- `worldmemory/GroundMemoryCapability.java` (99 lines) - per-chunk capability holding the memory field
- `fogofwar/FogExploration.java` (89 lines) - exploration tracking (name-based)
- `worldmemory/SyncRules.java` (85 lines) - which columns each viewer may receive
- `fogofwar/FogNeutralUnitClientboundPacket.java` (82 lines) - neutral unit fog packet
- `fogofwar/PlayerChunksClientboundPacket.java` (81 lines) - player chunk set packet
- `fogofwar/FogChunksClientboundPacket.java` (78 lines) - fog mask sync packet
- `fogofwar/FogOfWarClientboundPacket.java` (72 lines) - fog state packet

## Entry points and events
- Tick: `GroundMemoryServer.onLevelTick` (LevelTickEvent), sync every 10 ticks
- Tick: `FogChunkSnapshot.tick` (budgeted capture per server tick)
- Chunk/level/player events: `GroundMemoryServer` onChunkLoad, onChunkUnload, onLevelUnload, onPlayerLoggedOut, server start/stop
- Player events: `FogOfWarServerEvents.onPlayerJoin`, `onPlayerDisconnect`, `onPlayerExitOrthoview`
- Packets: FogChunks, FogNeutralUnit, FogOfWar (client and server bound), FrozenChunk, PlayerChunks, GroundMemory client-bound
- Commands: `disable`, `enable`, `rts-fog`

## Server vs client
- Server-only: FogOfWarServerEvents, GroundMemoryServer, FogChunkSnapshot, GroundMemoryCapability, SyncRules
- Client-only: FogOfWarClientEvents, PlayerChunksClientEvents, GroundMemoryClient, ScarRegionMesh, WorldMemoryClientEvents, FogTintingBakedModel, FogTintingBlockColor

## Data flow
- Imports from: registrars (8), unit (8), building (7), network (3), orthoview (3), worldborder (3), perf (3), alliance (2), player (2), config (2)
- Imported by: unit (48), mixin (19), building (11), gametest (8), barfx (4), match (4), matchstart (4), player (4), hero (3), registrars (3)

## Instrumentation and tests
- Instrumentation ids: FOG_OF_WAR, WORLD_MARKERS
- GameTests: WorldMemoryGameTests, HeroGameTests, SkirmishGameTests, AudienceGameTests, FogDefaultGameTests, FogExplorationGameTests, FogHidesEnemiesGameTests, FogSnapshotGameTests