# Codemap: hero
sha: bbbdac21 (bbbdac211d7d355181c00da37dc416b82fa04ff9)   date: 2026-10-27   source: dossier of bar/ at that sha + traps from review/plans/lessons/AGENTS
drift: `git -C D:\btr diff bbbdac21..origin/main --stat -- bar/src/main/java/com/solegendary/reignofnether/hero`

## Purpose
Possession and hero mode for the RTS: a player takes direct control of one team unit (server drives it via mixin, client renders camera/HUD). Also hero kits, progression, bot, and revive for faction heroes.

## Key classes
- `hero/PossessionServer.java` (992 lines)? no â (992 lines) - server-side possession: claims, drive, attacks, abilities, orders diversion
- `hero/PossessionClientEvents.java` (968 lines) - client camera, input, possessed HUD and controls
- `hero/HeroKits.java` (749 lines) - seven faction hero kits: body stats, costs, four abilities and effects
- `hero/PossessionHudClient.java` (501 lines) - crosshair, hit markers, damage numbers, cast feedback, compass, radar terrain
- `hero/HeroBot.java` (387 lines) - hero bot logic (?)
- `hero/FactionHeroAbility.java` (238 lines) - faction hero ability definition (name-based, role unclear)
- `hero/HeroCore.java` (233 lines) - core hero logic (name-based)
- `hero/HeroProgression.java` (223 lines) - hero level/rank progression (name-based)
- `hero/HeroFx.java` (193 lines) - hero visual/effect helpers (name-based)
- `hero/PossessionPredictionClient.java` (187 lines) - client-side movement prediction for possessed unit (name-based)
- `hero/PossessionServerboundPacket.java` (185 lines) - possession client-to-server packet (name-based)
- `hero/FactionHero.java` (181 lines) - faction hero type (name-based)
- `hero/PossessionClientboundPacket.java` (161 lines) - possession server-to-client packet (name-based)
- `hero/HeroServerEvents.java` (141 lines) - server event handlers for heroes (name-based)
- `hero/HeroKit.java` (138 lines) - hero kit data record/class (name-based)
- `hero/HeroClientboundPacket.java` (123 lines) - hero server-to-client packet (name-based)
- `hero/FallenHeroClientboundPacket.java` (115 lines) - fallen hero server-to-client packet (name-based)
- `hero/HeroRoles.java` (114 lines) - hero role definitions (name-based)
- `hero/HeroExperienceOrb.java` (113 lines) - hero XP orb entity (name-based)

## Entry points and events
- @SubscribeEvent: PossessionClientEvents (9), PossessionServer (8), HeroServerEvents (2), PossessionHudClient (1)
- Packets: FallenHeroClientboundPacket, HeroClientboundPacket, HeroServerboundPacket, PossessionClientboundPacket, PossessionServerboundPacket
- Commands: allow, deny, release, rts-possession
- Tick handlers: PossessionClientEvents.onClientTick, PossessionClientEvents.onRenderTick, PossessionServer tick loop (per possession)
- Input: PossessionClientEvents.onMovementInput, onComputeFov

## Server vs client
- Server-only: PossessionServer, HeroServerEvents, HeroProgression (?)
- Client-only: PossessionClientEvents, PossessionHudClient, HeroClientEvents, PossessionPredictionClient
- Shared: HeroKits, HeroKit, FactionHero, HeroTypes, packet classes

## Data flow
- Imports most from unit (46), ability (14), registrars (12), building (11), player (9)
- Imported by unit (21), gametest (9), registrars (4), building (3), mixin (3), player (3)
- Mixin: PossessionMobMixin calls PossessionServer.drive per mob
- GameTest classes importing hero: HeroGameTests, SkirmishGameTests, H13GameTests, DuelGameTests, HeroAiGameTests, RegressionGameTests

## Instrumentation and tests
- FrameParts/Sys ids: none seen
- GameTest classes: HeroGameTests (62 imports), SkirmishGameTests (39), H13GameTests (7), DuelGameTests (6), HeroAiGameTests (6), RegressionGameTests (6), WinPaysGameTests (4), AudienceGameTests (2)

## TRAPS (source tag in brackets: REV overnight-review, LES lessons.md, AGM AGENTS.md, P0xx plans, RUL RULES.md)
- HeroProgression.holdCarry has NO stop handler; HeroServerEvents.fallenHeroes leaked between worlds (fixed in PR #248) (P011, REV).
- Heroes never autocast; hero AI hooks run one hero per tick on UnitGrid/TargetScan/fog queries (REV perf).
- Open decisions: near-death flee vs hold order; hero auto-spend random vs fixed (REV needs-decision 1-2).
- Possession onboarding step does not exist yet (REV design). Hero tests: HeroGameTests, HeroAiGameTests.
