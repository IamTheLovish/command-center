# 017 - strategic icons batch (one draw per building-icon texture instead of one per building)

- **Goal:** draw the strategic view's building icons with one quad buffer per texture instead of one immediate `GuiGraphics.blit` per building, with the same pixels.
- **Lane:** Lane A (performance); `orthoview/` is a rendering area Lane C also edits, so post on issue #35 before touching `StrategicViewClientEvents.java`.
- **Branch:** `claude/improve-017-strategic-icons-batch`
- **Claim:** `python3 tools/claim.py check strategic icons orthoview blit batch` then `python3 tools/claim.py take improve-017 --lane "Lane A" --branch claude/improve-017-strategic-icons-batch --what "Strategic view: batch building icons per texture (plan 017)"`. Release when the PR merges.
- **Model / effort:** sonnet, high (size S: one pure class, one call site, one picture check).
- **Written against:** origin/main `bbbdac21`.
- **Drift check (run first):**
  `git fetch origin && git diff bbbdac21..origin/main --stat -- bar/src/main/java/com/solegendary/reignofnether/orthoview/StrategicViewClientEvents.java bar/src/main/java/com/solegendary/reignofnether/matchstart/EyesOverlaysScene.java bar/src/main/java/com/solegendary/reignofnether/perf/FrameParts.java`
  If any changed, STOP and report which. (Open PR #247 `claude/perf-quick-wins` touches `UnitClientEvents.java`; if it also touches the strategic view, STOP.)

## Context (paths relative to `bar/src/main/java/com/solegendary/reignofnether/`)

**The loop (verified on bbbdac21), `orthoview/StrategicViewClientEvents.java`:**
- `onRenderGui` (:230-243, `RenderGuiEvent.Pre`, screen space, inside `FrameParts.STRATEGIC_ICONS`) calls `drawStrategicOverlay(gg, partialTick)` (:269). It sets blend on, cull off, depth test off, the position-colour shader, opens ONE triangle buffer (`bb.begin(TRIANGLES, POSITION_COLOR)`, :288-290), fills it with the building plates, capture sites and unit icons, and draws it once: `BufferUploader.drawWithShader(bb.end())` at :392. The unit icons are already batched this way (coloured shapes in that one buffer).
- Then, at :394-415, the building icons are drawn after the plates, one `gg.blit` per building:
```java
for (BuildingPlacement building : BuildingClientEvents.getBuildings()) {
    if (!building.isExploredClientside || building.getBuilding() instanceof AbstractBridge) continue;
    if (roleOf(building.getBuilding()) != Role.NONE) continue;          // buildings with a role glyph are drawn above
    net.minecraft.resources.ResourceLocation icon = building.getBuilding().icon;
    if (icon == null) continue;
    ... sx, sy, plate, size = (int) Mth.clamp(plate * 0.7f, 6f, 16f) ...
    if (plate < 8 || sx < -20 || ... || underHud(sx, sy)) continue;
    gg.blit(icon, (int) (sx - size / 2f), (int) (sy - size / 2f), size, size, 0, 0, 16, 16, 16, 16);   // :414
}
```
Each `GuiGraphics.blit` sets the position-texture shader, binds the texture, opens a buffer, writes 4 vertices and draws immediately. With ~1,700 houses that is ~1,700 draws and texture binds a frame for ONE texture (houses). The audit measured `strategicIcons` 5.25 ms at zoom 200 in scene 18 (not yet measured by us: step 1 does).
- The icon is a full-texture quad: u 0..16 of 16, v 0..16 of 16 = UV (0,0)-(1,1) whatever the PNG size. Position is `(int)(sx - size/2f)`, `(int)(sy - size/2f)`, size x size. Cull is already off (:286) and depth is off (:287), blend is on with the default function (:284-285).

**The convention to follow:** the unit and plate drawing in the same method (`tri`, `line`, `drawGlyph`, :816-860) and `UnitIconCrowdRulesTest` (`bar/src/test/java/.../unit/modelling/renderers/UnitIconCrowdRulesTest.java`) for how a pure rule class next to a renderer is tested. Pure-class JUnit style: `perf/SysTimerTest.java`. Reused scratch collections: the file already keeps per-frame scratch structures (`SELECTED_BUILDINGS`, `PLATE_XS`, :265-267, "reused every frame, no per-frame allocation"): follow that.

**Measuring tools that exist:** `perf/FrameParts.java` (`STRATEGIC_ICONS` = id 2), `matchstart/EyesOverlaysScene.java` (EyesDirector scene 18: 500 units + 1,700 client-only houses; prints our handlers' median ms at zoom 30 and zoom 200, stills `18_overlays_mid`, `18_overlays_mid_building`, `18_overlays_strategic`), the `overlays` input of `.github/workflows/eyes.yml` (header of that file documents it), `tools/eyes_diff.py` (picture regression; read its header for arguments).

**Hard rules (all apply):**
1. Tests first, red on main: the batch is a pure class, so JUnit with a throwing skeleton first.
2. Client code stays in client classes (`python3 tools/check_server_client_imports.py`); the pure batch class has no Minecraft import except what a `ResourceLocation` key would need: make it generic in the key (`<K>`), the call site passes `ResourceLocation`.
3. Fog of war: not touched (the loop keeps its `isExploredClientside` test).
4. Oculus: this is a GUI-layer draw; `ShaderPacks.skipOverlays()` does not apply and must not be added. Keep the draw inside `drawStrategicOverlay` (same event, same point in the frame, after the plate buffer is drawn).
5. No file crosses 1,000 lines: `StrategicViewClientEvents.java` is ALREADY 1,034 lines, so its net change must be <= 0. The batching lives in the new classes; the wiring there is about 3 lines. If it grows, delete the two comment lines above the loop (:394-395; the new class's javadoc carries them) and any blank lines the edit leaves; if it still grows, STOP and ask.
6. `python3 tools/check_java.py` 0 structural errors; `bash tools/prepush.sh` before every push.
7. Commit by explicit path, identity `git -c user.name=IamTheLovish -c user.email=IamTheLovish@users.noreply.github.com commit`, trailers as given; never push `main`, never force push.

## Steps

### Step 1 - the pure batch, tests first (red), plus the baseline picture and number
1a. Create `orthoview/IconQuadBatch.java` as a THROWING skeleton and `bar/src/test/java/.../orthoview/IconQuadBatchTest.java` (pure, table style). API:
```java
final class IconQuadBatch<K> {
    void add(K key, int x, int y, int size);                 // one square quad
    int groups();                                            // distinct keys this frame
    int quads();
    void forEachGroup(GroupVisitor<K> v);                    // keys in first-seen order
    interface GroupVisitor<K> { void group(K key, int[] xys, int quads); }   // xys = x,y,size triples, insertion order, only [0, quads*3) valid
    void clear();                                            // keeps capacity; no allocation when the next frame has the same shape
}
```
Cases: (i) 1,700 adds over 3 keys give `groups() == 3`, `quads() == 1700`; (ii) keys are visited in first-seen order and quads inside a group keep insertion order; (iii) `clear()` then the same adds again: results identical and (assert through a counting visitor) the visitor sees the same arrays' content; (iv) a key with one quad; (v) an empty batch visits nothing; (vi) 100,000 adds do not fail (arrays grow). RED: the skeleton throws.
1b. Baseline: commit only the skeleton and the test (the build is still the old code path), push the branch, and when its `bar` job has built, dispatch scene 18 twice for noise: `gh workflow run eyes.yml --ref claude/improve-017-strategic-icons-batch -f overlays=true -f build_run=<that bar run id>` (get the id with `gh run list --branch claude/improve-017-strategic-icons-batch --json databaseId,name,status`). Read the `[Eyes] 18_overlays zoom 200` line (`strategicIcons` median ms) from `eyes-lines.txt` in artifact `eyes-overlays-<run id>`, or from the run annotations. Record both numbers and the stills' folder names (`<build sha>-<run id>` on branch `eyes-overlays`).
GATE 1: `IconQuadBatchTest` is RED in CI/locally (the failing tests are named), baseline medians (2 runs) written down. If the `strategicIcons` median at zoom 200 is under 1.5 ms in both runs, STOP: the audit's number does not reproduce here, report the two numbers and do not continue.

### Step 2 - implement and wire
2a. Implement `IconQuadBatch` (growable `int[]` per group, a small open-addressing or fastutil `Object2ObjectLinkedOpenHashMap<K, Group>` (fastutil is already used at :265); groups reused across frames, `clear()` only resets counts).
2b. Put the flush below in a small client class `orthoview/StrategicIconDraw.java` (`static void flush(IconQuadBatch<ResourceLocation> batch, BufferBuilder bb, Matrix4f mat)`), so `StrategicViewClientEvents` only gains the call. In `drawStrategicOverlay`, a static `IconQuadBatch<ResourceLocation> ICONS` next to the other scratch fields. At :414 replace the `gg.blit(...)` by `ICONS.add(icon, (int) (sx - size / 2f), (int) (sy - size / 2f), size)`; after the loop (before :417's state restore), flush:
```java
if (ICONS.quads() > 0) {
    RenderSystem.setShader(GameRenderer::getPositionTexShader);
    ICONS.forEachGroup((tex, xys, n) -> {
        RenderSystem.setShaderTexture(0, tex);
        bb.begin(VertexFormat.Mode.QUADS, DefaultVertexFormat.POSITION_TEX);
        for (int i = 0; i < n * 3; i += 3) {
            float x0 = xys[i], y0 = xys[i + 1], x1 = x0 + xys[i + 2], y1 = y0 + xys[i + 2];
            bb.vertex(mat, x0, y0, 0).uv(0f, 0f).endVertex();
            bb.vertex(mat, x0, y1, 0).uv(0f, 1f).endVertex();
            bb.vertex(mat, x1, y1, 0).uv(1f, 1f).endVertex();
            bb.vertex(mat, x1, y0, 0).uv(1f, 0f).endVertex();
        }
        BufferUploader.drawWithShader(bb.end());
    });
    ICONS.clear();
}
```
(`bb` and `mat` are the method's locals, :283 and :289; the plate buffer was already ended at :392, so `bb` is free again. Vertex order is vanilla's `GuiGraphics.innerBlit`: (x1,y1) (x1,y2) (x2,y2) (x2,y1); cull is off anyway.) `clear()` also in the exception path: put it in the `finally` of `onRenderGui` (:240) so a thrown frame cannot leak quads into the next.
2c. Known, accepted difference: icons now draw grouped by texture, not in the building list's order. Two icons of DIFFERENT types would only differ in stacking if their icons overlap on screen; icons are at least 6 px and centred on their own plates, plates of different buildings do not overlap. State it in the PR.
GATE 2: `IconQuadBatchTest` GREEN (6 cases, counted in the `JUnit summary` notice); `python3 tools/check_java.py` 0 errors; `git diff --stat origin/main` shows `StrategicViewClientEvents.java` net <= 0 lines.

### Step 3 - prove the pixels and the number
3a. Dispatch scene 18 twice on the new build (as 1b) and read `strategicIcons` at zoom 200 and zoom 30 from both.
3b. `python3 tools/eyes_diff.py` on `18_overlays_strategic` and `18_overlays_mid` between a baseline run (1b) and an "after" run: the stills must match; a difference limited to animated pixels (idle pulse, units) is explained in the PR, a difference at a building icon is a bug (suspects in order: the (int) truncation, the UV, the vertex order, a missing `setShaderColor(1,1,1,1)` if another handler left a tint).
GATE 3: after median at zoom 200 is at least 1.0 ms below the baseline median (both runs of each) and `eyes_diff` shows no icon difference; if the saving is under 0.5 ms report both sets of numbers and do NOT merge. CI green: `python3 tools/ci_wait.py --pr N` prints GREEN.

## Out of scope
The role glyphs (`drawGlyph`) and plates (already one buffer); unit icons; the minimap; culling the 1,700 buildings by distance or zoom (a separate idea: skip the whole loop above a zoom when `plate < 8` for every building); fog of war; texture atlasing of the building icons (would remove the per-texture draws too, but needs a new asset pipeline).

## STOP conditions
- Drift check shows changes; the strategic view is being edited by Lane C on #35.
- Step 1: the baseline `strategicIcons` is under 1.5 ms (no problem to fix here).
- `eyes_diff` shows an icon difference you cannot remove after one fix attempt.
- CI red you cannot explain after one fix attempt; same test red on main (`tools/known_flakes.txt`).

## Done criteria
- Building icons draw with one draw per distinct texture; same stills; measured saving in the PR; `StrategicViewClientEvents.java` not longer than before (1,034).

## PR body template
```
## What
Strategic view: building icons batched per texture (one draw per texture instead of one blit per building).

## Evidence
- Red commit <sha> (IconQuadBatchTest failing) -> green commit <sha>
- Scene 18, zoom 200, strategicIcons median: before <a> / <b> ms (runs <id>, <id>), after <c> / <d> ms (runs <id>, <id>); zoom 30: ...
- eyes_diff 18_overlays_strategic / 18_overlays_mid: <result>

## Numbers for lovish / questions
- Icons of different building types now draw in texture order, not building order (only visible if two icons overlap).

Do not merge without lovish's OK
```

## Return format (max 150 words)
PR number; GATE results (command + one-line result); before/after `strategicIcons` medians; eyes_diff result. Nothing else.
