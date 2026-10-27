# Siege spec, draft 1: walls, buildings, siege, game enders, towers, pacing

**Ground truth used:** `design/defences.md` and `design/balance.md` (big units and game enders) only.

**Missing inputs, which must be checked before this is final:**
- **`decisions.md` was not attached.** I could only respect the rules restated in the two docs:
  - one shape and one price per job across all seven factions;
  - danger is shown (telegraphs);
  - no multiplicative buff piles;
  - game enders are announced, slow and counterable.
- **PR 222 (artillery range and setup) and PR 146 (vehicles breaking buildings) were not attached.** Wherever this spec touches them, it states a *placeholder* rule and flags it **[verify vs PR]**.

All numbers marked *(est.)* are starting points for `tools/balance_audit.py` and DuelGameTests, not tuned values.

---

## 1. Target pacing (sets every other number)

**BAR (from memory):**
- A fortified line is cracked by artillery plus a T2 push in the low minutes.
- Raids on unguarded extractors are near-free.
- LLT and HLLT make raiding cost something rather than making it impossible.
- I am not certain of exact BAR timings.

**Proposed rule.** Pacing is anchored to the game-ender clock in `balance.md`. The first strike lands about **4.2 min of construction + 3 Ã 50 s charge â 6.7 min** after placement. A counter-attack is meant to be a real answer ("the counter-attack is the classic answer to a slow plan"). So an equal army must be able to crack a defended base well inside that window.

| Scenario | Target *(est.)* |
|---|---|
| T1 raid of equal metal vs one anti-raid tower at an expansion | Tower wins (already tested: `defence_anti_raid_tower_out_trades_its_cost_vs_raiders`) |
| T2 army with siege vs base whose defences â 25% of attacker's metal: breach outer wall | 30â45 s |
| Same: reach and kill capitol | 2â3 min, attacker loses 40â60% |
| Same army **without** siege units | Breach â¥ 2Ã slower; capitol only with â¥ 1.5Ã metal |
| Pure turtle (â¥ 50% metal in static) vs equal army that keeps teching | Turtle loses on economy within ~8 min (est.) |

These rows become DuelGameTests "Siege" rows, alongside the existing "Beast" row.

**Conflicts:** none yet. `balance.md` Â§3 has no siege-pacing row.

---

## 2. Walls and gates

**BAR.** Dragon's teeth and fortification walls are cheap, block pathing and are reclaimable. Any weapon can damage them, but units do not auto-target them. *Unsure:* whether BAR gives walls a damage reduction.

**Current rules (`defences.md`):**
- **Wall segment:** 15 m, 400 HP.
- **Fortified wall:** 40 m / 20 e, 1100 HP. Roughly the same HP per metal; you pay for footprint and time.
- **Gate:** 320 HP. Shuts while an enemy is within 6 blocks.
- **Auto-targeting:** ordinary units never auto-target walls (`MiscUtil.isBuildingAutoAttackable`).
- **Siege, heavy and experimental units** draw aggro from walls and deal Ã3 / Ã6 (`WallSegment.drawsAggroFrom`, `WallPlacement.destroyRandomBlocks`).

**Proposed rule:**
1. **Keep the current wall rules.** Walls exist to buy time and channel a push into gates and towers. They are not a damage sponge for everyone.
2. **Manual attack by ordinary units deals Ã0.5 to walls and gates** *(est.)*.
   - A T1 army can still cut through if ordered, slowly.
   - This prevents an unbreakable wall when the attacker has no siege.
3. **Gates are the weak point by design.** 320 HP is below a plain wall, so attackers have a reason to hit the gate.
   - Gates should take the Ã3 / Ã6 siege multiplier like walls.
   - *Unclear in docs:* whether gates use `WallPlacement` damage.
4. **Breach time targets** *(est.)*, one T2 siege unit with no repair:
   - plain segment â¤ 10 s;
   - fortified segment â¤ 25 s.
   - Example: Gorehorn Rhino does 6 dps Ã 2.5 building multiplier = 15 dps.
     - With Ã3 on top: about 9 s plain and 24 s fortified.
     - Without Ã3: about 27 s and 73 s.
   - So the stacking question below decides whether the targets hold.

**Conflicts:**
- **Multiplier stacking is undefined.**
  - Does the Rhino's 2.5Ã building damage (`balance.md` Â§1.2) stack with the wall Ã3 (`defences.md`)?
  - Is the Rhino even classed as "siege/heavy" for `drawsAggroFrom`?
  - **Proposal:** take the higher of the two multipliers, never the product (no multiplicative piles).
