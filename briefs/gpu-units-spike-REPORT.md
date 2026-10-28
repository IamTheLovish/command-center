# GPU units spike: can units be drawn outside the vanilla entity path? (2026-10-27)

Feasibility spike for the living-army motion system. The answer is wanted, not the code: nothing from it merges.
Spike branch: `claude/spike-gpu-units` (worktree `D:\bt-gpu-spike`, two local commits `ac026307` and `1f7b57e6`, **not
pushed**). It holds one throwaway file, `spike-gpu-units/GpuUnitsSpike.java`, plus `run.sh`, and both are labelled THROWAWAY.

## Recommendation

**Go, with our own renderer only, in the shader-friendly form "C". No-go on Flywheel and Veil. Gate: one in-client
proof under Oculus + Complementary, before round 3 (smooth skin) commits to it.**

- **C = GPU pre-skin, then a plain draw.** Each body type sits in a static VBO once. Every frame, the CPU uploads only the
  bone matrices: N units × B bones. A GPU skinning pass (transform feedback, GL 3.0, inside Minecraft's 3.2 core context)
  writes posed vertices into a buffer. That buffer is then drawn with the unit's ordinary entity `RenderType`, from a
  render stage, through `VertexBuffer.drawWithShader`. With a shader pack on, Oculus swaps in the pack's own entities and
  shadow programs, and those see plain entity vertices. That means no instancing inside the pack and no pack patching.
- **Why not plain instancing (B)?** B is the fastest path, but its vertex shader is ours. With a pack on, the pack owns the
  vertex stage, so B would either lose the pack's lighting and shadows or need the pack patched, which is the
  Flywheel-compat route. B is fine as a no-pack fast path later, but C serves both cases with one code path.
- **Rounds 1 and 2 don't wait for this.** See "Roadmap" below.

## Measured numbers

### 1. Today's cost: `[AnimBench]` rerun locally

Source: `bar/src/test/.../perf/AnimationCostBench`, `./gradlew test --tests '*AnimationCostBench*'`, at commit `d9fac5c6`
(origin/main, 2026-10-27), on the i7-12700KF here. It measures 500 units a frame, median of 30 frames, on the vanilla
`ModelPart` path, writing into a vertex sink that only counts (so the real buffer write comes on top).

| Phase | ms / 500 units | per unit |
|---|---|---|
| posing: restPose + procedural (Halberdier, 279 parts) | 0.33 | **0.7 µs** |
| Life math (breath, wing beat, 12-link chain) | 0.08 | 0.2 µs |
| Halberdier body pass, RTS zoom (6000 verts) / close (8568) | 10.78 / 16.66 | 22 / 33 µs |
| team + glow passes, pruned | 1.74 + 0.73 | 5 µs |
| **draw total, RTS zoom / close** | | **26.5 / 38.3 µs** |
| Radiant Paladin body pass, RTS (10488 verts) / close (12120) | 21.71 / 27.21 | **43 / 54 µs** |

This confirms audit §4. Posing is about 2% of a unit's CPU cost, and the CPU vertex transform is the rest. This PC is
about 1.6× faster than the CI runner (the CI figures were 42.7 / 62.7 µs per unit), so the ratios hold. At 500 Paladins,
the body pass alone costs 22–27 ms of CPU per frame, more than a whole 60 fps frame. With a pack's shadow pass, entities
are drawn a second time (reasoned, see below).

### 2. Throwaway prototype: three draw paths, same image

Source: `spike-gpu-units/GpuUnitsSpike.java` (`bash run.sh 500 12120`). It uses LWJGL 3.3.1, the version MC 1.20.1 ships,
with a hidden GL 3.3 core window on an RTX 3070 Ti (driver 610.88) and the i7-12700KF. The body is generated: 32 bones,
rigid skinning, one bone per vertex as with `ModelPart` today. Posing is the same for every path. Frames are 1280×720,
median of 60. All three paths drew identical pixel counts (117,358 / 117,353 / 160,626), which checks that they draw the
same army.

| 500 units × 10,368 verts (Paladin-sized) | CPU ms/frame | CPU per unit | GPU ms/frame |
|---|---|---|---|
| A: CPU vertex transform + upload (vanilla-like) | 74.2 | 148 µs | 38.4 |
| B: instanced GPU skinning (our shader) | 1.17 | 2.3 µs | 1.2 |
| **C: GPU pre-skin to buffer + plain draw** | **1.28** | **2.6 µs** | **4.2** |

| Other sizes (CPU / GPU ms) | A | B | C |
|---|---|---|---|
| 500 × 4,608 verts (Halberdier-sized at RTS) | 33.3 / 16.4 | 1.32 / 0.94 | 1.25 / 2.40 |
| 2000 × 4,608 verts | 137.0 / 67.8 | 4.64 / 2.04 | 4.73 / 8.51 |

How to read these:
- **A is not a precise model of today.** Its Java `ByteBuffer` writes are slower than `BufferBuilder`. The bench above is
  the authority for today's cost. A is here to show the shape: CPU cost and upload grow with vertex count.
- **In B and C, almost all the remaining CPU is posing plus a 1 MB matrix upload.** It stays flat at about 2.3–2.6 µs a
  unit, whatever the vertex count. That is roughly **15–20× less CPU per unit than today's vanilla path** (43–54 µs for
  the Paladin).
