# Codemap: tools-ci
sha: bbbdac21 (bbbdac211d7d355181c00da37dc416b82fa04ff9)   date: 2026-10-27   source: dossier of bar/ at that sha + traps from review/plans/lessons/AGENTS
drift: `git -C D:\btr diff bbbdac21..origin/main --stat -- tools .github/workflows`

## Purpose
CI and tooling for the mod: build/test workflows, GameTest sharding and routing, and generators for art, sounds, and modpack/installer publishing. Scripts under tools/ (python and sh) plus .github/workflows/*.yml.

## Key classes
- `.github/workflows/build.yml` (401) - CI: build/changes/bar/bar-tests (SHARD_n matrix)/bar-audit/bar-publish; SHARD_2..8 lists at top
- `.github/workflows/eyes.yml` (554) - Xvfb client tour + stills/video to eyes branches; `eyes-approve.yml` (35) copies baselines
- `.github/workflows/flake-stress.yml` (134) - N reruns of tests on main; read the [Stress] annotation, job is always green
- `.github/workflows/ci-mirror.yml` (21), `ci-mirror-report.yml` - second runner pool, label-triggered
- `tools/ci_plan.py` (91) - decides what a run must test (docs-only skips GameTests); `ci_route.py` (81), `ci_shard_env.py` (40)
- `tools/ci_wait.py` (251) - one-shot CI waiter; reruns once if all failures are in known_flakes.txt
- `tools/check_shards.py` (91), `check_guards.py` (101), `check_java.py` (57), `check_server_client_imports.py` (85) - prepush gates
- `tools/prepush.sh` (36) - local mirror of fast CI checks (~35 s); `claim.py` (156) - lane claims on issue #91; `merge_pr.py` (135)
- `tools/known_flakes.txt` (7) - 4 flakes at this sha: bots_play_each_other..., bots_reach_tier_2..., artillery_fires_over_a_wall..., attack_move_stops_to_fight...
- `tools/gametest_audit.py` (102), `gametest_timing.py` (79), `eyes_diff.py` (120), `junit_summary.py` (51), `triage_log.py` (80)
- Generators (gen_*.py, up to 4,110 lines: gen_lobby_art, gen_structures, gen_blocks, gen_hd_skins) are art tools, not CI; never hand-edit their outputs

## Entry points and events
- build.yml: triggers on push to main, pull_request, workflow_dispatch; concurrency groups per PR and for main
- ci-mirror.yml: on pull_request labeled (`ci-mirror`), queues the mirror
- ci-mirror-report.yml: scheduled every 5 minutes, syncs mirror results to commit statuses
- modpack.yml / publish-pack.yml: modpack build and publish; publish-pack runs after successful build of main (workflow_run)
- No tick handlers, packets, or commands seen in this area.

## Server vs client
- Not applicable to this area: tools/ and workflows run on CI or dev machines, not in the game.
- check_server_client_imports.py enforces that server-side classes do not import net.minecraft.client.* (static check).

## Data flow
- ci_plan.py, ci_route.py, and ci_wait.py are invoked by build.yml and related workflows.
- check_shards.py reads the SHARD_n lines in build.yml and @GameTest methods in the sources.
- check_guards.py reads SkirmishGameTests.java and compares it against the base branch.
- IMPORTS / IMPORTED BY lines are not in the dossier, so cross-area links are unknown (?).

## Instrumentation and tests
- none seen (no FrameParts/Sys ids or GameTest classes in the dossier for this area; known_flakes.txt lists GameTest names for CI rerun only)

## TRAPS (source tag in brackets: REV overnight-review, LES lessons.md, AGM AGENTS.md, P0xx plans, RUL RULES.md)
- CI is the compiler/test runner (no local MC classpath); run bash tools/prepush.sh (~35 s) before every push (AGM s4).
- CI red ~half of main builds (18 of 36, Oct 23-26) from flaky tests; auto-rerun only works while a session watches (REV headline 3).
- Shards: 8 via SHARD_n lines in build.yml; adding one = a new line; check_shards.py in prepush (AGM s4).
- GitHub Free = 20 concurrent jobs per ACCOUNT; two builds fit at once (LES gen-005, AGM s4).
- PC gh login lacks the workflow scope: workflow-file pushes are refused (REV decision 0).
- Copying code to another repo from a session is blocked; use a workflow with a scoped token (LES gen-005, RUL M007).
- GraphQL is blocked in cloud sessions: gh REST only; 2 concurrent git network ops (AGM s6).
- Never git add -A / add .; push to main denied by .claude/settings.json; claim before starting (tools/claim.py) (AGM s2, s6).
- ci_wait reruns once only when every failed test is in known_flakes.txt (AGM s4).
