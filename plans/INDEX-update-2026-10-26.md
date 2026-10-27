# Plans INDEX update - Oct 26 2026 (against origin/main bbbdac21)

Source for the reconcile: `gh pr list/view --state all`, `git log origin/main --grep`, the local worktrees. `claude/plans/INDEX.md` is a Project doc, not on disk, so the titles of 006, 007 (beyond the perf PR), 009 are NOT known to me: the rows say what the repo shows, not what the plan was.

## 1. Reconcile of plans 001-010

| Plan | Status Oct 26 | Evidence |
|---|---|---|
| 001 ruff-python-tools | DONE | PR #170 `claude/ruff-tools` MERGED; follow-ups #219 (lobby tools) MERGED, #199 (`claude/fix-t2-sim-lint`, main's ruff red) OPEN |
| 002 errorprone-trial | IN REVIEW, not done | PR #169 `claude/errorprone-trial` "Error Prone trial (warnings only)" still OPEN (draft) |
| 003 sandbox security | DONE | PR #172 `claude/improve-003-sandbox-security` MERGED Oct 23 00:45 UTC |
| 004 server i18n | DONE | PR #171 `claude/improve-004-server-i18n` MERGED Oct 23 00:45 UTC |
| 005 perf: mount search, neutral aggro, target acquisition | DONE (as revivals) | PR #217 "Perf 005 (revived #173)" MERGED Oct 24; PR #218 "Perf plan 5 (revived #119)" MERGED Oct 24; commit 3db40564 "Tests first (plan 005)". One tuning left waiting for lovish: `IDLE_AGGRO_TICKS` back to 4, "the 8-tick idle look waits on lovish's OK" (558d44dc) |
| 006 (title unknown) | NOT STARTED | no PR and no commit matches "improve-006" / "plan 006" |
| 007 perf quick wins | PARTLY DONE, OPEN | PR #247 `claude/perf-quick-wins` OPEN (draft): night sources, knockback ids, minimap overlay, item pickup gate, queue population (array reuse + minimap timing). Rest of 007 not started |
| 008 JUnit core | DONE | PR #174 `claude/improve-008-junit-core` MERGED Oct 23 20:28 UTC (PopulationRules, EconomyMath, the fast JUnit suite) |
| 009 (title unknown) | NOT STARTED | no PR and no commit |
| 010 errorprone-findings | BLOCKED | depends on 002: #169 still open |

Other open PRs that matter to the new plans: #248 `claude/security-state-fixes` (draft; fog/bot command gates, packet-table hash, world-stop clears; plans 011 and 012 must not redo it), #203 `claude/fix-extractor-footprint` and #221 `claude/t2-pacing` (both change what the bots' T2 test sees; plan 015), #222 `claude/artillery-nerf`. The branch `claude/ci-self-heal` (worktree D:\btc, auto-rerun of known flakes, known-flake lines) has NO pull request yet: `gh pr list --head claude/ci-self-heal` is empty.

Index numbering: the old INDEX also has idea-list items (the brief names "item 12, FoW rasterise" and "item 13, HUD"). The new plans take the numbers 011-017, so those two idea numbers now clash with plan numbers. Suggested wording for the INDEX: item 12 "partly superseded by plan 013 (the entity-tracking refresh; the rasterise part stays open)"; item 13 "superseded by plan 016".

## 2. The new plans, ranked

Impact = what it buys; effort S/M/L = PRs and care; confidence = how sure I am the finding is right and the fix works (numbers from the audit that I did not measure are marked).

