# Gen 006 - Oct 22 2026, 14:20 ET (account B, Beyond and Tabs Lane A: performance + CI)

Read first: Project doc claude/north-star-2026-10-21.md, AGENTS.md + design/LANES.md, newest #35 comments, dev log #150,
this file, then gen-005 (overnight detail) in this folder's sibling.
Repo access: add_repo IamTheLovish/Beyond-and-Tabs (push). REST only (GraphQL blocked). The org mirror
ILovishThe/beyond-and-tabs-ci is attached too when needed (add_repo ILovishThe/beyond-and-tabs-ci).

## What lovish asked (Oct 22)
- 01:14-01:17: MP match with Joisco "very laggy", "low fps" -> "improve this in every facet without hurting quality".
- 01:28-01:53: more CI runners -> free org ILovishThe; "cycle through the 40 runners as well as possible".
- 01:50: RTS pathfinder "should also be on big maps".
- 01:52: sessions MAY MERGE their own PRs when green; dev log; disliked PRs get reverted.
- 01:55-02:08: memories + development into the Command Center and the Obsidian vault; build the knowledge loop;
  "improve these systems whenever you see fit".
- 02:22: "keep working ... I expect to see some good progress tomorrow". 13:26: yes to the mirror watcher.

## Shipped (all merged, all on dev log #150)
| PR | What |
|---|---|
| #142 | Overlays skip the Oculus shadow pass (~23% of a frame); [FrameAuto] parser fixed (EMPTY PROFILE) |
| #117 | Per-frame overlay loops frustum-culled (+ idle rings) |
| #149 | RTS pathfinder in EVERY battlefield arena (ArenaPathing; prewarm 6 ms/tick; GameTest server excluded) |
| #153 | Vanilla-mode pathing: no block-update repath for units, cheap melee canContinueToUse, shooter keepPath, one repath loop for building attackers, distance-scaled search + fallback, classify memo, [Paths] counters |
| #154 | Worldgen CME fix (BaseWildlifeControl.inBase off-thread -> capitol snapshot) |
| #152 | No server ticker for campfires/blast furnaces; unit despawn check skipped; pickup every 2nd tick; frost lookup lazy |
| #155 | Frame sections: buildingParts, buildingDecor, bars, worldFx, worldMarkers |
| #144 | CI: Gradle cache in every job; history counted once |
| #147 | 40 runners: tools/ci_route.py routes PR GameTests to the less busy pool; token-free mirror; tools/merge_pr.py |
| #156 | Mirror watcher (60 s scans, always-on poll job in the org repo); reporter/router read once with GH_TOKEN |
| #157 | Shard artifacts per attempt (a green flake rerun no longer fails bar-audit); tidewrought_t2_units_attack -> known_flakes |

## How CI works now (tell other sessions; posted on #35)
- Push once when done; `python3 tools/merge_pr.py N --wait --note "what, why, what to check in game"` merges only when
  every check + `ci-mirror` is green, mergeable, not draft, no `hold` label; logs on #150. Skill: bat-ship.
- Labels: `ci-mirror` (force org pool), `ci-here` (force this repo), `hold` (no auto-merge).
- Mirror = ILovishThe/beyond-and-tabs-ci/.github/workflows/mirror-tests.yml (lives ONLY there; edit it by cloning that
  repo). It reads PRs from the public game repo. No secrets anywhere; CI_MIRROR_TOKEN is unused (lovish may delete it).
- Setting a commit status by hand is blocked (CI bypass). Only ci-mirror-report.yml sets `ci-mirror`.

## Not measured yet - the real test
Nothing above has been played. lovish + Joisco's next match is the check. Then read:
- server log (D:\BeyondAndTabs-Server\logs): [ArenaPathing] at match start, [Paths], [Tick]/[Sys], "Can't keep up" count;
- client log (D:\Downloads\BeyondAndTabs-Test\instances\BeyondAndTabs(1)\minecraft\logs): [FrameParts] with the new
  sections, [FrameAuto] (now parses). Fix the heaviest measured cost next.

## Open decisions for lovish
1. randomTickSpeed 12 -> 3 (biggest server lever left). Audit: Project doc claude/random-tick-speed-audit-2026-10-22.md.
   Recommend 3 + own timers for wraith-snow particles, soul-fire conversion, magma smoke. Farms unaffected.

## Next (ranked)
1. After the next match: measure (above), fix the top cost.
2. Client: HUD 6.9% of the frame - Lane C area (post #35 before touching hud/).
3. randomTickSpeed per lovish's answer.
4. Knowledge loop: a separate session builds command-center/BRIEF-knowledge-loop-2026-10-22.md (not started).
5. Watch: asset-download timeouts in CI (3 on Oct 22) should stop with the Gradle cache; if not, retry downloadAssets
   in tools/ci_gametests.sh. tidewrought_t2_units_attack + other known flakes need real fixes eventually.
