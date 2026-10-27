## Purpose
Performance instrumentation for the server tick and client frame, plus RTS debug overlays (navmesh, path preview, stats) and a task scheduler. Measures per-system cost; behaviour is intended to be read-only.

## Key classes
- `perf/ServerTickProfile.java` (~393 lines) - whole-tick profile, `[Tick]` log, `/rts-perf` recorder
- `perf/Sys.java` (~233 lines) - server-tick per-system timing, `bat:<name>` profiler sections
- `debug/RtsDebugNavmesh.java` (~177 lines) - navmesh score-tile overlay around selected unit
- `perf/FrameParts.java` (~158 lines) - client per-frame section ids and timing facade
- `perf/AnimProfile.java` (~156 lines) - unit body animation/draw profiling (name-based)
- `perf/SysTimer.java` (~153 lines) - self-time accounting for nested Sys sections (name-based)
- `persistence/MatchStateSaveData.java` (~142 lines) - match state saved data (name-based)
- `debug/RtsDebugPathPreview.java` (~129 lines) - path preview debug overlay (name-based)
- `perf/FrameAuto.java` (~124 lines) - automatic client frame capture (name-based)
- `debug/RtsDebugServerEvents.java` (~120 lines) - server-side debug event handlers (name-based)
- `perf/ProfileDump.java` (~120 lines) - profile dump output (name-based)
- `debug/RtsDebugClientEvents.java` (~96 lines) - client-side debug event handlers (name-based)
- `perf/FrameWindow.java` (~95 lines) - client 10 s `[FrameParts]` window writer (name-based)
- `taskscheduler/TickScheduler.java` (~89 lines) - tick-based task scheduler (name-based)
- `perf/BatSections.java` (~85 lines) - profiler section naming (name-based)

## Entry points and events
- `ServerTickProfile.onServerTick` (TickEvent.ServerTickEvent), `onRegisterCommands`, `onServerStopping`
- `/rts-perf [seconds]` command (op level 2)
- `RtsDebugNavmesh.onClientTick` (ClientTickEvent), `onRenderLevel` (RenderLevelStageEvent)
- `TaskSchedulerServerEvents` (2 @SubscribeEvent), `TaskSchedulerClientEvents` (2)
- `RtsDebugStatsClientboundPacket`, `RtsDebugChunksClientboundPacket` (network packets)

## Server vs client
- Server-side: `ServerTickProfile`, `Sys`, `TaskSchedulerServerEvents`, `RtsDebugServerEvents`, `MatchStateSaveData`
- Client-side: `FrameParts`, `FrameWindow`, `FrameAuto`, `TaskSchedulerClientEvents`, `RtsDebugClientEvents`, `RtsDebugNavmesh` (render)

## Data flow
- Imports from other packages: unit (19), orthoview (5), mana (3), network (2), registrars (2), util (2)
- Imported by: unit (16), building (14), ability (5), gametest (5), resources (4), fogofwar (3)
- Uncertain (?): exact direction of each import edge beyond these counts

## Instrumentation and tests
- Sys ids: ATTACKER, DIRTY_SECTIONS, FRAME_SECTIONS, NAMES, SECTIONS, UNIT_BODIES, UNIT_SHADOW (FrameParts/Sys ids as listed in dossier)
- GameTest classes: SkirmishGameTests (10 imports), RegressionGameTests (3), PerfProfileGameTests (2), TargetScanGameTests (2), PerfPushGameTests (1)