# Codemap: minimap-orthoview
sha: bbbdac21 (bbbdac211d7d355181c00da37dc416b82fa04ff9)   date: 2026-10-27   source: dossier of bar/ at that sha + traps from review/plans/lessons/AGENTS
drift: `git -C D:\btr diff bbbdac21..origin/main --stat -- bar/src/main/java/com/solegendary/reignofnether/minimap bar/src/main/java/com/solegendary/reignofnether/orthoview bar/src/main/java/com/solegendary/reignofnether/maps bar/src/main/java/com/solegendary/reignofnether/rtsmap`

## Purpose
Client-side RTS camera (orthoview), minimap, strategic zoom icons, and procedural map generation/layout for the Beyond and Tabs battlefield. Covers map spec (MapLayout), map build/match/start phases, and RTS map info sync.

## Key classes
- `minimap/MinimapClientEvents.java` (~1729 lines) [OVER 1000] - minimap rendering, map markers, virtual units, size toggling
- `orthoview/OrthoviewClientEvents.java` (~1404 lines) [OVER 1000] - RTS camera: zoom, yaw/tilt springs, pan, glides
- `maps/MapLayout.java` (~1369 lines) [OVER 1000] - deterministic symmetric battlefield spec (slots, boxes, mexes, sites)
- `orthoview/StrategicViewClientEvents.java` (~1034 lines) [OVER 1000] - strategic zoom: unit/building icons, range rings, selection rings
- `maps/MapClient.java` (~758 lines) - client-side map state handling (roles inferred from name, name-based)
- `maps/MapBuilder.java` (~750 lines) - builds map terrain in the world (name-based)
- `maps/StartPhase.java` (~572 lines) - start-phase handling (name-based)
- `maps/StartMarkers.java` (~518 lines) - start position markers (name-based)
- `minimap/MapDrawClientEvents.java` (~441 lines) - minimap draw events (name-based)
- `maps/MapMatch.java` (~295 lines) - match-level map state (name-based)
- `maps/ExtractorClearance.java` (~179 lines) - extractor clearing (name-based)
- `maps/MapStateClientboundPacket.java` (~167 lines) - map state sync packet
- `orthoview/CameraFadeClientEvents.java` (~148 lines) - camera fade effects (name-based)
- `rtsmap/RTSMapInfoServerEvents.java` (~83 lines) - server events for RTS map info (name-based)
- `rtsmap/RTSMapInfo.java` (~68 lines) - RTS map info data (name-based)

## Entry points and events
- @SubscribeEvent: OrthoviewClientEvents (13), MinimapClientEvents (7), MapDrawClientEvents (7), MapClient (5), StrategicViewClientEvents (4), StartPhase (4), CameraFadeClientEvents (3), RTSMapInfoServerEvents (2), MapMatch (2), MapBuilder (2)
- Packets: MapStateClientboundPacket, StartPhaseServerboundPacket, MapDrawClientboundPacket, MapDrawServerboundPacket, MapMarkerClientboundPacket, MapMarkerServerboundPacket, CameraClientboundPacket, CameraFadeClientboundPacket, RTSMapInfoClientboundPacket, RTSMapInfoServerboundPacket
- Commands: none seen
- Per-frame camera integrator: `OrthoviewClientEvents.updateCamera` (per the class doc)

## Server vs client
- Client-only: MinimapClientEvents, OrthoviewClientEvents, StrategicViewClientEvents, MapDrawClientEvents, CameraFadeClientEvents, RTSMapInfoClientEvents (name-based)
- Server-side: RTSMapInfoServerEvents (name-based); packets are bidirectional, so both sides exist. The server accepts orthoview movement from any client (per the class doc).

## Data flow
- Imports from: building (37), startpos (16), hud (15), player (11), util (11), registrars (10), matchstart (8), unit (8), match (7), sounds (6)
- Imported by: hud (17), mixin (17), gametest (13), matchstart (13), building (12), match (6), unit (6), commands (4), player (4), resources (4)
- Mixins (17) import this area, so camera and minimap behaviour is reached via mixins into vanilla/HUD code.

## Instrumentation and tests
- Instrumentation ids: MINIMAP, STRATEGIC_ICONS, UNIT_RINGS, WORLD_MARKERS
- GameTest classes (by import count): SkirmishGameTests (44), MapExtraMetalGameTests (4), MapMetalGameTests (4), MatchLifecycleCases (4), SpawnReadyGameTests (4), BotGameTests (3), MapRimGameTests (3), RealmMapGameTests (3)

## TRAPS (source tag in brackets: REV overnight-review, LES lessons.md, AGM AGENTS.md, P0xx plans, RUL RULES.md)
- Minimap allocated ~18 MB/s garbage before the perf PR (REV perf, PR #247).
- Shadow-pass and minimap timing sections were added so the next perf round can measure (REV).
- Level-render overlays here must return on ShaderPacks.skipOverlays() (LES gen-005).
- Camera maths has a checker: tools/camera_math_check.py (tools list).
