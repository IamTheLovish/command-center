# Hero AI v2: Technical Design

**Base:** merged HeroBot (PR 224, merged 2026-10-26) Â· **Codemap sha:** bbbdac21 Â· **Decisions:** D030 (flee vs orders), D031 (auto-spend)

> **Input gaps.** Only two inputs were attached: the brief and the **hero** codemap. The hero codemap was saved at `codemap\unit.md`, which looks like a misnamed file. `design/hero_mode.md` and the unit, ability, player and gametest codemaps were **not** attached. Everything I took from them, or from code outside `hero/`, is marked **VERIFY**.

---

## 1. Goals and constraints (from the brief)

- **Implementation.** Hand-coded only, with no runtime AI services.
- **Cost.** Decide about once per second. Use the existing spatial grids and never scan the full map.
- **Fairness.** The hero only knows what its owner can see.
- **Orders.** Player orders win (#14), with the D030 exception for FLEE.
- **Bots.** Bot heroes use the same brain (#17).
- **Process.** Tests come first. Nothing merges without lovish's OK.

---

## 2. Package and classes

**New package:** `com.solegendary.reignofnether.hero.ai`. The location is a proposal; existing files stay in `hero/`.

| Class | Responsibility | Key signatures |
|---|---|---|
| `HeroBrain` | HFSM controller, one per AI-driven hero. It owns the state and the sub-components. | `void tick(ServerLevel lvl, long tick)`; `BrainState state()`; `void onPossessionStart()`; `void onPossessionRelease(OrderSnapshot last)` |
| `BrainState` (enum) | The four top-level states. | `OBEY, ESCORT, FIGHT, FLEE` |
| `OrderLock` | Checked first, every tick. It holds the active player order, a suspended order, and the danger epoch used by D030. | `void onPlayerCommand(Order o, long tick)`; `void onPlayerSelect(long tick)`; `boolean blocksMovement()`; `boolean holdPosition()`; `boolean fleeAllowed(int dangerEpoch)`; `Optional<Order> resumable()` |
| `Perception` | Builds a fog-filtered snapshot. It runs only on budgeted scan ticks. | `PerceptionSnapshot scan(Unit hero, long tick)` |
| `PerceptionSnapshot` (record) | Visible allies, enemies, hostile buildings and projectiles/AoE, hero HP, and observed cooldowns. | immutable |
| `SeenCooldowns` | Tracks an enemy cooldown only after the owner actually saw the cast (brief H). | `void onCastSeen(UUID caster, AbilityId a, long tick)`; `OptionalLong readyAt(UUID, AbilityId)` |
| `FightEval` | Lanchester ratio with hysteresis, danger level, and surround detection. | `FightReading evaluate(PerceptionSnapshot s, Personality p, Behaviour b, FightReading prev)` |
| `FightReading` (record) | Fight assessment output. | `double ratio, Stance stance (ENGAGE/HOLD/DISENGAGE), double danger, boolean surrounded, int dangerEpoch` |
| `FightUtility` | Utility scoring inside FIGHT, and escape options inside FLEE. It is a refactor of v1 `bestTarget`. | `ScoredIntent best(PerceptionSnapshot, FightReading, Personality, TeamBlackboard)` |
| `TeamBlackboard` | One per team. Holds the focus target, stun claims, heal stagger and commander-guard flag. | `boolean claimStun(UUID target, long until)`; `Optional<UUID> focus()`; `void proposeFocus(UUID, double score)`; `boolean healSlotFree(long tick)` |
| `Personality` (record) | Data-only weights per kit: aggression, flee HP, kite range factor, target weights (healer, artillery, low-HP hero, attacker-of-self), and ability-spend weights. | loaded by `PersonalityTable.forKit(HeroKit)` |
| `Behaviour` (enum) | Per-player setting (#12). | `DEFENSIVE, BALANCED, AGGRESSIVE`; `double engageAt(), disengageAt(), fleeHpOffset()` |
| `ReactionQueue` | Delays intents by 250Â±100 ms (5Â±2 ticks) using a seeded RNG. Imperfection scales with Behaviour or bot difficulty and can be turned off in tests. | `void push(Intent i, long nowTick)`; `Optional<Intent> pollReady(long nowTick)` |
| `DecisionLog` | Per-hero ring buffer (64 entries) and a `[HeroAI]` log line. It feeds the debug overlay and records budget hits. | `void record(long tick, BrainState s, String why, FightReading r)`; `List<Entry> recent()` |
| `TickBudget` | Gates scans with `(tick + heroId) % 20 == 0`, counts scans per tick, and logs overruns. | `boolean scanDue(long tick, int heroId)`; `void noteScan()`; `int hitsThisTick()` |
| `AutoSpend` (PR3) | Spends ability points on the best-scoring pick (D031). | `Optional<AbilityId> choose(HeroCore core, Personality p, FightStats recent)`; `void maybeSpend(...)` |
| `HeroAiSettings` (PR3) | Server-side per-hero settings: AI on/off, Behaviour, auto-spend (default on). | `get(UUID hero)`, `set(...)`; cleared on world unload |

### Existing files touched

- `hero/HeroBot.java` (387 lines). This is where the brain is invoked; old casting logic is removed by PR2 (#17).
- `hero/HeroServerEvents.java`. Handles tick and world-unload cleanup.
- `hero/PossessionServer.java` (992 lines). Adds possession start/release hooks.
- `hero/HeroServerboundPacket.java`. Adds new settings actions; the location of the `HeroAction` enum needs **VERIFY**.
- `hero/HeroClientboundPacket.java`. Syncs settings and the debug line.
- `hero/HeroKits.java` (749 lines). Personality keys per kit.

---

## 3. Tick budget

1. **Every tick (cheap).** Run the `OrderLock` check, poll the `ReactionQueue`, and continue the current intent (path step, keep range).
2. **Scan ticks only.** When `(tick + heroId) % 20 == 0`, run `Perception.scan` â `FightEval` â transitions â `FightUtility`. This means one scan per hero per second, with 16 heroes spread across 20 slots.
3. **What the gate covers.** The gate applies **only** to UnitGrid and TargetScan queries. The codemap trap says the v1 hooks also do fog queries per tick. Fog checks therefore move inside the scan, run per candidate only.
   - UnitGrid and TargetScan class paths: **VERIFY** (likely in `unit/`, not mapped).
4. **Emergency wake.** Taking damage of at least X% max HP between scans sets `wakeNextTick`. This allows at most one extra scan per hero per second, and the extra scan is still counted.
5. **Budget hit.** If more than 2 scans happen in one tick, the extras slip to the next tick and `DecisionLog` writes `[HeroAI] budget`.
6. **Idle and distant heroes.** Use a period of 40 instead of 20 when no visible enemy is within ~32 blocks and there is no order change.

---

## 4. Data flow per decision

```
Player order / select packet âââº OrderLock.onPlayerCommand / onPlayerSelect
                                         â
tick ââº HeroBrain.tick
   1. OrderLock: possessed? â return (PossessionServer drives; PossessionMobMixin â drive)
   2. ReactionQueue.pollReady â execute intent (move/cast/attack), respecting OrderLock
   3. TickBudget.scanDue? no â continue current intent; return
   4. Perception.scan (UnitGrid radius query + fog filter + SeenCooldowns)
   5. FightEval.evaluate â FightReading (ratio, stance, danger, epoch)
   6. TeamBlackboard read (focus, stun claims, heal slot)
   7. Transition:
        FLEE    if danger â¥ p.fleeDanger AND OrderLock.fleeAllowed(epoch)
        OBEY    if OrderLock has active order (cast-only-while-executing)
        FIGHT   if visible enemies and no order
        ESCORT  otherwise (stay near owner's selected units, PR3)
   8. FightUtility.best (FIGHT/FLEE; in OBEY only casts that need no movement off the order)
   9. Blackboard writes (claim stun, propose focus) â ReactionQueue.push(intent)
  10. DecisionLog.record(state, why, reading)
```

### FightEval detail

- **Side power.** For each side, `P = (Î£HP) Ã (Î£DPS)`, using only visible units. Hostile defensive buildings in range count on the enemy side; the building attack-data API needs **VERIFY**.
- **Ratio.** `ratio = P_us / P_them`.
- **Stance and hysteresis.**
  - The stance becomes ENGAGE when `ratio â¥ 1.2 Ã b.engageMul`.
  - It becomes DISENGAGE when `ratio < 0.8 Ã b.disengageMul`.
  - Otherwise the previous stance holds.
- **No chasing into towers or bigger armies.** Any target whose position lies inside a visible hostile tower's range, or whose local ratio is below 1.0, gets a heavy penalty in `FightUtility`. In PR1, FightEval blocks pursuit outright.
- **Surround detection.** `surrounded` is true when at least 3 enemies sit in at least 3 distinct 90Â° sectors within 6 blocks.

---

## 5. FLEE vs player orders (D030, exact rules)

`OrderLock` holds three things:
- `activeOrder` (the latest player order)
- `suspendedOrder`
- the epochs `dangerEpoch` and `ackedEpoch`

**Rules:**

1. **New danger.** FightEval sets `danger` from HP fraction, incoming DPS and ratio. Each time `danger` crosses the personality and behaviour flee threshold upward from a *cleared* state, `dangerEpoch++`.
   - "Cleared" means danger stayed below `threshold â 0.15` for 3 consecutive scans (about 3 s), or the hero healed above `fleeHp + 15%`.
2. **The hero may flee on its own first.** `fleeAllowed(e)` returns `e > ackedEpoch`.
   - If an order is active, it moves to `suspendedOrder`; it is not erased.
   - The hero enters FLEE even under move, attack or hold.
3. **A fresh player command wins.** Any of the following, issued after FLEE began, sets `ackedEpoch = dangerEpoch`, exits FLEE, and makes the new order active:
   - a player move, attack, hold, stop or retreat command, or
   - a **select** of the hero ("selects or commands it again").
   - If the player only selects the hero, it resumes `suspendedOrder`. If there is none, it goes to OBEY/idle.
4. **No re-trigger within the same epoch.** Within the same danger epoch, FLEE cannot come back even if HP keeps falling. Under an order in that epoch, the AI may still cast defensive or escape abilities **in place**, without movement abilities that leave the order.
   - **Proposal to ASK:** should an extra drop of at least 25% max HP after the ack also count as "new danger"? It is off by default.
5. **When FLEE ends by itself** (safe, danger cleared), the hero resumes `suspendedOrder` if it is still valid. Otherwise it goes to ESCORT/idle.
6. **Escape by any means (#3).** Inside FLEE, `FightUtility` also scores "kill blocker first", using the blocker's HP, our burst, and the chaser's threat.
   - Example: a low-HP ranged chaser that would shoot us before we get far gets attacked first.
   - Escape and movement abilities score highest when their path leads toward the friendly army or commander.
7. **Possession.**
   - While a hero is possessed, the brain is fully off.
   - On release, `onPossessionRelease(last)` loads the player's last order into `activeOrder` (#14).
   - **VERIFY:** whether `PossessionServer` exposes the last movement or attack target at release (the codemap only says "orders diversion").

**Server-side select events:** **VERIFY.** I found no evidence that the server sees selection. If it doesn't, PR1 adds a `SELECTED` action to `HeroServerboundPacket`, sent by the client when the hero enters the selection.

---

## 6. Auto-spend (D031)

- **What it spends:** ability points (brief, `playtest_oct20_lane_c #7/#29`). How ability points are stored in `HeroProgression` or `HeroCore` needs **VERIFY**.
- **Pick rule.** The best pick is deterministic, not random. For each option:

  `score = Personality.spendWeight[ability] Ã fightFactor + rankSynergy`

  - `fightFactor` comes from `FightStats` for the last N fights: damage taken vs dealt, and the share of deaths spent fleeing.
  - Ties are broken by kit order in `HeroKits`.
- **Toggle.** On the hero panel, default **on**. Manual spending is always allowed. A manual spend made before the auto-spend tick simply takes the point.
- **When it runs.** Auto-spend runs on the hero's scan tick, only when points are above 0 and the hero is not in FLEE.
- **Bot heroes:** always on.
- **Doc conflict.** `hero_mode.md` 5b says skill points "stay manual". PR3 must update 5b to cite D031. The file was not attached; **VERIFY** the exact text.

---

## 7. Hero-panel settings

- **Move the toggle.** Move the `hero_ai` toggle from HUD settings (#224 client config plus HUD checkbox) to the **hero panel**. The hero panel class is not in the hero codemap: **VERIFY** its location.
- **Panel controls:**
  - **Hero AI**: on/off. The existing `HERO_AI_ON/OFF` action is kept.
  - **Behaviour**: Defensive / Balanced / Aggressive. New action `HERO_AI_BEHAVIOUR`.
  - **Auto-spend**: on/off. New action `HERO_AUTOSPEND`.
- **Authority.** The server (`HeroAiSettings`) is authoritative, and the client panel mirrors it via `HeroClientboundPacket`. The current `hero_ai` *client* config becomes only the default sent on join, so that bots and server logic do not depend on client config.
- **Lifetime.** Settings persist per hero for the match and are cleared on world unload, to avoid the `fallenHeroes` leak pattern. Saving per-hero preferences across matches is roadmap #4 and out of scope.

---

## 8. Selection: worker-style drag priority and stay-near

- **Drag-select (#20).** Reuse the worker rule: when a drag box contains any non-worker, non-hero unit, heroes are excluded.
  - Clicking the hero directly selects it.
  - A drag containing only the hero (or the hero plus workers, matching the worker rule) selects it.
  - The location of the worker drag-priority logic needs **VERIFY** (likely `unit/` or `player/` client selection, not mapped). The hero becomes a flagged participant in that same filter, not a second code path.
- **ESCORT (#19).** This is the idle job.
  - **Anchor.** The anchor is the centroid of the owner's current selection, excluding the hero. If nothing is selected, it falls back to the commander, then to the nearest friendly group.
  - **Leash.** The hero targets a 4â8 block offset behind the centroid relative to the nearest visible enemy, re-targeting on scan ticks.
  - **Source of selection.** This needs the server to know the owner's selection: **VERIFY**. Otherwise a throttled `SELECTION_CENTROID` packet (at most 1 per second, only on change) is added in PR3.
  - **Bots.** Bots use their army group centroid.

---

## 9. PR split (tests listed first in each PR)

**Dependency:** merge **#133** (nightly bot ladder) first. The harness (#9) rides on it rather than building a second one.

The six existing `HeroAiGameTests` from #224 have unknown names. **VERIFY** overlap, and rename or extend them rather than duplicating.

### PR1: OrderLock, Perception, FightEval, DecisionLog, plus a thin HFSM shell (OBEY/FLEE only)

**Tests:** `HeroAiGameTests`
- `move_order_not_overridden`
- `hold_position_respected`
- `flee_starts_without_order`
- `reselect_and_move_overrides_flee`
- `retreat_threshold`
- `no_chase_under_towers`
- *(added)* `fog_hidden_enemy_ignored`
- *(added)* `fight_eval_hysteresis_1_2_0_8`
- *(added)* `possession_release_resumes_order`

**New files:**
- `hero/ai/HeroBrain`
- `BrainState`
- `OrderLock`
- `Perception`
- `PerceptionSnapshot`
- `SeenCooldowns`
- `FightEval`
- `FightReading`
- `DecisionLog`
- `TickBudget`
- `Behaviour` (BALANCED only wired)

**Touched files:**
- `hero/HeroBot.java` (calls `HeroBrain`; v1 casting stays for now)
- `hero/HeroServerEvents.java` (tick and unload cleanup)
- `hero/PossessionServer.java` (start/release hooks)
- `hero/HeroServerboundPacket.java` (`SELECTED`, if needed)
- the gametest `HeroAiGameTests` file (path **VERIFY**)

**Notes:**
- The flee tests need a minimal FLEE that runs toward the army, which is why the shell is included.
- Target pick and combo order are left to PR2, where utility lands.

### PR2: FIGHT utility, ReactionQueue, TeamBlackboard, one brain

**Tests:**
- `target_pick` (healer > artillery > low-HP hero > attacker-of-self, finishes kills)
- `combo_order` (stun/slow then damage; gap-closer only if follow-up ready)
- `no_double_stun`
- `staggered_heals`
- `focus_converges`
- `ranged_kites_at_max_range`
- `steps_out_of_visible_aoe`
- `escape_kills_blocker`
- `skillshot_leads_target`
- `reaction_delay_within_150_350ms`
- `sixteen_heroes_budget` (8v8, budget hits logged, no tick overrun)

**Files:**
- `hero/ai/FightUtility`, `ReactionQueue`, `TeamBlackboard`
- `hero/HeroBot.java` (remove old casting, #17)
- `hero/HeroKits.java` (ability metadata: CC/gap-closer/heal tags, **VERIFY** whether these already exist)
- `hero/FactionHeroAbility.java` (tags)

**Harness:** reports from #133 cover AI-vs-AI and AI-vs-no-AI, each with imperfection on and off.

### PR3: Selection and hero panel

**Tests:**
- `drag_select_skips_hero`
- `click_selects_hero`
- `alone_drag_selects_hero`
- `escort_follows_selection`
- `autospend_picks_best`
- `autospend_off_leaves_points`
- `manual_spend_with_autospend_on`
- `settings_cleared_on_world_unload`

**Files:**
- `hero/ai/AutoSpend`, `HeroAiSettings`
- `hero/HeroServerboundPacket.java`, `hero/HeroClientboundPacket.java`, `hero/HeroProgression.java`
- `hero/HeroClientEvents` (listed client-only in the codemap; not in the key-class list, **VERIFY**)
- the hero panel UI (**VERIFY**)
- the selection filter (**VERIFY**, in `unit/` or `player/`)
- `design/hero_mode.md` (5b update, plus the "Hero AI: keep improving" standing rule)

### PR4: Personalities (data) for tank, assassin and support/caster

These map to three of the seven kits in `HeroKits`; the mapping should go through `HeroRoles.java`.

**Tests:**
- `personality_tank_holds_frontline`
- `personality_assassin_targets_backline`
- `personality_support_saves_dying_ally`
- `behaviour_defensive_retreats_earlier`
- `commander_guard_defends_own`

**Files:** `hero/ai/Personality`, `PersonalityTable`, `hero/HeroRoles.java`, `hero/HeroKits.java`.

**Follow-up:** the remaining four kits.

### PR5: Parry/block (new mechanic; 0 hits in the Java)

- 400â600 ms telegraph and a ~200 ms window.
- **Tests:** `parry_window_200ms`, `telegraph_visible_before_strike`, `ai_parries_telegraphed_strike`.
- **Files:** **VERIFY** (combat and ability code are not mapped), plus `hero/HeroFx.java`.

### PR6+: Per-hero animation and effects polish

This is the art lane, following the bat-animation-study and bat-art-director skills. It stays out of the AI PRs.

### Iteration rule

Each round is one measured change on the #133 harness. Stop after 3 rounds in a row that each improve win rate by less than ~2 points, then hand over to lovish for a playtest.

---

## 10. Risks

1. **`HeroProgression.holdCarry` has no stop handler (trap P011).** Auto-spend could interact with carried state. PR3 must audit this path first.
2. **World-leak pattern (`fallenHeroes`, fixed in #248).** `TeamBlackboard`, `DecisionLog`, `HeroAiSettings` and `SeenCooldowns` must all clear on world unload. A test covers this in PR3.
3. **Perf trap.** The v1 hooks hit UnitGrid, TargetScan and fog per tick. The PR1 budget and the `sixteen_heroes_budget` test guard this; it must not regress when FIGHT utility grows.
4. **"Heroes never autocast" (REV).** v2 does cast on its own. Confirm this does not conflict with the unit autocast system's assumptions (**VERIFY**, in `ability/`).
5. **Possession conflicts.** Two drivers on one mob (`PossessionMobMixin` â `drive`) could fight each other. The brain must hard-return while possessed.
6. **Server knowledge of selection** (select ack, escort centroid) may need new packets. Both should stay small and throttled.
7. **Flaky GameTests.** The reaction delay and imperfection are random. Use a seeded RNG, turn imperfection off in tests, and run a 10-run stress pass per the auditor advice.
8. **Fog fairness leaks** through `Î£HP` of partially visible armies. Count only units visible this scan, not remembered ones.
9. **Open item to ASK lovish:** should the 25% extra HP drop count as "new danger"? Also, the "near-death flee vs hold order" REV item is now settled by D030; close it in `review/`.
10. **#133 not merged.** The harness, and the stop rule that depends on it, would be blocked. If #133 stalls, PR1 can still merge on GameTests alone.