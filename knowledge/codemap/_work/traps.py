# area -> (packages as repo-relative prefixes under reignofnether, one-line purpose for entries.jsonl, traps)
# source tags: REV=briefs/overnight-review-2026-10-26.md  LES=command-center/lessons.md  AGM=btr/AGENTS.md  P0xx=plans/0xx-*.md  RUL=knowledge/RULES.md
T = {}
T['unit'] = (['unit'], 'Units, goals, orders (UnitActionItem), targeting, formations, sync, terrain, animation/model gen; the biggest package (648 files, 106k lines)', [
 'F7: ATTACK/FOLLOW/entity-ability orders (UnitActionItem ~383-396, 434-439, 557-562) do not check fog; a modified client can target through fog by id (REV F7, P012).',
 'UnitActionItem and BuildingServerEvents are already long: plan 012 demands net change <= 0 lines there (P012).',
 'New UnitAction enum values go at the END of the enum (AGM s4).',
 'Unit damage bypasses vanilla: LivingEntityMixin.actuallyHurt; BOTH LivingHurtEvent and LivingDamageEvent fire; Ward/Lantern Dome/Brass shield rely on the hurt event (AGM s4).',
 'Per-match state not reset on rematch: UnitKills dirty/ids/counts (stop handler clears only dirty), kills, bot brains (REV R1, P011).',
 'Never hand-edit unit/modelling/models/gen/ - change the generator in tools/ and re-export (AGM s7).',
 'Entity flags (isInWater, on-ground) refresh on the entity OWN next tick, not on teleportTo; wait 1-2 ticks in tests (AGM s4).',
 'Units autocast by default; tests counting energy/cooldowns must AutocastState.setAll(unit,false) (AGM s4).',
 'Cost hot spots: close-zoom bodies 38 ms at zoom 30; move packets every 3 ticks ~100k/s at 8v8 (REV perf; instanced-units plan).',
 'UnitServerEvents is edited by perf PR #247 and security PR #248 - rebase, do not redo (P011, P013, P014).'])
T['pathfinding'] = (['unit/pathfinding'], 'Custom grid A* pathfinder (worker pool, walkability grid, vanilla path budget) used by units', [
 'Real matches never set a world border, so anything gated on isRtsOptimisedMap() was OFF in play (rtsPathfinding). Check gates against what a real match does (LES gen-005).',
 'vanilla_path_* GameTests are on the flake list; Sys.force per-holder holds fixed a shared measuring flag switched off by another test (P015, PR #239).',
 'Lookup-budget thresholds (UNITS*40/2) flaked at 696 of 1600 lookups; fix root cause, do not widen (P015).',
 'Tests that move units: use gametest/ArenaReady (glass pad in the sky) to remove terrain and neighbour effects (P015).'])
T['ability'] = (['ability', 'mana', 'enchantments'], 'Abilities, autocast (AutoRule/AutocastState/AutoCaster), hero abilities, mana, enchantments', [
 'Units autocast by default, heroes never; tests must switch bystanders off with AutocastState.setAll (AGM s3, s4).',
 'Ward, Lantern Dome and Brass shield rely on LivingHurtEvent, which fires on the custom damage path (AGM s4).',
 'Entity-targeted abilities skip the fog check (UnitActionItem ~557-562) - same leak as F7 (REV F7, P012).',
 'No gameplay number changes without lovish; list them under "Numbers for lovish" in the PR (AGM s6).'])
T['building'] = (['building', 'research'], 'Buildings, placement, production, in-place levels L1-L3, population rules, research, structure .nbt', [
 'Server sync loop (BuildingServerEvents ~1037-1044) sends ~27k mostly unchanged packets/s; plan 013 adds SyncDelta/BuildingSync; delta must re-send in full when a building BECOMES visible (REV perf, P013).',
 'getUnitToBuildingRelationship has no ally case: allied workers walk to an ally building and never build (REV F9, P012).',
 'Fog re-rasterises ~1,700 static buildings every fog tick (REV perf).',
 'A structure naming an id no mod registers loads as AIR; BuildingBlockModGameTests fails on it. Never copy Macaw/Chipped assets (AGM s4).',
 'gen_lab_levels.py must reproduce L2/L3 .nbt byte for byte; BuildingParts.java anchors must match tools gen_structures.py rig rows (AGM s4, check_parts.py).',
 'Client overlay handlers (BuildingClientEvents, PlacementGridClientEvents) must return on ShaderPacks.skipOverlays() (LES gen-005).',
 'PopulationRules is a pure class tested by JUnit (no world); keep rules there, do not mock the world (AGM s4).',
 'Temp blocks / saved targets leaked between worlds - fixed in PR #248 (REV, P011).'])
T['bot'] = (['bot', 'survival', 'scenario', 'sandbox'], 'Skirmish bots, survival waves, scenarios, battle sandbox', [
 '/bot remove had no permission check - any player could run it (REV headline 2; fix in security PR).',
 'resetRTS (rematch) misses bot brains (REV R1, P011).',
 'bots_reach_tier_2 is the top flake: test wilderness bases break site search/extractor footprint while real matches use a prepared flat arena (P015 H1, REV).',
 'The bots soak runs alone in shard 6 (AGM s4). Hero AI should reuse the nightly bot ladder #133 (REV design).'])
