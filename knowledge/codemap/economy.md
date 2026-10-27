# Codemap: economy
sha: bbbdac21 (bbbdac211d7d355181c00da37dc416b82fa04ff9)   date: 2026-10-27   source: dossier of bar/ at that sha + traps from review/plans/lessons/AGENTS
drift: `git -C D:\btr diff bbbdac21..origin/main --stat -- bar/src/main/java/com/solegendary/reignofnether/resources bar/src/main/java/com/solegendary/reignofnether/items`

## Purpose
Resource economy and unit item system for the RTS: METAL/ENERGY flow economy (BAR-style stall/income/storage), per-player resource pools, unit equipment and shop items. Covers 62 files, ~10k lines across `resources/` and `items/`.

## Key classes
- `resources/ResourceCosts.java` (~669 lines) - static ResourceCost constants per unit/building, formatted cost helpers
- `resources/EconomyServerEvents.java` (~645 lines) - BAR-style flow economy: requestFlow, stall, income, storage, overflow sharing
- `resources/ResourcesServerEvents.java` (~516 lines) - per-player Resources list, starting amounts, save/load of resources
- `resources/ResourceSources.java` (~475 lines) - resource source definitions (name-based)
- `resources/TreeClearing.java` (~398 lines) - tree clearing with resource hookup (name-based)
- `resources/MetalPatches.java` (~341 lines) - metal patch placement/state (name-based)
- `resources/WreckServerEvents.java` (~482 lines) - wreck server-side handling (name-based)
- `resources/TierGate.java` (~206 lines) - tier unlock gating (name-based)
- `resources/ResourceIndex.java` (~196 lines) - resource index lookup (name-based)
- `resources/Resources.java` (~135 lines) - per-player resource container with getTotalResourcesFromItems (signature seen)
- `resources/EconomyMath.java` (~125 lines) - economy math helpers (name-based)
- `resources/EconomyPace.java` (~113 lines) - economy pacing (name-based)
- `items/UnitItems.java` (~703 lines) - ~703 lines; unit item constants (merchant equipment, hero experience bottle)
- `items/UnitItemBuilder.java` (~311 lines) - fluent builder for UnitItem (buyCost, sellValue, onUse, icon)
- `items/ItemClientEvents.java` (~491 lines) - client-side item events (name-based)
- `items/ItemServerEvents.java` (~241 lines) - server-side item events (name-based)
- `items/UnitItem.java` (~206 lines) - unit item base type (name-based)
- `items/ItemShopMenu.java` (~176 lines) - item shop menu (name-based)

## Entry points and events
- `EconomyServerEvents.onServerTickEnd()` - per-tick stall/income settlement (signature seen)
- `ResourcesServerEvents` - 8 @SubscribeEvent handlers
- `ItemClientEvents` - 7 @SubscribeEvent handlers; `WreckServerEvents` - 4; `WreckSyncServerEvents` - 3
- Packets: ItemClientboundPacket, ItemServerboundPacket, ItemShopClientboundPacket, EconomyClientboundPacket, EconomySliderServerboundPacket, MetalPatchesClientboundPacket, ResourcesClientboundPacket, ResourcesServerboundPacket, WreckSyncClientboundPacket
- Commands: sendemerald, sendfood, sendore, sendwood

## Server vs client
- Server-side: EconomyServerEvents, ResourcesServerEvents, WreckServerEvents, WreckSyncServerEvents, ItemServerEvents (by name)
- Client-side: ItemClientEvents, ResourcesClientEvents, WreckClientEvents, EconomySliderClientEvents, MetalPatchMarkerClientEvents (by name)

## Data flow
- Imports from unit (43), building (42), registrars (17), hud (15), player (10), util (9), sounds (8), orthoview (6), keybinds (5), faction (5)
- Imported by unit (315), building (126), ability (106), research (57), gametest (34), hud (11), bot (6), hero (6), matchstart (6), mixin (6)
- Heaviest consumers are unit and building packages, so economy API changes ripple there.

## Instrumentation and tests
- Instrumentation ids: ECONOMY, MARKERS_METAL, WORLD_MARKERS
- GameTest classes (by import count): SkirmishGameTests (173), BigUnitGameTests (16), BotGameTests (10), CombatEngineerGameTests (6), TierGateGameTests (6), WinPaysGameTests (4), BranchWindGameTests (3), EconomySliderGameTests (3)

## TRAPS (source tag in brackets: REV overnight-review, LES lessons.md, AGM AGENTS.md, P0xx plans, RUL RULES.md)
- Check how BAR gates a mechanic before briefing balance: T2 is gated on energy first (RUL M006).
- EconomyMath is pure and JUnit-tested; put arithmetic there (AGM s4).
- No gameplay number changes without lovish; one owner per balance file (AGM s6, LES gen-004).
- Item-pickup query skip and population cache came with the perf PR (REV).
