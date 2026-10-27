# Codemap INDEX (Beyond and Tabs)
sha: bbbdac21 (bbbdac211d7d355181c00da37dc416b82fa04ff9), date 2026-10-27. origin/main had already moved to 50572230 when this was built: run each file's `drift:` command before trusting line counts.
Class paths below are relative to `bar/src/main/java/com/solegendary/reignofnether/` unless they start with tools/ or .github/. ~2,000 java files, ~349k lines. Read INDEX, then ONE area file (max ~60 lines each). Rebuild recipe: `knowledge\codemap\_work\` (dossier.py, run.ps1, assemble.py, traps.py).

## Areas (one line each)
- unit.md - units, orders, targeting, sync, formations, models/animation (648 files, 106k lines)
- pathfinding.md - custom grid A*, worker pool, vanilla path budget (unit/pathfinding)
- ability.md - abilities, autocast, mana, enchantments
- building.md - buildings, placement, production, population, research, structures
- bot.md - skirmish bots, survival waves, scenarios, sandbox
- hero.md - heroes, possession (first-person), kits, progression, fallen heroes
- fogofwar.md - server visibility, chunk gating, snapshots, ground memory scars
- hud.md - HUD, command card, keybinds, onboarding, tutorial
- minimap-orthoview.md - RTS camera, minimap, maps
- match.md - lobby, match lifecycle, start positions, world border, EyesDirector
- player-alliance-time.md - player saves, alliances, factions, day/night, tides
- network.md - PacketHandler, Audience (who may know/command), registrars, commands, config
- economy.md - BAR flow economy, metal patches, items
- gametest.md - the headless GameTest suite (121 files, 49k lines)
- blocks-fx.md - custom blocks, ShaderPacks, barfx, particles, sounds
- perf.md - Sys / FrameParts instrumentation, task scheduler, debug, persistence
- mixin-misc.md - mixins, entities, compat, util, launcher
- tools-ci.md - tools/*.py, prepush, workflows, shards, flake list
- legacy-mod-engine.md - old prototype, reference only

## How to find X
| Feature / question | Area file | Key class or file |
|---|---|---|
| Possession (drop into a unit, first person) | hero | hero/PossessionServer, PossessionClientEvents, PossessionClientboundPacket |
| Hero AI | hero | hero/HeroBot, HeroCore; tests gametest/HeroAiGameTests |
| Hero kits, XP, revive | hero | hero/HeroKits, HeroProgression, HeroServerEvents |
| Fog of war server rule | fogofwar | fogofwar/FogOfWarServerEvents |
| Fog client tint / mesh | fogofwar | fogofwar/FogOfWarClientEvents, FogRemesh |
| Ground scars / decals | fogofwar | worldmemory/GroundMemoryServer, GroundMemoryClient |
| Packet registration + protocol version | network | registrars/PacketHandler |
| Who may see / command what | network | network/Audience (pure Facts), unit/Relationship |
| Server/client event registration | network | registrars/ServerEventRegistrar |
| Chat/RTS commands, typed command bar | network | commands/CommandsServerEvents, commands/lang/CommandLanguage |
| Unit orders (move/attack/follow) | unit | unit/UnitActionItem, UnitServerEvents, UnitClientEvents |
| Targeting / spatial queries | unit | unit/TargetScan, UnitGrid |
| Concealment (cloak, burrow) | unit | unit/Concealment |
| Unit position sync to clients | unit | unit/UnitSyncBatcher |
| Terrain effects (wading, banks) | unit | unit/Terrain |
| Pathfinding | pathfinding | unit/pathfinding/RtsPathfinder, GridAStar, PathfinderWorkerPool |
| Unit models + animation | unit | unit/modelling/ (never edit models/gen/; use tools/dsl_to_game.py) |
| Abilities and autocast | ability | ability/AutoCaster, AutocastState; mana/ManaServerEvents |
| Building placement | building | building/BuildingPlacement, BuildingClientEvents |
| Building server logic + sync | building | building/BuildingServerEvents (very long) |
| Population rules | building | building/production/PopulationRules |
| Research | building | research/ResearchServerEvents |
| Economy (metal/energy, extractors) | economy | resources/EconomyServerEvents, EconomyMath, MetalPatches |
| Bots | bot | bot/BotServerEvents, BotPlayer, BotEconomy, BotArmy |
| Survival waves | bot | survival/SurvivalServerEvents, Wave |
| HUD and command card | hud | hud/HudClientEvents (1,785-line drawHud), hud/CommandCard |
| Keybinds | hud | keybinds/Keybindings, KeybindsClientEvents |
| Minimap | minimap-orthoview | minimap/MinimapClientEvents |
| RTS camera | minimap-orthoview | orthoview/OrthoviewClientEvents |
| Match lifecycle / rematch reset | match | match/MatchServerEvents, MatchState, MatchPhase |
| Lobby and start screens | match | matchstart/ (SkirmishSetupScreen), startpos/StartPos |
| World border gate (isRtsOptimisedMap) | match | worldborder/WorldBorderServerEvents |
| Eyes (CI screenshot tour) | match + tools-ci | matchstart/EyesDirector, .github/workflows/eyes.yml |
| Alliances | player-alliance-time | alliance/AlliancesServerEvents, AllyCommand |
| Save / persistence | player-alliance-time + perf | player/PlayerServerEvents, persistence/MatchStateSaveData |
| Day/night | player-alliance-time | time/TimeServerEvents; match/DayCycle |
| Shader-pack handling | blocks-fx | postfx/ShaderPacks (skipOverlays) |
| Effects layer | blocks-fx | barfx/BarFxClientEvents |
| Perf timing sections | perf | perf/Sys (server), perf/FrameParts (client) |
| Damage path | mixin-misc | mixin/LivingEntityMixin (actuallyHurt) |
| GameTests: where, how | gametest | gametest/ArenaReady, SkirmishGameTests (15k lines) |
| CI shards | tools-ci | .github/workflows/build.yml SHARD_n lines, tools/check_shards.py |
| Flake list | tools-ci | tools/known_flakes.txt, tools/ci_wait.py |
| Before pushing | tools-ci | tools/prepush.sh, tools/check_server_client_imports.py |
| Claim a task | tools-ci | tools/claim.py |
| Old prototype | legacy-mod-engine | mod/, engine/ (not shipped) |
