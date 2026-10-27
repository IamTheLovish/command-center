# Self-diagnosis - gen-001

## Mistakes I made in this chat
1. Briefed two subagents to write their findings to scratchpad files → subagents' Write is refused for report files, so both returned findings as text and the files never existed → next commander: brief agents "return findings in your final reply (under N words); I will write the file".
2. Ran without the usage ledger (it didn't exist yet and I didn't create it at boot) → gaps for the auditor → create `usage/ledger-YYYY-MM-DD.md` at boot and log as you go.
3. propose_skills was refused once because I'd only `cat`-ed the synced SKILL.md files, not opened them with Read → read the current synced SKILL.md with the Read tool before proposing an improvement.
4. Groq free-tier figure: README said 30M, the guide said ~15M; I reported only 15M → when sources conflict, give both.
5. Minor: project_write with local_path outside the working directory failed → copy into the working directory first.

## Usage check (from today's ledger)
- Assignments: 2 · by model: haiku 0 / sonnet 2 / opus 0 / fable 0
- Redos: 0 · escalations: 0 · rate: 0%
- Work I did myself that an agent should have done: skimming Tristin's command-center skill myself (~30k chars) could have gone to a haiku summary.
- Overpowered agents: none. Sonnet high was right for distillation (~273k and ~287k tokens each).
- Underpowered agents: none.

## Efficiency score
- Usage 7/10: two cheap parallel agents did the heavy reading; the commander thread still read ~35k of process material itself.
- Output quality 7/10: grounded, critical adoption with honest caveats; not yet proven in game (the real test is the Bison study).

## Auditor advice: adopted / declined
None in `auditor/advice/`.

## Rule changes
- To lessons.md: "Brief agents to return findings in their final reply; the commander writes files" (added).
- To model-routing.md: none.
