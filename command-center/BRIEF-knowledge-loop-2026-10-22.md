# Brief: the knowledge loop (lovish approved Oct 22 02:08: "go ahead")

Goal: every session gets better at game development than the last, because what we learn is written down, condensed,
trusted by evidence, and READ at the right moment. One system: build it INTO the Command Center, not beside it.
Owner: a fresh Command Center session (account A or B). No game code, no CI. Ask lovish only for approvals.

Inputs to read first: command-center/COMMANDER.md, lessons.md, mistakes-ledger.md, handoffs/gen-005 (and gen-004),
auditor/AUDITOR.md, D:\Claude Vault\Home.md, 90 System/Templates/Vault Note.md, the 00 Inbox notes from Oct 21-22,
the skills vault-capture and bat-ship (synced skills), and OmniRoute's obsidian_* tools (search/read/write notes).

## Build (in this order; tick each in this file when done)
1. [ ] Craft playbooks in the vault: `30 Resources/Craft Playbooks/` - one note per topic (Game Design and Balance,
   World and Level Design, Engine and Performance, Art and Animation, Directing AI Work, lovish's Taste). Built ONLY
   from the "What holds in any game" halves of notes (game-agnostic), strongest rules first, each rule tagged with
   confidence: [verdict] lovish in game > [measured] > [reference] > [guess], plus its source note link.
2. [ ] Boot step: COMMANDER.md section 1 gets "read the playbook(s) for this task's topic" (short), and "search the
   vault mid-task" via obsidian_search_simple / local_corpus_search before designing anything new.
3. [ ] Handoff step: COMMANDER.md section 4 runs vault-capture (notes to 00 Inbox) and rewrites
   references/memory-snapshot-<date>.md from Claude's memory files.
4. [ ] Taste capture: a "lovish's Taste" note type - every approve/reject he gives in game (quote + date + what it was
   about) becomes a note; art/feel work checks the Taste playbook before calling anything done.
5. [ ] Lesson per merged PR: tools/merge_pr.py (repo, PR #147) gets `--lesson "..."`; bat-ship tells sessions to give one
   general lesson per merge; the dev log comment carries it and a vault note is written when the PC is reachable.
6. [ ] Repeat -> enforcement: when mistakes-ledger shows REPEAT >= 2, the handoff must promote it into a skill step or
   an automatic check (examples: check_java before every push; a CI check that overlay RenderLevelStage handlers call
   ShaderPacks.skipOverlays()). Record each promotion in lessons.md.
7. [ ] Nightly review actually running: schedule the auditor (it has never produced a report - auditor/daily is empty)
   and add a craft section: playbook rules used/contradicted today, notes to merge or retire.
8. [ ] Weekly condense: a scheduled job rewrites the playbooks shorter (merge duplicates, retire contradicted rules with a
   date, archive rules unused for 30 days - handoffs list which rules they used).
9. [ ] Numbers archive: `30 Resources/Numbers/Beyond and Tabs metrics.md` - before/after of every perf/feel PR (TPS, frame
   ms, TTK, unit counts); seed it from Oct 22 (server 74% budget/25 s behind at ~490 entities; client 27-39 ms frames,
   shadow pass 23%).
10. [ ] Playtest intake: a `playtests/` note per match lovish plays - [PerfAuto]/[FrameParts]/[FrameAuto] lines from
   D:\BeyondAndTabs-Server\logs and the Prism instance logs + his comments. Template + a skill step.
11. [ ] Reference studies as numbers: notes for The Isle, BAR, Direland, Day of Dragons with measured facts (speeds, turn
   rates, animation timings, tech gating). Seed from existing Project docs (animation-ref-*, dragon-refs, direland).
12. [ ] Knowledge test: once a week a fresh agent gets a solved past problem (first: the Oct 22 lag) with only the
   playbooks; score it in auditor/daily; fix the playbook when it fails.

## Rules
- Vault: write new notes to 00 Inbox; the Librarian files them. Playbooks under 30 Resources are the exception (create
  them there). Never touch `10 Projects/Command Center` (it mirrors D:\Command Center).
- Keep every always-read file short (lessons.md < 150 lines, each playbook < 120 lines). More system than gets read = waste.
- No secrets or personal data in notes.
- Ledger every assignment; handoff at ~40% context.

## Standing permission (lovish, Oct 22 02:08)
"improve these systems whenever you see fit and as needed" - any session may improve the Command Center, the vault
system, the CI/merge tools and the skills when it sees a real gain; log each change in lessons.md (dated) and the dev
log #150 when it touches the repo. Design/feel/art approvals and money still go to lovish.
