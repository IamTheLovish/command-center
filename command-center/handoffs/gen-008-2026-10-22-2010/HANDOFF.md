# Gen 008 - Oct 22 2026, 20:10 ET (continues gen-007 from the same session at 67% context)

Read first: gen-007 HANDOFF + SELF-DIAGNOSIS (sibling folder), Project doc claude/plans/INDEX.md (the /improve backlog),
north-star, AGENTS.md + design/LANES.md (NEW standing rule: TESTS FIRST, lovish 19:58 - write the test, show it red on
main, then implement; no special-casing, no weakened tests). Repo access: add_repo IamTheLovish/Beyond-and-Tabs (push) and
ILovishThe/beyond-and-tabs-ci (push, for mirror annotations).

## Since gen-007 (merged, dev log #150)
- #166 flaky tests (4 off known_flakes, bots skip canopies, merge tools read mirror failures/reruns)
- #167 graveyard "too full": levelled graveyards banked every unit as a skull -> units walk out unless at the army cap,
  autoRelease default on, GameTests per level
- #168 LANES rule: tests first. (#161, #163, #164 were in gen-007.)
- Server restarted 19:05 on a8bf003 (floor y48 live). Server address changes each restart (friend-address.txt).

## New skills saved by lovish (all auto-trigger)
lean-session (upgraded), lean-code (tests first + review checklist; an update adding tests-first was PROPOSED again -
check it's saved), brief-sharpener (same), architecture-deepening (Mode A = strict thermo-nuclear review before EVERY
merge; Mode B = survey), grill-design, improve (audit -> plans -> cheap executors). Credits: mattpocock/skills,
cursor/plugins thermos, shadcn/improve (all MIT).

## In flight - check first (branches survive this session)
1. PR #170 Ruff (tools lint, 0 bugs, 45 dead locals) - merge waiter running; if not merged, `python3 tools/merge_pr.py 170 --wait`.
2. Plan 002 Error Prone trial - branch claude/errorprone-trial (draft PR): read warning report, decide adopt or not.
3. Plan 003 security (sandbox escalation via faction NONE, per-player placement validation, teleport, custom button) -
   branch claude/improve-003-sandbox-security; tests first; review with architecture-deepening Mode A, then merge.
4. Plan 004 server I18n crash - branch claude/improve-004-server-i18n; same.
5. Silhouettes r3 - PR #165 (claude/canopy-silhouettes): r2 visuals good, soft fade good, COST too high (+8% shaders,
   +38% plain at ~45 covered units on CI); r3 target <= 3% frame. Then fresh review, then lovish.
6. VFX foundation - draft PR #162 (claude/vfx-foundation): build green; eyes run 39873260211 was in progress. Needs stills
   + fresh review.
7. Block textures - draft PR #160 (claude/block-pack-r24, r26 head 0eea1a8). Fresh review r26: ship planks/gravel/bark
   (~7/10); hold stone/dirt/grass/basalt (~5/10, plateau). Stills /home/claude/art/r26/ (container - may be gone).

## Waiting on lovish (ask once, numbered)
1. Ship planks + gravel + bark now (split them out of #160)?
2. Use CC0 photo scans (ambientCG / Poly Haven) for stone/dirt/grass instead of procedural?
3. Per-position grass tint noise in code (field macro variation)?
4. RTK trial in one cloud session (read source first)?
5. Stuck units: which units / when / where / does a new order free them (server healthy: 3 ms ticks, pathfinder on).

## Next (ranked, from claude/plans/INDEX.md)
005 mount loop + neutral aggro perf (S) -> 008 JUnit for core logic (economy, placement, levels, merge grid, grid
neighbours, multi-select, map layout, PopulationRules) -> 006 enemy scan -> 007 minimap tick -> 009 split
SkirmishGameTests. Then from gen-007: animation weight (hit-frame markers, hit-stop, easing, transitions, additive
layers), tree realism, atmosphere.
