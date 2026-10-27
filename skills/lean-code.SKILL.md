---
name: "lean-code"
description: "Use automatically whenever writing, changing or reviewing code (own work or an agent's PR): tests first, reuse before adding, smallest correct diff, delete before abstracting, plus a review/audit checklist."
---

# Lean code - the smallest change that is fully right

Our own take on "write less code" (inspired by the Ponytail idea; nothing copied). Less code means fewer bugs, faster CI, cheaper reviews and less context for the next session. Never at the cost of correctness, tests or quality.

## Tests first (lovish's standing rule, Oct 22 19:58)
"write the tests first and then implement it so you dont cheat and write bad code, which is something I dislike alot"
1. Write the test from the requirement (lovish's words, the bug report, the plan) BEFORE the implementation: a GameTest for gameplay/server behaviour, JUnit for pure logic, a metric gate + named stills for visuals.
2. Show it fails on the current code (a red CI run, a local JUnit run, or the failure line quoted in the PR). A test that already passes proves nothing about the fix.
3. Then implement the real behaviour until it passes. Commit order: test first (or the red evidence in the PR body).
4. Never cheat: no special-casing code for the test (test-only flags, checking for the test's world/positions, hard-coded expected values), no weakening/skipping/deleting a test, no moving it to known_flakes to get green. If the test is wrong, fix the test in its own commit and say why.
5. Characterisation first for refactors: lock current behaviour with tests before moving code.

## Before writing
1. **Find what exists.** Search the repo for the helper, pattern or system that already does most of it (`git grep -n` on the concept, the class names, the log tag). Extend it; don't build a parallel one. Example: effects extend barfx/, not a new particle system.
2. **Find the one place.** Fix at the root (the rule, the default, the shared function), not at every caller.
3. **Check the constraints first** (engine limits, licence, lane ownership, claims) so the design isn't redone later. Example: dimension min_y/height must be multiples of 16.

## While writing
- Smallest diff that fully solves it. No drive-by refactors in the same PR.
- Delete before you add: remove dead paths, old toggles, code the change makes unreachable.
- No new abstraction until there are 3 real uses. A small duplicated block beats a premature framework.
- Data over code when values will be tuned (JSON/config, one constants block), so balancing doesn't need a rebuild.
- One rule, one place: constants and thresholds in one spot with a comment saying why.
- Comments say why and cite the evidence (lovish's words + time, a measured number, a run id), not what the code does.
- Tests: one focused test for the behaviour that broke or is new, written first (above); fix the cause instead of loosening an assertion or deleting a test.
- Performance-sensitive paths: measure before and after (profiler section, bench); skip work in passes that don't need it (e.g. the shader shadow pass).

## Review / audit checklist (agent PRs and your own)
Run through this before merging; report only failures.
1. Does it solve the stated problem at the root? Evidence (log, test, still) attached?
2. Was the test written first and seen failing? Does the code special-case the test or weaken any assertion?
3. Could it reuse existing code instead? Any parallel system created?
4. Diff size proportionate? Unrelated changes split out?
5. Dead code, unused imports, leftover debug output, TODOs without an owner?
6. Defaults changed? (Player-visible default changes must be stated in the PR for lovish.)
7. Client vs server: client-only code never runs on the server; multiplayer/desync-safe; fog of war respected.
8. Shader packs: anything drawn per entity skips the shadow pass unless it must cast shadows.
9. Cost: per-frame / per-tick work bounded (caps, culling, batching); measured if hot.
10. Tests: new behaviour covered; known-flake list not used to hide a real failure.
11. Licence/originals: no copied assets or incompatible code; ported code credited.
12. Fail loud: no silent fallbacks, catch-alls or placeholder data. A fallback is disclosed in the PR; an undisclosed `catch (Exception e) {}` or default value hiding a failure is a finding (from Joisco's pack, Oct 27).

## Done table (before saying "done")
One row per requirement and per end-to-end check: item | pass / fail / not checked | evidence (test + result, command + output line, still path) | **ran after the last edit?** A test that exists but didn't run is "not checked". Then two rows that are usually empty and shouldn't be: **glossed over** (warnings, flaky runs, odd output you noticed and didn't act on) and **deferred** (what, and where it is recorded). Any fail, not checked or "no" = not done; say so plainly. For PRs this table goes in the report next to `cc.ps1 gate done` (from Joisco's pack, Oct 27).

## Debt log
When you notice debt you aren't fixing now, add one line to the session's handoff "Next" list (what, where, why it matters) instead of fixing it in an unrelated PR.