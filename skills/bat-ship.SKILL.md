---
name: "bat-ship"
description: "Ship a Beyond and Tabs PR end to end: check, push once, route CI across both 20-runner pools, wait, auto-merge when green, log it in the dev log."
---

# Ship a PR (Beyond and Tabs)

lovish (Oct 22 2026): sessions may merge their own PRs when CI is green; every merge is logged on the dev log issue #150 and anything he dislikes gets reverted. CI has 40 hosted runners: 20 on IamTheLovish, 20 on the org ILovishThe (mirror repo ILovishThe/beyond-and-tabs-ci).

## Steps
0. **Gate** first: `cc.ps1 gate start -Task "..." -Branch <b> [-Pr N] [-EditsWorkflows]` (live PR state, branch-check, overlap, `workflow` scope, heavy cap). It prints the commit identity from AGENTS.md: commit as that identity.
1. **Claim** before writing code: `python3 tools/claim.py check <words>` then `take <slug> --lane ... --branch ... --what ...`.
2. **Check locally before pushing**: `python3 tools/check_java.py` must say 0 structural errors (CI is the compiler and capacity is scarce). Workflow edits: `python3 -c "import yaml; yaml.safe_load(open(F))"`.
3. **Push once** when the work is done (not per step), then open the PR with `gh api repos/IamTheLovish/beyond-and-tabs/pulls` (REST; GraphQL is blocked). PR body: why (evidence), what changes, what to check in game.
4. **CI routing is automatic**: build.yml's `changes` job (tools/ci_route.py) sends the PR's GameTests to whichever pool has fewer jobs waiting. Label `ci-mirror` forces the org pool, `ci-here` forces this repo. Main pushes always test here.
4b. **Review** before merge: a reviewer who is not the builder runs architecture-deepening Mode A and writes `D:\Command Center\reviews\pr-N-modeA.md` (VERDICT, REVIEWER, SHA). Then `cc.ps1 gate done -Pr N` must PASS, and the reviewer posts the file as a PR comment (`gh pr comment N -R IamTheLovish/beyond-and-tabs -F reviews\pr-N-modeA.md`): once the GitHub `mode-a` check is required (guards\github\README.md), that comment is what lets the PR merge from any side.
5. **Wait and merge in the background**: `python3 tools/merge_pr.py <N> --wait --note "<what, why, what to check in game>"` (run_in_background). It merges only when every check and the `ci-mirror` status are green, the PR is mergeable, not draft, and has no `hold` label; then it comments on #150.
6. **Red?** Read the check-run annotations, fix, push once more. A known flake is rerun once by ci_wait. A conflict: merge main into the branch, check_java, push.
7. **Several PRs ready**: merge them in one call (`merge_pr.py 142 143 144 ...`) so main's builds collapse.
8. **Tell lovish** in the chat: one line per merged PR (what it changes, what to check), with #150 as the full log.

## Merge authority (lovish, Oct 27 00:21)
- D033: keep merging green, reviewed PRs for flow. D038: the `lovish-ok` label merges a green, reviewed PR.
- Art, animation and anything players see still needs lovish's OK in game first.

## Never
- Merge a PR with the `hold` label, a red check, or a conflict.
- Push code to the mirror from a session (blocked as exfiltration); the workflow copies it with its own token.
- Force-push or push to main; `git add -A`; stash/reset over another session's work.