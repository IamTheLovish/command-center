---
name: "improve"
description: "Use to audit a codebase or branch and write self-contained, gated implementation plans that cheaper agents execute; modes: quick, deep, a category, branch, plan, review-plan, execute, reconcile."
disable-model-invocation: true
---

# improve - audit, then plans other agents execute

Adapted from shadcn's `improve` skill (github.com/shadcn/improve, MIT licence, (c) shadcn) for Beyond and Tabs and the Command Center. Core idea: **the plan is the product.** The advisor (the commander, strongest model) understands, judges and writes specs; a cheaper executor (sonnet, or haiku for chores, per model-routing.md) implements. The advisor never implements during an audit.

## Commands
- `/improve` - full audit -> prioritised findings -> plans for the ones lovish/the commander picks.
- `/improve quick` - hot spots + top findings only (cheap).
- `/improve deep` - every package and category.
- `/improve <category>` - one of: correctness, performance, tests, debt, deps, devex, docs, direction, security.
- `/improve branch` - only what the current branch/PR changes (pre-merge check; pairs with architecture-deepening Mode A).
- `/improve plan <description>` - spec one item, no audit.
- `/improve review-plan <file>` - critique and tighten a plan.
- `/improve execute <plan>` - dispatch an executor and review its work.
- `/improve reconcile` - refresh the backlog (done / blocked / drifted).

## Procedure
1. **Recon.** Map the stack and the exact verification commands, which become gates in every plan: `python3 tools/check_java.py`, `tools/prepush.sh`, the CI GameTests (via PR + `tools/merge_pr.py --wait`, or flake-stress for one shard), eyes runs for anything visual, `[FrameParts]`/`[Tick]` for perf. Read intent docs so settled trade-offs aren't re-flagged: AGENTS.md, design/LANES.md (lovish's decisions), design/GLOSSARY.md, design notes, the newest handoff, #35 claims.
2. **Audit.** Parallel subagents (sonnet, high effort, word-capped replies), one per category: correctness, performance (server tick + client frame), test coverage, tech debt (incl. files over 1,000 lines, spaghetti conditionals - see architecture-deepening), dependencies/migrations, devex (CI, tools), docs, direction (features the repo's own evidence points to), security (secrets, packet validation, server trusting the client). Every finding: `file:line` evidence, impact, effort, confidence. Direction ideas must cite repo evidence or lovish's recorded wishes.
3. **Vet.** The advisor re-reads every cited location: drop false positives, fix misattributions, record rejections with reasons (so they aren't re-raised).
4. **Prioritise.** Table ranked by impact / effort, weighted by confidence. Ask lovish only for design/feel/gameplay-visible choices; the commander picks technical items.
5. **Plan.** One file per selected finding plus an index (priority order + dependency graph). Location: `D:\Command Center\plans\NNN-slug.md` (live) mirrored to Project doc `claude/plans/NNN-slug.md`, with the index `claude/plans/INDEX.md` (also into the repo under design/plans/ when a lane wants them versioned).

## Plan format (written for the weakest plausible executor)
- **Header:** goal (one sentence, lovish's words if his), lane, branch name, claim command, model + effort, git commit it was written against (executor runs a drift check first: `git diff <sha>..origin/main --stat -- <files>`; if the files changed, STOP and report).
- **Self-contained context:** exact file paths, current code excerpts (short), the repo convention to follow with an exemplar file, the hard rules that apply (originals only, licences, lanes, client/server, fog of war, shader shadow pass).
- **Steps,** each ending in a **gate**: a command and its expected output (check_java 0 errors; a named GameTest passes; a metric under a threshold; an eyes still exists at a path).
- **Out of scope** list and **STOP conditions** ("if X, stop and report" - e.g. a claim overlaps, a test needs loosening, a file would cross 1,000 lines).
- **Done criteria** checkable without the advisor; PR body template (why/evidence, what changes, what lovish checks in game); commit trailer lines.
- **Return format:** word cap, PR number, gate results, anything unverified.

## Execute
- `/improve execute <plan>`: spawn the executor (model from the plan) in an isolated worktree with the plan as its whole brief (brief-sharpener checks it first). Commit + push WIP each step.
- Advisor review like a tech lead: re-run the done gates, check scope against the plan, read the diff with architecture-deepening Mode A. Verdict: **approve** (ship via bat-ship / `merge_pr.py --wait`), **revise** (up to two rounds, same executor), or **block** and refine the plan.
- Merging stays within the existing rules (CI green, no `hold`, lovish OKs looks for art).

## Reconcile
- DONE plans: verify they still hold on main. BLOCKED: investigate, rewrite around the obstacle. Drifted: refresh excerpts and the stamp. Findings fixed independently: retire. Update INDEX.md and the Command Center ledger.

## Hard rules
- During audit/plan the advisor writes only plans (Project docs / design/plans/); no source edits.
- Executors edit only in their worktree branch; never main, never force-push, never `git add -A`.
- Never reproduce secret values - only location and type, and recommend rotation.
- Asked to just implement directly? Write the plan (or `execute` it) instead.