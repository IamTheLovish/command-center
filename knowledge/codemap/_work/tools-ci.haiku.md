## Purpose
CI and tooling for the mod: build/test workflows, GameTest sharding and routing, and generators for art, sounds, and modpack/installer publishing. Scripts under tools/ (python and sh) plus .github/workflows/*.yml.

## Key classes
- `tools/gen_lobby_art.py` (~4110 lines) [OVER 1000] - lobby art generator (name-based)
- `tools/gen_structures.py` (~2900 lines) [OVER 1000] - structure generator (name-based)
- `tools/gen_blocks.py` (~2679 lines) [OVER 1000] - realistic block texture pack generator (name-based)
- `tools/gen_hd_skins.py` (~1998 lines) [OVER 1000] - HD unit skin generator (name-based)
- `tools/gen_storm_skins.py` (~1385 lines) [OVER 1000] - skin generator (name-based)
- `tools/lobby_depth.py` (~1351 lines) [OVER 1000] - lobby depth tool (name-based)
- `tools/gothic_parts.py` (~1227 lines) [OVER 1000] - gothic model parts generator (name-based)
- `tools/gen_trees.py` (~1191 lines) [OVER 1000] - tree generator (name-based)
- `tools/gen_verdant_skins.py` (~1159 lines) [OVER 1000] - skin generator (name-based)
- `tools/gen_sfx.py` (~1155 lines) [OVER 1000] - sound effects generator (name-based)
- `tools/materials.py` (~1149 lines) [OVER 1000] - unit material calibration (name-based)
- `tools/gen_paladin.py` (~1146 lines) [OVER 1000] - paladin unit generator (name-based)
- `tools/gen_brass_skins.py` (~1115 lines) [OVER 1000] - skin generator (name-based)
- `tools/gen_models.py` (~1073 lines) [OVER 1000] - model generator (name-based)
- `tools/gen_tide_skins.py` (~1046 lines) [OVER 1000] - skin generator (name-based)
- `tools/gen_t2t3_skins.py` (~1032 lines) [OVER 1000] - tier 2/3 skin generator (name-based)
- `tools/dsl_to_game.py` (~994 lines) - DSL-to-game converter (name-based)
- `tools/ci_plan.py` (lines not in dossier) - decides matrix and code/docs routing for the build.yml `changes` job
- `tools/ci_wait.py` (lines not in dossier) - waits on CI for a commit/PR, reruns known flakes once
- `tools/check_shards.py` (lines not in dossier) - static check of SHARD_n lists in build.yml
- `tools/check_server_client_imports.py` (lines not in dossier) - static guard against client imports in server code
- `tools/check_guards.py` (lines not in dossier) - camera-key and SkirmishGameTests growth guards
- `tools/ci_route.py` (lines not in dossier) - routes GameTests to here or the mirror by load
- `tools/prepush.sh` (lines not in dossier) - local mirror of build.yml fast checks
- `tools/claim.py` (lines not in dossier) - work-claim tool using issue #91 comments

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