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
