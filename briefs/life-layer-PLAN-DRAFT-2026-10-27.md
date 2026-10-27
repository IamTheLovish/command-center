# Plan: Shared Humanoid Life Layer (L-series PRs)

**Inputs used:** the animation foundation audit (Oct 21, `7ce498e3`), the unit codemap (`bbbdac21`), and D035 as stated in the brief (no GeckoLib or Photon; consolidate the four animation systems into one). The north-star file and the decisions log were not attached. I take the north star only from the audit's quote ("every soldier breathes, shifts its weightâ¦"). Anything I could not confirm in the audit or codemap is marked **VERIFY**.

---

## 1. Goal and scope

Lift the 60+ humanoid units at once:
- 28 renderers on `AbstractVillagerUnitRenderer`
- 9 on `VindicatorUnitRenderer`
- skeleton, zombie and piglin humanoids
- the 9 RoN keyframe models
- the 5 Sunforged generated bodies

The layer adds breathing, idle weight shift, look-at, directional hit reactions and real deaths. It works without Lane B touching each model.

Out of scope: quadrupeds, dragons and Alex's Mobs creatures. They inherit the shared state and math later, through Lane B's own rigs.

Audit scores today: breath 3, weight shift 2, look-at 4, hit 2, death 2. The target for this plan is 5-6 on each for every humanoid. Each score is earned by lovish's eye, not claimed.

---

## 2. Consolidation: which system becomes the base

