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
