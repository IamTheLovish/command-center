---
name: "vault-capture"
description: "At the end of every task or handoff, save the important lessons, decisions and references from the session as notes in lovish's Obsidian vault inbox (D:\\Claude Vault\\00 Inbox)."
---

# Vault capture

lovish (Oct 22 2026): important things go into the Obsidian vault automatically. The vault's Librarian (every 2 hours) files whatever lands in `00 Inbox` into Projects / Areas / Resources, merges duplicates and adds links, so a session only has to write good inbox notes.

## When
- At every handoff (Command Center), and when a task finishes with something worth keeping.
- When lovish says "save this to the vault".
- Worth keeping: a decision lovish made, a lesson that holds beyond this one bug, a reference (where something lives, how a system works), a measured number. Not worth it: step-by-step progress, PR status (that's the dev log #150 and the handoff).

## How
1. One note per idea, filename `YYYYMMDD-HHMM-short-slug.md`, written to `D:\Claude Vault\00 Inbox\` through the linked computer (folder `D:\Claude Vault` connected; request it if not).
2. Format (template: `90 System/Templates/Vault Note.md`):

```
---
id: YYYYMMDD-HHMM-short-slug
title: <Area> - <the lesson in a few words>
type: lesson | decision | reference
topic: <Craft - Game Design and Balance | Craft - World and Level Design | Craft - Engine and Performance | Craft - Directing AI Work | Beyond and Tabs | Command Center>
tags: [..]
source: <chat / PR / session>, <date>
created: <ISO time with -04:00>
---

**What holds in any game** (the general rule, so the next game reuses it)
- ...

**In Beyond and Tabs**: the concrete numbers, files, PRs.
```
3. Quote lovish's decisions exactly with the time. Never write secrets, tokens or personal data.
4. If the PC is unreachable: put the notes in a Project doc `claude/vault-notes-<date>.md` as ````vault-note fenced blocks and list it in the handoff as "to file"; the next session with the PC copies them into the inbox.
5. Don't move or edit notes outside `00 Inbox` (that's the Librarian's job), and don't touch `10 Projects/Command Center` (it mirrors D:\Command Center).