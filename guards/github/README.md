# GitHub merge gate (lovish applies; sessions can't: workflow scope + branch protection are owner actions)
Why: the PC gates are scripts a session can forget, and merges also happen from Joisco's side (#247 merged without
Mode A). A required GitHub check stops EVERY merge path until a Mode A review covers the PR's latest commit (D040).

## Switch it on (once)
1. Give gh the workflow scope: `gh auth refresh -h github.com -s workflow`
2. Add the workflow on its own branch and PR (it also tests the gate on itself):
   ```
   cd D:\BeyondAndTabs-Repo
   git fetch origin; git switch -c guards/mode-a-gate origin/main
   copy "D:\Command Center\guards\github\mode-a-gate.yml" .github\workflows\mode-a-gate.yml
   git add .github/workflows/mode-a-gate.yml; git commit -m "CI: mode-a required review gate (D040)"
   git push -u origin guards/mode-a-gate
   gh pr create --fill
   ```
   Merge that PR (the gate isn't required yet, so it can merge).
3. Make it required on main (repo owner only):
   ```
   gh api -X PUT repos/IamTheLovish/beyond-and-tabs/branches/main/protection --input "D:\Command Center\guards\github\protection.json"
   ```
   main has NO branch protection today (checked Oct 27 03:30). protection.json requires only "mode-a" (CI green is
   still enforced by merge_pr.py; making path-filtered CI jobs required can wedge merges). It also blocks force pushes
   and deleting main. enforce_admins is false, so you can still override in an emergency.

## How a review passes it
The reviewer (never the builder) posts the Mode A file as a PR comment:
`gh pr comment N -R IamTheLovish/beyond-and-tabs -F "D:\Command Center\reviews\pr-N-modeA.md"`
It needs the lines `VERDICT: PASS` (or BLOCK), `REVIEWER: ...` and `SHA: <head sha>`, the same format `cc.ps1 gate done` reads. A new push resets it.

## Off switch
Remove "mode-a" from required checks: GitHub > Settings > Branches > main > edit, or re-run step 3 with it removed.
