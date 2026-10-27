---
name: "grill-design"
description: "Use when lovish wants a plan or design pressure-tested (\"grill me\", a brainstorm to settle, a feature spec): a relentless one-question-at-a-time interview that records decisions and terms as it goes."
disable-model-invocation: true
---

# Grill a design (with docs)

Adapted from Matt Pocock's `grill-with-docs` / `grilling` / `domain-modeling` skills (github.com/mattpocock/skills, MIT licence, (c) Matt Pocock) for Beyond and Tabs. The goal: every branch of a design resolved, in lovish's own words, written down where the next session will find it.

## When
- lovish says "grill me", or asks to settle a brainstorm (hero kits, factions, economy, maps, launcher...).
- Before a large build whose design isn't decided (the commander asks lovish only design/feel questions; this is the tool for that).

## How to interview
1. Restate the plan in 3-5 lines and list its open branches (decisions not yet made) as a numbered map. Ask lovish to correct the map first.
2. Then one question at a time, depth-first on the riskiest branch. Each question:
   - start from the problem (what the player is trying to do, what goes wrong now), features after;
   - give a recommended answer with each question so lovish can just say yes (from Joisco's grill-spec, Oct 27);
   - if the repo, decisions.md or a design doc can answer it, look it up instead of asking;
   - concrete and answerable (offer 2-4 options with the trade-off of each, plus "something else");
   - grounded in the game: name the unit, building, faction or screen; cite references he gave (The Isle, Day of Dragons, Direland, BAR, the add-on videos) where they help.
3. Push back when an answer conflicts with an earlier decision, the north star ("best game in the world", hyper-realism with a touch of dark fantasy), performance budgets or multiplayer; say what conflicts and ask which wins.
4. Keep going until every branch on the map is decided or explicitly parked ("later"). Don't stop at the first plausible answer.
5. Batch nothing he must think hard about; quick yes/no confirmations can go 3 at a time.

## Docs as you go
- **Decisions**: append to design/LANES.md under "Decisions to build toward (lovish, <date>)" with his exact words and the time. A reversed decision moves to "Retired" with the date and his reason - never deleted.
- Also add each decision as the next D-number in `D:\Command Center\knowledge\decisions.md` (date, decision, his quote, source).
- **Terms**: when a name gets settled (a unit, a mechanic, a resource), add it to design/GLOSSARY.md (create if missing): term, one-line meaning, where it lives in code or docs. Use the settled term from then on; flag old names in code for renaming later.
- **Hard-to-explain choices** (why X over Y): a short design note (design/<topic>.md or a Project doc) with the options, the choice, and why.
- At the end: a summary of what's decided, what's parked, and the first build step; save it as a Project doc and a vault inbox note (vault-capture skill).

## Don't
- Don't build anything during the grill.
- Don't put words in his mouth: if you inferred it, ask him to confirm before writing it as his decision.