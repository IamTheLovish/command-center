---
title: Model routing
type: system
---
# Model routing

The Command Center owns this file. The auditor only suggests changes to it, through `auditor/advice/`.

Rule: **start at the cheapest tier that has reliably done this kind of work before.** Move up one tier after two failed tries. Move down when the auditor shows a tier is consistently overkill.

| Assignment type | Model | Effort | Examples |
|---|---|---|---|
| Mechanical chores | haiku | low | file moves/renames, formatting, extracting lines from logs, simple lookups, ledger tallies, merge --wait / CI polling, skill or file copies, vault notes. A haiku "runner" agent or a background script, NOT commander context |
| Lint / dead-code cleanup (tools/, non-game) | haiku | medium | Ruff-style passes; commander Mode A review still required. Trial: back to sonnet medium after 2 failed tries |
| Scans and summaries | haiku → sonnet | medium | "find where X is defined", reading a long log for errors, summarizing a doc or chat, read-only skill/tool surveys, mod-source reads, token/cost research (haiku for pure listing). Exception: visual frame-by-frame catalogues stay sonnet high |
| Standard build work | sonnet | high | routine code edits, tests, config changes, docs, research write-ups, small refactors |
| Quality-critical project work | opus | xhigh | game code that must be best-in-class, animation and rendering, balance design AND balance tuning (T1/T2 gates, raids, economy numbers, bot ladder), art direction critique, architecture, integrating several agents' output |
| Hardest problems | fable | xhigh | after opus has failed twice, or for deep multi-system design where a miss is very costly |

Notes
- `xhigh` is the default for real Beyond and Tabs work (lovish's standing preference). Never use `max`.
- Mechanical chores don't need xhigh. Keep them cheap so the budget goes to the work that shows on screen.
- Review and verification agents can usually run one tier below the agent that did the work, unless the work is high-stakes.
- Art and perf iteration loops (textures, rendering, silhouettes, VFX look): freeze the metric gates in the round-1 brief (noise/Laplacian per material, frame budget <= 3%). Tier stays opus xhigh.
- **Debrief loop between rounds (lovish, Oct 22 21:1x): no texture or rendering round starts straight after the last one.**
  1. *Pause and write it out.* After each round, a critic agent (opus, looks at the numbered same-camera stills + gate numbers) writes two lists per material/feature: **what looks good (keep)** and **what looks off (with where and why)**. Evidence only, no fixes yet.
  2. *Bounce ideas.* A strategist agent (opus) reads that list and proposes how to tackle each "off" item (technique, parameters, or change of method such as CC0 scans). The critic answers each proposal: will it fix the issue, will it break a "keep" item, which gate proves it. They exchange via SendMessage; the commander only relays and watches.
  3. *Loop until a good plan.* Repeat step 2 until both agree on a numbered plan: each change tied to an observed issue, a predicted look, and the gate that checks it, with every "keep" item protected. Cap 4 exchanges; if still split, the commander picks (or asks lovish if it's an art-approval call) and writes down why.
  4. *One agent starts the next round.* Only then does ONE builder (the same resumed builder) get the agreed plan and run the round. The discussion agents stop.
  - Heavy-agent limit holds: the builder is idle during the debrief, so critic + strategist = 2 heavy agents. Log each debrief as one ledger row (`debrief rN`, tokens of both agents).
  - If two rounds in a row miss the same gate even with a debrief plan, the next debrief MUST put a change of method on the table.
- Balance briefs start with "check how the reference game (BAR) does this" before any numbers.
- Gameplay fixes that add GameTests run at opus xhigh and need a 10-run flake-stress pass before merge. Read the "[Stress]" summary annotation, not the job colour (#167 "passed first try" on opus high, then failed 2/10 under stress).

## Changelog
- 2026-10-21: initial table (gen-000 setup).
- 2026-10-22: auditor advice 2026-10-22-2238 auto-applied (lovish approved auto-apply): chores -> haiku runner; lint -> haiku medium trial; read-only scans/surveys -> sonnet medium; balance tuning explicitly opus xhigh (gen-004: 11 redirects on sonnet high); round-1 gates on art/perf loops (r24-r26 ~1.56M opus at plateau).
- 2026-10-22: lovish: debrief loop between texture/rendering rounds (critic + strategist bounce ideas until an agreed plan, then one builder runs the next round). Replaces the plain 2-round cap; method change is forced after 2 same-gate misses.
- 2026-10-26 (gen-013): auditor advice 2026-10-22-2238-b auto-applied: new GameTests/gameplay fixes -> opus xhigh + 10-run stress pass (UPGRADE).
