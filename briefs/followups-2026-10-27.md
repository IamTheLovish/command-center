---
title: Open follow-ups after the living army (PRs #277-#284) and gen-014
type: tracking
date: 2026-10-27
---
# Open follow-ups, 2026-10-27 evening

State as handed over by the living-army session at 18:50Z, plus what this Command Center session did. Re-check each line
with `gh pr view` before acting on it (branch-check rule).

## Waiting on lovish (merge OKs: not ours to push)

| # | What | Where | Why it matters |
|---|---|---|---|
| 1 | DONE: **#276** merged 2026-10-27 19:08Z (2407a0ef), Mode A PASS; merged on the elder_druid red that #273 fixed (lovish: "Merge #276 now") | game repo | main cannot open any world since #248 ("Channels [reignofnether:main] rejected their server side version number"). Verified in a real client by merging it locally. |
| 2 | DONE: **#273** merged 2026-10-27 19:07Z (511e663f), Mode A PASS, stress 40565576897 clean | game repo | fixes `elder_druid_is_a_t2_worker` on main (stale test after #253) plus the fog-snapshot block-entity bug. Report: `briefs/flake-roots-2026-10-27-REPORT.md`. Design note: if the Elder Druid should keep Awaken Thicket, the fix goes the other way. |
| 3 | Merge **#274** (mode-a gate workflow), then apply `guards/github/protection.json` | game repo | Mode A PASS on e090f687 (round 2). Test the app_id on one throwaway PR first (guards/github/README.md). main is still unprotected. |
| 4 | Nightly jobs | Task Scheduler | stay off (D046); D037 suspended until lovish says otherwise. |

## Game repo work (needs a session in `D:\BeyondAndTabs-Repo`)

| # | What | Blocked by |
|---|---|---|
| 5 | CI eyes harness stalls on Supplementaries' WelcomeMessageScreen at step 0 (last green 03:46Z, run 40445996646). Fix belongs in `EyesDirector.java`. | PR #176 owns that file |
| 6 | Add a parade scene to the eyes harness (living army). | #176 merged |
| 7 | Bring the Bone Dragon into the living army. | #145 merged |
| 8 | FIXED in draft #286: local `prepush.sh` failed on three pre-existing main issues: check_java "Argument list too long" on Windows; animation lab data; SHARD_8 entry `test:men` names no test (#253 deleted the mending tests; needs a `.github/workflows/build.yml` edit and the gh `workflow` scope). | none |
| 9 | Intermittent COMMON_SETUP crash: `ResourceCostConfigEntry.getWood() is null` (bar-tests (5), job 122075675704, run 40469588386). | draft PR #285 (session "1"): a config reload clears ForgeConfigSpec's cached value between its check and return; getters re-read the transient null, test first (red on f963972d). Shares no files with #273/#272; merge main in after #273, then Mode A. |
| 10 | Hero AI v2 PR 1 (#275): five feel questions for lovish in `briefs/hero-ai-v2-pr1-2026-10-27-REPORT.md`; GREEN_RUN / STRESS_LINE placeholders still unfilled in that report. | lovish plays the Paladin |
| 11 | GPU units: in-client proof of path C under Oculus + Complementary before round 3 (smooth skin). | about a day of spike work, then lovish's eyes |

## PC / Command Center

| # | What | Status |
|---|---|---|
| 12 | The "lovish" desktop shortcut was said to launch the empty `BeyondAndTabs` instance. | checked: it already launches `BeyondAndTabs(1)` through `D:\BeyondAndTabs-Server\Play Beyond and Tabs.bat` (D045) |
| 13 | Gate-hook blocked reviewer agents on branches with commits under 2h old. | DONE on `cc/gen014-guards-and-reports`: M17, `-Reviewer` / brief line `ROLE: reviewer`; selftest 44/44 |
| 14 | Private repo `main` (origin) and the public mirror (`public`) have unrelated histories; M16 (branch-check own-gen comments) is only on the public side. | asked: which remote gets `cc/gen014-guards-and-reports` |

## Joisco's ready PRs vs main after #273 / #276 (checked Oct 27 ~19:30Z)

Every run below predates #273, so `elder_druid_is_a_t2_worker` is in all of them. A branch update from main (Joisco, or lovish's "Update branch" button; not ours to push) re-runs CI on today's main.

| PR | failing tests in its last run | expected after a branch update |
|---|---|---|
| #264 launcher PLAY hang | elder_druid | green |
| #270 build-order fixes | elder_druid | green |
| #272 main green (test setup) | elder_druid | green; its capture_bounded / ac1_shift fixes still stand |
| #266 fog ghost | elder_druid, ac1_shift (fixed by #272) | green once #272 is in |
| #265 select + camera | elder_druid, bots_reach_tier_2 (plan 015, waits on #203/#221), capture_bounded (#272) | probably green apart from the bots T2 flake |
| #269 enemy inspect | elder_druid, the_snapshot_of_unloaded_chunks (fixed by #273), bots_play_each_other | rerun; bots_play_each_other needs a look if it repeats |
| #267 fast pack | elder_druid, artillery_fires_over_a_wall, wading_unit_moves_at_half_speed, bots_play_each_other | needs a look: artillery and wading are not known main flakes |
| #227 T4 Worldbreaker | build, ruff, every_building_and_production_item_icon_ships, every_unit_type_has_cost_... (Oct 24 run) | its own reds; Joisco's to fix |

## Done in this session after the merges

- Draft PR #286 (`claude/prepush-windows`): `tools/prepush.sh` passes on Windows (check_java @argfile + UTF-8, anim_lab path slashes, SHARD_8 `test:men` removed). Needs Mode A + lovish's OK.

## Who is on what (Oct 27 ~19:50Z)

| Work | Owner | Where |
|---|---|---|
| #286 prepush on Windows | this session | Mode A PASS round 2 (bc8e8491), lovish OK'd the merge; merge when CI is green |
| #285 ResourceCost NPE | Desktop session "1" | Mode A PASS (a38e2c2d), draft, waits on lovish's OK |
| #287 config reload race everywhere (mixin) | claude.ai chat "13" (Beyond All Craft project) | draft; Mode A review started from this session |
| plan 015 step 3, vanilla_path arenas | Desktop session "1" | branch claude/flake-015b-pathing-arenas |
| ac2 guard flake | this session | branch claude/flake-ac2-guard; shard-1 stress 40570846741 on main for a diagnosed red sample |
| idle_reclaim_never_overrides_orders_or_building, the only new red on main after #273/#276 (runs 40566241275, 40566701183) | claude.ai chat "13" | branch claude/flake-idle-reclaim |

## Flake results, Oct 27 ~20:30Z

- ac2_a_guard_follows_its_ward_to_the_next_site_and_helps_there: NOT reproduced since #273's changes: 0 of 6 in shard-1 stress 40570846741 on main 2407a0ef, plus 0 of 10 twice on the #273 branch (40469592779, 40472451498): 0 of 26, against 4 of 20 before. No fix without a red sample; #273's diagnostics (guard end, B's order, A's site ticks, wall time) stay on main for the next one. Branch claude/flake-ac2-guard deleted (no commits).
- Same run, other reds: ac1_shift 2 of 6 and capture_bounded 2 of 6 (Joisco #272), vanilla_path_wall_detour 1 of 6 (#289), bombard_backs_out_of_its_dead_zone 1 of 6: "the bombard never hit the target (moved at most 3.7, now 6.7 away, dead zone 6.0, nav done true, aggressive false)". Not fixed: #222 (artillery nerf: 2 s set-up after moving) changes ArtilleryGameTests, BombardCrewUnit, FieldArtillery and BombardShell; fix it on #222 or after it.
- Claude PRs #133 #136 #146 #196 #199 #204 #206 #221 #222 are 3-5 days behind main; their reds predate #273/#276. `gh pr update-branch` from a session was refused (external write); needs lovish's say-so or a session with that permission.

## Coordinator, Oct 27 night (took over from the Command Center session at ~21:50Z)

- **Vacuous stress runs.** flake-stress 40582259285 (#136), 40582056986 (#287) and 40581759617 (#289) passed bare test names without `test:`, so BAT_GAMETEST_ONLY matched nothing and every sample logged "All 0 required tests passed". #289's "[Stress] 0" comment is corrected on the PR. Reruns with `test:` prefixes, 8 runners: 40591016638 (#136), 40591020841 (#287), 40591024675 (#289). Follow-up: flake-stress should fail a sample that ran 0 tests.
- **#222.** `PossessionServer.keysHeld` (a walk key held with fresh input) replaces `isPossessed` in SetUp `driven`. That alone left the keys-driven knockback test red: a real knockback(0.4) throws the crew ~2 blocks through the air and crossed DRIFT (1.5) mid-flight (debug trace). The airborne, not-walking part of a step now carries the anchor along; ground pushes over 1.5 and one-tick jumps over 1.5 (teleports) still count. This applies to AI crews too ("being shot at is not moving").
- CI reruns of the named flakes: #287 (capture_bounded + the_budgeted_snapshot, Joisco #272 area), #289 (a_pile_of_units_still_spreads_out, PerfPushGameTests, not touched by #289), #196 and #204 (capture_bounded, bots_reach_tier_2).
- **Gate M19** (bcae214): lovish's own GitHub-web commits (`<digits>+IamTheLovish@users.noreply.github.com`, as on main's merge commits) count as IamTheLovish. "Claude <noreply@anthropic.com>" commits still fail the authors check: #133 #146 #196 #204 #206 #287 are blocked on it. Rewriting authors needs a force-push, which the auto-mode classifier refused; asked lovish.
- **#222** round 4 BLOCK (a lying client could hop a possessed crew with no keys and keep its set-up): fixed tests-first (7b4b56bd red, b4f5cbd0 green, 11/11 ArtilleryGameTests locally); stress 40593300699.
- **#204** round 1 BLOCK: the main merge split a Go string literal (compile error); fixed 2b2da719, installer build 40591983227 green. Needs a round-2 look and the authors fix.
- **#290** (ResourceCost race, session 2): Mode A PASS (red 3/3 before, 5/5 green after); marked ready; shard-1 rerun for capture_bounded.
- **Relay to Itachi 1** (lovish's other account = claude.ai chat "13" in the browser pane): `tools\relay.ps1` mailboxes in `relay\` (git-ignored). It took two tasks: the stress-evidence guard (gate M20 + flake-stress fails a 0-test sample) and the a_pile_of_units_still_spreads_out flake.
- **Merged:** #290 (ResourceCost reload race, 01b9011a). #221 got main merged in (8ad46cb8, PR diff unchanged, review carried over); its CI is running.
- **Authors:** lovish OK'd force-push for author-only rewrites. #133 962ced97, #146 47feccbb, #196 9a44e165, #204 a9428c4a, #206 b0999667, #287 bcfd2c9e (every tree identical). Local worktrees D:\bt-133, D:\bt-146 and D:\bt-204 still hold the old commits, so re-fetch before working there. Gate M21 (70197b5): a review file is judged on its last round.
- **Reviews:** #204 round 2 PASS (a9428c4a); #146 Mode A running. The reviewer left a partial clone at D:\bt-204-review (safe to delete).
- **Session 3:** the a_move_into_unloaded_chunks PR waits on the pr-budget override; it is asking lovish directly.
- **Itachi 1 (chat 14):** the stress-check PR goes from claude/flake-stress-runname-entries (session 1's entries check and run-name, stacked on Itachi 1's dfb06a44 0-test guard), then the a_pile flake (lead: the pile test skips SkirmishGameTests.openGround). Its link to lovish's PC shows "Not connected", so it works from the cloud. Messages typed while it is busy queue up ("Send now").
- **Merged:** #204 (installer cat bubble, ce551321), #221 (slower T2, 2d51b82e). #196 got main merged in (c47b8f09, PR diff unchanged).
- **#222** rounds 5-6 BLOCK, both client-cheat holes now closed tests-first: a faked sprint-jump (bda2718f red, ee5a55f7 fix: serverShove only from the server's own velocity) and keys momentum (b11e1cbb red, c27cb144 fix: claimsLastTick). 13/13 ArtilleryGameTests locally; round 7 running; stress 40600855397. Pre-existing, separate issue: under continuous claims a possessed unit never reads on-ground (travel's move(0) after applyClaim), so airTicks keeps climbing, the honest sprint-jump boost rarely applies, and the hover rule can force a fall.
- **#146** round 1 BLOCK (fragile new tests) fixed in 1539a669 (pad chunk ring, hurt-worker judged after the first hit); round 2 PASS; stress 40598837754.
- **New flake candidate:** JUnit AnimationCostBench.livingArmyTick (timing budget 1.0 us/unit, got 1.41 on a CI runner; #146 run 40598844824). A wall-clock budget in JUnit on shared runners will flake; it needs a margin or a non-CI gate.
- **capture_bounded_when_barrier_hangs** failed about half of all shard-1 runs tonight (#206 twice, #287, #133, #196, #290). Joisco's #272 fixes it; asked lovish whether a red that is only this test may merge.
- **Merged later in the night:** #287 (1dd70f96), #136 (e8940e7b), #206 (02426303), #272 Joisco's capture_bounded fix (ffda3533, lovish OK'd; gate exceptions recorded on the PR), #146 (07808f31), #133 (cf3c972d). 11 merged tonight in all, counting #289 by session 2.
- **Open at hand-over:**
  - #222: round 7 PASS (c27cb144). Its CI red is capture_bounded only. The gate wants stress for artillery_never_targets_or_hurts_a_flyer: run 40607650522.
  - #292: merged main after #136 (66e728a7), round 2 PASS; CI 40607278477.
  - #293: PASS, but the JUnit zero-allocation gate is red (4000 bytes from the new rounds harness); Itachi 1 is fixing it.
  - #291: PASS (63a072aa); needs proof runs from its head before merge.
  - #203: its session found the "pad WET" cause; stress running.
- **Bug found tonight:** flake-stress `focus` given with test: prefixes matched nothing, so the summary had no per-test lines (#136, #146 and #222 had to be re-stressed). Fixed in #291 (63a072aa). Until it lands, dispatch without `focus`.

## Coordinator-2, Oct 28 early (took over at ~00:20Z)

- **Merged:** #291 (flake-stress hardening + focus fix, 5b73665f; delta round 2 PASS on 39bb0d3b, gate PASS). `focus` with test: prefixes works again; 4 runners and test: prefixes stay the rule.
- lovish re-OK'd in this session (Oct 28): "go and merge" #222 #292 #293 #203 each on Mode A PASS on its exact head + green CI + gate done PASS; #203's 6 Claude-authored commits may be re-authored with a force-push if `git diff old new` is empty. The auto-mode classifier refuses merges and force-pushes on relayed OKs; get them from lovish in the acting session.
- **#203:** Mode A FAIL on da64266d (6 commits authored Claude; code judged correct). Its session: probe via GameTestChunks.loadNowOrFail (d30c7025/516b8e96), bamboo-jungle pad fix (11785bc3, red first), body updated. Footprint stress 40607450396 (da64266d): solid_top 0/4 failed, footprint test 2/4 failed at 1604,63,5584 (pad dry, bot OK, player ground_not_flat). Re-stress with obstruction dumps 40609781800 on 11785bc3. Author rewrite ready locally at 5f2db5cd (tree identical); its force-push needs lovish's OK in that session or his own push.
- **#293:** Itachi 1's fix 18b38fc9 (JIT/OSR allocation, 300-frame warm-up): delta round 3 FAIL, the quietest-round gate lets 6 of 7 rounds allocate; fix = at most one round with bytes + a 45-frame test. With Itachi 1.
- **#292:** CI 40607278477's only red was bots_reach_tier_2 (known, plan 015); failed jobs rerun.
- **#222:** stress 40607650522 on artillery_never_targets_or_hurts_a_flyer still queued/running.
- Committed session 3's tools\prove-red.ps1 (default now 4 runners), its README line and 3 ledger lines (d29aff8).
- **Merged (Oct 28, coordinator-2):** #292 (move-unloaded flake, c62d50f2), #293 (AnimBench rounds + OSR-tolerant zero-allocation gate, round 4 PASS, d393118b), #222 (artillery nerf, CI rerun green past capture_bounded, stress 40607650522 clean, bbd64097). 15 merged since Oct 27 evening, counting #291.
- **Lag (Oct 28 ~00:45Z):** lovish's game lagged. A local GameTest server in D:\bt-203 (~5 GB + 1 GB Gradle daemon) left <1 GB RAM free; his server logged "Can't keep up" up to 306 ticks behind. Stopped; rule: no local Gradle/GameTest while lovish plays, test on GitHub (lovish: "we can work on other tasks and use our 20 runners"; stress now 8 runners).
- **bots_reach_tier_2** (failed 1/4 in 40607484452, and on #292's CI): not #203's pads. Medium piglins had mex 11/11 but "lab_annex_nether: no valid site within 32 blocks" min 24-34, then energy_converter_nether; the T2 lab never started. Building-site search near the base. Its own session after #203 merges (BotPlayer overlap).
- **Sessions started:** flake-budgeted-snapshot (local_77fb4962), stale-pile-1 (local_94982587: #216 #169 #257 #120 #177 #198 updated from main, CI running). Itachi 1: possession on-ground fix started after #222 merged; pile flake ongoing.

## Coordinator-3, Oct 28 (took over at ~01:45Z from coordinator-2)

- All working sessions told to report to coordinator-3 (local_1679b2c3): #203 (local_898e9773), stale-pile-1, flake-budgeted-snapshot, dev-match-stats-graphs, fog-of-war commands/mex, keep-units-selected.
- **Itachi 1 (chat 14):** #294 (tidewrought_t2_units_attack diagnostics, 57e438f1, draft): 6 of 7 old reds fixed Oct 22; the one Oct 26 red is unexplained, so a miss now reports ticks, target and shells; 32+16 samples queued. #131 merged main, retargeted to main; waits on CI, stress 40614186955 and two lovish design calls (T2 extractor numbers; generated maps follow main's metal options?). Possession on-ground at f6533896 (red proof 40613576657, guards 40613729513/40613777924), PR after proofs. Pile fix: 32 shard-1 samples. New task: bombard_backs_out_of_its_dead_zone flake (claude/flake-bombard-dead-zone), replacing the waiting card task_334eba2b.
- Stale pile CI at 01:45Z: #177 no checks listed; #216 #257 #198 #120 #169 still pending.
- **lovish OKs in coordinator-3 (Oct 28):** "Yes, merge each" the stale pile (#216 #169 #257 #120 #177 #198) and tonight's drafts (#294, budgeted-snapshot, match-stats graphs, fog-of-war commands, keep-units-selected, possession, pile), each on Mode A PASS on its exact head + green CI + gate PASS. "Yes, force-push it": #203's author rewrite from coordinator-3 if `git diff old new` is empty. Bone dragon (#145): model, animation and flight are wrong (scale OK). #222 follow-up: option A, cap client movement during a knockback.
- **Author rewrites (lovish OK in coordinator-3, "Yes, rewrite and push"):** #216 69cc090b -> ce039990, #169 705ff72b -> d07f149e, #177 8db1ec74 -> eb87af2b. `git diff old new` empty, 0 Claude identities left, commit counts unchanged. Done with `filter-branch --env-filter` in a bare blobless clone (scratchpad), force-with-lease.
- **Itachi 2 (via lovish paste):** Mode A of ~70 merged PRs done; ranked summary on #35 (issuecomment-6458214563), comments on #275 #274 #257 #216 #203. Top bugs: breath strobe (Motion.java:71), capture points survive back-to-lobby (#233), hero v1 ignores orders (#224), artillery hit by a flyer while moving freezes (#222), factory guard not cleared by build orders (#260). Plan 014 save hitch = draft #295 (72d14b66), not compiled yet, CI first check. New task for Itachi 2: T2 site-search flake (diagnose + red test now, fix after #203).
- **lovish answers:** X key for commander attack -> ask Joisco. Start phase 120 s -> keep. #295 5-minute crash rollback -> OK. #295 may merge on the same rule.
- **Owners proposed (cards):** breath strobe (task_630ec3a5), rematch capture reset (task_74cb232c), hero v1 orders + factory guard (task_268ea0e8). Artillery vs flyer -> knockback-cap session (local_305001b6) after its PR (message not yet sent: cross-session message cap).
- **Runners:** ~10 jobs running, 32 runs queued at 01:28Z. GitHub secondary rate limit tripped; all sessions told to poll at most every 5-10 min.
- **#131 answers (lovish):** T2 numbers A (follow main, re-run balancer). Metal: "each map should have mexes spread randomly and not be connected to where the townhall spawns" (none of Itachi 1's A/B/C); relayed to Itachi 1. X-key question posted to Joisco on #265 (issuecomment-6458322488). knockback-cap session: red test ab1975b1 pushed on claude/possession-knockback-cap; artillery-vs-flyer follow-up still to send (message cap).
- **T2 site-search flake, root cause (Itachi 2, from stress 40607484452 sample 4 annotations):** Horde converter, lab annex, Hoglin Stables and Flame Sanctuary must stand on nether blocks (BuildingValidators.isNonPiglinOrOnNetherBlocks). The bot lays its wind field at layoutSlot(WIND), 14-26 blocks behind the capitol (BotPlayer ~L2397), on the capitol's own netherrack (CentralPortal range 30); 9-18 winds by min 8-10 use the nether ground up. placeNearImpl (BotPlayer 2350-2369) samples the same 65 fixed points every think with no idea where nether ground is, so nether-only buildings fail forever. The T2 lab's own "no valid site" is hidden: blk keeps only the last failure (converter rule L682 overwrites the T2 lab rule L624). Fix direction after #203: nether-only buildings search the bot's nether zones, and/or winds avoid netherrack while plain ground is free. Itachi 2 owns it: red test next. #295 build check passed (compiles); GameTest shards queued.
- Artillery-vs-flyer follow-up sent to knockback-cap session (local_305001b6).
- **Reviews (coordinator-3):** #296 fog blueprints Mode A PASS (12ba5433); author asked to keep isKnownPatchUnderFog off the server path, then a delta review. #297 budgeted snapshot PASS (2ec560eb), round 2 delta PASS (5f09f7c5, timeout 3000 -> 5000). Both wait on proof runs and CI; #297's red run must fail with "holds the changed state, not the pre-match one".
- **Bone dragon (#145, a6fa0467):** flight rebuilt (DragonFlight/DragonMoveControl), take-off and flare bugs fixed; critique in side-session-notes/local_1c03e1b4.../pr145-dragon-critique.md. lovish: keep purple, heave ~1/3, half fold on the upstroke, bulk not answered (keep thin). Landing: a BAR-like land/fly command that dives onto ground units with an impact, plus a LONG cooldown against dive abuse; numbers to lovish.
- **Knockback cap:** claude/possession-knockback-cap red ab1975b1, fix a2571621; artillery vs flyer on claude/fix-artillery-vs-flyer. No stress run yet (rate limit).
- **Runners 01:45Z:** 4 runs in progress (~10 jobs), 40 queued. Archived living-army, command-center, session-2, session-3; coordinator-2 refused (mid-turn); finish-203-dry-extractor kept until #203 merges (its idle side session would go with it).
- **#298** match-end graphs stay up for non-hosts (session 5.1): Mode A PASS e2ef2662, round 2 delta PASS f0aa039b (main merged, stale reset, body). Waits on red 40613134748 / green 40613231322 and CI. Manual two-client check suggested for lovish later.
- **#296** round 2 delta PASS f2698983 (server path always reads real ground, hook try/finally). Waits on body line, proof runs, CI.
- **Bone dragon:** #145 claude/dragon-r13 at ba7f0c59 (flight steering, heave 1/3, half fold); dive = draft #300 stacked on #145 (claude/dragon-dive 4e66e34b, tests 477d9073), stress 40619145840. lovish: "Allow 512x256" atlas; dive numbers "OK as proposed" (90 s cooldown, 60 dmg in 4.5 blocks, 0.8 knockback, 10 s grounded, early take-off after 4 s, 16-block range).
- **Itachi split (Oct 28 ~02:10Z):** Itachi 2 took over #131 (head 2c1878e1: T2 4.5/s + 75 s refit, random metal spread, extra metal scales patch count, reach-floor rule 0.6 meanwhile; 240-map report: robustness drops, 22 redraws, 4v4 build 7.4 s) and opened #299 (bombard dead-zone diagnostics, dc8ce213, stress 40619021723). Itachi 1 (chat 14) stood down on seeing that; its work is in claude/handoff-itachi1-oct27-late.md: possession f6533896, pile fix fcbd30cf (15/15 green), #294. lovish on #131 metal: "design them like beyond all reason and put clumps in strategic positions all around the map including the back rear sides ... clump them, have stranded ones alone. Maybe a path or cluster." -> BAR-style placement, not uniform random. Relay via lovish paste (pane in use by lovish on chat 16).
- **Knockback cap / artillery vs flyer:** 4 stress runs dispatched; draft PRs after results.

## Command Center Xerath, Oct 28 (took over at ~02:40Z from coordinator-3; session id local_fde47261)

- All 8 working sessions told to report to Xerath (local_fde47261; first messages wrongly said local_1c03e1b4, corrected).
- Merge and #203 force-push OKs re-asked in this session (pending).
- **keep-units-selected:** claude/far-selection 053e7d46, no PR yet. Cause: vanilla tracks entities only within ~view distance of the player entity, but the RTS camera slides the player back along the view ray, so own units on screen are never sent. Fix: TrackedEntityMixin + FogOfWarServerEvents.tracksAcrossLoadedSquare (own/allied units tracked across the loaded square), plus a HUD-focus flap that wiped pending left-click orders. Test own_units_stay_tracked_across_the_loaded_square. Red 40613786472, fix x8 40613901674, neighbours 40613942341. Its FogOfWarServerEvents edit is in sharesVisionWith (not save paths); #198 overlap noted.
- **#120:** e1045d28 (main 80770aac, tests be80d603, fix e1045d28 for findings 1/3/4). Delta review round 2 running. Stress 40620610547 (4 tests x 8); 40619255673 superseded.
- **Stale pile:** #216 ce039990 waits on #297 merge then rerun; #169 d07f149e and #177 eb87af2b CI pending; #257 diagnostic 2a88c60b, stress 40619185376; #198 77c54445 rerun of ac1_shift_queued_build_order... pending.
- **#297:** 5f09f7c5; red 40611300957 and greens still queued at ~02:45Z.
- **Obsidian:** OmniRoute's Obsidian tools have no API token (Settings > Context Sources); vault read from D:\Claude Vault directly. Librarian last ran Oct 24; 5 inbox notes unfiled.
- **lovish design (Oct 28 ~02:50Z):** infantry should be able to destroy buildings (revises the Oct 22 raid-roles rule). The "vehicle" slot is per-faction themed, not modern machines: e.g. a mythological light wielder on a cloud, mobile ents that root into the ground and attack like a lurker; tanks fit the AI faction. Vault inbox note 20261028-0250. Open questions: how much infantry building damage; design doc vs prototype first. Merge/#203 OKs still not answered in this session.
- **lovish OKs in Xerath (Oct 28):** "Yes, merge each PR on Mode A PASS on its exact head + green CI + gate done PASS (the stale pile, tonight's drafts, #295, #203). Yes, force-push #203's author rewrite if git diff old new is empty."
- **Runners ~02:26Z:** 0 runs in progress, 56 queued (oldest 00:41Z); builds were finishing until 02:22Z; githubstatus Actions operational. Watching; nothing cancelled.
- **#120 round 2 PASS** at e1045d28 (posted issuecomment-6459000843). Needs main re-merge (main 1223baba, 10 ahead) + merge-resolution delta, body line (watchers incl. CREATIVE ops stay SPECTATOR on Backspace), CI, stress 40620610547.
- **Itachi 2 (paste, ~02:35Z):** #131 BAR-style metal rework in progress (clumps of 2-4 incl. rear sides, lone stranded patches, route paths; home metal standardized), nothing pushed. T2 site-search red test claude/flake-t2-site-search 2f1f8abe (T2SiteSearchGameTests), stress 40617582276 queued; fix waits on #203. #295 42bf85a1: 72d14b66 was red (snapshot also wrote survival data, null difficulty -> NPE at first autosave, shards 8+9); fixed by leaving survival out; CI pending. #299 dc8ce213 stress 40619021723 queued.
- **#120 round 3 (merge-resolution 8cc4aa7d, main cb64eae3) PASS**, posted issuecomment-6459042819. Waits on CI + stress 40620610547 (on e1045d28, same branch, counts for M20), then gate + merge.
- **Main ruff red:** tools/human_kit.py F401 (on_plate, slab, lathe, _add, _mul) from 9bbb60cf (Sunforged bodies); prepush fails for every session. Card proposed: task_f5fd772d.
- **Runners:** back at 02:32Z (3 runs in progress, 52 queued).
- Paste blocks written for lovish: Itachi 2 (four tasks, don't merge, hand PRs back) and Itachi 1 (resume: possession-on-ground f6533896 PR, pile fcbd30cf PR, #294 1 CI failure).
- **Merged outside the gate by Itachi 1 (on lovish's direct order in chat 14):** #199 cfd4cda, #267 1223bab, #121 826b2c9, #105 cb64eae; command-center #1 b879d59. **#120 merged early as e6d69b3a (02:53Z)** by Itachi 1's waiter before its stress 40620610547 and gate; head 8cc4aa7d had 13/13 green as a draft and Mode A rounds 1-3 PASS. Main CI on e6d69b3a pending; Itachi 1 reverts if red.
- **#301** pile flake (Itachi 1, claude/flake-pile-spreads f20658d5, main merged): Mode A running. **#169** Mode A PASS (Error Prone trial; body "Not for merge", own advice "do not adopt as-is"; lovish to decide close vs trimmed). **#198** Mode A PASS 77c54445; stale-pile-1 asked to fix ArenaRetirement findings 1-2 test-first + merge main, then delta.
- **Artillery set-up flakes on main (#222 area):** possessed_artillery_driven_by_a_client_needs_two_seconds_to_set_up (#203 CI) and a_crew_hopped_after_a_faked_sprint_jump_must_set_up_again (#294 CI 40614747627, "fired 35 ticks ... needs 40"). Sent to knockback-cap session. New cross-branch flake: ac1_shift_queued_build_order_at_the_ghosts_centre_runs_after_the_move (#198, #216). #114 superseded by #121 (suggest close). Itachi 1: possession-on-ground f6533896 waits on runners; overlaps knockback-cap in PossessionServer.
- **Merged (Xerath):** #302 main ruff fix (a80d4b8a; gate PASS after adding the OK line to its body).
- **Reviews (Xerath):** #297 round 3 PASS 817fe5b4 (timeouts only; new red 40626316291 / green 40626296048). #301 PASS f20658d5. #198 round 2 PASS 6cc8db82. #257 round 2 PASS 99e9aafe. #169 closed, #114 closed (lovish).
- **Itachi 2:** #295 CI green 42bf85a1, stress 40626428525. #131 BAR-style metal bf307b31 (7 standard home patches 48-72 out, contested clumps of 3, clumps/paths/strays; 240-map report: 4v4 seat fairness up, redraws 22->17, max build 5.57->3.33 s). Open lovish question: home metal set. Itachi 1: #294 stress re-dispatched on full SHA (40628382926/85030/87257/89476).
- **PC:** BAR lag = memory pressure (90% committed, spring paging); archived ruff-fix and spike-gpu sessions. Janitor protects spring.
- **Hand-over:** Xerath -> Command Center Vertos (note: side-session-notes/local_1c03e1b4.../coordinator-handover-2026-10-28-0350-xerath.md).

## Command Center Vertos, Oct 28 (took over at ~03:50Z from Xerath; session id local_d19c1449-6b3d-46bc-9122-c5bff6ce18ea)

- All 8 working sessions told to report to Vertos (local_d19c1449) and to cancel nothing, not even their own superseded runs.
- **lovish OKs in Vertos (Oct 28 ~03:55Z):** "Yes to both": merge each PR on Mode A PASS on its exact head + green CI + gate done PASS (stale pile, tonight's drafts, #295, #203), and force-push #203's author rewrite if git diff old new is empty.
- **lovish design answers (Oct 28 ~03:55Z):** #131 home metal = standard 7 patches (48-72 out, none within 40 of a start; Itachi 2's current bf307b31 build). Infantry vs buildings = real damage (infantry can kill buildings, slower than vehicles). Faction-themed vehicles = design doc first.
- **Runners ~03:55Z:** 6 jobs running, 43 runs queued. Nearly every pending run (#297 #298 #296 #198 #257 #120 #295 #294 #145/#300 keep-units-selected T2) is still queued.
- **#301** CI 40621815134 red on ruff only: main's old F401s (gen_architect, gen_cleric, gen_dawn_paladin), fixed on main by #302. Needs a main merge (8 behind) and a fresh CI; Itachi 1's branch.
- **#300** head is now 85450f49 (was 3805a1c4).
- **#295 Mode A PASS** 42bf85a1 (opus; 0 blocking, 5 non-blocking), posted issuecomment-6460275420. Waits on stress 40626428525 (title "flake-stress claude/save-hitch", queued), then gate + merge.
- **#300 Mode A FAIL** 85450f49 (sonnet), posted issuecomment-6460273431. Blocking: the dive cooldown and grounded state are not saved (lost on unload or reload). Sent to the bone dragon session (local_cb4ba178): fix test-first, tighten the tests, re-stress on the new head (40619145840 was on an older sha).
- **#298:** red 40613134748 8/8 FAIL as expected; green 40613231322 8/8 pass. CI 40617687211 red only in bar-tests (8) on two artillery tests from main (a_crew_hopped_by_keyless_client_claims_must_set_up_again, a_crew_hopped_after_a_keys_run_must_set_up_again). Main cb64eae3 failed only on ruff, so these are the artillery set-up flake family. Reran the failed jobs (attempt 2). Sent all four artillery set-up reds to the knockback-cap session (local_305001b6) as top priority.
- **#177** (stale-pile-1): CI 40615604556 green on attempt 2; stress 40627300155 pending; Mode A (opus) running. The gate hook first blocked the review on a stale gen-009 "running" row from Oct 22 (usage/ledger-2026-10-22.md:85, hand-typed, no id); Vertos closed it as closed-stale with a note. Needs a merge-only main commit before landing.
- **Vehicle design doc:** lovish chose "do it here"; an opus subagent is writing it into the vault.
- **#145 Mode A PASS** 16fccee0 (opus; 0 blocking, 6 non-blocking), posted issuecomment-6460300257. Art PR: merge only after lovish looks at it in game. bar-audit pending.
- **#177 Mode A PASS** eb87af2b (opus; 0 blocking, 5 non-blocking), posted issuecomment-6460315667. stale-pile-1 pushes a merge-only main commit after stress 40627300155 lands.
- **#131 Mode A PASS** bf307b31 (opus; 0 blocking, 5 non-blocking), posted issuecomment-6460329637. Main one: the 7 home patches lovish chose are not guaranteed (GenEconomy.java:833-859 drops a clump per seat when no spot fits; MetalClumpsTest.java:275 accepts any equal count >= 2). Also triangle tips reach ~81.5 blocks vs the 72 in docs; an invalid best draw can be returned; generation runs on the server thread (up to 3.3 s at 4v4). bar jobs pending, ruff red = main's old F401s (needs a main merge). Paste block for Itachi 2 given to lovish.
- **Artillery set-up reds:** the knockback-cap session (local_305001b6) found 3 of 4 likely share one cause: PossessionServer.attack spends the 68-tick cooldown even when BombardCrewUnit.fireShell refuses a shot inside MIN_RANGE (6 blocks), and lookTarget can pick a neighbouring test's unit. A real player bug too. Go-ahead given: red test first on claude/fix-possessed-artillery-refused-shot. The sprint-jump red goes to Itachi 1's f6533896.
- **Vehicle design doc** written: D:\Claude Vault\10 Projects\Beyond and Tabs\vehicles-design-2026-10-28.md. Recommended first prototype: the Verdant Rooted Treant (rework of the Sentinel Treant). lovish answered: Brassworks keeps steam machines now, a futuristic faction gets real tanks later; a separate vehicle lab per faction; infantry break buildings half as fast as vehicles (PR #146 numbers stay). Open: Q4 low flyers vs walls, Q5 root/uproot time.
- **BAR lag (~04:15Z):** CPU (spring ~1.3 of 20 cores) and GPU (26%) are fine; spring has run 6 h with 14.4 GB private, 7.4 GB resident; page faults ~1000/s but mostly soft (page reads ~0-47/s). Advised lovish to restart BAR between games. Archived "Code handoff task" (local_f15f9de9) with lovish's OK. Available RAM went from 6.7 to 11.4 GB, commit from 53.3 to 47.8 GB. The old coordinators were NOT archived: their archive cascades to live no-PR owners (keep-units-selected, knockback-cap).
- **Vehicle labs (lovish ~04:35Z: "shouldnt we also give itachi 2 the building designs"):** given to Itachi 2 by paste block: a per-faction vehicle lab design (design/ doc in a draft PR, lovish approves), Verdant first, then build. Queued after its #131 fix and the breathing flicker. rooted-treant session does not build labs.
- **#300 round 2** (delta 85450f49..7338a3c8) and **#145 round 2** (16fccee0..4d09bdb8) delta reviews running. Red-proof 40629941619 (7fd616d9), green 40630155473 (7338a3c8).
- **#198** 6cc8db82: CI 40625072588 GREEN on attempt 3 (attempts 1-2 red only on ac1). Waits on stress 40624316761 + 40625082579, then gate + merge. ac1 A/B stress (main a80d4b8a 40631553527 vs 6cc8db82 40631555986, 4 runners each) by ac1-ghostclick-flake (local_5a40eb97); code read says #198 cannot change ac1's shard or neighbours. Itachi 1 owns the ac1 fix.
- **#300** round 2 PASS 7338a3c8, then round 3 PASS 133e8227 (posted). Shard-1 crash in PR build 40630152099 was the dive tests' nested runAfterDelay; rewritten as everyTick state machines; groundBelow cliff/fluid refusals; #145 merged in. Old stress 40629941619/40630155473 void. Red proof 40632544091 (d779daa6, claude/dragon-dive-redproof), green 40632576441 (133e8227).
- **#145** round 2 PASS 4d09bdb8 (posted). Art: lovish looks in game first.
- **#203** round 2 PASS ad552d7d (opus, posted issuecomment-6460808170). Rewrite list: 8c5538a1, c433f3d2, 2a015c98, 01c59fae, 6f7b1e28, b88b337b. Stress 40633166390 + 40633200705 (report only). Notes: siteOk chunk loads can hitch match start; building guard at pad height only.
- **#305** Rooted Treant prototype (rooted-treant local_29ae0278): draft; red 40632544836, green 40632836151 queued. Needs Mode A.
- **Buildings (lovish):** vehicle labs -> buildings-design session (local_0aa9bb40); capitols + metal extractors -> designed in Vertos ("we can do the capital and metal extractor here"), opus subagent writing D:\Claude Vault\10 Projects\Beyond and Tabs\capitols-extractors-design-2026-10-28.md. Both told to build on existing art: design/buildings/*.png, building_preview_*.png, building_detail.md, buildings.json, REFERENCES.md, tools/capitol_*.py, and lovish's D:\Downloads\buildings_evening.png, extractors_now.png, moving-buildings.png. Itachi 2 builds from the docs after lovish approves.
- **lovish:** "you can use stronger agents and models if needed" (Fable for the hardest work).
