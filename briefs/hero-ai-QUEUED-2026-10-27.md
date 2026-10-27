---
title: Hero AI - queued for Oct 27 (saved by gen-013, acct B, Oct 26 22:05 ET)
type: brief
status: queued
---
# Hero AI - pick up tomorrow

lovish (Oct 26 22:05): "save all this down for tomorrow, tonight I have a special task for you".
Start tomorrow with: "Command Center, resume" -> then this file.

## LOVISH ANSWERS (00:21 Oct 27) - knowledge\decisions.md D030-D031
- Flee vs orders (question A): a near-death hero MAY flee on its own at first. Once the player selects or commands it again, the player's order wins. FLEE can override an order, but a fresh player command clears FLEE until the next new danger. Tests: flee_starts_without_order, reselect_and_move_overrides_flee.
- Auto-spend (question F): pick the best option automatically (score from the hero's personality and current fight data). It can be turned off, and the player can always pick manually ("both"). Toggle on the hero panel; default on.

## RESEARCH DONE (gen-013, Oct 26)
Project doc `claude/hero-ai-research-2026-10-26.md` (16 sources). Recommendation:
- HFSM on top: OBEY / ESCORT / FIGHT / FLEE.
- Utility scoring inside FIGHT; v1's bestTarget is already a utility function, so v2 is a refactor.
- Lanchester power ratio with hysteresis 1.2/0.8.
- Reaction queue of 250+-100 ms.
- OrderLock is checked first.
- Personality is data, so it can be tuned.
- Harness rides on #133.
- Parry gets its own PR with a 400-600 ms telegraph and a ~200 ms window.
Start tomorrow from that doc; skip a second research pass.

## CORRECTION (gen-013, 22:40, verified with gh)
#224 (hero AI v1) and #223 (winning pays) were MERGED 2026-10-26 19:50 UTC. #221 and #222 are still OPEN. 44 PRs are open in all.
So: PR 1 below is not "#224 rebased". It is a new branch extending the merged HeroBot brain. Item 17 (one brain) is now a rewrite of the merged code.
The harness (item 9) should ride on #133 (nightly bot ladder, OPEN: bot-vs-bot matrix, [Sim] lines). Merge #133 first rather than building a second harness.
Auto-spend: hero_mode.md 5b says skill points "stay manual"; lovish now says optional auto-spend. It spends ability points (playtest_oct20_lane_c #7/#29). Open: random pick vs fixed build order, and default off/on.
Parry/block: 0 hits in the Java. It is a brand-new mechanic.

## State found at boot (Oct 26)
- Command Center booted as gen-013 (newest handoff: gen-012-2026-10-23-2050). Boot NOT finished:
  - auditor/advice/2026-10-22-2238-b.md is still `status: unread` (5 items: method-change rule, heavy cap per ACCOUNT + PR ownership in boot row, GameTest fixes opus xhigh + 10-run stress, off-load chores via api\offload.ps1, ledger fields). Apply at next boot.
  - auditor/CHANGES-APPLIED.md has 9 Unannounced lines - announce to lovish at next boot.
  - No usage/ledger-2026-10-26.md was created (no work done).
- Hero AI PR already exists: #224, branch claude/hero-ai, NOT merged, CI not reported as of Oct 24. Claim `hero-ai` on #91. Commits 26a07699 (tests first, HeroAiGameTests, 6 tests) and d0295e9f (HeroBot brain, `hero_ai` client config + HUD checkbox, HeroAction.HERO_AI_ON/OFF packet, docs). Notes: C:\Users\<user>\AppData\Local\Claude-Data\claude_pzs8sxrjxfjjc\side-session-notes\local_02d36c00-7748-4659-afd5-51f986a5e118\hero-ai.md
- Windows gotchas: clone path > 260 chars -> `git -c core.longpaths=true`; run Python tools from a short `git worktree add --detach $TEMP/hw HEAD` with a python3 shim. Python: C:/Users/chris/AppData/Local/Programs/Python/Python312/python.exe
- gh on PowerShell: --jq/--template with `\(...)` or `"\n"` break quoting; use `--json ... | ConvertFrom-Json` instead.
- Priority order (Oct 24): finish open PRs (#221, #222, #223), then hero AI, building art, possession, siege spec, balance last.
- Next steps: (1) check #224 CI + last commit/comment (branch-check HARD RULE); (2) research pass first (lovish asked: research before designing; use project docs hero-kit-2026-10-21.md, direland-hero-reference, animation-standard, north-star); (3) extend #224 in reviewable PRs; (4) loop + measure with the harness; hand off at ~40-50% context.

## lovish's answers already given
1. As smart as possible. 2. Yes, optional auto-spend. 3. Escape by any means with any tool it has - even "I need to kill this guy before I run or he shoots me before I get far". 4. Settings go on the hero panel (not HUD settings). Bot heroes use the same brain (approved).

## Full requirements (lovish, Oct 24-26, his words kept where possible)
Original: "Id allow for heros to be complex ai's that use their abilities and act extremely smart when there is no hero player this can be a toggle players can set if they dont want this option".
Rules: plain hand-coded, no AI services, no Claude at runtime, cheap per tick (decide ~1/s, existing spatial grids, no full-map scans). Tests first; never merge without lovish's OK; one brief per PR with file:line pointers; cheaper models for small work.

Core + extras:
1. Combos: stun/slow then damage; gap-closer only when follow-up is ready.
2. Fight reading: army strength (HP x damage both sides) -> engage/hold/disengage; never chase into towers or a bigger army.
3. Threat focus: healers, artillery, low-HP heroes, units hitting our hero; finish kills.
4. Dodge and kite: ranged keep max range; step out of visible AoE / artillery shells.
5. Protect the army: heals/shields to allies about to die; pull back to army when low.
6. Commander guard: defend own commander; punish an exposed enemy commander (big wreck + XP burst after #223).
7. Personalities per kit (tank, assassin, support, caster) + shared core.
8. Debug overlay / log line: what it decided and why.
9. MEASURING HARNESS (most important of round 2): GameTest AI-vs-AI and AI-vs-no-AI standard fights; log win rate, damage, deaths, ability counts.
10. Fog-of-war fairness: only what the owner can see; no peeking at hidden units or enemy cooldowns.
11. Team play: no double stuns, staggered heals, converge on one focus target.
12. Behaviour setting per player: Defensive / Balanced / Aggressive (engage/retreat thresholds).
13. Human-like: short reaction delay, slight imperfection.
14. OBEY RTS ORDERS (core): player move/attack/hold/retreat always wins; AI only casts while executing and takes over when idle; never leaves a move order to chase; hold = cast only from where it stands; on possession release, continue what the player was doing. Tests: "move order not overridden", "hold position respected".
15. Prediction: lead skillshots/AoE (velocity x travel time); read incoming fights (grouping, visible cooldowns).
16. Speed limit: per-tick budget for all hero AI; distant/idle heroes decide less often; 16 heroes in 8v8 add no lag; log budget hits.
17. One brain: bot heroes use the new rules; replace HeroBot's old casting logic.
18. Use abilities to kite or play aggressively; correct spacing through fights; detect being surrounded/overpowered.
19. Stay next to the units the RTS player is selecting.
20. Not drag-selectable: like workers, other units get priority in drag-select; select the hero by clicking it directly or when it's alone.
21. Block strikes and maneuver like a seasoned warrior.
22. Build on unit animations for fluidity; interactive human-like animations; "extremely amazing effects" per hero (follow bat-animation-study / bat-art-director skills).
23. Research the topic before designing; use any tool and stored info.
24. Loop over and over until as good as possible; switch session automatically when it gets too big.
Tests on: combo order, retreat threshold, target pick, no chase under towers, move order not overridden, hold respected.
First PR: shared core + 2-3 heroes; rest as follow-ups.

## Roadmap (PR body + design/hero_mode.md, don't build yet)
1. Offline self-tuning on CI (like tools/BalanceTune). 2. Learn from lovish's possessed play. 3. Callouts ("Paladin retreating - low HP"). 4. Saved per-hero preferences.
Standing rule to add in design/hero_mode.md: "Hero AI: keep improving" - any session touching heroes, bots or playtest feedback looks for a hero-AI improvement and makes it or lists it.

## Quick review (gen-013, Oct 26) - conflicts to settle and how to split the work
Defaults below are the commander's proposal; ask lovish only the items marked ASK (batch them in one list).

Conflicts / gaps:
- A. Escape-by-any-means (#3) vs obey RTS orders (#14). Default: player orders still win; under an order the AI may cast defensive/escape abilities in place but never walks off the order. ASK: should a near-death hero break a hold/attack order to flee?
- B. Not drag-selectable (#20) vs obeying orders (#14): the hero will rarely get group orders, so "stay next to selected units" (#19) becomes its default idle job. Clicking the hero directly (or when it stands alone) selects it normally.
- C. "As smart as possible" vs human-like imperfection (#13). Default: imperfection scales with the behaviour setting / bot difficulty; the harness measures with imperfection both on and off.
- D. Blocking (#21): check whether the combat code has a block or parry at all. If not, it is a new mechanic (timing window, animation, effects, balance), so give it its own PR after the brain.
- E. Animations/effects (#22): art lane with its own skills (bat-animation-study, bat-art-director) and reviewers. Keep it out of the AI PRs, and give each hero its own polish PR.
- F. Auto-spend: ASK what it spends (hero XP/skill points? resources?) and its default (off).
- G. Settings location: #224 put the toggle in HUD settings; lovish wants the hero panel. Move it, and put behaviour (#12) and auto-spend next to it.
- H. Fog fairness (#10) vs reading cooldowns (#15): only cooldowns of casts the owner actually saw.
- I. Stop rule for "loop until as good as possible": stop when 3 rounds in a row raise harness win rate by less than ~2 points, then lovish playtests. Each round = one measured change.
- J. Priority: on Oct 24 #221/#222/#223 came first. Check they are merged before starting.

PR split (each one reviewable, tests first):
1. #224 rebased: core brain + orders-obey + harness + debug line + budget + one brain (HeroBot). Tests: move not overridden, hold respected, retreat threshold, target pick, no tower chase, combo order.
2. Fight reading, threat focus, team play, fog fairness, prediction, spacing/surround detection, escape logic.
3. Selection: worker-style drag priority, stay near the selected units, hero panel settings (toggle, behaviour, auto-spend).
4. Personalities: 2-3 heroes first (tank, assassin, support/caster), the rest as follow-ups.
5. Blocking/maneuvering mechanic (if new).
6+. Per-hero animation and effects polish (art lane).
Research pass before PR 2 (sonnet medium survey: BAR/SC2/Dota bot behaviour-tree and utility-AI patterns, kiting, focus fire, retreat logic; plus project docs hero-kit, direland-hero-reference, animation-standard). Routing: core brain + harness = opus xhigh (max 2 heavy agents); selection/UI = sonnet high; research = sonnet medium.
