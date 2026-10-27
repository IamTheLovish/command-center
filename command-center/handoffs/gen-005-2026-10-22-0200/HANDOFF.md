# Gen 005 - Oct 22 2026, 02:00 ET (account B, Beyond and Tabs Lane A) - CHECKPOINT (session still running)

## Owner's asks tonight (lovish)
- 01:14 "the game joisco and I played was very laggy" -> 01:15 "low fps I think" -> 01:17 "can we improve this in every facet without hurting quality at all"
- 01:28-01:41 CI capped at 20 runners -> made a free org ILovishThe (+ mirror repo ILovishThe/beyond-and-tabs-ci, Claude app, secret CI_MIRROR_TOKEN on the game repo)
- 01:50 RTS pathfinder "should also be on big maps"
- 01:52 sessions MAY MERGE their own PRs automatically when green; give lovish a dev log; anything disliked gets reverted
- 01:53 "cycling through the 40 runners as well as possible ... better and better each time"
- 01:54 "create a tool or plugin to help automate this"; 01:55 "upload memories and development into the vault or the command center"

## Diagnosis (evidence)
- Server (D:\BeyondAndTabs-Server\logs): 12x "Can't keep up", up to 25 s behind 00:51-00:56. PerfAuto 00:49: ~490 entities, 74% tick budget.
  tinker 12.9%, mortar crawler 8.3%, zombie villager 7.2%, behemoth 5.3% (one find_path 108 ms), chunkSource 13%, bat:buildings 5%.
  ROOT: rtsPathfinding gamerule only auto-on when world border <= 1280; matches never set a border -> vanilla A* (1024 nodes, ~100 getChunk per path).
- Client (D:\Downloads\BeyondAndTabs-Test\instances\BeyondAndTabs(1)): 27-39 ms frames with Complementary. Oculus SHADOW PASS re-fires render stages:
  our overlays drew into the shadow map = 23% of frame. after_translucent main pass still 23% (13.6% unlabelled). hud 6.9%.
  [FrameAuto] said EMPTY PROFILE every time: parser regex expected "name(n/m)- x%" (real: "(n/m) - x%").

## PRs (status at 02:00)
- #117 perf render loops (old) - merged main in, idle rings frustum-culled. CI queued.
- #142 overlays skip shadow pass + parser fix. CI queued.
- #144 CI gradle cache + history once. CI queued.
- #147 CI mirror + load router (tools/ci_route.py, ci_mirror_send.sh), merge_pr.py, dev log issue #150. Labelled ci-mirror (self-test).
- #149 RTS pathfinder in every battlefield match (ArenaPathing, prewarm 6 ms/tick, GameTest server excluded).
- perf-pathing (agent building): vanilla-mode path fixes - Unit block-update repath cancel, cheap melee canContinueToUse, ranged/building repath throttle, behemoth double repath, distance-scaled node budget with fallback, classify memo.

## Next
1. As each PR goes green: `python3 tools/merge_pr.py N --note "..."` (after #147 merges; until then gh api merge + dev log comment by hand).
2. Merge order: #144 -> #147 (rebase on #144: both edit build.yml) -> #142, #117, #149, perf-pathing.
3. Chunk/entity overhead agent result -> PR 7.
4. Client: label un-instrumented after_translucent handlers (13.6% unspecified), HUD 6.9% (Lane C area - post #35 first).
5. Post on #35: mirror/router/merge_pr rules for all sessions.

## Update 03:45 ET (overnight)
MERGED (dev log #150): #142 shadow pass, #117 render loops, #149 RTS pathfinder in every arena, #153 pathfinding
fixes, #154 worldgen CME fix, #152 server ticking, #155 frame sections, #144 faster CI. #147 (40-runner router,
token-free mirror, merge_pr.py) merged main + resolved build.yml, merge queued (label ci-here: stale ci-mirror status
on an old sha is ignored by merge_pr once bar ran here).
- Mirror is TOKEN-FREE: ILovishThe/beyond-and-tabs-ci/.github/workflows/mirror-tests.yml polls every 5 min for PRs
  whose head has status ci-mirror "Queued for the mirror", checks the PR out of the public game repo, runs build +
  all shards. Proven: run 39733236954 green (attempt 2). Secret CI_MIRROR_TOKEN is unused (lovish may delete it).
- Setting a commit status by hand is blocked as a CI bypass - only the reporter workflow may set ci-mirror.
- Next: randomTickSpeed audit (report only); after lovish's next match read [Paths], [ArenaPathing], [FrameParts]
  (new sections buildingParts/buildingDecor/bars/worldFx/worldMarkers) and fix the heaviest client handler.

## Update 04:15 ET - queue empty
#147 MERGED (40 runners live on main; merge_pr.py + bat-ship skill are the merge path). 9 PRs merged overnight, all on #150.
Rules posted on #35. Claims released. randomTickSpeed audit: Project doc claude/random-tick-speed-audit-2026-10-22.md
(recommend 3 + own timers for 3 mod blocks; lovish decides).
Next session: after lovish + Joisco's next match, read the server [Paths]/[ArenaPathing]/[Tick] lines and the client
[FrameParts] (new sections) and fix the heaviest measured cost; if asset-download timeouts recur after the Gradle
cache, add a retry around downloadAssets in tools/ci_gametests.sh.
