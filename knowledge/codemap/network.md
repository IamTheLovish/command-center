# Codemap: network
sha: bbbdac21 (bbbdac211d7d355181c00da37dc416b82fa04ff9)   date: 2026-10-27   source: dossier of bar/ at that sha + traps from review/plans/lessons/AGENTS
drift: `git -C D:\btr diff bbbdac21..origin/main --stat -- bar/src/main/java/com/solegendary/reignofnether/network bar/src/main/java/com/solegendary/reignofnether/registrars bar/src/main/java/com/solegendary/reignofnether/commands bar/src/main/java/com/solegendary/reignofnether/config`

## Purpose
Network, registration and command layer for the mod: packet channel setup, DeferredRegister registries (entities, items, blocks, sounds, game rules), server commands including the rtsapi and command-language systems, and config specs. Central hub for client-server sync.

## Key classes
- `registrars/EntityRegistrar.java` (~1214 lines) [OVER 1000] - DeferredRegister of unit EntityTypes with clientTrackingRange; `getEntityType(String)` lookup
- `commands/CommandsServerEvents.java` (~1092 lines) [OVER 1000] - RegisterCommandsEvent handler; registers rtsapi-* and related commands
- `config/ReignOfNetherCommonConfigs.java` (~730 lines) - ForgeConfigSpec for unit/building costs and [world_memory] block
- `registrars/PacketHandler.java` (~616 lines) - SimpleChannel "main"; registers client/server packet messages in init()
- `commands/rtsapi/PlayerCommands.java` (~533 lines) - rtsapi player command tree (role from name, ?)
- `commands/rtsapi/BuildingCommands.java` (~530 lines) - rtsapi building command tree (name-based)
- `registrars/ItemRegistrar.java` (~529 lines) - item DeferredRegister (name-based)
- `network/Audience.java` (~474 lines) - audience/recipient logic for packets (name-based)
- `commands/lang/IntentExecutor.java` (~412 lines) - executes parsed command-language intents (name-based)
- `commands/lang/CommandLanguage.java` (~403 lines) - command-language parser/front end (name-based)
- `commands/rtsapi/UnitCommands.java` (~398 lines) - rtsapi unit command tree (name-based)
- `registrars/BlockRegistrar.java` (~394 lines) - block DeferredRegister (name-based)
- `commands/rtsapi/argument/BuildingSelectorParser.java` (~382 lines) - parses building selectors (name-based)
- `registrars/SoundRegistrar.java` (~352 lines) - sound event registration (name-based)
- `network/PacketAuth.java` (~199 lines) - packet authentication (name-based)
- `config/ReignOfNetherClientConfigs.java` (~241 lines) - client-side ForgeConfigSpec (name-based)

## Entry points and events
- `@SubscribeEvent` in `commands/CommandsServerEvents.java`: `onRegisterCommands(RegisterCommandsEvent)`
- `@SubscribeEvent` in `config/ConfigClientEvents.java` (2 handlers)
- `@SubscribeEvent` in `config/DisplaySettings.java` (1), `config/ConfigVanillaServerEvents.java` (1)
- `@SubscribeEvent` in `commands/lang/CommandBarClientEvents.java` (1)
- Packets (registered in `registrars/PacketHandler.java`): TopdownGuiServerbound, UnitActionServerbound, UnitSyncServerbound, plus many UnitSync/Beacon/Unit* clientbound packets; also `config/ClientboundSyncResourceCostPacket.java`, `network/PacketAuth.java`
- Commands: rtsapi-place-building, rtsapi-destroy-building, rtsapi-set-unit-owner, and the rtsapi/lang command set (action, move, attack-related literals, etc.)

## Server vs client
- Server-side: `commands/CommandsServerEvents.java`, `commands/rtsapi/*`, `registrars/ServerEventRegistrar.java`, `config/ConfigVanillaServerEvents.java`
- Client-side: `config/ConfigClientEvents.java`, `commands/lang/CommandBarClientEvents.java`, `registrars/ClientEventRegistrar.java`, `config/DisplaySettingsScreen.java`, `config/ReignOfNetherConfigScreen.java`

## Data flow
- Imports most from `unit` (52), `building` (39), `resources` (24), `player` (17), `hud` (13), `hero` (10), `orthoview` (9), `items` (9), `ability` (8), `fogofwar` (8)
- Imported by `unit` (317), `gametest` (66), `building` (36), `ability` (20), `blocks` (16), `hero` (14), `hud` (14), `mixin` (12), `resources` (12), `player` (10)
- Acts as a hub: registries and packets are consumed by unit/building logic; unit package is the heaviest coupling in both directions.

## Instrumentation and tests
- Instrumentation ids: none seen
- GameTest classes (by import count): SkirmishGameTests (372), BrassworksGameTests (29), BotGameTests (6), AudienceGameTests (4), BlueprintGameTests (3), AttackMoveGameTests (2), CommandLanguageGameTests (2), H13GameTests (2)

## TRAPS (source tag in brackets: REV overnight-review, LES lessons.md, AGM AGENTS.md, P0xx plans, RUL RULES.md)
- Two dev builds could connect and silently mis-decode packets; fix = protocol hash from the packet table (REV headline 2; PacketHandler PROTOCOL_VERSION).
- Permission holes on /rts-fog and /bot remove (REV headline 2).
- Audience.java has the pure Facts interface (allied, commandersOf, spectator, mayCommand) and mayKnow; reuse, do not add a 5th copy (P012).
- Client imports in server code: run tools/check_server_client_imports.py (in prepush) (P011-P014).
- New server events register in registrars/ServerEventRegistrar (P014). Test gap: packet fuzz and commands (REV tools/CI).
