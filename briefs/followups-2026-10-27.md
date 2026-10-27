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
| 1 | Merge Joisco's **#276** | game repo | main cannot open any world since #248 ("Channels [reignofnether:main] rejected their server side version number"). Verified in a real client by merging it locally. |
| 2 | Merge **#273** (claude/flake-roots) | game repo | fixes `elder_druid_is_a_t2_worker` on main (stale test after #253) plus the fog-snapshot block-entity bug. Report: `briefs/flake-roots-2026-10-27-REPORT.md`. Design note: if the Elder Druid should keep Awaken Thicket, the fix goes the other way. |
| 3 | Merge **#274** (mode-a gate workflow), then apply `guards/github/protection.json` | game repo | Mode A PASS on e090f687 (round 2). Test the app_id on one throwaway PR first (guards/github/README.md). main is still unprotected. |
| 4 | Nightly jobs | Task Scheduler | stay off (D046); D037 suspended until lovish says otherwise. |

## Game repo work (needs a session in `D:\BeyondAndTabs-Repo`)

| # | What | Blocked by |
|---|---|---|
| 5 | CI eyes harness stalls on Supplementaries' WelcomeMessageScreen at step 0 (last green 03:46Z, run 40445996646). Fix belongs in `EyesDirector.java`. | PR #176 owns that file |
| 6 | Add a parade scene to the eyes harness (living army). | #176 merged |
| 7 | Bring the Bone Dragon into the living army. | #145 merged |
| 8 | Local `prepush.sh` fails on three pre-existing main issues: check_java "Argument list too long" on Windows; animation lab data; SHARD_8 entry `test:men` names no test (#253 deleted the mending tests; needs a `.github/workflows/build.yml` edit and the gh `workflow` scope). | none |
| 9 | Intermittent COMMON_SETUP crash: `ResourceCostConfigEntry.getWood() is null` (bar-tests (5), job 122075675704, run 40469588386). | sent to the Desktop session "1" on Oct 27 evening, branch `claude/fix-resource-cost-npe` |
| 10 | Hero AI v2 PR 1 (#275): five feel questions for lovish in `briefs/hero-ai-v2-pr1-2026-10-27-REPORT.md`; GREEN_RUN / STRESS_LINE placeholders still unfilled in that report. | lovish plays the Paladin |
| 11 | GPU units: in-client proof of path C under Oculus + Complementary before round 3 (smooth skin). | about a day of spike work, then lovish's eyes |

## PC / Command Center

| # | What | Status |
|---|---|---|
| 12 | The "lovish" desktop shortcut was said to launch the empty `BeyondAndTabs` instance. | checked: it already launches `BeyondAndTabs(1)` through `D:\BeyondAndTabs-Server\Play Beyond and Tabs.bat` (D045) |
| 13 | Gate-hook blocked reviewer agents on branches with commits under 2h old. | DONE on `cc/gen014-guards-and-reports`: M17, `-Reviewer` / brief line `ROLE: reviewer`; selftest 44/44 |
| 14 | Private repo `main` (origin) and the public mirror (`public`) have unrelated histories; M16 (branch-check own-gen comments) is only on the public side. | asked: which remote gets `cc/gen014-guards-and-reports` |