- **C pays about 3 ms more GPU than B** at 500 Paladins, because it writes and re-reads ~166 MB of posed vertices. With a
  pack, the plain draw happens twice (main and shadow), and the pack's own fragment work then dominates either way. Not
  measured under a pack: the prototype has no Oculus.
- Linear blend skinning adds 2–4 matrix fetches and a blend per vertex on the GPU, which is trivial there. On the CPU
  path it would multiply the dominant vertex cost (reasoned, not measured).

## Options compared

| | (a) Flywheel 1.0 | (b) own instanced renderer (= B) | (b′) own renderer, pre-skin (= C) | (c) Veil |
|---|---|---|---|---|
| Forge 1.20.1 build | yes, bundled with Create 6 (`flywheel-forge-1.20.1`); Modrinth only lists the old 0.6 for 1.18/1.19 | n/a | n/a | **no**: Modrinth lists Veil only for Fabric/NeoForge 1.21.1 |
| Licence vs GPL-3 | MIT: fine as a dependency | ours | ours | LGPL-3: fine, but moot |
| Oculus + Complementary | **turns its instancing off when a pack is on and falls back to CPU** (stated by the compat mods). It needs a third-party mod that patches the pack's shaders (Iris & Oculus Flywheel Compat, CC0; Ocuwheel; Colorwheel, which is Iris-only). | **pack loses control** (our vertex shader); same patching problem | **pack draws it**: plain entity vertices, the pack's own gbuffers and shadow programs | Iris Veil Compat needs Iris 1.8.1+ and Veil 4, with no Oculus build |
| Shadow pass | via the compat mod only | ours to fake | **reasoned yes**: Oculus re-fires the level render stages for the shadow map (seen in our own code and logs, `postfx/ShaderPacks.skipOverlays`, Oct 22 match), so a stage-hooked draw lands there too | — |
| Embeddium | independent | independent | **independent**: bypasses `ModelPart` entirely, which also avoids the eyes #249 trap where Oculus cancels `ModelPart.render` | — |
| `MeshBody` / `MeshCube` | needs a custom instance type and shader | direct fit: each part's `pos/nrm/uv/quads` becomes a VBO, and the part index becomes the bone index | same as B (the `a b c c` quads become triangles) | — |
| `TeamColourLayer`, glow, upgrade layers | port each as an instance shader | a draw per pass, per-instance colour | **re-draw the posed buffer** with the team or emissive `RenderType`, colour baked per instance in the skin pass | — |
| Mipmaps | same atlas | same atlas | same `RenderType` texture state, so unchanged | — |
| Skinning (round 3) | write it ourselves inside Flywheel's shader system | ours | ours | — |
| Verdict | **no-go**: zero gain on lovish's real setup without a third-party pack patcher, plus a heavy dependency | keep as an optional no-pack fast path | **go (gated)** | **no-go** |

