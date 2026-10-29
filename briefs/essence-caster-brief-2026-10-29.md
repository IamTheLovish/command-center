# Essence caster per race: shared brief (Command Center Rust, Oct 29)

lovish approved (decisions: `D:\Claude Vault\10 Projects\Beyond and Tabs\decisions-2026-10-29-rust.md`; design: `D:\Claude Vault\10 Projects\Beyond and Tabs\design-draft-essence-casters-2026-10-29.md`, committed as `design/essence_casters.md` on branch `claude/essence-wisps`):
- Dead units drop floating essence wisps; a caster gathers them (8 blocks, holds 30).
- Each race gets one NEW caster unit, made at that race's T2 lab, with 3 essence abilities (cheap 5 / mid 10 / big 20 essence; cooldowns 12 / 25 / 60 s) plus the shared Empower (15 essence: one veterancy rank to an ally within 6).
- Names are placeholders; numbers get tuned later in balance.

## Base you build on
The essence base (wisps, carriers, spend/add API, Empower) is on branch `claude/essence-wisps` (head f87386d8 or newer), reviewed PASS and waiting for its runs to merge. Branch your race off `claude/essence-wisps`, not main. When the base merges to main, merge main into your branch (normal merge, no force-push). Read the base's PR body and `Essence.java` for the API. Your caster must be an essence carrier, its summons must be marked summoned (they drop no essence), and every ability must refuse without spending essence or setting the cooldown when it cannot act (see `AutoCaster.java:188`).

## How
1. Clone into your own folder on D: (e.g. `D:\bt-caster-<race>`), branch `claude/caster-<race>` off `origin/claude/essence-wisps`. Never touch `D:\BeyondAndTabs-Repo` or `joisco/` branches; never push to main.
2. The real game is under `bar/` (`mod/`, `engine/` are an old prototype). Model the unit on the race's existing casters and lab buttons (look at how its T2 lab produces units, `Ability.java`, `AutoRule`, `SupportBrain`, `BarFx` for effects). Placeholder look: reuse an existing body/texture of that race.
3. GameTests FIRST: the unit is producible at the T2 lab with a cost; it gathers essence; each ability does its effect with the numbers below, spends the right essence, refuses when short (no spend, no cooldown), and its cooldown holds; Empower present. Push tests-only, prove they fail with the `flake-stress` workflow (FULL 40-character SHA, `test:` prefixes), then implement and prove green on 8+ runners. No nested runAfterDelay/onEachTick inside GameTest callbacks; clean up in a try/finally in the last callback (as `EssenceGameTests` does) so cleanup runs however a test ends. `TestCleanup` is NOT on your base (it lives on the unmerged GameTest-cleanup branch): do not merge that branch; switch to it only after it reaches main and you merge main.
3b. Runner queue: do NOT dispatch flake-stress until the PR's `build` job shows the head compiles (a compile error makes every queued stress run worthless). Then dispatch one red (3 runners) and one green (8 runners) per head; no exploratory runs.
4. NEVER run Gradle, GameTests or the game locally (lovish plays on this PC). GitHub runners only; cancel no runs.
5. Commit with `git -c user.name=IamTheLovish -c user.email=IamTheLovish@users.noreply.github.com commit`, trailer `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`. Open a DRAFT PR whose base is `claude/essence-wisps` until that merges (then retarget to main), body: "Do not merge without lovish's OK", the red and green run ids, and the ability numbers.
6. Report to the coordinator Command Center Rust (session local_ba489985-988c-41cc-8152-675bd817862a): PR number, head SHA, run ids. Ask lovish nothing directly; send design questions to the coordinator.

Done = a draft PR with red and green proof.
