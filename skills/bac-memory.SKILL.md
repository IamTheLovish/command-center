---
name: "bac-memory"
description: "RETIRED 2026-10-27 (decision D039). Do not use. Shared project memory now lives in D:\\Command Center (knowledge loop + decisions.md); see the command-center skill."
---

# bac-memory - RETIRED

Retired by decision D039 (2026-10-27 00:24): the folder this skill pointed at does not exist, and it named an old repo
that now redirects to IamTheLovish/Beyond-and-Tabs.

Use instead:
- **Start of session:** the command-center skill boot (`cc.ps1 boot`), which reads the newest handoff, `knowledge\RULES.md`
  and `model-routing.md`, then `kb.ps1 recall` per task.
- **Decisions:** `D:\Command Center\knowledge\decisions.md` (D-numbers, lovish's exact words and time).
- **Lessons:** `ledger-close -Learn` -> `kb.ps1 learn` -> `knowledge\entries.jsonl` (promoted to RULES.md after 3 confirmations).
- **End of session:** the handoff (COMMANDER.md section 4) and vault-capture notes.

Kept as a stub so older briefs that name it fail loudly instead of silently using a dead path.