## Shader compatibility: what was seen and what is reasoned

**Seen, in our repo or its logs:**
- Oculus 1.8.0 cancels `ModelPart.render` for Sodium writers and redraws from cube constructors. That is why `MeshCube`
  goes through `PlainBuffers`, and it is the trap any `ModelPart`-level trick falls into (eyes #249, documented in
  `MeshCube`/`PlainBuffers`).
- A prebuilt `VertexBuffer.drawWithShader` drawn under a vanilla `RenderType` gets the pack's program swapped in by
  Oculus, and draws correctly with and without shaders. This is the `StartMarkers` precedent (gbuffers_basic, eyes runs
  39066637227 with shaders and 39086552639 without).
- Oculus fires render stages a second time for the shadow map. Real geometry drawn there gets a shadow (building parts,
  per the `ShaderPacks` docs).

**Seen today:** in the standalone GL 3.3 prototype, the three paths produce identical images, and C's second draw uses a
non-skinning shader on plain posed vertices.

**Reasoned, not seen:**
- Flywheel's and Veil's behaviour under packs. This comes from their compat mods' pages, not from running them.
- C under Oculus would use the pack's entities program for an entity `RenderType`, just as gbuffers_basic was swapped in
  for `StartMarkers`.
- **C must write Oculus's extended entity vertex format when a pack is on.** That format adds `mc_Entity`,
  `mc_midTexCoord` and `at_tangent` to `NEW_ENTITY`. Without the tangents, our units' `_n`/`_s` maps (`SimpleTextureMixin`)
  would shade wrongly. The skin pass can output those fields: rest tangents are rotated by the bone, and mid-tex comes from
  the face. The exact layout has to be read from Oculus at runtime.

## Risks

1. **The extended vertex format** (above). It is the biggest unknown and can only be proven in a client with Oculus.
2. **Per-entity state that packs and vanilla read:** the entity id (`entityId` uniform or `mc_Entity` used for
   per-entity effects), the hurt flash (overlay), fog-of-war hiding, and **selection outlines**. Outlines use vanilla
   glowing (`mixin/EntityMixin`), so the posed buffer must also be drawn into the outline target for selected units.
3. **Hybrid rendering:** held items (`ItemInHandLayer` on 21 renderers), banners, eyes, upgrade trims and glows, name tags
   and health bars stay on the vanilla path. The entity renderer keeps running but skips the body, and needs bone
   matrices for hand and attachment points. That is cheap, because posing produces them anyway.
4. **Draw order and translucency.** The `MeshBody` comment notes that coplanar trims depend on part draw order. A VBO
   keeps that order within a unit, but translucent passes across units lose vanilla's per-entity ordering.
5. **GPU cost under a pack.** C writes posed vertices once and the pack reads them twice. That is +3 ms GPU at 500
   Paladins on a 3070 Ti, more on testers' weaker cards. A far body (audit §3.6) still matters on the GPU side.
6. **Maintenance.** We would own a renderer that Oculus, Embeddium or a pack update can break. The eyes shader lane is
   the regression net.

## Steps for lovish (in-client proof)

There is **nothing for lovish to run today**: the prototype is standalone, so it doesn't show pack behaviour. The decisive
test needs a small in-mod spike, about a day of work. On a throwaway branch, add a client command that draws 500 copies of
the Radiant Paladin mesh body with path C from `RenderLevelStageEvent.AFTER_ENTITIES`, next to 500 vanilla Paladins. Then
lovish would:

