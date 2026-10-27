---
title: Hero AI v2 PR 1 - report (OrderLock, Perception, FightEval, DecisionLog)
type: report
date: 2026-10-27
pr: 275
branch: claude/hero-ai-v2
---
# Hero AI v2, PR 1: report

- **PR:** #275 (draft), branch `claude/hero-ai-v2`, from origin/main d9fac5c6. Not merged.
- **Claim:** `hero-ai-v2-pr1` on #91. Release it after the merge.
- **Scope:** v2 drives the Dawn Paladin only (`HeroBrain.ROLLED_OUT`, lesson L005). The other six heroes run v1 unchanged. D031 (auto-spend) is not in this PR.

## Files changed

New, in `bar/src/main/java/com/solegendary/reignofnether/hero/ai/`:
- `OrderLock.java`: the player's order comes first. It reads the hero's command queue and the queue's own `stillCarriedOut` rule, and holds the D030 danger counters (new danger vs acknowledged).
- `Perception.java`: one UnitGrid query (16 blocks) and one BuildingGrid query a second. It filters by concealment and fog (the owner's fog masks when online, sight circles for a bot). It also finds enemy towers that shoot ground units.
- `FightEval.java`: Lanchester power ratio with 1.2/0.8 hysteresis; near death at 30% (healed at 45%); threatened.
- `DecisionLog.java`: a 16-entry primitive ring per hero. Text is built only when read, or at DEBUG on logger `reignofnether/HeroAI`.
- `HeroBrain.java`: the per-hero state, kept on HeroCore (it dies with the hero, so there is no world-unload leak). It also holds the rollout set.

Changed:
- `hero/HeroBot.java`: v2 section (think / everyTick / fightV2 / flee / resume / onPlayerSelect / mayAutoTarget). v1 is extended, not replaced:
  - `bestTarget` gains an overload that adds the player's focus target and a bonus for disabled targets;
  - `heal` gains a slack parameter (v1 keeps its +2).
- `hero/FactionHero.java`: calls `HeroBot.everyTick` every tick for v2 heroes.
- `hero/HeroCore.java`: `brain()` / `brainIfAny()`.
- `hero/HeroKit.java`, `hero/HeroKits.java`: `AbilitySpec.cc` flag (stun / root / slow), set on 7 abilities.
- `hero/HeroAction.java`, `hero/HeroServerboundPacket.java`: `HERO_SELECTED`. It is rate-limited and accepted only for heroes the sender may command, and the server then runs `HeroBot.onPlayerSelect`.
- `unit/UnitClientEvents.java`: sends `HERO_SELECTED` when the player's own hero joins the selection.
- `util/MiscUtil.java`: `isIdleOrMoveAttackable` asks the brain. The effect: no auto-chase under a tower when there is no order, and no picking fights while fleeing.
- `unit/command/CommandQueue.java` (`currentStartedAt()`), `unit/command/CommandQueues.java` (`stillCarriedOut` made public), `unit/support/SupportOrders.java` (`gunRange` made public).
- `gametest/HeroAiV2GameTests.java`: 7 tests, each in its own batch.

## Tests: red and green

- **Red (tests first, on main's code):** run **40469338039**, commit 0ec3f805. All six failed for the reason each test names:

  | Test | Why it failed on main |
  |---|---|
  | move | left its lane by 6.1 blocks |
  | hold | left its hold spot by 6.0 blocks |
  | retreat | walked into the enemies at 25% |
  | target | Judgement struck the cloaked Shade Ranger |
  | tower | went 10.4 blocks from a raid tower that reaches 14 |
  | combo | charged with Judgement on cooldown |

- The 7th test (select, D030) was committed before its code (b6a0f918), because it calls the server's select entry point, which main lacks.
- **Test fixes:** c60e7035 fixes four observation bugs found on the first local run. No rule was weakened.
- **Green:** GREEN_LINE

| Test | Red (40469338039) | Green |
|---|---|---|
| hero_ai_v2_a_move_order_is_not_overridden | red | GREEN_RUN |
| hero_ai_v2_hold_position_is_respected | red | GREEN_RUN |
| hero_ai_v2_flees_below_the_retreat_threshold_until_the_player_orders_again | red | GREEN_RUN |
| hero_ai_v2_target_pick_skips_an_enemy_its_side_cannot_see | red | GREEN_RUN |
| hero_ai_v2_never_chases_into_an_enemy_tower | red | GREEN_RUN |
| hero_ai_v2_combo_gap_closer_waits_for_its_follow_up_then_stuns_before_the_damage | red | GREEN_RUN |
| hero_ai_v2_selecting_a_fleeing_hero_hands_it_back_to_its_order | (needs the new entry point) | GREEN_RUN |

Locally, all 13 `hero_ai*` tests pass: the 7 new ones plus the 6 from v1, including the Paladin's ultimate test, which now runs through v2.

**Unrelated failures:** `elder_druid_is_a_t2_worker` and `capture_bounded_when_barrier_hangs` also fail on main itself (d9fac5c6, run 40457081140). `check_shards` reports a pre-existing `SHARD_8: entry 'test:men' names no test`.

## Stress

STRESS_LINE

## Cost per hero per tick

Measured locally (steady state, 200 repeats in a test arena):
- **Per-tick half** (possession and switch lookups, two command-queue fields, OrderLock mode, cast-busy check): **50-150 ns**.
- **Once-a-second scan plus FightEval:** **0.65-0.95 us** with 1-5 units in view, **2.6-3.3 us** with an enemy tower in view. It grows linearly with the units within 16 blocks.
- **Total:** about **0.1-0.3 us per hero per tick**, not counting the actions themselves (casts and path requests the hero would make anyway). Sixteen heroes would cost a few microseconds a tick.
- **DecisionLog with DEBUG off:** one level check and six array writes per decision (at most about one a second per hero), with no strings.
- **MiscUtil hook:** one `instanceof` per auto-target candidate for non-heroes.

## Notes for the commander

- **Bot heroes:** a bot re-issues Fight to every fighter every 40 ticks. If those orders counted as "the player commands it again", a near-death bot hero would walk straight back in. So bot orders neither acknowledge the danger nor end a flight (commit 6066f042). That is my reading of D030 ("the player's word"); flag it if lovish sees it differently.
- **Rollout:** after lovish plays the Paladin, rolling out to all seven is one line in `HeroBrain.ROLLED_OUT`.
- **Known gaps** (PR 2 territory):
  - A hero with no enemy unit in aggro range may still auto-attack a tower building within its aggro range. Building aggro does not ask the brain yet.
  - The flight runs straight away from what the hero sees. It does not yet head toward the army or the commander.
- **Numbers for lovish** (AI judgement, no unit stat changed):
  - engage 1.2 / disengage 0.8;
  - near death at 30%, healed at 45%;
  - threat radius 8;
  - flight of 10 blocks;
  - follow-up window of 40 ticks;
  - a non-tower gun building counted at 10 DPS.

## Open design questions for lovish (feel only)

1. When you click a hero that is fleeing on its own, it currently goes straight back to the order it had (for example, walks back toward the enemies it fled). Would you rather it stop where it is and wait for your next order?
2. After it gets out of reach, a near-death hero stops at the edge of danger and waits for a heal or your order. Should it instead walk back to your army or commander on its own?
3. The Paladin starts running at 30% health and counts as safe again at 45%. In play, does a frontline hero like the Paladin feel like it bails too early or too late?
4. Once you have sent a hurt hero back in, it obeys until it is healed and hurt again. Should a further big hit (say another quarter of its health) let it break off on its own again?
5. Under a move order the hero still stops for about 0.3 s to cast Judgement at an enemy in reach as it walks past. Keep "fight while obeying", or should a move order mean "just walk"?
