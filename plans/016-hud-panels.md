# 016 - HUD panels (measure drawHud, cache the selection strip, then move one panel per PR out of HudClientEvents)

- **Goal:** know what the HUD costs per frame, stop rebuilding the selection strip's grouping every frame, and cut `HudClientEvents.java` (2,709 lines) down panel by panel without a pixel changing.
- **Lane:** Lane C (UI). Post on issue #35 BEFORE touching anything in `hud/` and say which panel you take (22 commits touched this file since Oct 1; Lane C's human developer and his Claude work in it). Shared with Lane A only through `perf/FrameParts.java` and `matchstart/EyesOverlaysScene.java`.
- **Branch:** `claude/improve-016a-hud-sections` (step 1), `claude/improve-016b-selection-cache` (step 2), `claude/improve-016c-<panel>` (step 3, one per panel).
- **Claim:** `python3 tools/claim.py check hud panel selection strip HudClientEvents` then `python3 tools/claim.py take improve-016 --lane "Lane C" --branch claude/improve-016a-hud-sections --what "HUD: frame sections, selection strip cache, panel extraction (plan 016)"`. Re-take with the new branch for each PR; release when the last merges.
- **Model / effort:** sonnet, high (UI, no gameplay timing, no fog). Step 3 is mechanical cut-and-paste with a picture check; if a panel will not move without changing behaviour, STOP.
- **Written against:** origin/main `bbbdac21`.
- **Drift check (run first, and before every step-3 PR):**
  `git fetch origin && git diff bbbdac21..origin/main --stat -- bar/src/main/java/com/solegendary/reignofnether/hud bar/src/main/java/com/solegendary/reignofnether/perf/FrameParts.java bar/src/main/java/com/solegendary/reignofnether/matchstart/EyesOverlaysScene.java tools/hud_layout.py`
  If any file changed, STOP and report which (for step 3, a change in `HudClientEvents.java` only means: re-read the block you are about to move and re-take its line numbers; a change INSIDE that block means ask on #35 first).

## Context (paths relative to `bar/src/main/java/com/solegendary/reignofnether/`)

**The shape of the problem (verified).** `hud/HudClientEvents.java` is 2,709 lines. `onDrawScreen` (:381-394) wraps `drawHud` (:428-2207, 1,780 lines, 200 `if (` ) in the one frame section `FrameParts.HUD`. Everything the player sees at the bottom, top and right edge is one method; the blocks inside it are marked by comment banners:

| lines | block |
|---|---|
| 428-508 | setup: screen size, `selUnits`/`selBuildings`, the bottom-left backing panel (HudLayout) |
| 509-884 | selected building: portrait, production buttons, ability buttons |
| 885-1008 | unit head portrait + stats |
| 1009-1050 | hovered unit card, hovered building card, controls cheat-sheet |
| 1051-1240 | selection strip (one tile per unit type) |
| 1241-1272 | sandbox buttons |
| 1273-1529 | unit action buttons (orders, abilities) |
| 1530-1640 | resources, economy bar, global production queue |
| 1641-1695 | temporary warning messages, control-group clean-up |
| 1696-1897 | minimap buttons + warning |
| 1898-2072 | spectator start buttons, game rules menu |
| 2073-2135 | menu button, observer/diplomacy toggle, right-edge helper column |
| 2136-2190 | minimap start-pos buttons |
| 2191-2207 | tooltips (last, on top), tutorial overlay |

Other click/key code in the same file: `onMousePress` (:2279-2295, loops `renderedButtons`), `onKeyRelease` (:2301), `onKeyPress` (:2505), `cycleUnitSubgroups` (:2572), `cycleBuildingSubgroups` (:2620). Already extracted (do not duplicate, call them): `EconomyBarRenderer`, `GlobalProductionQueueRenderer`, `HoverCards`, `UnitInfoCard`, `CommandCard`, `SlimTiles`, `IdleArmy`, `IdleFactories`, `PortraitRendererUnit/Building`, `HudPanels` (collapsible-panel state, chevrons; 247 lines) and `HudLayout` (pure rectangle maths, 211 lines, mirrored line for line by `tools/hud_layout.py`, which `tools/prepush.sh` and CI run). So "HudLayout/HudPanels" exist: this plan extracts RENDERING, it does not invent a layout system.

**The selection strip (the audit's finding, corrected).** `HudClientEvents.java:1058-1084` runs every frame: `selectionGroups.clear()`, then for each run of equal names calls `getModifiedEntityName(first)` once (:1065) and `getModifiedEntityName(next)` once per further unit (:1069), sums HP, looks up the cost, builds a `SelectionGroup` (record at :154), sorts by cost (`BY_COST_DESC`, :157-158). That is about ONE name build per selected unit per frame (not two as the audit said), plus one per group in each tile's `isSelected` lambda (:1102). `getModifiedEntityName` (:268-345) does `MiscUtil.getSimpleEntityName`, `I18n.get` for babies/banner/militia/vehicles, `getItemBySlot`, `getPassengers`: string work per unit. At 500 selected units and 60 fps that is 30,000 name builds a second. The buttons for the first `buttonsPerRow*2` groups (:1086-1155) are also rebuilt each frame (`ButtonBuilder... .build()`), with their click lambdas; that is allocation, not a hot loop (at most 12-24 tiles), leave it.

**What the cache may and may not assume.** The name changes without the selection changing: a baby grows up, a banner is equipped, a rider mounts (`getPassengers`), a militia switches bow. So the cache is keyed on the selection AND refreshed on a short clock; HP changes every frame and is summed every frame from an index array, with no strings.

**Measuring tools that exist:** `perf/FrameParts.java` (client frame sections, `[FrameParts]` line every 10 s; add a section exactly as commit `59296212` did for `MARKERS_RANGE/METAL`: constant, `NAMES` entry, `FRAME_SECTIONS`/`UNIT_TICK`/`SECTIONS` bumped together; `FrameWindow` reads the arrays, `SysTimerTest` and `RenderStageGateTest` mention it), `matchstart/EyesOverlaysScene.java` (EyesDirector scene 18: 500 units + 1,700 buildings; its `SECTIONS` array at :64-67 lists what it prints; a nested section must be excluded from the `ours` total as `MARKERS_*` were at ~:433-436), `tools/eyes_diff.py` + `eyes-approve.yml` (picture regression against `<lane>-approved`; read the header of `tools/eyes_diff.py` for its arguments), `tools/hud_audit.py`, `tools/hud_layout.py`.

**Conventions to follow:** `hud/EconomyBarRenderer.java` and `hud/GlobalProductionQueueRenderer.java` are the exemplars of an extracted panel: a final class with static methods taking what they draw with, called from `drawHud`. Pure-class JUnit style: `bar/src/test/java/.../perf/SysTimerTest.java`; source-scan ratchet style: `bar/src/test/java/.../perf/RenderStageGateTest.java` (reads `bar/src/main/...` as text).

**Hard rules (all apply):**
1. Tests first, red on main: pure classes get a JUnit table with a throwing skeleton first; each extraction PR gets a line-count ratchet test that fails on main (step 3).
2. Client code stays in client classes; `python3 tools/check_server_client_imports.py` passes.
3. Fog of war: the HUD shows only what the client already knows; do not add any new lookup of hidden entities.
4. Oculus: HUD is drawn on the screen layer, `ShaderPacks.skipOverlays()` does not apply; do not move any call into a level-render handler.
5. No file crosses 1,000 lines: `HudClientEvents.java` is over, so every PR's net change is NEGATIVE; new panel files stay under 600 lines.
6. `python3 tools/check_java.py` 0 structural errors; `bash tools/prepush.sh` (includes `hud_layout`) before every push.
7. A panel moves with its code UNCHANGED (cut and paste; only variables it needs become parameters). No cleanup, no renaming, no "while I am here" in a move PR. Every visual change is a bug.
8. Commit by explicit path, identity `git -c user.name=IamTheLovish -c user.email=IamTheLovish@users.noreply.github.com commit`, trailers as given; never push `main`, never force push. Post on #35 before touching `hud/`.

## Steps

### Step 1 - split the HUD section and measure (PR 016a, no behaviour change)
1a. `perf/FrameParts.java`: four nested frame sections after `MARKERS_METAL` (ids 15-18): `HUD_SELECTION` (strip, 1051-1240), `HUD_ORDERS` (unit action buttons + building buttons, 509-884 and 1273-1529), `HUD_ECONOMY` (1530-1695), `HUD_MINIMAP` (1696-1897 and 2136-2190); `FRAME_SECTIONS = 19`, `UNIT_TICK = 19`, `SECTIONS = 20`; names `hudSelection`, `hudOrders`, `hudEconomy`, `hudMinimap` in `NAMES` (same order). Wrap each block in `int t = FrameParts.begin(FrameParts.X); try { ... } finally { FrameParts.end(t); }`: wrapping means ADDING a `try {` line before and `}` after; do NOT re-indent the block (the diff stays small; step 3 moves them anyway).
1b. `matchstart/EyesOverlaysScene.java`: append the four ids to `SECTIONS` (:64-67) and to the exclusion list in the `ours` sum (they are nested in `HUD`).
1c. JUnit `perf/FrameSectionsTest` (pure, new): `FrameParts.NAMES.length == FrameParts.SECTIONS`, ids are unique and contiguous, `FRAME_SECTIONS < SECTIONS`, and the four new names exist. RED first (write it before 1a); it needs `NAMES` visible to the test (package-private already: `static final String[] NAMES`).
1d. Run scene 18 on the PR's `bar` build: `gh workflow run eyes.yml --ref <branch> -f overlays=true -f build_run=<the PR's bar run id>` (the id: `gh run list --branch <branch> --json databaseId,name,status`). Read the `[Eyes] 18_overlays zoom 30` and `zoom 200` lines from `eyes-lines.txt` in the artifact `eyes-overlays-<run id>` or the run annotations: the median ms of `hud`, `hudSelection`, `hudOrders`, `hudEconomy`, `hudMinimap`, with the selected count printed on the `18_overlays_mid` line.
GATE 1: `FrameSectionsTest` counted in the `JUnit summary` notice (+1 class); the four numbers and the selected count are in the PR body. DECISION RULE: if `hudSelection` median is under 0.15 ms with the 500-unit selection, step 2 is not worth its risk: skip it, say so in the PR, go to step 3 only if lovish wants the refactor for its own sake (report that and stop). Otherwise continue.

### Step 2 - cache the selection grouping (PR 016b)
2a. Pure `hud/SelectionGrouper.java` (no Minecraft imports; generic): 
```java
final class SelectionGrouper<T> {
    record Group<T>(T first, String name, int count, int cost, int firstIndex) { }
    List<Group<T>> groups(List<T> sorted, long signature, int nowTick, ToIntFunction<T> idOf, Function<T,String> nameOf, ToIntFunction<T> costOf);
    int groupIndexOf(int i);            // for the HP sum: which group the i-th unit is in
}
```
Rebuild rule (the whole cache contract): rebuild when the signature changed (size, and the sum of `(i+1) * idOf(unit_i)`: ints only, O(n), no strings), or when `nowTick - lastBuildTick >= 5` (names can change under an unchanged selection; 5 ticks = 250 ms, state this in the PR), else return the cached groups and call `nameOf` ZERO times. Groups are in cost-descending, then name order (the `BY_COST_DESC` rule, :157-158; the sort happens at rebuild only). HP: `HudClientEvents` sums `getHealth/getMaxHealth` per frame into two float arrays indexed by `groupIndexOf(i)` (one pass over `selUnits`, no allocation: reuse the arrays).
2b. JUnit `SelectionGrouperTest` (table, RED first against a throwing skeleton; fake units are a plain `record U(int id, String name, int cost)`): (i) runs of equal names collapse, counts right; (ii) order is cost descending then name; (iii) an unchanged signature inside 5 ticks calls `nameOf` 0 times (counting lambda); (iv) a changed signature rebuilds at once; (v) unchanged signature at tick +5 rebuilds (a renamed unit regroups); (vi) a unit that is not controllable is NOT filtered here (filtering by owner stays in `HudClientEvents`, :1075-1078, because it depends on alliances that change without the selection changing: call it on the cached groups each frame, it is a few comparisons per GROUP, not per unit).
2c. Wire it: replace `HudClientEvents.java:1061-1084` by the call, keep `SelectionGroup` fields the tiles already use (:1086-1155 unchanged). `UnitClientEvents.getSortedSelectedUnits()` (:170) is the input; do not touch selection code.
2d. GameTest or eyes? Not a GameTest (client). Check by picture: scene 18's `18_overlays_mid` still (a mixed army selected) before/after must be identical: `python3 tools/eyes_diff.py` on the two runs' stills (read its header for arguments).
GATE 2: `SelectionGrouperTest` green (+6 cases in the JUnit notice); scene 18 `hudSelection` median before vs after (same selected count) in the PR body; `eyes_diff` says the stills match (or lists a diff you explain as animation/noise); `bash tools/prepush.sh` passes; `git diff --stat origin/main` shows `HudClientEvents.java` with more deletions than additions.

### Step 3 - move one panel per PR (PRs 016c-..., smallest and least risky first)
Order (each is one PR; re-take the claim for it): (1) tooltips + menu button + observer/diplomacy toggle + right-edge helper column (2073-2207); (2) spectator start buttons + game rules menu (1898-2072); (3) minimap start-pos buttons (2136-2190); (4) minimap buttons + warning (1696-1897); (5) resources + production queue + temporary messages (1530-1695); (6) selection strip (1051-1240, now thin after step 2); (7) unit action buttons (1273-1529); (8) portraits and hovered cards (885-1050); (9) selected building (509-884).
Per PR, the same five moves:
 a. RATCHET FIRST: `bar/src/test/java/.../hud/HudSizeGateTest` (source scan, style of `RenderStageGateTest`): `HudClientEvents.java` has at most `<current line count - lines you will move>` lines (use `git show origin/main:<path> | wc -l` for the current count, subtract the block's lines minus about 12 for the call and parameters). RED on main, GREEN after. Each PR lowers the constant; do not raise it.
 b. New file `hud/<Name>Panel.java` (final, static `render(...)`, exemplar `EconomyBarRenderer`), holding the block verbatim. What the block reads from `HudClientEvents` statics (`renderedButtons`, `hudZones`, `unitButtons`, `mouseX/mouseY`, `hudSelectedEntity`, `economyBar`, `bottomPanelTop`, ...) is passed in or read through the existing `public` fields; do NOT make private fields public beyond what the block needs and say which in the PR.
 c. The block in `drawHud` becomes one call, inside the same `FrameParts` section wrapper as before (step 1), same ORDER of drawing (draw order is z-order: tooltips last).
 d. Picture check: the PR's `bar` build through the full tour (`gh workflow run eyes.yml --ref <branch> -f build_run=<id>`; MIN_STILLS 30) and `tools/eyes_diff.py` against the main build's stills of the same commit base: the HUD stills (the 02, 04, 11b, 12-ish shots) must match; any difference is a bug in the move.
 e. `python3 tools/hud_layout.py` still passes (nothing in `HudLayout` changes).
GATE 3 (every PR): `HudSizeGateTest` green (red on main first), `eyes_diff` result quoted, CI green (`python3 tools/ci_wait.py --pr N` prints GREEN), `HudClientEvents.java` line count before -> after in the PR body.

## Out of scope
Changing what any panel shows, its layout, keys or tooltips; a new layout system or panel interface; `HudLayout`/`HudPanels`/`Button` internals; cursor and input code (`onKeyPress`, `onKeyRelease`, `onMousePress`: they stay, a later plan can move them once the panels are out); the minimap itself (`MinimapClientEvents`); the unit-card and command-card renderers; GUI scale handling.

## STOP conditions
- Drift check shows a change inside the block you are moving; #35 has a Lane C message saying they are editing that panel.
- `eyes_diff` shows a visual difference you cannot explain as noise after one fix attempt: do not merge, report with both stills' names.
- A block uses a local variable declared far above it (setup at 428-508 feeds everything): pass it as a parameter; if more than 8 parameters are needed, stop and report the block's dependencies instead of inventing a context object.
- `hudSelection` is under 0.15 ms (step 1 decision rule) and lovish has not asked for the refactor.
- CI red you cannot explain after one fix attempt; same test red on main (`tools/known_flakes.txt`).

## Done criteria
- `[FrameParts]` shows the four HUD sub-sections; the HUD cost is in the PR with the selected count.
- The selection strip calls `getModifiedEntityName` zero times on a frame whose signature and clock did not change (proved by `SelectionGrouperTest` (iii)).
- Each moved panel: `HudClientEvents.java` shorter, the ratchet raised nowhere, stills identical.

## PR body template
```
## What
<step and panel>

## Evidence
- Before/after FrameParts (scene 18, run <id> / <id>, N selected): hud X ms -> Y ms; hudSelection ...
- Red commit <sha> (ratchet or JUnit failing) -> green commit <sha>
- eyes_diff: <result>, stills <build_run ids>
- HudClientEvents.java: <before> -> <after> lines

## Numbers for lovish / questions
- Name staleness: the grouping refreshes within 250 ms of a baby growing up, a banner equipped or a rider mounting.

Do not merge without lovish's OK
```

## Return format (max 200 words)
PR number(s); GATE results (command + one-line result); the FrameParts numbers; line counts of `HudClientEvents.java` before/after. Nothing else.