1. Install the spike jar in the normal pack (Embeddium 0.3.31 + Oculus 1.8.0), with **shaders off**. Run `/spikegpu 500`,
   look at the two armies side by side, and note the FPS and the `[Frame]` / `[Anim]` lines in `latest.log`.
2. Turn on **Complementary Reimagined**, run the same command, and check:
   - (a) the C army is lit and fogged like the vanilla army;
   - (b) it **casts shadows**;
   - (c) its normal and specular maps look the same, which is the tangent check;
   - (d) team colour and glow show;
   - (e) selecting a C unit draws its outline.
3. Send back screenshots of both armies (shaders on and off) and the log. Pass means (a)–(e) look the same as the vanilla
   army, at a fraction of the frame time.

The eyes shader lane can run the same check headlessly for regressions afterwards. lovish's approval of the look in his
own client is still needed.

## Roadmap impact (snapshot + springs → jointed bodies → smooth skin)

- **Rounds 1 and 2 are unaffected.** They can go ahead on today's path. Posing is about 1 µs a unit and stays cheap at
  10× its current work. One requirement: **the AnimState snapshot outputs a flat array of per-bone matrices** (model
  space, bone order fixed per body type), rather than mutating `ModelPart` fields as its source of truth. A thin adapter
  can copy that array into the `ModelPart` tree for the vanilla renderer. The same array is exactly what C uploads, so
  the renderer can be swapped later without touching animation.
- **Round 3 (smooth skin) should wait for the GPU path.** On the CPU path, LBS turns the already dominant 26–54 µs per
  unit vertex transform into a multi-bone blend per vertex. On the GPU it costs almost nothing. So the in-client proof of
  C belongs between rounds 2 and 3. If it fails under packs, round 3 needs a rethink (skin only the close-zoom LOD on the
  CPU, or B for players without packs).
- **Jointed bodies (round 2) get easier with C.** Fewer, larger parts per bone make for a smaller bone count per instance
  and less matrix upload. `dsl_to_game`'s nearly-one-part-per-cube trees (341 cubes in 279 parts) would become
  bone-indexed vertices in one VBO, with no tree walk at all.

## Sources

- Local `[AnimBench]` run, 2026-10-27, commit `d9fac5c6`; `design/animation-foundation-audit.md` §4 (CI runs
  39580028441, 39582976366).
- Prototype: `D:\bt-gpu-spike\spike-gpu-units\GpuUnitsSpike.java`, run 2026-10-27.
- Repo code: `unit/modelling/mesh/MeshCube.java`, `PlainBuffers.java`, `maps/StartMarkers.java`,
  `postfx/ShaderPacks.java`, `mixin/EntityMixin.java`, `unit/modelling/layers/TeamColourLayer.java`.
- [Flywheel (GitHub)](https://github.com/Engine-Room/Flywheel): MIT, GPU instancing for entities and block entities.
- [Flywheel 1.20.1 README mirror](https://git.grimmauld.de/mirrors/Flywheel/raw/branch/1.20.1/dev/README.md):
  `flywheel-forge-1.20.1` artifact.
- [Iris & Oculus Flywheel Compat](https://modrinth.com/mod/iris-flw-compat): Flywheel turns its optimisations off under
  packs.
- [Ocuwheel](https://www.modpackindex.com/mod/173147/ocuwheel-oculus-flywheel-compat): Forge 1.20.1 Create, Flywheel and
  Oculus fix.
- [Colorwheel](https://www.curseforge.com/minecraft/mc-mods/colorwheel/files/8206638).
- [Veil (GitHub)](https://github.com/FoundryMC/Veil) and [Veil (Modrinth)](https://modrinth.com/mod/veil): LGPL-3;
  Modrinth API lists only Fabric/NeoForge 1.21.1.
- [Iris Veil Compat](https://www.curseforge.com/minecraft/mc-mods/iris-veil-compat).
- [Oculus (Modrinth)](https://modrinth.com/mod/oculus/version/yUsIHXQX).