- **Breach Charge vs wall lines.** Breach Charge stops at the "first building" for 120 damage. That one-shots nothing in a wall line: plain walls have 400 HP. This is fine. Note that the charge also ignores the Ã3, because it is a flat ability hit.

---

## 3. Building HP, armour and repair under fire

**BAR (I believe):**
- Buildings have HP and share a default armour class in the weapon damage tables. Some weapons deal reduced damage to buildings.
- Constructors repair at build power at any time, including under fire. *Unsure* whether repair costs resources in current BAR.

**Proposed rule:**
1. **No armour types on buildings.**
   - `balance.md` Â§2.5 states "buildings take block damage, not damage types". Adding armour classes would be a new hook in every weapon.
   - Use one per-attacker **building multiplier** (the Rhino's 2.5Ã is the model) and HP as the only tuning knobs.
2. **Repair under fire is allowed, at reduced rate.**
   - A building damaged in the last 3 s repairs at 50% *(est.)*.
   - Reason: a constructor ball out-healing a tower line makes turtling unbeatable. Pure BAR behaviour may be fine at BAR's scale but is untested here.
   - The Steam Hauler's heat cost (`balance.md` Â§1.7) is the faction-flavoured precedent for "repair has a price".
3. **Repair rate cap:**
   - One T1 constructor â¤ 8 HP/s *(est.)*. That is about one raider's dps, so one worker can hold one raider and no more.
   - Stacking workers is linear (BAR-like) but capped at 4 per building *(est.)*.
4. **HP reference ladder** (existing, keep):

| Building | HP |
|---|---|
| Trap | 60 |
| Raid tower | 260 |
| Gate | 320 |
| Wall | 400 |
| Enhanced raid tower | 600 |
| Anti-T3 emplacement | 700 |
| Fortified wall | 1100 |
| Game ender | 2400 |

**Conflicts:**
- **Trap rearming.** Trap rearming *is* repair (`defences.md`). Exempt traps from the under-fire penalty, or rearming a snare mid-fight becomes pointless.
- **Game-ender raids.** The under-fire penalty makes game-ender raids (10% HP = one stage, `balance.md` Â§2.1) slightly stronger. This is intended; flag it to the balance audit.

---

## 4. Siege units

### 4a. Artillery range and setup **[verify vs PR 222]**

**BAR.** Artillery outranges standard defences and LLT and HLLT, but is fragile and inaccurate against moving units. *Unsure* whether any BAR artillery has an explicit deploy time; most fire on the move or after a short turn.

**Proposed rule (placeholder until PR 222 is read):**
- Artillery range **> 16** (the enhanced raid tower and anti-T3 range), so artillery always out-ranges T1âT2 towers.
- Artillery range **< 20â24** (Sky Watch, Flak) is irrelevant, because those are air-only.
- Suggested numbers: range 20 *(est.)*, setup 2 s to deploy and 2 s to pack *(est.)*.
  - This mirrors the Shellback's Moor (2 s each way), so the faction language stays consistent.
- **Minimum range 4** *(est.)*, again mirroring the Shellback's dead zone. Melee that reaches the guns is safe.

**Conflicts:**
- **Shellback battery range.** The Shellback's deck battery reaches exactly **16**, equal to tower range, not more. Either:
  - it is not "artillery" under this rule (it is a beast, so the exemption is acceptable), or
  - it moves to 17 *(est.)*.
- **Mortar Galley.** `balance.md` calls the Mortar Galley the Tidewrought artillery, but neither doc gives its range. Audit all artillery against the >16 rule.

### 4b. Vehicles breaking buildings **[verify vs PR 146]**

**Proposed rule:**
- Vehicles and heavies use the wall multiplier set by the `drawsAggroFrom` class: Ã3 heavy, Ã6 experimental.
- Against non-wall buildings they use their own building multiplier: default Ã1.5 heavy *(est.)*, Rhino Ã2.5.
- Never both (see Â§2).

**Conflict:** if PR 146 implemented building damage as block destruction (like `destroyRandomBlocks`), confirm it does not bypass building HP.

### 4c. Do T1 raiders hurt buildings?

**BAR.** Yes. Raiding extractors and constructors is the core of the early game.

**Proposed rule:**
- **Yes, at Ã1 against economy buildings.**
- **Ã0.5 against walls and gates on manual order only** (Â§2).
- **Ã0.5 against towers** *(est.)*. A raider squad must not trade into a tower it should flee from. The existing tower test already expects towers to win.
- This keeps lovish's "raiding units that necessitate a reaction" (`defences.md`). Undefended extractors die; towered ones don't.

---

## 5. Game enders vs fortified bases

**BAR.** Nuke versus anti-nuke stockpile, silo raids, and commando strikes on energy.

**Current rules (`balance.md` Â§2):**
- 5500 m / 12000 e, 2400 HP.
- Auto-targets the nearest enemy capitol.
- Ward Spire: 650 m / 2500 e, 64-block radius, 90 s charge, intercepts one strike.

**Proposed rules:**
1. **Ward Spires are not stopped by walls.** A fortified base still needs a Ward Spire. Static defences protect against armies, not against strikes.
2. **Game-ender damage is tuned against fortified-base HP.**
   - A Sun Spire strike (400 to buildings, r10) kills:
     - every raid tower and plain wall in radius;
     - leaves fortified walls (1100) and emplacements (700) standing.
   - Doom Forge (500) behaves the same.
   - This is good: a strike strips the light defence layer, then an army must still walk in. Keep it.
3. **Enhanced and fortified buildings take Ã0.75 from strikes** *(est.)*. This is the turtle player's reward. Ward Spires stay the hard counter.
4. **Raiding a game ender through its defences** must be achievable inside one 50 s stage:
   - 240 damage per stage knock-back (10% of 2400);
   - one T2 siege unit at about 15 dps needs about 16 s.
   - That is reachable if the attacker breaches the outer wall in 30â45 s (Â§1).

**Conflicts:**
- **World Seed.** The World Seed's 500 to buildings (25/s) is a damage-over-time field. Should rule 3 apply to it? Proposal: yes, uniformly.
- **Placement rule.** `balance.md` says the game ender is built "near home". Inside a fortified base it may be unraidable within one stage. Add a minimum distance of 24 blocks from own capitol *(est.)* only if playtests show this.

---

## 6. Defensive towers: counters on both sides

**BAR.** LLT, then HLLT, then heavy defences, with artillery out-ranging all of them. Turtles lose to artillery and to economy; rushes lose to a well-timed LLT.

**Existing ladder (`defences.md`):**
- **Raid tower:** 110 m, 7 dps, range 14, Ã1.5 vs â¤70 HP units.
- **Enhanced raid tower:** 260 m, 18 dps, range 16.
- **Anti-T3 emplacement:** 15% of the priciest T3, range 16, Ã3 vs experimentals.

**Proposed rule.** Each tower has one designed loser and one designed killer:

| Tower | Beats | Loses to | Number to hold *(est.)* |
|---|---|---|---|
| Raid tower | Equal-metal T1 raiders | 2 T2 heavies; artillery | Dies to 2 T2 heavies in â¤ 20 s |
| Enhanced raid tower | T1 armies â¤ 2Ã its metal | Artillery (range > 16); siege beasts | Rhino + 1 heavy kill it in â¤ 25 s |
| Anti-T3 emplacement | A lone experimental (Ã3) | T2 mass (no bonus vs them) | 3 T2 heavies kill it in â¤ 20 s |
| Sky Watch / Flak | Flyers | Any ground unit (air-only) | Unchanged |

**Anti-turtle levers:**
- artillery out-ranges every tower;
- repair under fire is halved;
- towers deal no bonus damage to T2 heavies;
- game enders strip light defence.

**Anti-rush levers:**
- the raid tower is capitol-tier, at 110 m, and buildable in the field by combat engineers;
- gates shut automatically within 6 blocks of an enemy.

**Conflicts:**
- **Tower stats are faction-shared** ("one shape and one price per job"), but the factions' T2 heavies differ. "Dies to 2 T2 heavies in â¤ 20 s" must hold for the *weakest* T2 heavy. Add this to `DefenceGameTests`.
- **Self-firing T2 towers.** The Storm Oak, Lighthouse Battery and Rail Battery are outside the shared ladder (`defences.md`, "Existing defences stay"). Audit their range against the >16 artillery rule.

---

## Implementation order *(proposal)*

1. Siege DuelGameTests rows that assert the Â§1 pacing table.
2. Multiplier rule: max, never product.
3. Artillery range audit against 16.
4. Repair-under-fire penalty.
5. Strike Ã0.75 on enhanced and fortified buildings.

Tune numbers only after the step-1 tests exist.

---

## Questions for lovish (taste)

1. **Repair under fire:** halved while a building is under attack (anti-turtle), or full BAR-style repair, accepting that a constructor ball can hold a line?
2. **Ordinary units versus walls:** may a T1 army chew through walls slowly on a manual order (Ã0.5), or are walls strictly a siege/heavy problem, as today?
3. **Capitol loss** (already open in `balance.md` Â§4): does a capitol destroyed end the game? This decides whether "crack a base" means "take the capitol" or "raze everything", and so it decides the Â§1 pacing targets.