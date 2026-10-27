---
name: "architecture-deepening"
description: "Use automatically before merging any PR (own or an agent's) for a strict structural code-quality review, and when hot spots keep causing redos for an architecture survey; also on \"thermo-nuclear review\" or \"improve the architecture\"."
---

# Architecture deepening + thermo-nuclear code-quality review (Beyond and Tabs)

Combines and adapts two MIT-licensed skills for this repo's lanes, docs and CI:
- `improve-codebase-architecture` by Matt Pocock (github.com/mattpocock/skills, MIT licence, (c) Matt Pocock)
- `thermo-nuclear-code-quality-review` from Cursor's `thermos` plugin (github.com/cursor/plugins, MIT licence)

A deep module hides a lot of behaviour behind a small interface; a shallow one makes callers know its internals. Deep modules are easier to test, cheaper for agents to read, and safer to change.

Two modes, both switched on automatically:
- **Mode A - PR gate (every merge).** Before `merge_pr.py` on any PR with Java changes, run the strict review below on the diff. Quick when the diff is small; never skipped.
- **Mode B - survey (when needed).** When a hot spot keeps causing redos (same files in several fixes, a SELF-DIAGNOSIS miss, a mistakes-ledger REPEAT), when a file crosses 1,000 lines, or when lovish asks: survey for modules to deepen. It's a survey and a decision aid, not a big-bang refactor; every change it leads to ships as normal small PRs.

## Mode A - strict structural review (thermo-nuclear rubric)
Gather the diff (`gh api repos/<r>/pulls/<n>/files` plus the changed hunks; whole files only for small ones), then review against these standards, in order. Behavioural correctness alone is not enough to approve.

0. **Be ambitious about simplification ("code judo").** Look for the reframing that makes whole branches, helpers, modes or layers disappear. Deleting complexity beats rearranging it.
1. **The 1k-line rule.** A PR must not push a file from under 1,000 lines to over 1,000 without a strong structural reason; prefer extracting helpers/modules. Many of our files are already over - flag growth in those too.
2. **No spaghetti growth.** Ad-hoc conditionals, scattered special cases, one-off branches in unrelated flows (e.g. a faction check inside a generic unit tick) belong in a dedicated abstraction, policy, state machine or data entry.
3. **Bias toward the cleaner design** when behaviour is the same: fewer moving pieces.
4. **Direct, boring code over magic.** Flag reflection where a direct call works, generic mechanisms hiding simple assumptions, thin/identity/pass-through wrappers.
5. **Type and boundary cleanliness.** Question nullable/Optional churn, raw casts, `Object`/wildcard generics, silent fallbacks that hide unclear invariants. Prefer explicit records/enums and shared contracts (packets, configs).
6. **Canonical layer and reuse.** Feature logic leaking into shared paths (util/, MiscUtil, base classes), client code reachable from the server, duplicated helpers (a second particle/path/packet system), logic in the wrong package or lane.
7. **Orchestration and atomicity.** Related state updated half-way (server state vs client sync, building + resources), per-tick/per-frame work serialised or repeated without need. No micro-optimisation nitpicks.

Game-specific additions:
- Client vs server split, multiplayer/desync safety, fog of war never leaking hidden enemies.
- Per-frame/per-tick cost bounded (caps, culling, batching); anything drawn per entity skips the shader shadow pass unless it must cast shadows.
- Player-visible default changes stated in the PR for lovish.

Output: a few high-conviction findings in priority order - structural regressions; missed code-judo; spaghetti growth; boundary/type problems; file size; modularity; legibility. No flood of nits. Tone: direct, serious, not rude ("can we decompose this first?", "can we reuse the canonical one?").

**Write the verdict** to `D:\Command Center\reviews\pr-<N>-modeA.md` (the `gate done` check reads it):
```
VERDICT: PASS | BLOCK
REVIEWER: <name> [id:<ledger id>]
SHA: <PR head sha the review covered>
<findings, priority order>
```
The reviewer must not be the builder, and the file must be written after the head commit; a new push needs a new review. Post the same file as a PR comment so the GitHub `mode-a` check sees it.

**Presumptive blockers** (fix or justify in the PR before merging): incidental complexity a code-judo move would delete; a file pushed past 1,000 lines; ad-hoc branching tangling an existing flow; feature checks scattered across shared code; needless wrappers/casts/optionality; a duplicated helper or logic in the wrong layer. For an agent's PR, send blockers back to the same builder instead of fixing them yourself; small ones can become follow-up PRs logged in the handoff "Next".

## Mode B - architecture survey

### 1. Explore
- Focus: the area lovish or the task names; otherwise the hot spots - `git log --since=14.days --name-only --pretty=format: | sort | uniq -c | sort -rn | head -25` - plus whatever caused redos in the handoffs (SELF-DIAGNOSIS, mistakes ledger).
- Read the vocabulary first: AGENTS.md, design/LANES.md, design/GLOSSARY.md if it exists, and design docs for the area.
- Hand the walk to a subagent (it returns findings, not file dumps). It looks for friction:
  - one concept spread over many small classes or static helpers (e.g. unit state across UnitClientEvents, goals, mixins);
  - shallow interfaces that leak internals (callers poking fields, flags set from many places);
  - parallel systems doing the same job (two particle paths, two path-finders, duplicated packet types);
  - code that can't be tested in a GameTest/JUnit without the full game;
  - per-frame / per-tick work scattered so no one can budget it;
  - files over 1,000 lines and the spaghetti conditionals inside them.
- **Deletion test** for each suspect: if this module were deleted, how much would callers have to absorb? Little = shallow (merge or inline it); a lot = it earns its keep (deepen its interface instead).

### 2. Report
- Write one self-contained HTML report and publish it as an Artifact (or a Project doc for text-only), never into the repo.
- One card per candidate: files (paths), problem, proposed direction, benefits (tests, perf, agent navigability), a before/after box diagram, effort, and a strength rating: **Strong**, **Worth exploring**, **Speculative**.
- End with one top recommendation. Don't design the new interface yet.
- Flag conflicts with lovish's recorded decisions (LANES.md) instead of overriding them.

### 3. Settle the chosen candidate
- When lovish (or the lane's commander) picks one: walk constraints, dependencies, lanes/claims touched, and the deepened module's shape - its small interface first, then what moves behind it.
- Use the brief-sharpener skill for the build brief and lean-code for the change itself; split into PRs that each keep CI green and each pass Mode A.
- Record the decision where the repo keeps them: design/LANES.md for lovish's decisions (his words + time), a short design note for the architecture (why this shape, what was rejected and why) so later sessions don't reopen it.
- Add new or sharpened terms to design/GLOSSARY.md (create it if missing: term, one-line meaning, where it lives in code).

## Rules
- Never refactor across another lane's open claim; post on #35 first.
- Behaviour must not change unless the PR says so; GameTests prove it.
- Measure before/after for anything on a hot path ([FrameParts], [Tick], benches).