T['hero'] = (['hero'], 'Hero mode, possession (first-person unit feed), hero kits/progression/AI hooks, fallen heroes', [
 'HeroProgression.holdCarry has NO stop handler; HeroServerEvents.fallenHeroes leaked between worlds (fixed in PR #248) (P011, REV).',
 'Heroes never autocast; hero AI hooks run one hero per tick on UnitGrid/TargetScan/fog queries (REV perf).',
 'Open decisions: near-death flee vs hold order; hero auto-spend random vs fixed (REV needs-decision 1-2).',
 'Possession onboarding step does not exist yet (REV design). Hero tests: HeroGameTests, HeroAiGameTests.'])
T['fogofwar'] = (['fogofwar', 'worldmemory'], 'Per-player fog of war (server visibility, chunk gating, snapshots) and ground-memory scars', [
 '/rts-fog disable is a map hack any player can type; command is registered in FogOfWarClientEvents (~259, 275) (REV headline 2).',
 'F7: attack/follow orders do not check fog (REV F7, P012). Audience.mayKnow is the pure rule to reuse (P012).',
 'World-border gate: FogOfWarServerEvents ~348 uses WorldBorderServerEvents.isRtsOptimisedMap; real matches set no border (LES gen-005).',
 'Perf: entity-tracking refresh 16k calls every 10th tick; re-rasterises 1,700 buildings per fog tick (REV perf).',
 'Visibility latency after a vision change must stay <= 10 ticks (P013).',
 'HUD shows only what the client already knows - add no lookups of hidden entities (P016).',
 'Missing tests: a fog-leak test (REV tools/CI). Existing: FogHidesEnemiesGameTests, FogExplorationGameTests.'])
T['hud'] = (['hud', 'cursor', 'guiscreen', 'healthbars', 'keybinds', 'onboarding', 'tutorial', 'attackwarnings'], 'RTS HUD: command card, selection strip, economy bar, panels, keybinds, onboarding', [
 'drawHud is one 1,785-line method rebuilt every frame; split into *Panel classes with a HudSizeGateTest ratchet (REV R5, P016).',
 'HUD draws on the screen layer: ShaderPacks.skipOverlays() does NOT apply; do not move calls into level-render handlers (P016, P017).',
 'Post on issue #35 before touching hud/ (AGM s6).',
 'Selection strip rebuilt every frame; strategic zoom issues one draw call per house icon - plan 017 batches in drawStrategicOverlay (REV perf, P017).',
 'FrameParts HUD_* ids 15-18 are planned after MARKERS_METAL (P016).'])
T['minimap-orthoview'] = (['minimap', 'orthoview', 'maps', 'rtsmap'], 'BAR-style top-down camera (orthoview), minimap, map definitions', [
 'Minimap allocated ~18 MB/s garbage before the perf PR (REV perf, PR #247).',
 'Shadow-pass and minimap timing sections were added so the next perf round can measure (REV).',
 'Level-render overlays here must return on ShaderPacks.skipOverlays() (LES gen-005).',
 'Camera maths has a checker: tools/camera_math_check.py (tools list).'])
T['match'] = (['match', 'matchstart', 'startpos', 'worldborder', 'gamemode', 'gamerules'], 'Lobby, match lifecycle, start positions, world border, EyesDirector CI tour', [
 'resetRTS (rematch) misses capture points, bot brains, kills, hero progression; ~70 hand-written stop handlers - plan 011 adds a lifecycle registry (REV R1, P011).',
 'Real matches never set a world border; isRtsOptimisedMap is the gate (LES gen-005).',
 'EyesDirector drives the CI screenshot tour: add a scene when a feature has no shot (AGM s5).',
 'Multiplayer has never been tested over a real connection (REV design). FFA enemies can /ally to share a win; lock alliances at start is open (REV needs-decision 3).',
 'Per-test flakes via shared static state not cleared at stop (P015, P011).'])
T['player-alliance-time'] = (['player', 'alliance', 'faction', 'time', 'tide', 'environment'], 'Player state/saves, alliances, factions, day-night time, tides, environment', [
 'Three 30 s timers each save synchronously on the server thread -> mid-fight hitch (REV F10, P014).',
 'PlayerServerEvents:204 SAVE_TICKS_MAX=1200 may be dead code - check before touching (P014).',
 '"Who may command / relationship" exists in 4+ disagreeing copies; one has no ally case (REV R2, P012).',
 'Night-source scan cache added in the perf PR (REV).'])
T['network'] = (['network', 'registrars', 'commands', 'config'], 'Packet registry (PacketHandler), Audience visibility/auth rules, event registrars, commands, config', [
 'Two dev builds could connect and silently mis-decode packets; fix = protocol hash from the packet table (REV headline 2; PacketHandler PROTOCOL_VERSION).',
 'Permission holes on /rts-fog and /bot remove (REV headline 2).',
 'Audience.java has the pure Facts interface (allied, commandersOf, spectator, mayCommand) and mayKnow; reuse, do not add a 5th copy (P012).',
 'Client imports in server code: run tools/check_server_client_imports.py (in prepush) (P011-P014).',
 'New server events register in registrars/ServerEventRegistrar (P014). Test gap: packet fuzz and commands (REV tools/CI).'])
