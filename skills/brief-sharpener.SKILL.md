---
name: "brief-sharpener"
description: "Use automatically before sending any agent brief, subagent prompt, scheduled-task prompt, skill or CLAUDE.md edit: checks it against a template and the lessons that made past agents redo work."
---

# Brief sharpener - prompts that get it right the first time

A brief is the agent's whole world. Most redos come from a missing line in the brief, not from the model. Check every brief against this before sending; add a line to "Lessons" whenever a redo happens.

## Template (every brief has all of these)
1. **Goal** in one sentence, with the owner's own words and time when the goal came from him.
2. **Context it can't find itself**: what you already know, what is ruled out, file paths and line numbers, run ids, PR numbers. Point at docs; don't paste them.
3. **Constraints**: hard rules (originals only, licences, lanes/claims, don't touch X), engine limits, perf budget, multiplayer/fog-of-war safety.
4. **Tests first** (lovish's standing rule, Oct 22 19:58): the brief names the test(s) to write BEFORE implementing and requires evidence they failed on the old code; no special-casing for tests, no weakening/skipping/deleting tests.
5. **Definition of done** that is measurable: a metric with a threshold, a test that must pass, stills of named shots, a cost line under N.
6. **Process**: branch name, claim command, commit+push WIP each step, check_java/prepush, PR type (draft or not), "don't merge".
7. **Waiting**: say exactly what to wait for and how (a background waiter on run id X), or "hand back with the exact next commands" - agents otherwise stop mid-wait and report nothing new.
8. **Model and effort** stated (and never max); heavy design/art = strongest model, chores = light model.
8b. **Size and cost**: a tool-call cap sized by expected calls (split build and capture into separate runs), and one line naming the cheaper alternative considered (smaller model, a script, reuse, skip) (from Joisco's pack, Oct 27).
9. **Footer**: a "how could this be wrong?" line, `kb.ps1 recall` output under "Known pitfalls", and a required 3-line LEARN footer (worked / failed / rule).
10. **Return format**: word cap, what to include (PR number, paths, numbers, test red/green evidence, unverified items, questions for the owner), big outputs written to files.

## Quality gates by kind of work
- Art: matched BEFORE/AFTER pairs at the same cameras, plain AND shaders, a metric gate (e.g. plain Laplacian noise <= main per material, plus a mid-band structure metric so "less noise" isn't just blur), defined before the round starts, and a fresh reviewer who never saw the making.
- Performance: a before/after number from the game's own profiler section; a target (e.g. frame p50 delta <= 3%).
- Bugs: root cause with evidence (log line, parsed data) and a regression test written first that fails on the old code.
- Research: licence checked from the actual LICENSE file before reading code for porting.

## Lessons (append when a redo happens)
- Texture round judged "partly fixed" with no metric -> always give a numeric gate (Oct 22, r24).
- Removing noise by blurring passed the noise gate but read as mush -> pair every "less" gate with a "still has structure" gate (Oct 22, r25).
- Agents handed back while CI was still running -> brief says what to wait for or which exact commands to hand back (Oct 22).
- Offered y 40 for the world floor; min_y must be a multiple of 16 -> brief lists engine constraints up front (Oct 22).
- Silhouette cost was copied into each unit's draw and got worse in total -> perf briefs give the metric that includes ALL changed sections, not just the new one (Oct 22).
- Released a claim before the PR merged -> release only after MERGED (Oct 22).
- lovish dislikes code written to game tests -> tests first, seen red, then implement (Oct 22 19:58).

- Brief said a PR was unmerged from a sibling's old note; it was merged -> check PR/branch state live with gh before saving a brief (Oct 26, REPEAT x3).
- CI agent edited workflows without the gh `workflow` scope; the push was refused after the work -> `gh auth status` shows the scope before any .github/workflows brief (Oct 26).
- Assigned a branch a parallel session was still pushing to -> brief includes last commit time, last PR comment and ledger tail (Oct 23, REPEAT x2).

- A builder ran ~206 tool calls on a 150 cap -> size briefs by expected calls; build, gates and capture are separate runs (Joisco, Oct 2026).
- "Keep the normal maps OR add a trim sheet": the first was impossible, the agent dropped both -> required items are written as required, never behind "or" (Joisco, Oct 2026).
- A builder chased a technical score and the look got worse -> a metric gate is a floor that must hold, not the goal; the reviewer judges the look against the reference (Joisco, Oct 2026; pairs with our Oct 22 structure-gate lesson).

## Before sending, ask
- Could a capable stranger do this with only this text and the repo?
- Is "done" checkable without asking me?
- Are the tests named and required to fail first?
- Did I hand it my conclusion instead of the evidence? (A reviewer gets the work, not my opinion.)