# Design revision: essence casters, siege lobber, anti-siege tower (Oct 29)

Read-only review of the essence draft, the Oct 29 decision logs and main f1a9ba5e (veterancy, wrecks, hero XP, AutoCaster, abilities, design/balance.md, design/defences.md).

## 1. Balance risks

**Summons feed the loops.** Only angels are exempt from essence; tombstone skeletons, Sprout Guardian, Ghost Furnace and the Grave Adept are not, and no summon is exempt from XP orbs ((pop+1)x5 per death) or veterancy kill XP. A tombstone raises a free skeleton every 20 s; it dies, drops 2 essence and an orb, and "orbs within 16 fly to the Adept" lets a Gravebound player feed his own skeletons to his own Adept. DragonRaiseServerEvents already tags risen units this way (no wreck, pop room, 8 per owner).

**Empower has no cooldown.** 15 essence = one rank (+10% HP and damage, 3 ranks). A caster at 30 essence gives two ranks at once; three casters make a Sun Colossus (1840 metal) rank 3 for 45 essence, which the kill path prices at 5520 metal of kills.

**Heals are 2-6x the existing ones.** Bloom (Bloom Priestess, 175 metal) heals 12 HP in radius 8 every 20 s. Grave Tide: 4 HP/s x 8 s = 32 HP per unit, radius 8, every 12 s, for 5 essence. Seed of Renewal: 6 x 12 = 72 HP per unit for 10.

**Damage is out of scale with T1 health (30-80 HP).** Brine Bolt 50 every 12 s for 5 essence one-shots any skirmisher (an Iron Warden's 4.2 DPS on a support unit). Drowned Tithe 8 dmg/s x 8 s = 64 area damage. Captured Spark "120 damage, 4 jumps" is ambiguous: 120 per jump kills four T1 units for 10. Thunderhead 10 x 40 = 400. Solar Lance is 40 on a 45 s cooldown.

**Tombstones.** 3 stones x 2 skeletons = 6 free Skeletons (270 metal) per caster at all times for 30 essence per 90 s, no pop cost stated. A "summoned structure" takes melee at the 0.25x building rate: 300 HP is 1200 effective.

**Grave Adept.** Hero level 2 needs 320 XP, each level +160 more. A level per Empower with no XP table means 30 essence = level 3 soul bolt instantly. The XP burst on death is good, keep it.

**Income across races.** 1 per 25 metal is cost-neutral: a 700 v 700 trade drops ~56 essence, one caster keeps 30, and the cooldowns cap spending at ~69 essence/min per caster. Brassworks dying less changes nothing (both sides' deaths drop). The one asymmetry is Gravebound's 16-block pull on creep: four times the area, two to three times the wisps.

## 2. Counterplay

Every caster is ~40 HP inside 8 blocks of the fight: kill it, Seal or Hex it, or stand your own caster there (nearest caster takes the wisps, both sides harvest). No-counter cases: the Seraph Archer flies, so a melee-only army cannot touch it and the raid tower and HLT are ground-only; Brine Bolt and Rising Tide have only the cooldown; Spirit Puppet has no break condition (Possess is a channel that breaks when the Wraith is hit); Blood Totem and the Seed sapling need stated HP to be targetable; tombstones counter creep only at full damage. Whirlpool and Thunderhead are fine if static (a slowed unit leaves a radius-5 pool in ~2 s).

## 3. Consistency

- "Gravecaller" is already the Gravebound hero (heroes/GravecallerUnit.java, HeroKits.GRAVECALLER). Rename the caster.
- Hex is Seal plus "cannot attack" for 5 essence against Seal's 25 energy and 20 s; Mender Angel overlaps Witch potions and Bloom; Patch Kit overlaps Repair Crawler and Sapper; Ghost Furnace overlaps DeployTurret; Blood Totem sits next to War Drums; Verdant now has three roots; the Evoker already summons Vexes (30 s life, 60 s cooldown) from the same Sunforged T2 lab.
- Adept level 5 "raises from fresh corpses" breaks RaiseDead's rule that a raise is never free.
- Bots: AutoCaster casts for every non-hero unit from a rule inferred by name and shape, so heals, roots, bolts and summons work for bots once an essence gate like autocastEnergy exists. No rule targets a building, so Patch Kit and Soul Boiler are manual-only, and Soul Boiler at the base while essence is at the front makes the caster a courier: micro-heavy, un-BAR-like. Static Step needs SupportBrain's kiting (casters as SupportUnits).

## 4. Lobber, HLT, casters

The range ladder holds: raid tower 14 < lobber 15 < enhanced tower 16 < HLT 20 < Bombard/Mortar 22 < Rocket Battery 24. The HLT (1000 HP, 45 per 1.5 s = 30 DPS, ground only) kills a lobber in two shots from 5 blocks outside its reach, BAR's Rocko v HLT; the answer is the existing T1 artillery. Inside the defence set, the enhanced anti-raid tower (260/400, 600 HP, 18 DPS, range 16) is obsolete next to an HLT (450/650, 1000 HP, 30 DPS, range 20) from the same T1 lab, and raiders have under 60 HP so the slow cadence still one-shots them. Lobbers matter only before an HLT stands, by minute 4-5. Casters barely touch siege: Rising Tide pushes lobbers 6 blocks; Patch Kit's 10 HP/s on a wall loses to one lobber's 27 DPS. Lobbers should hit tombstones and the Ghost Furnace at the defence rate (54).

## 5. Top 8 changes, ranked

1. Plain fix. Every summon (angels, skeletons, Adept, guardian, furnace, puppet while puppeted) carries a bt_risen-style tag: no wreck, no essence, no XP orb, no veterancy XP for the killer, needs pop room; tombstone skeletons share DragonRaise's 8-per-owner cap.
2. Plain fix. Empower: 20 s cooldown, one rank per target per 60 s, never on heroes, commanders, experimentals or summons. Fed to the Adept it gives 120 XP, not a level; Adept levels at 120/300/540/840/1200 XP, enemy deaths only.
3. Plain fix. Damage: Brine Bolt 25; Drowned Tithe 3 dmg/s (24 total), the slow is the point; Captured Spark 30 per jump x 4; Thunderhead 25 per strike (250); Rising Tide gains 15 damage.
4. Plain fix. Heals on Bloom's scale: Grave Tide 2 HP/s (16 HP, 32 on creep); Seed 3 HP/s x 10 s (30 HP), sapling 60 HP and targetable.
5. Taste (lovish's idea). Tombstone 150 HP at unit-rate damage, 1 skeleton alive per stone, creep pull 12 blocks not 16; rename the caster (Barrow Warden or similar); Adept level 5 raises from essence (2 per skeleton), not corpses.
6. Taste. HLT gated behind Tier 2 research, or 45 per 2.5 s (18 DPS) with x2 against siege and artillery roles, so the enhanced raid tower keeps a job and lobbers keep a window.
7. Taste. Angels hover at melee height (targetable by melee, like the Phoenix), Mender Angel 15 s life so two never stack; Spirit Puppet is a channel that breaks when the shaman is hit, sealed or dies, and the puppet drops nothing.
8. Plain fix. autocastEssence on Ability (gated like autocastEnergy), explicit AutoRules for all 22, a BUILDING_HURT rule for Patch Kit; Soul Boiler only on buildings within 24 blocks of the caster and moved to the 20-essence slot (Ghost Furnace to 10). A dead caster drops its held essence as wisps (decisive kills pay).
