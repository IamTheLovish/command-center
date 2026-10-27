## Purpose
Mixins and utilities that patch vanilla/Forge behaviour for the RTS: fog of war rendering, unit inventories, projectile/arrow and fire behaviour, plus shared helpers (MiscUtil, MyRenderer).
Also holds custom entities (fireball/projectile units), the launcher branding, and small compat/api glue.

## Key classes
- `util/MiscUtil.java` (~1153) [OVER 1000] - shared helpers: fireworks, ground/height queries, unit targeting and attack-priority logic
- `util/MyRenderer.java` (~961) [OVER 1000] - render types, box/line/ground-marker drawing, GUI icon, tooltip and item rendering helpers
- `mixin/UnitInventoryMobMixin.java` (~572) - Mob mixin giving units an item inventory, use/drop/cooldown logic
- `mixin/AbstractArrowMixin.java` (~381) - arrow hit logic, garrison-aware collision with buildings
- `mixin/LivingEntityMixin.java` (~381) - LivingEntity behaviour patches (role from name only)
- `mixin/TitleScreenMixin.java` (~369) - title screen patches (role from name only)
- `mixin/BaseSpawnerMixin.java` (~226) - spawner behaviour patch (name-based)
- `mixin/fire/FireBlockMixin.java` (~219) - fire block behaviour patch (name-based)
- `util/MyMath.java` (~216) - math helpers (name-based)
- `mixin/ClientLevelMixin.java` (~209) - client level patch (name-based)
- `mixin/fogofwar/LevelRendererMixin.java` (~186) - fog-of-war level renderer patch (name-based)
- `mixin/fogofwar/ClientChunkCacheMixin.java` (~179) - fog-of-war chunk cache patch (name-based)
- `mixin/EntityMixin.java` (~173) - Entity patch (name-based)
- `launcher/LauncherBrand.java` (~167) - launcher branding (name-based)
- `entities/BlazeUnitFireball.java` (~148) - blaze unit fireball projectile (name-based)
- `compat/EntityCullingCompat.java` (~84) - compat with entity culling mod; only @SubscribeEvent file in this area (name-based)

## Entry points and events
- Commands registered in this area: allies, building, enemies, entity, owner
- Packet-related mixins: `mixin/ClientPacketMixin.java`, `mixin/ServerGamePacketListenerImplMixin.java`, `mixin/fogofwar/ClientPacketListenerLightMixin.java`
- Event class: `compat/EntityCullingCompat.java` (1 @SubscribeEvent)
- Tick hook: `UnitInventoryMobMixin.tick(CallbackInfo)` (@Inject-style tick override)

## Server vs client
- Client-leaning (judged from names): `util/MyRenderer.java`, `mixin/fogofwar/*`, `mixin/ClientLevelMixin.java`, `mixin/ClientPacketMixin.java`, `mixin/TitleScreenMixin.java`, `launcher/LauncherBrand.java`.
- Server-leaning (judged from names): `mixin/ServerGamePacketListenerImplMixin.java`, `mixin/UnitInventoryMobMixin.java` (server sync via syncToClient), `mixin/AbstractArrowMixin.java`. Mixed/unsure: `util/MiscUtil.java`.

## Data flow
- Imports most from `unit` (106), `building` (36), `registrars` (30), `orthoview` (20), `fogofwar` (19).
- Imported by `building` (109), `unit` (80), `ability` (70), `hud` (34), `gametest` (14), `commands` (8).
- `gametest` imports this area mainly via SkirmishGameTests (14).

## Instrumentation and tests
- Instrumentation ids (FrameParts/Sys): none seen
- GameTest classes (by import count): SkirmishGameTests(14), BuildGroupGameTests(2), BiomeBaseGameTests(1), BuildingGridGameTests(1), GameTestChunks(1), LaneCGameplayGameTests(1), MapMetalGameTests(1), MapRimGameTests(1)