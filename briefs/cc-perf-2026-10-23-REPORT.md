# Report: cc-perf-2026-10-23 (acct B, gen-012, Claude Code on lovish's PC)

## Summary (updated 22:00)
| item | PR | state | numbers |
|---|---|---|---|
| 1 buildingDecor hitch | #202 | MERGED 294cd477 | crowd zoom 2.08 -> 0.00 ms, close 1.17 -> 0.32 ms (eyes, shaders, 505 units) |
| 2 worldMarkers | #202 + #214 | MERGED f3b3008d, partial | crowd zoom 3.73 -> 2.22 (#202) -> 1.42 ms (#214); close zoom 3.59 -> 2.65 ms; target < 1 ms NOT met. #214: BlockClientEvents fetched getBuffer every frame even when nothing was drawn (ends the open batch); range-indicator buildings/units refreshed every 5 ticks. Remaining: markersRange ~0.8 ms with cheap loops - needs a finer split. Numbers indicative (runner speed varied). |
| 3 unit models at strategic zoom | #202 | MERGED | crowd zoom unitBodies 22.29 -> 1.20 ms (icons +2.28); close zoom unchanged |
| 4 server per-unit vanilla tick | #207 | MERGED fb82fade | push via UnitGrid. Measured: stress_building_scans (300 idle vindicators + 1,000 buildings, whole server tick, grid phase), 5 samples each: BEFORE 49daa4d median 19.55 ms/tick (14.9-21.4), AFTER fb82fade median 17.99 (14.5-19.7), about -1.6 ms/tick (-8%). Ranges overlap: right direction, imprecise size (runs 40060818145 / 40060819829). Consistent with ~2-3 ms at 450 units if linear; the -5 ms target is not reached by this alone. |
Also merged: #174 (main red -> green), #208 (server log spam), #212 (benchmark crowd zoom), #213 (known flakes), #215 (bots re-picking unreachable sites: root of the T2 flake). Parked: #203 (wet metal pads, island fallback, lovish's call). #199 is superseded by #174 and still open.
Server follow-ups: #217 merged c1b0e52f (revived #173: one mount search per call instead of one per unit; neutral-aggro scan skips units, behaviour equal). #218 (revived #119: target acquisition through an entity grid, combat/attack-move/target-scan GameTests green; its own benchmark showed targeting 1.80 -> 0.25 ms/tick on the old base) merges with idle aggro kept at 4 ticks.
**Question for lovish:** idle units looking for enemies every 8 ticks (0.4 s) instead of 4 (0.2 s) halves those lookups again (80 -> 40 per tick at 300 idle units). The code marks it "GAMEPLAY NUMBER (lovish to approve)". Yes or no? It's one constant: AttackerUnit.IDLE_AGGRO_TICKS.

**lovish, in your next late-game match:** FPS at 450+ units around zoom 50-70; units still spread out and titans still shove infantry; bots don't stand still at metal patches; extractors place on patches near water (some still won't: #203). Off switch for the icon change: `unit_render_lod = false`.

Intake (16:40): no code changed yet.

