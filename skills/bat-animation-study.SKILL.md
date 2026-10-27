---
name: "bat-animation-study"
description: "Use when making or revising a Beyond and Tabs unit, creature or hero animation: reference, phase table, calibrate, recipe, render, fresh review - repeated until it holds up next to The Isle / Day of Dragons / Direland."
---

# BAT animation study

North star: animation first. One unit up close should feel like **The Isle**; dragons like **Day of Dragons**; melee heroes as fluid as **Direland**. lovish is the final judge of "lifelike", and the loop never stops at good enough. Read only what the unit needs: Project docs `claude/animation-standard-2026-10-21.md` (the rules), `claude/animation-ref-the-isle.md` + `claude/animation-ref-part4-cycles.md` (the 28-point creature / dragon / walk-cycle checklist), `claude/animation-ref-clips-index-2026-10-21.md` (reference frames on the PC), `claude/skill-pack-lessons-oct21.md` section 1.

## Before starting
- Check which clips the unit actually HAS in code. Idle and walk can be inherited (the Halberdier's were, for 9 rounds).
- Pick the body type (human, quadruped, bird, dragon, serpent, construct) and weapon class (polearm, sword, axe/hammer, bow, cast, shield); inherit the rig convention, base clips and timing family.

## The loop (one unit, one action: idle, walk, run, attack, hit, death; flight states for fliers)
1. **Reference.** The best example: The Isle / Path of Titans creatures, Day of Dragons, Muybridge plates, fencing treatises, Direland. Frames stay on the PC (`D:\Command Center\references\isle-refs-view\`) or in study folders, never in the game. Name the ref in the clip JSON (`"ref"`). Study footage only - never extract another game's files.
2. **Phase table.** Timings in seconds: contact / down / passing / up per step; anticipation / action / recovery per attack; which parts lead and which follow (hips, chest, neck, head; tail later). Fliers: downstroke / upstroke, glide, climb, banked turn, dive, hover, take-off, landing.
3. **Calibrate.** Measure travel (head bob, hip drop, rib rise, tail sweep, bank angle) as a fraction of body height. Numbers, not guesses.
4. **Recipe.** Keys as data in `design/anims/<unit>.json`, Java via `tools/anim_lab.py --gen-java`. Minimum-jerk / Hermite easing, no dead stops at inner keys. Breathing, spine-chain lag, head look-at, tail counter-swing and banking come from the shared procedural layers (Life.java and friends), not hand keys. Ranged attacks key off the shot (`isShooting`), not the melee swing. Damage tick = the clip's hit frame.
5. **Check.** `tools/anim_lab.py --motion --play`: no snaps, joints in range every frame, hands on grips, planted feet don't slide, clean blends to the ready stance. Measure in the RENDERED sheet (sheet px), not model space.
6. **Review sheet.** Three rows with the same timing (in game / study / reference), at RTS zoom AND hero zoom, plus a posed limit check (no floating or detached parts). Keep every round's images (`*_rN.png`).
7. **Fresh review.** A reviewer that did not make the clip grades it side by side with the reference: realism, life, detail, cohesion with finished units. Then verify each claim on the image yourself - reviewers misread (wrong view, inherited pose, unloaded chunks). Score out of 10 honestly; keep the number low until it is earned.
8. **In game early.** Offline previews miss renderer layers and translucency/SSS - get an eyes close-up of every unit early, not only at the end. Bad footage (occlusion, 1 fps) gives no verdict; fix the camera first.
   - Every capture asserts its state first (the clip is playing, the unit is in frame, the right zoom) and fails loudly otherwise; a frame that shows the wrong state gives no verdict (from Joisco's pack, Oct 27).
9. **Iterate** on the same unit (resume the same agent) until no FAIL or STILL-WEAK on realism, life and detail. Then show lovish one still or a frame strip. Animation PRs merge only with lovish's OK.
10. **Log.** One line per try in the lane handoff (round, verdicts, open faults); new mistakes go into the lane's lessons. A proven recipe rolls out to similar units on sonnet.

## Rules
- No GeckoLib or Photon (commander decision D035, Oct 27): there are already 4 parallel animation systems; extend the game's own clip data + Life.java layers. The shared humanoid life-layer plan (`briefs\life-layer-PLAN-DRAFT-2026-10-27.md`) is the direction.
- One hero unit first; never roll an untested style across the roster.
- Full animation at every zoom by default; savings only through the player's Unit animation setting.
- Bigger = slower, deeper, heavier (breath, stride, wing beat); the same physics for every faction. Faction flavour lives in pose and secondary motion.
- Design and critique: a fable or opus subagent. Builds and roll-outs: sonnet. Max two heavy agents at once. Rotate a long agent at ~350-500k tokens.