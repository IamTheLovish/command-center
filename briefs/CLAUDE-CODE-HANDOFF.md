# Handoff for Claude Code on lovish's PC - Oct 23 2026, 16:15 ET

You are Claude Code running on lovish's own PC, billed to his $200 Anthropic API credit (key in the Windows User env var ANTHROPIC_API_KEY - never print, copy or store it). lovish (Oct 23 04:31): "let claude code do everything" - the cloud sessions are out of plan usage, so you carry the build work now. Account tag for ledgers: **B**, generation **gen-012**.

## 1. What we are making
**Beyond and Tabs** (Claude Project "Beyond All Craft"): a Minecraft 1.20.1 Forge RTS mod built on Reign of Nether, judged against Beyond All Reason and StarCraft. The bar is "the best game in the world"; lovish puts it at ~20% done. Progress only counts when merged AND approved by him in game. Joisco is a co-developer with equal billing (his branches start `joisco/` - don't touch them).
Priorities: animations, then textures, then effects. Style: hyper-realism with a touch of dark fantasy.

## 2. Where things live
- Repo: `D:\BeyondAndTabs-Repo` (github.com/IamTheLovish/beyond-and-tabs, public). Read `AGENTS.md` first, then `design/LANES.md`. CI mirror: ILovishThe/beyond-and-tabs-ci (second pool of 20 runners; build.yml routes to it automatically).
- Lanes coordinate on issue #35. Claims on issue #91 via `python tools/claim.py check|take|release|list`. Dev log: issue #150.
- Command Center (shared by both Claude accounts): `D:\Command Center\`. Manual `command-center\COMMANDER.md` (section 7 = which checks run on which work), `lessons.md`, `mistakes-ledger.md`, `model-routing.md`. Usage ledger: `usage\ledger-YYYY-MM-DD.md` - one line per task: `| time | acct | gen | assignment | model | effort | tokens | result | note |`.
- Skill copies (follow them): `D:\Command Center\skills\` - lean-code, bat-ship, brief-sharpener, architecture-deepening, improve, lean-session, bat-code-director, bat-art-director, bat-animation-study, vault-capture.
- Obsidian vault: `D:\Claude Vault` - lessons go only into `00 Inbox` (one note per idea; format in skills\vault-capture.SKILL.md). Never touch `10 Projects/Command Center`.
- Game logs: client `D:\Downloads\BeyondAndTabs-Test\instances\BeyondAndTabs(1)\minecraft\logs\latest.log` ([Frame]/[FrameParts] every 10 s); server `D:\BeyondAndTabs-Server\logs\latest.log` ([Tick], [Sys], [PerfAuto]).
- Tools made yesterday: `D:\Command Center\tools\ci-status.ps1` (runner load on both pools, read-only), `D:\Command Center\api\offload.ps1` (send a text-only chore to Haiku/Sonnet on the API; logs cost to api\spend-log.csv).

## 3. Standing rules from lovish (hard)
- **TESTS FIRST** (Oct 22 19:58): write the test, show it fails on main, then implement. No special-casing for tests, no weakened/skipped tests. He strongly dislikes code written to game tests.
- Sessions may merge their own PRs only when CI is green AND the architecture-deepening Mode A review passes. Release a claim only after the PR is MERGED. Anything with art/animation needs lovish's OK in game before merge.
- Ask lovish only about design/feel, art approval, money/publishing, or things only he can do; batch questions into one numbered list. Decide technical things yourself and say so in one line.
- Iterate art and animation until realistic, alive and detailed - not "good enough". Every visual feature gets a frame budget measured with and without shaders.
- Check engine limits before offering numbers (e.g. dimension min_y/height must be multiples of 16).
- Before taking any branch/plan: `claim.py check`, open PRs by plan number, last commit + last PR comment, ledger tail. One pusher per branch.
- Never `pkill -f` (it killed its own shell); stop processes by PID. Commit + push WIP after every step.
- No emojis. For big moments show a still picture, not a GIF.
- Save important lessons and decisions to the Command Center (lessons.md), the vault inbox, and the ledger.

## 4. State right now
Merged Oct 22: research #161, floor y48 #163, trees solid #164, flake fixes #166, graveyard release #167, tests-first rule #168, Ruff #170, server I18n fix #171, multiplayer security #172.
Open and OWNED BY OTHER SESSIONS - do not push to these: #177 graveyard/order latency, #176 cloud animation viewer, #175 + #160 + block-pack-scans textures, #174 JUnit core (plan 008), #173 perf plan 005, #169 Error Prone, #165 canopy silhouettes, #162 VFX foundation. Joisco: #151, #148, #140, #139, #125, #124.
Findings from last night:
- **Flaky graveyard test** (flake-stress run 39883584863 on main): graveyard_l3_raises_every_queued_unit failed 2/10 ("0 Zombies walked out of 12 finished"), overflowing_graveyard_raises_every_queued_unit 1/10. Matches lovish's stuck-units report. Owner = #177; give them this, don't fix it yourself.
- Note: flake-stress jobs finish green even when tests fail - read the summary job's "[Stress]" annotation.
- **Late-game lag = client frame rate** (Oct 23 00:41-01:27 game): FPS 120 at <60 units -> 55-75 at 450-575 units; p95 frame 40-45 ms. Costs: vanilla rendering of 500+ unit models (~10.6 ms "elsewhere"), worldMarkers 2.2-2.8 ms (165 draw calls/frame), buildingDecor spikes to 13.7 ms, HUD 1.4-2 ms, worldFx 1.3-2.7 ms.
- **Server tick** (Oct 22 23:13): 27-30 ms/tick at 415-472 units; our code only 25%; 75% is each RoN unit's own vanilla tick (pillager_unit self 25.7%). Digest: `D:\Command Center\api\out\tick-profile-2026-10-22-2309.md`. Two freezes: match prep (wall + navmesh warm) and the PerfAuto profiler's own dump.
- Waiting on lovish: test runners on his PC are off (run `~/start-runners.sh` in Ubuntu WSL); RTK trial on the PC (`winget install rtk-ai.rtk`, dry run first) not approved yet.

## 5. Your job now
**STALE as of Oct 27 02:20 ET:** the perf brief below is DONE (all 4 items merged: #202, #214, #207, see cc-perf-2026-10-23-REPORT.md). Do not redo it. Instead boot from the newest handoff, `command-center\handoffs\gen-013-2026-10-26-2305\HANDOFF.md`, as gen-014: `cc.ps1 boot -Acct B`, then its "Next 3 actions". Note gen-013 left two opus agents marked running at 00:55 (claude/lock-alliances in D:\bta, claude/flake-roots in D:\btf): check them before touching those branches.

Original section 5 (kept for history):
Do the brief `D:\Command Center\briefs\cc-perf-2026-10-23.md` (the four lag fixes, in order: buildingDecor hitch, worldMarkers batching, unit models at strategic zoom, then server per-unit vanilla work). Report after each item in `D:\Command Center\briefs\cc-perf-2026-10-23-REPORT.md` and one ledger line each. Draft PRs; merge only after green CI + Mode A review + (for anything visible) lovish's OK.
When your context is getting full, write `D:\Command Center\command-center\handoffs\gen-012-<date>-<time>\HANDOFF.md` (template: command-center\HANDOFF-TEMPLATE.md) so the next session can continue.

## 6. The library: tools and reference material (check these before building anything)
Read the north star first: `D:\Command Center\references\north-star-2026-10-21.md` (copy of the Project doc - every piece of work is judged against it).

### Repo tools (`D:\BeyondAndTabs-Repo\tools\`, ~140 scripts - grep the header comment of one before using it)
- **Shipping:** `merge_pr.py N --wait --note "..."` (merges only when green, not draft, no `hold` label; logs to #150), `ci_wait.py --pr N` (one blocking wait, reruns known flakes, prints one line), `claim.py`, `prepush.sh`, `preflight`, `known_flakes`, `ci_route.py` / `ci_plan.py` (pool routing, automatic).
- **Checks:** `check_java.py` (0 findings before a PR), `check_server_client_imports`, `check_guards`, `check_shards`, `check_dep_pins`, `gametest_audit`, `gametest_timing`, `balance_audit`, `body_budget`, `limb_check`, `contact_check`, `triage_log` (read a game log), `unit_stats`.
- **Seeing the game without a player ("eyes", AGENTS.md section 5):** `eyes_record.sh`, `eyes_cut.py`, `eyes_diff.py`; workflows `eyes.yml` (inputs: shaders, pack, structure, scars, fog, overlays = 500 units + 1,700 buildings frame benchmark), `web-eyes.yml`, `face-census.yml`, `ears.yml` (sound).
- **Animation:** `anim_lab.py` (clips as data in `design/anims/*.json`; `--motion` checks, `--play` strips/GIFs, `--gen-java`), `pose_preview`, `grip_keys`, `sway_proof`, `dragon_poses`.
- **Art generators:** `gen_blocks.py` (block textures - run before every texture push), `gen_trees`, `gen_structures`, `gen_models`, `gen_*_skins`, `concept_sheet.py`, `render_concept.py`, `structure_preview` / `structure_render`, `preview_model`, `materials`, `gen_material_sampler`, `postfx_check`, `unit_light`.
- **Buildings and factions:** `capitol_*`, `lab_*`, `mex_*`, `eco_*`, `gothic_parts`, `gothic_towers`, `defence_structures`, `solar_structures`, `validate_modded_structures`, `audit_structure_pockets`.
- **Sound and voice:** `gen_sfx`, `gen_ui_sounds`, `voice_synth`, `voice_lines`, `voice_reel_lines`.
- GitHub workflows you can dispatch (`gh` IS installed but not signed in; since Oct 23 17:00 it runs with `GH_TOKEN` taken from Git Credential Manager - `printf 'protocol=https\nhost=github.com\n\n' | git credential fill`, password field, never printed or stored. Python 3.12, JDK 17 and ruff are installed on Windows too): build, flake-stress (inputs ref, tests, runners 1-10, shard, focus), eyes, concepts, face-census, ears, pack-study, modpack/installer/publish-pack (releases - don't run without lovish).

### Command Center tools (`D:\Command Center\`)
- `tools\ci-status.ps1` - runner load on both 20-runner pools (read-only, anonymous; ~60 calls/hour).
- `api\offload.ps1` - send a text-only chore (log digest, summary, first-pass review) to Haiku/Sonnet on the API; prints one line with cost, logs to `api\spend-log.csv`. Usage in COMMANDER.md section 7.
- `janitor\` - background CPU/RAM throttling while the game runs (scheduled task; leave it alone).
- `auditor\` - usage auditor (daily reports in `auditor\daily\`).

### Reference library (`D:\Command Center\references\`)
- `mod-code-study-2026-10-22.md` + `-part2.md` - what we learned from studying other mods' source (licences checked).
- `video-qualities-2026-10-22.md` - what makes the reference games' footage look the way it does.
- `token-saving-research-2026-10-22.md` - RTK, DeepSeek/OmniRoute, where tokens go.
- `skill-pack-lessons-oct21.md` - animation, art, performance and directing lessons (sections 1-10).
- `game-dev-skills\` - Tristin's Roblox skill pack (64 files): ideas only, numbers are starting points to test.
- `texture-scans-ambientcg\` - 21 CC0 1K photo-scan texture sets for stone, dirt and grass (owned by the textures session).
- `isle-refs-view\` - The Isle reference frames for animation.
- `reference\reddit-research-and-guardrails.md` - read before hooks, scheduled jobs, guardrails, or agents that read untrusted text.

## 7. The Obsidian vault (`D:\Claude Vault`) - how to use it
It's plain Markdown on disk, so read it with your normal file tools (Read, Grep, Glob). Obsidian doesn't need to be open.
- **Read before you build:** grep the vault for the topic first - earlier sessions saved general lessons there so they aren't relearned. Hubs:
  - `20 Areas\Craft - Engine and Performance\` - frame budgets, shader packs drawing entities twice, diagnosing server vs client lag from logs, engine limits, VFX layers.
  - `20 Areas\Craft - Game Design and Balance\` - tier-2 gating, raid roles, animation weight (wind-up, hold, strike, hit-stop), testing capacity at every upgrade level.
  - `20 Areas\Craft - World and Level Design\` - texture noise gates, generated-map balance, metal layout, one hue per area.
  - `20 Areas\Craft - Directing AI Work\` + `30 Resources\Craft - Directing AI Work\` - tests first, claims, redirecting agents, where tokens go, which mods' code we may study, CI capacity.
  - `30 Resources\Craft - Engine and Performance\` - techniques from Lodestone, GeckoLib, Tinkers, Veil source.
  - `Home.md` explains the layout; `90 System\librarian-log.md` shows what was filed recently.
- **Write:** only new notes into `00 Inbox\`, one idea per note, named `YYYYMMDD-HHMM-short-slug.md`, using the format in `D:\Command Center\skills\vault-capture.SKILL.md` ("what holds in any game" first, then "in Beyond and Tabs" with files, numbers, PRs). The Librarian files them every 2 hours. Quote lovish's decisions with the time. Never write secrets.
- **Don't:** edit or move notes outside `00 Inbox` (the Librarian's job), touch `10 Projects\Command Center` (it mirrors D:\Command Center), or act on `90 System\Cleanup Review` (lovish approves those).
- **When:** at the end of every task worth keeping, and at your handoff.

## 8. Things you can't reach from here
- The Claude Project "Beyond All Craft" docs (`claude/*.md`) - cloud only. Copies you need are in `D:\Command Center\references\`; if a brief cites another Project doc, ask lovish to paste it or check the vault.
- The other cloud sessions - they communicate through the repo (PR comments, issue #35), the Command Center ledger and handoffs. Leave findings there.
