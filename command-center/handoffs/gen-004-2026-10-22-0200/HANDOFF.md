# Handoff - Oct 22 early (23:54 Oct 21 - 02:00 ET) - Command Center gen-004

(Filed from the chat by gen-005 at 02:05 ET; the PC was unreachable for gen-004.)
The previous handoff (Project doc claude/handoff-planning-oct21-late.md) still needs filing as gen-003, and last night's claude/vault-craft-notes-oct21.md still needs the vault inbox: both live in the Project "Beyond All Craft", not reachable from gen-005's Project.

## Start of next session
1. Read claude/north-star-2026-10-21.md, this file, then the PR list below.
2. Repo IamTheLovish/beyond-and-tabs is public. GitHub REST only (GraphQL blocked); the Actions runners API is blocked through the proxy. Shallow clone + explicit refspec fetches (`+branch:refs/remotes/origin/branch`).
3. Up to **six Sonnet agents at once** is OK (lovish, 01:08). Give each agent its own git worktree.

## lovish decisions this session (all in Project memory)
- **Nightly bot ladder on CI: yes.**
- **"Edgeline"** = edge metal sits just far enough from the wall that an extractor isn't blocked.
- **More metal in the game, to contest.** Home metal is standardized per base; extra metal is spread all over the map; **outskirts pay a bonus** (richer patches toward the edge).
- **Pacing:** slow the fighting down (units live longer), intricate abilities, build up to **massive armies**. More metal is fine. Supersedes "fewer, weightier units".
- **Tier 2 is too easy; people rush it.** Make it BAR-like: costly and slow even with 6-7 extractors. **Energy must be built up first** to supply T2 extractors (they drain energy).
- **Raids:** T1 infantry raids should **hunt workers** (killing workers sets people back), not melt buildings. **T1 vehicles kill buildings more easily.**
- **Converters are weak** (bad deal + fragile) to punish reliance. **Extractors are somewhat weak**, but not as weak as BAR's.
- **Blueprints:** nothing physical until the worker arrives; **enemies never see your blueprints**.
- Healer kits design: **on hold** (lovish 01:44).

## PRs and agents
| Work | Branch / PR | State at handoff |
|---|---|---|
| Spectator free-fly | #120 draft | CI green earlier; waiting on lovish's key call (Caps Lock?) |
| Maps M1 metal + edgeline | #122 draft, claude/maps-m1-metal | **Done part:** derived 11-block wall clearance (5x5 extractor half 2 + gap 1 + worker lane 1 + gatehouse 2 + rounding 1.5, x root 2), edge metal on by default, rim patches 292 -> 398, new MapRimGameTests, CI green at bdc2d4b. **In flight (agent):** standardized home metal, extra metal spread everywhere, outskirts yield bonus, a low/normal/high "extra metal" lobby knob (normal generous, high ~2x), no mid-map loss, side spread no worse. |
| Healer AI | #130 draft | Delivery-agnostic SupportBrain, 21 maths tests; CI was running. Review, then ready. |
| Generated maps | #131 draft (base #122) | Report done: `design/generated-maps-report.md` + 7 render sheets in `design/generated-maps/`; headless tool `tools/mapgen_sim/run.sh` (JDK only). **Last night's chat (session 01CbFRWA) is still pushing to this branch.** Rebase onto #122 only after it stops and #122's metal work lands. |
| Nightly bot ladder | claude/bot-ladder (agent) | Building: `.github/workflows/bot-ladder.yml`, cron + dispatch, matrix over 20 runners, [Sim]/[Pace]/[Stuck] lines, win-rate table artifact. Headline columns: time-to-kill, combat lifetime, casts per life, peak army and when, army value at min 10/20/30. Measurement only. |
| Tier 2 gate | claude/t2-gate (agent) | BAR-style: priced from a 6-7-extractor income; T2 at ~min 7-10 normally, no earlier than ~5 for an eco rush; energy cost + **T2 extractors drain energy** (stall when short); converter becomes a poor rate; T2 lab check re-done server-side for every faction; bots build energy before teching. |
| T1 raids | claude/t1-raids (agent) | Infantry hunts workers (lone worker 2-4 s, group of 4 8-12 s for 4-6 raiders); workers flee to the capitol/towers; worker loss must cost time; **T1 vehicles get a building-damage bonus** (windmill 5-8 s, T1 extractor 6-10 s for 3-4); **converters fragile** (+ small chain blast between adjacent converters); **T1 extractors softer** (infantry 12-18 s), T2+ ~2x; destroyed patches rebuildable at once; bots raid workers and protect their own. |
| Blueprints | claude/blueprints (agent) | Placement = order + ghost only (owner/allies); construction starts when the worker arrives; re-validate on arrival; full refund on cancel; ghosts never sent to enemies (network level); spectators see all. |

Other open PRs from before (not touched this session): #128, #125, #124, #123, #121, #119, #118, #117, #114, #111, #109, #108, #107, #106, #105, #102, #86.

## Next (in order)
1. Collect the five agents' PRs; check the CI and the numbers; land #120/#122/#130 per CI and lovish's calls; then rebase #131.
2. First nightly ladder table -> tune the T2 gate, extra-metal knob and raid numbers from data.
3. Slower fights (pacing): a global time-to-kill / combat pace pass, judged on the ladder's TTK and lifetime columns. Not started - needs a brief.
4. Healer kits design (held), Stormcaller lightning FX, then the coding queue (halberdier walk, Bison gait, ranged kite, Shields Up, readability S1/S2, Battle Lab S1, smarter Brutal bot).

## Open calls for lovish
1. Should the Easy bot announce its attacks? 2. City dressing on human bases, on by default? 3. "Random" richness on pre-made maps: normal or rolled? 4. Maps spec Q2-Q4, Q6-Q9. 5. Free-fly key: Caps Lock? 6. "Lighting effects": the Stormcaller lightning, or the lantern light?
(Answered this session: nightly ladder = yes; edgeline = extractor clearance.)

## Self-diagnosis
- Context stayed small (director only; big reads delegated). Ten tool-heavy steps, no quality redos, one dropped commit set (branch collision, not a quality issue).
- Could not run the Command Center boot, ledger or OmniRoute (PC offline): the ledger is kept here.

## Facts worth keeping
- Claude usage "resets": given out occasionally to eligible plans; they show in Settings -> Usage with an expiry date; there's nothing to redeem and no way to request one. The Opus 5.5 launch reset expired Oct 22; lovish's account showed none.
