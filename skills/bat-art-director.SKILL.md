---
name: "bat-art-director"
description: "Art pipeline for Beyond and Tabs units, buildings, capitols, trees and block textures: concept, build, in-game photo, fresh critique, technical check, repeat until it beats lovish's references."
---

# BAT Art Director

Make art the way professionals do and revise until it is as good as it can be - no fixed round count. The bar (north star) is the best game in each category, never "good for Minecraft". Direction (lovish, Oct 21): **hyper-realism first, a touch of dark fantasy** - real materials, natural light and palettes, believable buildings; dark fantasy only as an accent (monsters, Gravebound/Ashborn, gothic crag castles, night). **Max everything**: build the ULTRA version first (his i7-12700KF), then scale down with presets; RTS readability holds on every preset. Detail: Project docs `claude/skill-pack-lessons-oct21.md` sections 2-3 and 7, `claude/lane-b-how-we-work.md` (lessons), `claude/dark-fantasy-refs-2026-10-21.md`, `claude/tree-refs-2026-10-21.md`; repo `design/ART-FAULTS.md`.

## Pipeline for each asset
1. **Concept.** Brief: KEEP (what lovish already liked), 3-5 refs, silhouette and shape language, 3-5 signature features, palette roles (60/30/10 + accent), glow budget, a one-line feel, and the faction style kit (3 blocks + accent, roof motif, trim, light, one signature detail).
2. **Build.** Block palette, structure generator, model DSL, or Blender on his PC. Use Macaw's and Chipped where detail needs it.
3. **Photograph in game.** A merged pack or a green tick is not done: photograph it with shaders and plain (eyes `structure` lane, small samplers ~40x24). Judge in-game stills over renders.
4. **Fresh critique.** A separate reviewer with only the images + ART-FAULTS.md grades before lovish sees anything; the maker never grades their own work. Then verify each claim on the pixels yourself (compare the same crop across runs). Every round checks:
   - Give the reviewer the previous round's image and the KEEP list (what lovish asked for or already liked) as well as the new one, but not the maker's opinion: a judge that only sees the new image repeats itself for rounds and flags intended details (from Joisco's pack, Oct 27).
   - Every capture asserts the state it claims to show (unit present, chunk loaded, right zoom, shaders on/off as labelled) and fails loudly otherwise.
   - **Shrink test** at real RTS pixel height: only silhouette, value and glow survive.
   - **Greyscale value**: 60/30/10; dominant vs secondary >= ~0.08 luma, accent >= ~0.25. Measure in the view players see (top faces get full light, so a side-view palette reads 1-2 stops pale from above).
   - **Three detail scales**; fine detail never rescues weak masses.
   - **Focus**: one focal feature plus deliberate quiet areas.
   - **Kill tests**: sticker look, wallpaper scatter, zebra hatching, flat black, plastic sheen, pure black or white (albedo ~55-220).
   - **Life**: reads with animation off; idle glow under 10% of the body, anchored to a bone.
   - **Sculpture**: compare with real Roman and Catholic sculpture; 3-4 big drapery/feather tiers, 2-3 value steps.
5. **Technical check.** Cost (blocks, cubes, texture reuse, LOD, perf budget). Unit textures: no feature under 2-3 texels, form light baked in (cavities ~0.6, lit rim, light from upper-left), team-colour zones near-white. Tree and building blocks must be the right resource source in ResourceSources (trees = WOOD).
6. **Repeat** until the critique finds nothing major. Show ORIGINAL | PREVIOUS | NOW, keep every round's images, state fidelity honestly ("~75% of the ref, the ceiling is X").
7. **Present** a still to lovish: no emojis, labelled with exactly what was done, verified at every angle and in game.

## Block textures (LabPBR under Complementary)
- Method decisions (lovish, Oct 22 20:23): stone, dirt and grass switch to CC0 photo scans (`D:\Command Center\references\texture-scans-ambientcg\`), plus per-position grass colour variation; planks, gravel and bark ship and keep improving. Once he approves a method change, run no more rounds of the old method on those materials unless he asks.
- Diagnosis + evidence (run id or still) before a fix. After two failed tries, write what is ruled out and run a SPLIT TEST (albedo-only vs normals/height-only panels on a never-merge branch).
- Height (`_n` alpha) is read: POM is on by default in labPBR mode. 255 for flat, lower only where depth is wanted. `_s` alpha 255 on anything that must not glow; `_s` blue >= 65 = SSS (keep pore < 65); keep smoothness variation tiny (band noise reflects the sky as worms). Ship `optifine/texture.properties` (`format=lab-pbr/1.3`).
- Preview offline with the LOW sun (`LIGHT="-0.85,-0.35,0.30"`) like the eyes rig. Too pale or warm: fix TARGETS (luma, sat), not the tint.
- Shared helpers get a per-material parameter; never change a default other materials use. Run `tools/gen_blocks.py` before every push.

## Trees and buildings
- Trees: taper by block shape (wood, then stairs/slabs/walls, then fences), smooth bends, crowns as separate flat-bottomed pads with sky between, claw or flared roots and a ground skirt. Silhouettes belong to `gen_trees.py`, not the leaf texture. Stripped logs read as planks from above.
- Buildings: each upgrade level is a superset - bigger, more intricate, more articulated, with its own hero camera. At least 3 height levels and a readable skyline; detail shallow and subtractive; equal window blocks read as Tetris. Capitols are the largest and most intricate; crags under gothic castles; clustered spires. White Angel keeps warm light grey stone with a hue-drifted ramp (cool shadows, warm lights). Sign "SixWings" on the side of the White Angel capitol.
- Originals only: nothing from Reign of Nether or other games/mods; references stay in study folders (never import a schematic, never extract game files).

## Across the ten factions
A sameness sheet of silhouettes (every faction and tier); no repeated archetype within a faction, none shared across factions at the same tier; each faction its own trim material. A new style is a hypothesis: ONE hero piece in game, lovish's OK, then roll out.

## Blender render rig
Khronos PBR Neutral view transform. Key 360 W, fill 100 W, rims 280 + 170 W, on an Empty that turns with the camera. Cycles 128-256 spp + OIDN; previews 16 spp at 960x540; CI 1600x900 with 512 tiles. Turntables 120 frames; stamp name, round and view on every PNG. One Blender job at a time (FIFO queue file).

## Routing
Concept and critique: opus or a fable subagent. Art reviewer: the strongest model available, never cheap. Mechanical builds and roll-outs: sonnet. Render and file chores: haiku. Max two heavy agents at once; resume the same builder each round.