## Purpose
Skirmish bot opponents: BotPlayer runs a full match for an AI RTSPlayer (economy, buildings, army, waves). Also hosts the survival/scenario/sandbox game-mode support packages.

## Key classes
- `bot/BotPlayer.java` (~2885 lines) [OVER 1000] - bot brain; faction kits, economy, building and army decisions per think
- `bot/BotArmy.java` (~632 lines) - army state machine (BUILD_UP, ATTACK, DEFEND, RETREAT)
- `bot/BotCombatEngineers.java` (~409 lines) - engineer training, reclaim/follow orders, forward towers, faction abilities
- `bot/BotGameEnders.java` (~279 lines) - game-ending logic (?)
- `bot/BotEconomy.java` (~268 lines) - economy (name-based)
- `bot/BotServerEvents.java` (~260 lines) - bot server event handlers
- `bot/BotSites.java` (~239 lines) - site selection (name-based)
- `bot/BotSiteWatch.java` (~231 lines) - site watching (name-based)
- `bot/BotDefences.java` (~216 lines) - defence building (name-based)
- `bot/BotStartPick.java` (~88 lines) - start position pick (name-based)
- `bot/BotTuning.java` (~81 lines) - tuning constants (name-based)
- `bot/BotRoles.java` (~80 lines) - bot roles (name-based)
- `survival/SurvivalServerEvents.java` (~356 lines) - survival server events
- `survival/WaveEnemy.java` (~318 lines) - wave enemy (name-based)
- `survival/spawners/WaveSpawner.java` (~213 lines) - wave spawner base (name-based)
- `scenario/ScenarioMenu.java` (~379 lines) - scenario menu (name-based)
- `sandbox/SandboxClientEvents.java` (~464 lines) - sandbox client UI/state

## Entry points and events
- `BotPlayer.think(ServerLevel, long)` - periodic bot tick, roughly once per second; calls BotArmy and BotCombatEngineers
- `BotServerEvents` - 4 @SubscribeEvent handlers
- `SurvivalServerEvents` - 7 @SubscribeEvent handlers
- `ScenarioServerEvents` - 3 @SubscribeEvent handlers; `ScenarioClientEvents` - 2
- `SandboxClientEvents` - 1 @SubscribeEvent handler
- Packets: SandboxServerboundPacket, ScenarioClient/ServerboundPacket, SurvivalClient/ServerboundPacket
- Commands: add, bot, debug-end-wave, debug-next-night, remove

## Server vs client
- Server-side: bot/* (BotPlayer think runs on server thread), survival/*ServerEvents, scenario/ScenarioServerEvents, sandbox/SandboxServer
- Client-side: SandboxClientEvents, ScenarioClientEvents, SurvivalClientEvents

## Data flow
- Imports most from unit (90), building (86), faction (30), player (21), hud (15), registrars (15)
- Imported by gametest (16), building (11), hud (5), player (4), unit (4), commands (3)
- Gametest classes importing this area: SkirmishGameTests (36), BigUnitGameTests (24), BotGameTests (8), DuelGameTests (4)

## Instrumentation and tests
- Instrumentation id: BOTS (FrameParts/Sys ids beyond this: none seen)
- GameTests: SkirmishGameTests, BigUnitGameTests, BotGameTests, DuelGameTests, BrassworksGameTests, TierGateGameTests, CombatEngineerGameTests, HeroAiGameTests