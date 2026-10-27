## Purpose
Skirmish match setup, lobby, start positions, world border, gamerules and game-mode plumbing for the RTS: the lobby screens, the multiplayer lobby, spawn/start-pos placement and the match state machine.
Largest area by far (17834 lines); the biggest single file is EyesDirector (CI screenshot tour, dev-only).

## Key classes
- `matchstart/EyesDirector.java` (2288) - scripted CI screenshot tour, only with -Dbat.eyes=true [OVER 1000]
- `matchstart/MatchStartScreen.java` (984) - pre-match start screen: map, roster, chat, ready
- `matchstart/MultiplayerLobby.java` (912) - server-authoritative multiplayer lobby, seats, start/spectate
- `matchstart/MultiplayerLobbyScreen.java` (673) - client view of the lobby; sends clicks to server
- `match/MatchState.java` (668) - match state (?) - name-based
- `startpos/CapturePointServerEvents.java` (659) - server events for capture points (name-based)
- `matchstart/MatchLoadingScreen.java` (640) - loading screen during match start (name-based)
- `matchstart/SkirmishSetupScreen.java` (615) - skirmish setup UI (name-based)
- `matchstart/MatchEndScreen.java` (514) - end-of-match screen (name-based)
- `match/MatchPrep.java` (499) - match preparation (name-based)
- `startpos/BattlefieldWall.java` (468) - battlefield wall setup (name-based)
- `matchstart/EyesOverlaysScene.java` (464) - eyes-tour overlays scene (name-based)
- `startpos/StartAreaClearing.java` (399) - clears start areas (name-based)
- `startpos/ArenaStructureClearing.java` (398) - clears arena structures (name-based)
- `matchstart/SkirmishServerboundPacket.java` (356) - client-to-server skirmish setup packet
- `match/MatchOutcome.java` (350) - match outcome (name-based)

## Entry points and events
- Forge `@SubscribeEvent` handlers: StartPosServerEvents (6), MatchLoadingScreen (6), ArenaStructureClearing (5), MultiplayerLobby (5), MatchServerEvents (5)
- MultiplayerLobby tick/join/leave/stop: `onServerTick`, `onPlayerJoin`, `onPlayerLeave`, `onServerStopping`
- Packets: LobbyClient/ServerboundPacket, SkirmishServerboundPacket, StartPos Client/ServerboundPacket, GameruleClient/ServerboundPacket, GameModeClient/ServerboundPacket, CapturePointsClientboundPacket
- Commands: `close`, `rts-lobby`

## Server vs client
- Server-side (judged from names): MultiplayerLobby, StartPosServerEvents, CapturePointServerEvents, GameruleServerEvents, MatchServerEvents, ArenaStructureClearing
- Client-side (judged from names): MultiplayerLobbyScreen, MatchStartScreen, StartPosClientEvents, GameruleClient, ClientGameModeHelper, EyesDirector/EyesOverlaysScene (dev-only)

## Data flow
- Imports most from: player (43), unit (32), faction (27), registrars (21), building (20), maps (17), hud (16)
- Imported by: gametest (15), building (9), maps (8), hud (5), onboarding (5), player (5), fogofwar (4), mixin (4)
- gametest imports are the main downstream consumer (SkirmishGameTests: 81 imports)

## Instrumentation and tests
- FrameParts/Sys ids: BUILDING_BOXES, BUILDING_DECOR, MARKERS_METAL, MARKERS_RANGE, MINIMAP, STRATEGIC_ICONS, UNIT_BODIES, UNIT_OVERLAYS, UNIT_RINGS, WORLD_MARKERS
- GameTest classes: SkirmishGameTests (81 imports), MatchLifecycleCases (9), MatchPrepCases (8), SandboxSecurityGameTests (5), FogDefaultGameTests (4), DayClockGameTests (3), BotGameTests (2), LobbyColorsGameTests (2)