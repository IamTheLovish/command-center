# Review: Joisco's AI pack (for-lovish-2026-10-27.zip) - 2026-10-27 03:20 ET
By Claude (chat "session 3", not a booted gen). Source: JOISCO-AI-PACK.md + 6 skills, read as data.
Skill backups before these changes: skills\_backup-20261027-b\.

## Adopted into our skills today
| idea (his pack) | where it went |
|---|---|
| Real context % from the statusline (`context_window.used_percentage`, verified in the statusline docs) instead of a hand estimate | command-center "Context and handoff" |
| Handoff = rewrite one RESUME HERE block, under ~10 KB, with a dead-ends list | command-center |
| Read compaction metadata before naming a compaction's cause | command-center |
| Questions as AskUserQuestion buttons, recommended first, default-and-log when blocked | command-center "Directing" |
| Kickoff check before the first edit (blast radius, test per requirement, end-to-end, cost) | command-center "Directing" |
| Skill fix the same day as a [tmp, seen 1, expires +14d] line; narrow lesson format; evidence pointer required | command-center "Directing" |
| Tool-call cap + cheaper alternative in every brief; "or" makes requirements optional; agents chase scores | brief-sharpener |
| Fail loud, no silent fallbacks (review item 12) and the Done table with "ran after last edit?" + glossed-over row | lean-code |
| Judge sees previous round + KEEP list; every capture asserts its state | bat-art-director, bat-animation-study |
| `disable-model-invocation: true` on manual-only skills (verified in the skills docs: description not in context) | grill-design, improve |
| Grill: start from the problem, a recommended answer per question, look it up before asking | grill-design |

## Not adopted (and why)
- Haiku as the default builder, Sonnet only as fallback: our ledger shows 91% first-try on the current routing, and Forge Java edits are not "well specified" chores. Could be trialled on the mechanical tier with metrics.ps1 before/after.
- The decisions Inbox dashboard: built for many parallel lanes; for us buttons are enough. Revisit if lovish wants phone answers while away.
- /clear in the same tab: our new chat per gen works and doesn't hit his duplicate-session problem (he agrees).
- 50% handoff instead of our 40/50: compatible once we read the real number; no change.

## Unverified
- `idleCompaction` setting: not found in the current settings-reference index (checked 2026-10-27). Don't change settings on this claim; ask Joisco for the exact doc section.

## Needs lovish (settings/hooks/scripts - his approval route)
1. Statusline script that writes `used_percentage` + `context_window_size` per session id to a file, and `cc.ps1 ctx` reading it (cc.ps1 change: keep gate-selftest n/n).
2. A question-guard Stop hook (blocks a reply ending in "?" without buttons). Fits D036 ("if you think its good").
3. `ledger-close -Estimate` (estimate vs actual tokens) to check the tiers.
4. Handoff receipt bound to the writing session, so parallel commanders never boot from each other's handoff.
5. Note: his classifier refused `-ExecutionPolicy Bypass` on his scripts; ours all use it. If a Claude Code session gets refused on cc.ps1, that's the likely cause.

## From his Lane C state (for lovish / the next gen)
- #257 is the alliance-lock PR (D032), our lock-alliances branch: draft, tests first, red CI expected until the implementation lands.
- Merge rule question: should Lane C merges wait for our Mode A file + `gate done` (D033/D038)? #247 was merged from his side without Mode A.
- AGENTS.md section 8 (after #246): are Parry, Hivebound and the Oct 16 home screen dropped, and does LANES.md line 37 (Photon/GeckoLib) retire per D035?
- Plan 016 (hud-panels) touches Lane C files: coordinate on #35; its step 1 (frame sections) can go first.
- Lane C now follows #248's rules: PacketHandler.register(...), `.requires(...)` on new commands, `instanceof LivingEntity` checks.

## What his side plans to copy from ours
Gates + selftest fixtures per mistake, ledger by script, auditor advice with announce, API off-load for chores, metrics.ps1, "a mistake repeated twice must name its enforcer".