T['economy'] = (['resources', 'items'], 'BAR flow economy: metal/energy, extractors, storage, no population cap; EconomyMath', [
 'Check how BAR gates a mechanic before briefing balance: T2 is gated on energy first (RUL M006).',
 'EconomyMath is pure and JUnit-tested; put arithmetic there (AGM s4).',
 'No gameplay number changes without lovish; one owner per balance file (AGM s6, LES gen-004).',
 'Item-pickup query skip and population cache came with the perf PR (REV).'])
T['gametest'] = (['gametest'], 'Headless GameTests: the real test suite (121 files, 49k lines)', [
 'SkirmishGameTests.java is 15,357 lines that every lane edits; split by topic (REV).',
 'New GameTests go in their own class and in NO shard list (they land in shard 1); tools/check_shards.py fails on duplicates (AGM s4, P011).',
 'flake-stress jobs finish green even when tests fail: read the summary "[Stress]" annotation (LES gen-011).',
 'A test failing right after a shard re-cut is a neighbour problem (arenas sit beside batch neighbours): move it, do not retry (AGM s4).',
 'Load far chunks with GameTestChunks.hold; never setChunkForced/getChunk on ungenerated chunks; poll with bounds, not fixed ticks (AGM s4).',
 'Known flakes: tools/known_flakes.txt; do not paper over - fix and remove (AGM s4).'])
T['blocks-fx'] = (['blocks', 'postfx', 'particles', 'barfx', 'brass', 'nether', 'sounds'], 'Custom blocks, shader-pack detection (ShaderPacks), barfx effects layer, particles, sounds', [
 'Shader shadow pass: Oculus re-fires RenderLevelStage events, so every overlay handler must return on ShaderPacks.skipOverlays() (LES gen-005).',
 'The shadow pass re-poses every unit and was never measured (REV perf, fixed in the perf PR).',
 'Every visual feature needs a CI frame budget with and without shaders (LES gen-007).',
 'Temporary blocks (BlockServerEvents) leaked between worlds - PR #248 (REV).',
 'barfx wraps drawing in FrameParts.WORLD_FX; blocks use WORLD_MARKERS (code).'])
T['perf'] = (['perf', 'taskscheduler', 'debug', 'persistence'], 'Instrumentation: Sys (server sections), FrameParts (client frame sections), task scheduler, debug, save persistence', [
 'New Sys section ids go at the end; [Sys] line prints every 10 s only while the server is slow or in /rts-perf (P013).',
 'Hook byte counting only while Sys.isMeasuring(); never in normal play (P013).',
 'A shared measuring flag was switched off by another test; Sys.force now holds per holder (P015).',
 'Nothing counts packets today (REV perf). Fixed timers line up on the same tick (REV).',
 'Save hitch lives in persistence + PlayerServerEvents timers (REV F10, P014).'])
T['mixin-misc'] = (['mixin', 'compat', 'util', 'launcher', 'api', 'entities'], 'Mixins into vanilla/Forge, entities, compat, utilities, launcher hooks', [
 'LivingEntityMixin.actuallyHurt is the custom damage path (~265 hurt / ~280 damage events) (AGM s4).',
 'Mixins run on both sides: keep client-only imports out (tools/check_server_client_imports.py) (P011).',
 'ClientLevelMixin/PathNavigationMixin change vanilla behaviour globally - check gates against a real match (LES gen-005).'])
T['tools-ci'] = (['tools', '.github'], 'Python tools, prepush, CI workflows (build.yml shards, eyes, flake-stress), claims, flake list', [
 'CI is the compiler/test runner (no local MC classpath); run bash tools/prepush.sh (~35 s) before every push (AGM s4).',
 'CI red ~half of main builds (18 of 36, Oct 23-26) from flaky tests; auto-rerun only works while a session watches (REV headline 3).',
 'Shards: 8 via SHARD_n lines in build.yml; adding one = a new line; check_shards.py in prepush (AGM s4).',
 'GitHub Free = 20 concurrent jobs per ACCOUNT; two builds fit at once (LES gen-005, AGM s4).',
 'PC gh login lacks the workflow scope: workflow-file pushes are refused (REV decision 0).',
 'Copying code to another repo from a session is blocked; use a workflow with a scoped token (LES gen-005, RUL M007).',
 'GraphQL is blocked in cloud sessions: gh REST only; 2 concurrent git network ops (AGM s6).',
 'Never git add -A / add .; push to main denied by .claude/settings.json; claim before starting (tools/claim.py) (AGM s2, s6).',
 'ci_wait reruns once only when every failed test is in known_flakes.txt (AGM s4).'])
T['legacy-mod-engine'] = (['mod', 'engine'], 'Older from-scratch prototype (mod/ and engine/), reference only, not shipped', [
 'Not shipped and not built by CI as the game; the live game is bar/ (AGM s3).'])