| Rank | Plan | Impact | Effort | Confidence | Why this rank |
|---|---|---|---|---|---|
| 1 | 015 flake-root-causes | HIGH: 17 of the last 40 non-cancelled main builds were red (23 green, 20 cancelled by queue collapse); 12 of the 17 name the bots T2 test; every PR waits on it | M (3 small PRs + a baseline) | bots: medium-high (rough ground + 15-minute window, with CI notices as evidence); pathing: medium (water in the pocket is shown by the new `around()` text); mirror: low; unit_push: probably already fixed by #239 | unblocks every other merge |
| 2 | 012 authority-module | HIGH: F9 (allied workers never build) is a plain bug; F7 is a fog information leak (order by id through fog) | M (pure table test, F9 fix, fog check) | F9 high (code read at 6 sites); F7 medium (fix is clear, the rule is lovish's call) | correctness and fairness |
| 3 | 011 lifecycle-registry | HIGH for rematch correctness (state that survives `resetRTS`) | L (registry, scan test, migrations over several PRs) | high that the gaps exist (CapturePoint hired/recruits, bot brains, UnitKills, HeroProgression, BuildingReclaim, mutable `getAllUnits`); medium that 70 clearers migrate cleanly | after #248 (same world-stop files) |
| 4 | 017 strategic-icons-batch | MEDIUM: strategic zoom with many buildings (audit: 5.25 ms, NOT measured by me) | S (one pure class, one call site, one picture check) | medium-high; the plan stops itself if the baseline is under 1.5 ms | cheap, independent, client-only |
| 5 | 013 server-tick-spikes | MEDIUM-HIGH at 450+ units (audit: ~16k `updatePlayers` calls and ~27k building packets, NOT measured by me; step 1 measures) | L (counters, sync deltas, fog refresh spread, phases) | medium | opus xhigh; fog latency bound 10 ticks |
| 6 | 014 save-hitch | MEDIUM (a synchronous multi-file write every 30 s plus every research change; size of the hitch not measured, step 1 logs it) | M | medium; vanilla semantics read from the bytecode (dirty-only, no atomic rename, 6000-tick autosave) | has a crash-window question for lovish |
| 7 | 016 hud-panels | MEDIUM for maintainability (2,709-line file, 22 commits since Oct 1, 200 ifs), perf unproven (the audit's "twice per unit" is once per unit plus once per type) | L (about 11 PRs) | low on perf, high that the mechanical moves work with picture checks | Lane C file: coordinate on #35; plan stops if the HUD costs under 0.15 ms |

## 3. Recommended order and dependencies

Rule that drives it: one plan at a time per file. `UnitServerEvents.java` is touched by 011, 013, 014 and PRs #247 and #248; `BuildingServerEvents.java` by 011, 012, 013, 014; `PlayerServerEvents.java` by 011 and 014.

0. Before anything: lovish decides on #248 (security) and #247 (perf quick wins); they share files with 011 and 013/014.
1. 015 step 1 (baseline stress runs, no code) at once; 015a (bots) after #203 and #221 are decided; 015b/015c in parallel with the rest (test files only).
2. In parallel with 1 (different files, client only): 017.
3. 012 steps 1-2 (pure rules + F9 fix) next; its step 3 (fog check on orders) waits for lovish's answer on refuse-versus-grace.
4. 011 after #248 is merged; steps 1-2 (registry + scan test + allow-list) then migrations in small PRs.
5. 013 after 011's `UnitServerEvents` changes are merged, then 014 (013 adds the Sys sections and the timer phases that 014 reuses; never both at once: they edit `UnitServerEvents.java:265-270` and `BuildingServerEvents.java:185-200`).
6. 016 whenever Lane C agrees; its step 1 (frame sections) is small and can go first; the later moves are one panel per PR.

Dependency graph: #248 -> 011 -> 013 -> 014; #247 -> 013; #203, #221 -> 015a; ci-self-heal PR (not yet opened) -> removal of known-flake lines (not part of 015); 012 -> nothing (but not alongside 011 on `BuildingServerEvents`); 016, 017 independent.

## 4. Questions waiting for lovish (all are in the plans' PR templates)

- 012: may allies build and repair allied building sites? Should an order given at a unit that just entered fog be refused, or accepted for a short grace window (BAR keeps chasing)?
- 014: is a 30 s crash window (buildings, targets), 60 s (resources), about 1 s (research) acceptable, or vanilla-only saves (5 minutes)?
- 015: if the bots' calm-wind spells turn out to decide the T2 timing, the bots' energy plan is a design question, not a test fix.
- 016: refactor for its own sake if the HUD costs little? Name regrouping delay of 250 ms in the selection strip.
- 017: icons of different building types draw in texture order (invisible unless two icons overlap).

## 5. Corrections to the audit's findings (nothing was rejected outright)

- 016: `getModifiedEntityName` runs once per selected unit per frame (plus once per type), not twice.
- 017: the unit icons are one coloured-shape buffer, not textured quads; the batch for building icons is per TEXTURE.
- 015: the brief's "18 red / 18 green" is 17 red / 23 green / 20 cancelled in the last 60 push runs; `unit_push_neighbour_lookups_are_counted` failed only before PR #239 (merged 19:21 UTC Oct 26); the open "claude/ci-self-heal PR" is a branch with no PR.
- 013 and 014: the call counts (16k, 27k) and the hitch sizes are unmeasured; both plans measure first and stop if the number is small.
