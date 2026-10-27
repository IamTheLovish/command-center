# Codemap: pathfinding
sha: bbbdac21 (bbbdac211d7d355181c00da37dc416b82fa04ff9)   date: 2026-10-27   source: dossier of bar/ at that sha + traps from review/plans/lessons/AGENTS
drift: `git -C D:\btr diff bbbdac21..origin/main --stat -- bar/src/main/java/com/solegendary/reignofnether/unit/pathfinding`

## Purpose
Server-side RTS pathfinding for units: builds a walkability grid from world chunks, runs grid A* (with a 2x2 footprint and climbing rules), and converts results to vanilla Path objects. Work is dispatched to a daemon worker-thread pool (fixed-size, resizable via the `pathfindingThreads` gamerule).

## Key classes
- `unit/pathfinding/PathfinderWorkerPool.java` (385 lines) - worker pool, build queue, server start/stop/tick handlers
- `unit/pathfinding/GridNeighbors.java` (273 lines) - shared 20-neighbour movement model, wide-unit footprint and crowding tests
- `unit/pathfinding/PathConverter.java` (251 lines) - converts waypoints to MC Path, wall-press and drop-clear offsets
- `unit/pathfinding/GridAStar.java` (245 lines) - 3D A* search over GridNeighbors, climb-move table
- `unit/pathfinding/WalkabilityGrid.java` (210 lines) - walkability grid storage (name-based)
- `unit/pathfinding/RtsPathfinder.java` (197 lines) - pathfinder entry (name-based)
- `unit/pathfinding/WalkabilityGridChunk.java` (196 lines) - per-chunk walkability (name-based)
- `unit/pathfinding/WalkabilityBuilder.java` (192 lines) - builds walkability from world data (name-based)
- `unit/pathfinding/ChunkSnapshot.java` (107 lines) - chunk snapshot (name-based)
- `unit/pathfinding/PathfinderConfig.java` (106 lines) - pathfinder config (name-based)
- `unit/pathfinding/VanillaPathBudget.java` (73 lines) - vanilla path budget (name-based)
- `unit/pathfinding/MobilityClass.java` (68 lines) - mobility enum (name-based)
- `unit/pathfinding/WalkabilityView.java` (29 lines) - walkability view interface (name-based)
- `unit/pathfinding/PathCallback.java` (17 lines) - result callback (name-based)

## Entry points and events
- `PathfinderWorkerPool.onServerStart` (ServerStartingEvent) - creates pool, applies chunk-build budget
- `PathfinderWorkerPool.onServerStop` (ServerStoppingEvent) - shutdown
- `PathfinderWorkerPool.onServerTick` / `serverTick` (ServerTickEvent) - applies pending resize, processes build queue, dispatches
- `PathfinderWorkerPool.submit(...)` - public request entry point
- `requestResize(int)`, `setChunkBuildsPerTick(int)` - gamerule-driven settings

## Server vs client
- Server-only: `PathfinderWorkerPool` (server lifecycle events, main-thread build queue). Pathfinding grid building must run on the server main thread.
- Client-only: none seen in dossier.

## Data flow
- Imports from `unit` (7), `items` (2), `blocks` (2), `util` (2), `tide`, `debug`, `perf`, `registrars`, `resources` (1 each).
- IMPORTED BY: none recorded in dossier (?).
- `PathfinderWorkerPool` reads `GameRuleRegistrar.PATHFINDING_CHUNK_BUILDS`.

## Instrumentation and tests
- Instrumentation id: PATHFINDER
- GameTest classes: none seen

## TRAPS (source tag in brackets: REV overnight-review, LES lessons.md, AGM AGENTS.md, P0xx plans, RUL RULES.md)
- Real matches never set a world border, so anything gated on isRtsOptimisedMap() was OFF in play (rtsPathfinding). Check gates against what a real match does (LES gen-005).
- vanilla_path_* GameTests are on the flake list; Sys.force per-holder holds fixed a shared measuring flag switched off by another test (P015, PR #239).
- Lookup-budget thresholds (UNITS*40/2) flaked at 696 of 1600 lookups; fix root cause, do not widen (P015).
- Tests that move units: use gametest/ArenaReady (glass pad in the sky) to remove terrain and neighbour effects (P015).
