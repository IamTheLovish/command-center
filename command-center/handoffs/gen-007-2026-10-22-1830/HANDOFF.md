# Gen 007 - Oct 22 2026, 18:30 ET (Lane A perf/CI + Lane B art takeover + effects; account ?)

Read first: Project doc claude/north-star-2026-10-21.md, AGENTS.md + design/LANES.md, newest #35 comments, dev log #150,
this file, gen-006 (sibling). Repo: add_repo IamTheLovish/Beyond-and-Tabs (push); mirror ILovishThe/beyond-and-tabs-ci
(push) for mirror check-run annotations (its job logs redirect to Azure blob = blocked; use
`gh api repos/ILovishThe/beyond-and-tabs-ci/check-runs/<job id>/annotations`).

## What lovish asked today (after gen-006)
- 14:24 randomTickSpeed option "B" (3 + own timers). 14:33 "keep shadows on with people being able to turn them off".
- 14:29 "lets add them and improve playbability" (frame-rate list). 14:57 "We should improve textures and blocks";
  his Lane B session was out of usage, so this session took Lane B art.
- 17:02-17:25: add-on/mod showcase videos -> "I want those results in our game ... effects, animations, projectiles,
  systems"; "study the codes of those extensions"; "note and record"; "analyze"; permission to read open-licensed mod
  code on his PC; "save all this info into our memory command center and the vault".
- 17:17 asked about Bedrock: answered no (no custom rendering/RTS UI/deep systems in add-ons).
- 17:41-17:45 underground still visible in spectator -> "maybe even 42-30", "we dont need that many safe floors".
- 17:46-17:52 trees see-through in RTS view + trees not realistic -> "all three work" (off by default, silhouettes, fade).
- 17:54 "use other runners if their empty on other tasks we need to test".

## Merged today in this session (all on dev log #150)
| PR | What |
|---|---|
| #158 | randomTickSpeed 12 -> 3; soul fire own exponential timer (mean 341 ticks); wraith-snow wisps client animateTick |
| #159 | Unit render LOD: overlays/eyes/glow skip shader shadow pass; health bars no longer drawn twice; FP detail by screen size; toggle `unit_render_lod` |
| #161 | design/research/: video-qualities + mod-code-study docs |
| #163 | Battlefield floor y 48 (176 high, 11 sections), bedrock 0..3, no underground-only ores |
| #164 | RTS leaf hiding default NONE (green-glass swap made trees see-through + re-meshed chunks) |
Client settings on lovish's PC: Sound Physics rays halved (backup .bak-20261022); Complementary entity shadows left ON.

## In flight (background agents of this session; if this chat is gone, pick up from the branches)
1. Block pack r25 - branch claude/block-pack-r24, draft PR #160. r24 fresh review: bark + planks better (S 6.5);
   stone/basalt/dirt worse (plain pepper: Laplacian 14.8->34.2 stone, 6.7->39.4 basalt). r25 brief: noise gate
   (plain Laplacian <= main), real soil dirt, columnar basalt, small-pebble gravel, grass macro variation, orange
   grass-side patch. Stills /home/claude/art/r25/ (container - lost if it restarts; rerun eyes). Needs a FRESH reviewer
   before lovish sees it. Metals PR #105 still waits on lovish's clear-sky screenshot.
2. VFX + projectile foundation - branch claude/vfx-foundation (draft). Textured additive/translucent render types +
   own atlas, ribbon trails, cast circle + sky pillar showcase, `/bat vfx <id>`, eased particle values, shake falloff.
3. Canopy silhouettes + smooth leaf fade - branch claude/canopy-silhouettes (draft), on top of #164.
4. Flaky tests - branch claude/flake-fixes: known flakes + merge_pr gaps: (a) mirror-side failures aren't parsed
   as known flakes ("no failed GameTest named"); (b) after a mirror rerun goes green the ci-mirror status stays failure
   until ci-mirror-report's 5-min cron - dispatch workflow 392616568 to refresh. Soak stall seen: blocked jade_pagoda,
   workers 11 blocks away not idle.

## Reference docs written today (Project + Command Center references\ + vault inbox)
claude/instanced-units-plan-2026-10-22.md (6-8 wk, P1 go/no-go), claude/magic-vfx-refs, claude/addon-refs,
claude/video-qualities-2026-10-22.md (top-10 qualities), claude/mod-code-study-2026-10-22.md (+ part2 from real source
in D:\mod-study: GeckoLib 5 MIT, Lodestone 1.8.3 LGPL-3, Tinkers 3.12.1 1.20.1 MIT, Veil 4.5.2 LGPL-3).
Vault inbox: 7 notes (20261022-1730..1742).

## Next (ranked)
1. Finish the in-flight four: fresh art review for r25 (strongest model), review + merge VFX / silhouettes / flake PRs
   (stills in game before merging art; lovish OKs looks).
2. Animation weight (top of the code study): hit-frame event markers in HumanBase clips fired over (prev,cur], hit-stop
   2-4 ticks, per-key easing (easeOutBack), snapshot transitions, additive layers (Life breath, flinch, attack over Gait).
3. Trees realism round (lovish 17:46): tree shapes (tools/gen_trees.py), leaves, bark - Lane B pipeline.
4. Atmosphere vs "flat graphics": per-area hue/fog/particles, weather grade swap (vault note 1733).
5. Tinkers-style hero/unit kit JSON + rebuildStats (hero spell tree from Ascension ref) - design doc first, lovish decides.
6. Measure next MP match: server [Paths]/[Tick]/[Sys], client [FrameParts] incl. unitShadow; spark profile if lovish runs it.
7. HUD frame cost is Lane C's (posted on #35 twice: caching + shadow-pass skip in HudClientEvents.onRenderLivingEntity).
