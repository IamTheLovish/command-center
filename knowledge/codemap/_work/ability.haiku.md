## Purpose
Ability, mana (Stormcallers' energy-as-mana core, Mana Wells, sustained channels) and enchantment logic for the RTS: commander signatures, unit and hero abilities, and per-faction spell effects.
Entry points are the Mana core API (ManaServerEvents) and per-ability `use(...)` methods driven by AutoCaster and the packets.

## Key classes
- `ability/abilities/CommanderDGun.java` (~481) - faction D-gun; aimed line/cone/broadside/column damage
- `mana/ManaServerEvents.java` (~473) - Mana core: tryCast, channelShot, openChannel, Overcharge, Mana Well multipliers
- `ability/abilities/CommanderAbility.java` (~366) - per-faction commander signature (rally, war horn, dread, riptide, blink, overclock)
- `ability/abilities/SunriseSortie.java` (~348) - Sunforged charge with follower gathering and per-tick Charge movement
- `mana/FrostServerEvents.java` (~343) - Frost mana server events (name-based)
- `ability/abilities/TotemOfThePack.java` (~323) - pack totem ability (name-based)
- `mana/ManaWellServerEvents.java` (~309) - Mana Well server events (name-based)
- `ability/AutoCaster.java` (~308) - autocast driver for abilities (name-based)
- `mana/TempestServerEvents.java` (~294) - Tempest drain/channel events (name-based)
- `mana/LeyNetwork.java` (~282) - ley-line network for mana (name-based)
- `ability/Ability.java` (~279) - base ability class
- `mana/LanternDomeServerEvents.java` (~275) - Lantern Dome sustained spell events (name-based)
- `ability/abilities/PlantThicket.java` (~264) - Verdant thicket ability (name-based)
- `ability/abilities/Rootwalk.java` (~254) - Verdant movement ability (name-based)
- `ability/abilities/LeafDash.java` (~254) - Verdant dash ability (name-based)
- `ability/abilities/StagLeap.java` (~252) - leap ability (name-based)

No files are over 1000 lines.

## Entry points and events
- `@SubscribeEvent` handlers: DecoyServerEvents (4), TotemOfThePack (4), WardServerEvents, ManaWellServerEvents, LanternDomeServerEvents (3 each), ManaClientEvents (3), TempestServerEvents, LeyNetwork, FrostServerEvents, WitheringFog, SunriseSortie, StagLeap, SoulWisps (2 each), AwakenThicket (3)
- Packets: AbilityClientboundPacket, AbilityServerboundPacket, BuildingAbilityClientboundPacket, BuildingAbilityServerboundPacket, ManaServerboundPacket
- Commands: none seen
- Tick hooks: SunriseSortie's server tick drives charges (per its class doc)

## Server vs client
- Server-only: ManaServerEvents (documented as server side only), plus the *ServerEvents classes (Mana, Frost, Tempest, Ward, Decoy, LanternDome, ManaWell)
- Client-only: ManaClientEvents (name-based); the Client/Serverbound packet pairs split traffic across the two sides

## Data flow
- Imports from unit (548), hud (215), keybinds (161), resources (153), building (111), cursor (81), util (33), registrars (25), alliance (24), research (14)
- Imported by unit (157), building (18), gametest (14), hero (9), player (8), hud (5), blocks (4), registrars (4), bot (3), commands (3)
- Mana spells pay through EconomyServerEvents.drawSpell (per ManaServerEvents doc)

## Instrumentation and tests
- FrameParts/Sys ids: none seen
- GameTest classes: SkirmishGameTests (430 imports), ExperimentalAbilityTooltipGameTests (11), CombatEngineerGameTests (9), BigUnitGameTests (7), T3RoleGameTests (7), AutocastGameTests (6), CommanderAntiAirGameTests (5), ReactionGameTests (3)