---
title: Lessons carried forward
type: system
---
# Lessons carried forward

Every Command Center generation reads this file at boot and merges what it learned at handoff. Condense rather than append. One line per lesson, prefixed with the gen that learned it. [tristin] = adopted from Tristin's Roblox Command Center (~60 generations), Oct 21; full list in `D:\Command Center\references\skill-pack-lessons-oct21.md` section 10.

## Directing
- [gen-000] Protect the commander's context: delegate big reads and keep only conclusions.
- [gen-000] Give every agent a definition of done. Vague briefs are the main cause of redos.
- [gen-001] Brief agents to return findings in their final reply (with a word cap); subagents can't write report files, so the commander writes them.
- [tristin] Ask lovish only about design/feel, art approval, money/publishing and things only he can do. Decide operations yourself and mention them in one line; batch any questions into one numbered list.
- [tristin] A design theory is a hypothesis: build ONE hero in game, get lovish's OK, then roll out.
- [tristin] Long voice notes or idea dumps go into a numbered notes file first; brief agents from the file.
- [tristin] Keep skills small: a short core plus references/ files, and brief agents to read only their lane's file. Check skill sizes at boot.

## Verifying
- [tristin] An agent's "done" is not done. Before telling lovish something is fixed or polished, check it in game: every angle, against the reference, where he plays. List what's unverified and label what was actually done to each item.
- [tristin] Look or mood changes: numbered before/after from the same fixed camera BEFORE merging.
- [tristin] Before publishing an artifact, syntax-check its script and load it once.

## Usage
- [gen-000] Log every assignment in the ledger, including failures. A ledger with gaps makes the auditor blind. Create today's ledger file at boot (gen-001 forgot).
- [tristin] Once a method is scripted, roll it out on sonnet (haiku if mechanical). Opus/fable only write new recipes and critique; opus roll-out agents cost Tristin ~$780 in 2 days.
- [tristin] Resume the SAME builder for each design round instead of a fresh agent. Rotate long iteration agents at ~350-500k tokens.

## Safety on the PC
- [tristin] Stop processes by their own PID, never by image name (an agent killed every python on the PC, MCP servers included).
- [tristin] Only one Blender job at a time: a FIFO queue file, not a plain lock (a lock starved one agent for 25-40 min).

## Project-specific (Beyond and Tabs)
- [gen-000] Read the north star first. When the goal changes, re-rank the work list before doing the next item.
- [tristin] Animation work follows the `bat-animation-study` skill: reference -> phase table -> calibrate -> recipe -> three-row review sheet (live / study / reference).
- [gen-005] Real matches never set a world border, so anything gated on isRtsOptimisedMap() was OFF in play (rtsPathfinding). Check gates against what a real match does.
- [gen-005] With a shader pack, Oculus re-fires RenderLevelStage events in the shadow pass: every overlay handler must return on ShaderPacks.skipOverlays().
- [gen-005] GitHub Free = 20 concurrent jobs per ACCOUNT (all repos share it); a free org adds its own 20. Copying code to another repo from a session is blocked - let a workflow with a scoped token do it.
- [gen-005] Browser pane: preview_start can reuse the current tab - use tabs_create for a second page when the first holds a filled form.
- [gen-004] lovish refines designs in bursts (6+ messages in 5 min): redirect the running agent with SendMessage and say which earlier instruction each message replaces.
- [gen-004] Overlapping balance work: one owner per file/topic (converter rate -> T2 agent, converter HP -> raid agent), and tell both.
- [gen-004] Before assigning a branch, check no other session is still pushing to it (a report agent's commits were dropped).
- [gen-004] Cost reference: a Sonnet feature-PR agent ~215-275k tokens. lovish: up to six Sonnet agents at once.
- [gen-005] The container can restart and kill background agents: agents commit + push WIP after every step (a branch without a PR starts no CI).
- [gen-007] TESTS FIRST (lovish, Oct 22 19:58): test written and shown red on main before implementing; no special-casing, no weakened tests.
- [gen-007] Check engine constraints before offering lovish numbers (dimension min_y/height are multiples of 16).
- [gen-007] Texture rounds need a numeric gate (plain Laplacian <= main per material) before review; between rounds run the DEBRIEF LOOP (lovish, Oct 22): critic writes good/off lists, critic + strategist bounce ideas until an agreed plan, then one builder runs the next round. 2 same-gate misses with a plan = change method. Full steps in model-routing.md notes.
- [gen-007] Every visual feature gets a frame budget measured on CI with and without shaders (silhouettes r3 target <= 3%).
- [gen-007] Release a lane claim only after MERGED. Never pkill -f (it matched and killed its own shell): pidfile or pgrep -x.
- [gen-007] Verify /improve auditor claims before planning (2 rejected in the first run). Run architecture-deepening Mode A before every merge.
- [auditor 10-22] HARD RULE (REPEAT x2): before assigning ANY branch or plan, check last commit time, last PR comment, open PRs by plan number, and the ledger tail. Parallel commanders are allowed only with disjoint lanes written in their boot ledger row (e.g. "gen-010: art queue only #160/#165/#162"); never take a branch outside your lane.
- [auditor 10-22] Nothing merges before the commander's Mode A review (#172 merged unreviewed): executors open PRs, they never merge.
- [auditor 10-22] Check the brief's premise in code before launching (plan 005 aggro premise and the T2 "energy is cheap" premise each caused a redo chain).
- [gen-011] flake-stress jobs finish green even when tests fail: read the summary job's "[Stress]" annotation for per-test pass/fail (graveyard_l3 failed 2/10 under an all-green run).
- [auditor 10-22b] Before any art round, read lovish's latest decision on those materials in the ledger tail. Once he approves a change of method (e.g. CC0 scans), run no more rounds of the old method on those materials unless he asks.
- [auditor 10-22b] Heavy agents (opus/fable xhigh) are capped at 2 per ACCOUNT. Parallel commanders on one account split the cap and write their heavy count and owned PR numbers in their boot ledger row; a PR owned elsewhere is off-limits.
- [auditor 10-26] Workflow edits need the gh `workflow` scope, and PR state is checked live with gh, never copied from notes. ENFORCED by `cc.ps1 gate start -EditsWorkflows` / `-Pr N`.
- [gen-011] Idle runners: flake-stress on main (10 runners) for every test merged that day is a cheap, read-only use; it found the graveyard flake behind lovish's stuck-units report.