## Finding: items 1-3 already have a PR
PR #202 (draft, branch `claude/perf-late-game`, head 10f617b): an earlier PC Claude Code session (D:\BeyondAndTabs-Repo, 01:55-02:04 ET, see ledger 04:31) did it before this brief was written. The brief and the 16:15 handoff don't mention it.
- d6d4b02 tests first (UnitIconCrowdRulesTest, FrameBudgetTest, RenderStageGateTest; red = they don't compile on main).
- 10f617b: crowd-scaled icon switch + model skip in EntityRenderDispatcherMixin.shouldRender (item 3), stage gate in front of the FrameParts timer and Iris call in all 14 level-stage handlers + frustum culling of metal rings and gems, banners, mill parts (item 2), one banner mount per frame via FrameBudget (item 1).
- Claim `perf-late-game` on #91, 05:56Z, until 2026-10-24T05:56Z (Lane A).
- Decision (technical): this seat continues #202 as that session's successor. No parallel branch.

## CI on 10f617b: red
build, changes, ruff and bar-tests 2-9 pass. **`bar` (compile + shard 1, where new tests run) fails** at exit code 1; the annotations don't give a cause. The job log (run 39909198368, job 120268053279) is 403 without a login, so the cause is unknown. All the other shards passing suggests the code compiles and a shard-1 test fails, but that isn't confirmed.

### Fix (17:05)
The cause was the test, not the game code: `RenderStageGateTest` (JUnit, line 49) treated the private helper `StatueRenderClientEvents.draw(RenderLevelStageEvent)` as a handler, and that helper has no FrameParts section. Commit e05c152 matches only `@SubscribeEvent` handlers. Checked: 15 handlers found; all 15 gated on the branch, all 15 ungated on main, so the test is still red on main and not weakened. check_java: 0 structural errors. CI rerun pending (tools/ci_wait.py --pr 202).
Local prepush on Windows: `ruff (tools)` and `animation lab data` fail on the unchanged tree too, while CI passes both. That's a PC environment difference, not this branch; not investigated yet.

### CI and review (18:20)
- CI green on 0db999e (main merged in; first attempt red only on the bots_reach_tier_2 flake: 1/5 on main, stress run 40022354822).
- Mode A pass. One rule (UnitLodRules.skipUnitModel) serves both the dispatcher cull and the render-event net; the budget is a plain counter; off-screen decor is frustum-culled. Visible default change: icons from zoom ~49 instead of 70 at 600+ known units, off with `unit_render_lod = false`. Note: with shaders the banner handler can run twice a frame, so the budget is effectively 2 mounts/frame. Still bounded.

### Benchmark gap found (18:10)
eyes overlays (scene 18) measured only zoom 30 and 200 and didn't report buildingDecor/worldMarkers, so it can't see any of #202's three changes (the LOD change acts at zoom 49-70). BEFORE on main 5ce0ea3, shaders (run 40021956473): zoom 30 unitBodies 37.31 ms, overlays+HUD 8.05 ms; zoom 200 unitBodies 0.38, strategicIcons 5.25, hud 5.25, overlays+HUD 13.69 ms. CI frame times are ~1.2 s (software GL), so only the per-section CPU ms mean anything.
Fix: PR #212 adds a crowd-zoom 60 slice plus buildingDecor and worldMarkers to scene 18 (measurement only). After it merges: BEFORE on main and AFTER on #202, plain + shaders.

### BEFORE -> AFTER (19:55), eyes overlays scene 18 with shaders (Complementary), 505 units + 1,715 buildings, CPU ms per frame, medians of 4 slices
BEFORE main 48e3586 (run 40029740744); AFTER #202 4b6bcd9 (run 40031791643).

| zoom | section | before | after |
|---|---|---|---|
| 60 (crowd) | unitBodies | 22.29 | **1.20** |
| 60 | strategicIcons | 0.00 | 2.28 (icons drawn instead) |
| 60 | buildingDecor | 2.08 | **0.00** |
| 60 | worldMarkers | 3.73 | **2.22** |
| 60 | overlays+HUD | 8.57 | 9.13 |
| 30 (control) | unitBodies | 38.06 | 37.99 |
| 30 | buildingDecor | 1.17 | **0.32** |
| 30 | worldMarkers | 3.59 | 3.53 |

Net at crowd zoom: about -24 ms of our CPU per frame. Close zoom is unchanged, as intended. CI frame times (~1.2 s, software GL) mean nothing; the per-section CPU numbers do.
Against the brief: item 1 buildingDecor mean 0-0.3 ms (target was max < 3 ms; the max isn't in the scene, but the spike source is capped). Item 3 model cost at crowd zoom -95%; "elsewhere" can't be measured in CI, so lovish's next late-game log is the check. **Item 2 NOT met**: worldMarkers is 2.2-3.5 ms vs the < 1 ms target. #202 only gates the stages; batching the 165 draws into one buffer is still to do (follow-up).
Plain lane (no shaders): crashes at startup on main as well (Oculus wants Sodium classes; PR #135's subject), so there are no plain numbers.
Merge: held only by the bots_reach_tier_2 terrain flake. Lands after #203.

For lovish in game: with a big army (200+ units) units turn into icons a little closer in (zoom ~49-70 instead of 70); `unit_render_lod = false` restores the old switch. Banners on a newly revealed base can appear a few frames late.

## Item 4 (server per-unit vanilla work)
PR #207 (draft, claude/perf-unit-vanilla-tick, claim perf-unit-vanilla-tick), built by a sonnet agent: a unit's vanilla pushEntities finds overlapping bodies through UnitGrid instead of a world entity query (~104 queries per pillager per window in the Oct 22 profile). Tests: PerfPushGameTests (pushScan counted, a pile of 40 units still spreads out).
Mode A (17:40): BLOCKER, sent back to the builder. It called push() directly, which skips the doPush overrides (TitanMass shoving for War Mammoth/Iron Leviathan/Leviathan, plus Bat/Wraith/Wretched Wraith). Fix: call each entity's own doPush from the mixin, with a GameTest guarding titan shoving through the real push pass.
Fixed (19:00): ba48738. LivingEntityMixin @Shadow doPush now runs every entity's own override, which also covers WorldTreeWalker and SunColossus. New GameTest a_titan_still_shoves_small_bodies_in_the_push_pass (War Mammoth + 3 Brutes, shove >= 0.1): red on 4e01a78 (pushes 0.05/0.06/0.00) with an earlier setup, green on a6c16a3. Mode A pass. Marked ready; merges on green after #213 (known flakes).
Numbers: the new lookup costs 0.11 ms/tick for 24 units (CI SysSample). The old cost wasn't measured, so there's no BEFORE -> AFTER yet; ~2-3 ms/tick at 450 units is extrapolated, not measured. baseTick and travel are untouched (nothing provably unused found without an MC classpath).

On hold (19:40): the #207 merge stopped on bots_reach_tier_2, failed twice. Diagnosis (sonnet, read-only): a flake, not the push change. Bot base positions shift with the test count (#207 adds tests), and on some terrain the bots stall on build sites their workers can't reach. The same stalls happen on passing main runs, and #202 (client-only) fails the same test. Root cause found in draft PR #203 (the previous PC session's, same seat): **8 of 48 stamped metal patches refuse every faction's extractor (ground_not_flat), for players too**. A sonnet builder is fixing #203; then #207 and #202 rerun.
Update (20:30): #203 NOT fixed after 3 rounds. Cause, partial: MetalPatches.stamp (~209-275) stamped a patch with no dry spot within 12 blocks anyway and skipped water columns, leaving a wet pad. Fixes cut refusals to 1-5 of ~50 per map, but some pads are still wet. The latest commit raises an island in open water, which changes the map look (lovish's call), so it is parked as a draft and NOT merged. Next step: log the stamp branch and fluids around a refused patch. It also does not fix the bots flake. So the bot-side fix is now claimed (bot-unreachable-site): a bot drops a site no builder can reach and re-picks, built by the sonnet agent that diagnosed it.
Update (21:00): PR #215. Cause: BotSiteWatch (~162) marked a cancelled extractor site's patch as bad only within 3D distance 4 of the site's centre. A site raised over its patch has its centre several blocks up, so it never matched and the bot re-laid the same unreachable site every few seconds. Fix: match by column, avoid for 5 min, drop after 3 cancels (existing PATCH_GIVE_UP). Tests: BotSitePatchRuleTest (JUnit) and the bot_leaves_the_patch_of_an_extractor_site_its_workers_could_not_reach GameTest. The red commit didn't compile in CI, so red is by construction, not shown. CI green; flake-stress on bots_reach_tier_2: 0/5 (main 1/5). Mode A pass. Merge chain queued: 215, then main into 207 and 202, then merge both.

## Also done
- Merged #174 (16:28): main was red since 04:37 (T2 bot test found no dry bases, plus ruff). Main green again at 5ce0ea3. #199 is superseded but left open; permissions blocked closing another session's PR.
- PR #208: server log spam. A dropped connection logged 78,376 stack traces in 30 s (28 MB); now 1 trace + a count line every 1,000. Tests first, merge on green queued.
- bots_reach_tier_2... fails on main too (run 40021858426, "never finished its T2 lab"), so it's flaky on main. Stress run 40022354822 (5 runners) is measuring it.

## Blockers
Cleared 16:55 (lovish gave full access): Python 3.12 + JDK 17 + ruff installed on Windows; `gh` runs with GH_TOKEN from Git Credential Manager, never printed or stored.
Remaining note: the local repo fetches only `main` (remote.origin.fetch). Harmless, but it hid #202's branch from `git branch -r`.

## For lovish in game
Nothing to check yet.
