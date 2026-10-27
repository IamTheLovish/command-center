## Purpose
Client and server battle-effects system (BAR-style): server queues events in BarFx and sends them as packets; BarFxClient renders flashes, smoke, debris, scorch marks, craters and camera shake. Also covers blocks (thicket, tidepool, frost, vine snare), postfx, particles, brass heat/shield, nether block mappings and sound playback.

## Key classes
- `barfx/BarFxClient.java` (~1268) [OVER 1000] - client particle pool and renderer for BAR effects
- `barfx/BarFx.java` (~531) - server event queue and helpers (shot, impact, explosion, death, dome, sfx)
- `nether/NetherBlocks.java` (~392) - overworld-to-nether block mappings near piglin bases
- `sounds/SfxClient.java` (~330) - client sound playback with per-category budgets and distance volume
- `barfx/DomeFx.java` (~324) - dome barrier geometry rendering (name-based, from the dossier heads only; role inferred from BarFx.dome)
- `postfx/WorldLookPass.java` (~287) - post-processing pass (name-based)
- `sounds/SoundClientEvents.java` (~277) - client sound event handlers (name-based)
- `blocks/ThicketCover.java` (~254) - thicket block cover logic (name-based)
- `blocks/ThicketBlock.java` (~245) - thicket block (name-based)
- `barfx/BarFxServerEvents.java` (~236) - server-side BAR event handlers (name-based)
- `blocks/BlockServerEvents.java` (~223) - server block event handlers (name-based)
- `sounds/Sfx.java` (~219) - sound effect enum and categories
- `blocks/BlockClientEvents.java` (~209) - client block event handlers (name-based)
- `blocks/WraithSnowLayerBlock.java` (~200) - snow layer block (name-based)
- `brass/Heat.java` (~180) - brass heat values (name-based)

## Entry points and events
- `BarFx` packets: `barfx/BarFxClientboundPacket.java` (server to client event batches)
- `SoundClientboundPacket` (`sounds/SoundClientboundPacket.java`) for SFX events
- `@SubscribeEvent` handlers: `BarFxServerEvents` (7), `WorldLookClientEvents` (3), `ThicketCover` (3), `BarFxClientEvents` (3), `ShieldServerEvents` (2), `BlockServerEvents` (2), `BlockClientEvents` (2), `ZoomVolume` (1), `SoundClientEvents` (1), `BrassUnitEvents` (1)
- No commands seen in the dossier.

## Server vs client
- Client-only: `BarFxClient`, `SfxClient` (both `@OnlyIn(Dist.CLIENT)`), `*ClientEvents`, `*ClientboundPacket` receivers.
- Server-only: `BarFx` (server queue/helpers), `*ServerEvents`, `ShieldServerEvents`.

## Data flow
- Imports most from `unit` (28), `registrars` (26), `building` (17), `items` (9), `util` (6), `ability` (6), `alliance` (6), `fogofwar` (5), `faction` (5), `orthoview` (4).
- Imported by `unit` (68), `building` (31), `ability` (26), `gametest` (7), `registrars` (7), `items` (6), `mixin` (6), `resources` (6), `hero` (5), `mana` (4).
- Gameplay code calls `BarFx` static helpers; packets carry events to clients, which `BarFxClient.ingest` and `SfxClient.onFx` consume.

## Instrumentation and tests
- FrameParts/Sys ids: MARKERS_RANGE, WORLD_FX, WORLD_MARKERS.
- GameTest classes by import count: SkirmishGameTests (150), BrassworksGameTests (19), AudioGameTests (4), AudienceGameTests (2), BigUnitGameTests (1), SoundLevelGameTests (1), WorldMemoryGameTests (1).