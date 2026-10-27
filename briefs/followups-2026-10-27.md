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