| Today (audit Â§1) | Becomes |
|---|---|
| **Life layer** (`animations/Life.java`, #72): pure functions of age and entity id | **The base: the math library.** Extended with springs, chains, look and fidget. |
| Generated bodies plus procedural `setupAnim`, keys as data (`design/anims/*.json` -> `gen/*Anim`, #66) | **The clip format.** Every authored clip becomes keys-as-data via `anim_lab`. |
| Vanilla keyframe clips (`KeyframeHierarchicalModel`, Blockbench exports) | Ported to keys-as-data (PR L8). The `KeyframeAnimations.animate` path is retired. |
| Vanilla / Alex's Mobs models | Humanoids get the additive Life pass through a renderer mixin. Creatures stay as they are. |

**Why Life is the base**
- **It is the only system that is stateless and shared.** Audit Â§1: "pure functions of age + entity id", and it already underpins the Bone Dragon, `Quadruped` (#76) and `Dragon` (#79).
- **It is effectively free.** Audit Â§4: Life math is 0.03 ms per 500 units; posing as a whole is about 1 Âµs per unit and 1-2% of unit cost.
- **It can react.** Directional flinch, spring settle and look lag all need it. Keyframe clips cannot do any of these (audit Â§2: "overshoot and settle â¦ separates The Isle from a sine").
- **The audit's own verdict:** "the pattern is right, the bar is far" (procedural rigs over generated bodies, keys as data).

**Why the others are not the base**
- Keyframe clips are authored per model and are direction-blind.
- Vanilla posing is nothing more than `limbSwing` sines.

**"One system" means:**
- one state store (`AnimState` slab)
- one math library (`Life.*`)
- one clip format (keys-as-data)
- one hook point per body family

It replaces:
- the per-model `WeakHashMap<Entity,float[]>`
- the rigs' private `STATE` maps
- the duplicated derivation of yaw rate and speed in each rig

---

## 3. Module layout

```
unit/modelling/animations/
  life/AnimState.java       pooled float slab keyed by entity id; slots below
  life/MotionSnapshot.java  client tick: speed, accel, yaw rate, vert speed, airborne,
                            tSinceStop/Start, exertion, attack phase
  life/HitStamp.java        last hit: age, dir (hurtDir yaw), magnitude class, source
  life/Life.java            (existing) + spring(), chain(), look(), fidget(seed,t)
  life/HumanoidLife.java    the additive pass: breath, weight shift, look, flinch
  life/DeathPose.java       death contract, fling, corpse hold
  life/BodyProfile.java     per-body-type data (section 6), table generated from data
  life/LifeLod.java         zoom-based switches (section 5)
mixin/
  LifeRendererMixin.java    hook into LivingEntityRenderer (VERIFY: name a new mixin or
                            extend AnimProfileRendererMixin)
  LivingEntityHitStampMixin.java   client animateHurt(yaw) -> HitStamp
```

**Hook points (all VERIFY against 1.20.1 mappings and our mixins):**

1. **Snapshot.** Runs in a client tick handler, once per tick, only for units drawn last frame. Candidate: a new handler, not `UnitClientEvents` (already about 2183 lines). VERIFY tick event choice.
2. **Additive pass.** Inject in `LivingEntityRenderer.render` immediately **after** `model.setupAnim(...)` and before the body and layer draws.
   - The Life layer adds rotations and offsets on top of whatever the model posed.
   - This covers vanilla `HumanoidModel`/`IllagerModel`, the keyframe models and the gen bodies uniformly.
   - Team and glow layers reuse the same parts, so they inherit the pose. VERIFY that layers copy or share part transforms after this point, especially `PassPruning` hiding subtrees.
3. **Death flip.** Vanilla rotates on `deathTime` in `LivingEntityRenderer.setupRotations`. VERIFY the method and the exact injection point.
   - Opted-in body types cancel the flip.
   - `DeathPose` drives the parts instead.
4. **Hit stamp.** Mixin on client `LivingEntity.animateHurt(float yaw)`.
   - **VERIFY this fires for unit damage at all.** Codemap trap: unit damage bypasses vanilla via `LivingEntityMixin.actuallyHurt`. It is not confirmed that `ClientboundHurtAnimationPacket` is still sent.
   - If it is not sent, the fallback is a `hurtTime` rising-edge detector plus a yaw from the last known attacker position. That fallback is less accurate.
5. **Gen bodies.** They already call `restPose()` and then their sines.
   - Their breath and smoothing move onto `AnimState` in L8.
   - Bone mapping comes from `dsl_to_game.py` output, never by hand-editing `models/gen/` (codemap trap, AGM s7).

**Stay out of server files:**
- `UnitServerEvents`, being edited by #247/#248 (rebase, do not redo).
- `UnitActionItem`, where plan 012 requires a net change of â¤0 lines.

The layer is client-only except the optional stagger one-shot (section 7, L6b).

---

## 4. Behaviours (technique per audit Â§2)

### Breath
- An additive layer on the spine, clavicles/arms and head:
  - shoulders rise
  - head lifts slightly
  - quick in, long out (`Life.breath`)
- Rate and amplitude come from shared exertion: running raises it, and it settles over about 10 s, as in `Quadruped`.
- Phase is offset per entity id.

### Idle weight shift
- A slow hip sway (body translate plus a small roll) with counter-rotation on the legs.
- A seeded fidget scheduler: `Life.fidget(seed, tSinceStop)` picks from a small additive bank:
  - glance
  - shoulder roll
  - weapon re-grip
  - stance widen
- Fidgets fire only when `tSinceStop` exceeds about 2 s. A spring "settle" plays on stop.

### Look-at
- Per-bone shares: eyes 100%, head 60%, neck 30% (where a neck bone exists), chest 10%.
- A critically-damped spring on the target yaw and pitch. The head arrives late and settles; a large target change gives a "notice" snap.
- Target priority:
  1. the current attack target
  2. the ordered move/attack point (own units, known in `UnitClientEvents`)
  3. the nearest visible threat
  4. idle glance
- **Fog safety (codemap trap F7 spirit):**
  - Only look at entities the client renders as visible.
  - Never use a server-sent id to point a head at something hidden in fog. A head turning into fog leaks information.
  - VERIFY which client fog query to use (`fogofwar` package) and whether `UnitSyncClientboundPacket` carries a target id.

### Hit reactions
- **Directional flinch.** Uses `HitStamp.dir` relative to `yBodyRot`, in 4 quadrants:
  - torso twists away from the hit
  - head snaps
  - a short spring recoil
- The flinch is additive over locomotion and never stops the walk.
- **Magnitude:**
  - The client does not know the damage (audit Â§2).
  - L6a classes the hit from the observed health delta if health is synced (VERIFY).
  - L6b adds a server one-shot for heavy hits (stagger: one step back, arms out) only if a poise decision exists. Any new `UnitAction` value goes at the **end** of the enum (AGM s4).

### Death
- The rig opts out of the flip.
- A 20-tick fall seeded by the last hit direction: knees buckle, the torso falls along the hit vector, arms trail on springs.
- A small root fling from the hit impulse.
- A client-side corpse hold of a few seconds, render only (the entity is already gone server-side), then sink and fade.
- Per body type, a death style: fall back, fall forward or crumple.

---

## 5. Cost budget at 1000 humanoids, and LOD

Audit baseline (CI, vanilla `ModelPart` path):
- posing about 1 Âµs per unit
- draw 42.7 / 62.7 Âµs per unit (RTS / close)
- gate: posing under 40 Âµs per unit, animation share under about 10%

**Budget (`[AnimBench]` extended to 1000 units, `[Anim]` in client):**

| Piece | Budget per unit | Budget at 1000 units |
|---|---|---|
| Motion snapshot + hit stamp (per tick, 20 Hz) | â¤ 0.5 Âµs | â¤ 0.5 ms per tick |
| `HumanoidLife` additive pass (per frame) | â¤ 2 Âµs | â¤ 2 ms per frame |
| Death and corpse (concurrent, capped at 64) | â¤ 3 Âµs | negligible |
| Total animation share of unit cost | â | â¤ 10% (audit gate) |

Allocations per frame must be zero: slab slots only, no `WeakHashMap`, no boxing.

**LOD policy.** The audit's decision stands: **no animation decimation** ("a block of units stuttering at 10 Hz reads worse than static").

- **Always on wherever a body is drawn:**
  - breath
  - weight shift
  - flinch
  - death fall
- **What turns off:**
  - **Past `DETAIL_ZOOM` 36:**
    - eye motion (eye parts are `lod` parts and hidden anyway)
    - the chest share of look (the head carries 100% of the visible share)
    - micro-fidgets under about 1 px (shoulder roll, re-grip)
  - **Past zoom 50:** corpse hold shortened and capped lower.
  - **Not drawn (culled, off-screen) or icons past zoom 70:**
    - no per-frame pass
    - snapshot skipped
    - state resumes from age and id without pops, because breath and weight shift are functions of time
- **Fallback:** if a block of 1000 units on lovish's PC exceeds budget, cut the fidget evaluation rate per unit first. That is an event scheduler, so it does not stutter.

---

## 6. Data per body type (`BodyProfile`)

The five families:
1. Vanilla `HumanoidModel` (zombie, skeleton, piglin)
2. `IllagerModel` (vindicator family; arms-crossed variant)
3. Villager-unit model (VERIFY the actual model class behind `AbstractVillagerUnitRenderer`)
4. RoN keyframe (named bones per model)
5. Sunforged gen (bone names from DSL)

Fields per profile:
- **Bone map:** pelvis/body, chest, neck (optional), head, eyes (optional), arms L/R, legs L/R
- **Limits:** head yaw/pitch, torso twist
- **Look shares**
- **Breath:** amplitude and rate scale
- **Sway amplitude**
- **Fidget bank ids**
- **Flinch scale**
- **Mass class:** light, medium or heavy; scales recoil and fling
- **Death style and opt-in flag**
- **Per-unit overrides**, for example the Royal Guard is heavy with a slower breath

Storage and validation:
- Authored as JSON under `design/anims/bodies/` and generated to Java by `anim_lab`, keeping keys as data (#66).
- A unit test asserts that every humanoid renderer resolves to a profile.

---

## 7. PR sequence

Each PR is shippable, reviewable and gated.

| PR | Content | Visible change | Gate |
|---|---|---|---|
| **L1** | `AnimState` slab, `MotionSnapshot`, `HitStamp` mixin; reset on level unload/rematch (codemap trap R1); `[Anim]` gains slot count | None | `[AnimBench]` snapshot â¤0.5 Âµs/unit at 1000; unit tests; GameTest waits 1-2 ticks after teleport (AGM s4); hit stamp verified firing on unit damage |
| **L2** | `Life.spring/chain/look/fidget` + `BodyProfile` data and generator | None | JUnit: spring critically damped, no overshoot past spec; zero allocations (bench); profile coverage test |
| **L3** | `LifeRendererMixin` + breath + exertion on all 5 families | Army breathes | `anim_lab` review sheet (breath curve per family; VERIFY sheet mode exists, else L3 adds it); eyes stills: 20 Halberdiers plus 20 villager units at zoom 5/30/50, out of phase; `[Anim]` posing +â¤1 Âµs/unit |
| **L4** | Weight shift + fidget scheduler + stop settle | Idle life | Review sheet over a 30 s idle timeline; eyes stills: block at zoom 30 at t=0/10/20 s with no two neighbours synchronous |
| **L5** | Look solver with fog-safe targeting | Heads/eyes track | Eyes stills: ranged unit tracking a moving target; fog test confirms no head turns toward a fogged enemy; `[Anim]` â¤2 Âµs/unit total |
| **L6a** | Directional flinch (4 quadrants) + health-delta class | Flinches | Review sheet: one flinch per quadrant; eyes stills mid-flinch, front and back hit |
| **L6b** | (Only if a poise decision exists) server stagger one-shot | Stagger | GameTest with `AutocastState.setAll(unit,false)` (AGM s4); new enum value at end |
| **L7** | Death contract, fling, corpse hold (cap 64, rematch reset) | Real deaths | Eyes stills at death ticks 0/10/20/+60 for each death style; `[Anim]` during a 50-unit death wave |
| **L8** | Consolidation: Sunforged `WeakHashMap`s, and `Quadruped`/`Dragon` `STATE` (with Lane B) onto `AnimState`; the 9 keyframe clips ported to keys-as-data; `KeyframeHierarchicalModel` path removed | None intended | Review sheets: old vs new clip, frame-matched; eyes stills before and after identical; `[AnimBench]` keyframe layer â¤ today's 0.19 ms/500 |

**Rules for every PR:**
- `[Anim]` must appear in the eyes log.
- No PR may move posing past 40 Âµs per unit or animation share past 10%.

---

## 8. What lovish must judge by eye

Numbers cannot decide these:

1. **Breath readability at zoom 30.** Visible without a whole block "bobbing". This is the single most important amplitude call.
2. **Variety.** Does a block of 40 read as individuals? Watch the phase spread and fidget frequency, and check that nothing fidgets in unison.
3. **Look feel.** Snap-then-settle speed and how far the torso joins in. Alert, or twitchy?
4. **Flinch strength by mass class.** Readable in a big fight without everyone looking drunk.
5. **Death.** Fall styles per family, fling distance (heroic vs silly), and corpse hold length (atmosphere vs clutter at 8v8).
6. **Stagger (if L6b).** Does it feel earned and match the poise rules?
7. **L8 regression.** The 9 ported RoN clips must look the same as before, especially Marauder and Wildfire.

Each call is made on the eyes stills and review sheets attached to its PR, and the PR merges only on his sign-off.