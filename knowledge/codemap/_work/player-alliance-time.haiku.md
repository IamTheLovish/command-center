## Purpose
Covers player lifecycle and RTS match state (who plays, joins, leaves, commanders, alliances, resign votes, stats), plus the time-of-day/clock client and server hooks, faction definitions and traits, the Tidewrought tide/tidepool system, and wind environment effects. The largest concern is PlayerServerEvents (1467 lines).

## Key classes
- `player/PlayerServerEvents.java` (1467 lines) [OVER 1000] - server hub for the RTS player list, start/join/leave, tick, and match delegates
- `faction/Factions.java` (641) - faction registry, entity-to-faction mapping, playable faction constants
- `tide/TidepoolServerEvents.java` (640) - tidepool registry: raise, drain, evaporate, expiry, caps, save/restore
- `player/PlayerClientEvents.java` (577) - client RTS player lookup, spectator check, client-side player state
- `player/PlayerServerboundPacket.java` (391) - client-to-server player packet (role inferred from name)
- `faction/FactionTraits.java` (370) - faction trait definitions (role from name)
- `player/PlayerPanelServerEvents.java` (321) - server handling of player panel state (name-based)
- `player/CommanderServerEvents.java` (310) - commander server events (name-based)
- `time/TimeClientEvents.java` (267) - client time-of-day handling (name-based)
- `player/CommanderAntiAir.java` (261) - commander anti-air logic (name-based)
- `player/PlayerColors.java` (255) - player colour assignment (name-based)
- `player/ResignVoteServerEvents.java` (225) - server resign vote handling (name-based)
- `alliance/AllyCommand.java` (219) - /ally command implementation (name-based)
- `player/PlayerClientboundPacket.java` (215) - server-to-client player packet (name-based)
- `player/RTSPlayer.java` (177) - RTS player record (name-based)
- `faction/Faction.java` (185) - faction object: icons, sound, spawn wave, traits (from head)

## Entry points and events
- Server tick: `PlayerServerEvents.onServerTick(TickEvent.ServerTickEvent)`
- Login/logout: `PlayerServerEvents.onPlayerJoin` / `onPlayerLeave` (PlayerEvent handlers)
- Server start/stop: `onServerStarted` / `onServerStopping`
- @SubscribeEvent counts: PlayerClientEvents 11, PlayerServerEvents 8, TimeClientEvents 5, TidesServerEvents 3, TidepoolServerEvents 3, ResignVoteClientEvents 3
- Packets: AllianceClientbound/Serverbound, MatchStatsClientbound, PlayerClientbound/Serverbound, PlayerPanelClientbound
- Commands: ally, allycancelrequest, allyconfirm, allycontrol, disable, disband, enable, rts-camera, rts-controls, rts-help, rts-lock, rts-scores, rts-surrender, rts-syncing, rts-tidepool

## Server vs client
- Server-side: PlayerServerEvents, TidepoolServerEvents, TidesServerEvents, FogBankServerEvents, CommanderServerEvents, ResignVoteServerEvents, DefeatCleanupServerEvents, PlayerPanelServerEvents, TimeServerEvents, AlliancesServerEvents
- Client-side: PlayerClientEvents, TimeClientEvents, ResignVoteClientEvents, CommanderClientEvents, AlliancesClient, BranchWindClient (judged from names and dossier)

## Data flow
- Imports from: building (34), unit (32), registrars (20), resources (14), ability (13), hud (12), survival (12), scenario (8), gamemode (7), sounds (7)
- Imported by: unit (99), building (42), gametest (40), ability (28), hud (22), matchstart (18), mixin (11), bot (9), hero (8), mana (8)
- PlayerServerEvents delegates match lifecycle to the match package (MatchState, MatchRoster, MatchOutcome, Spectators); the match package itself is not in this area's dossier.

## Instrumentation and tests
- FrameParts/Sys ids: none seen
- GameTest classes (by import count): SkirmishGameTests (266), MatchLifecycleCases (14), BigUnitGameTests (9), CommanderAntiAirGameTests (5), RegressionGameTests (5), SandboxSecurityGameTests (5), TierGateGameTests (5), BranchWindGameTests (4)