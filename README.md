---
title: Command Center
type: hub
---
# Command Center

The real files live in `D:\Command Center\`. Obsidian shows them through a link at `Claude Vault/10 Projects/Command Center`. Librarian and Cleaner: leave this folder alone. Don't move, merge or archive anything in it.

| Part | What it does | Start it |
|---|---|---|
| **Janitor** (`janitor/`) | Every 2 min, while Claude / Minecraft / Blender / Obsidian / VS Code is open, it lowers the priority of background apps using a lot of CPU or RAM and trims their memory. It closes only apps on your kill list, never touches the app you're using, and restores everything when you stop working. | Double-click `janitor/INSTALL (double-click).cmd` once. Edit `janitor.config.json` to tune it. |
| **Command Center** (`command-center/`) | The director you talk to. It splits work into assignments, picks the model and effort for each subagent, logs usage, and hands off to a fresh chat at ~40-50% context with a self-diagnosis. | In any chat: **"Command Center, resume"** (or "start Command Center"). |
| **Usage Auditor** (`auditor/`) | Checks the ledger and today's chats for work a cheaper model could have done equally well. It advises the commander without interfering, and writes a nightly diagnosis. | Runs nightly. Ask any time: **"run the usage auditor"**. |

Folders: `usage/` holds daily ledgers · `command-center/handoffs/` holds one folder per generation · `auditor/daily/` holds your nightly reports · `auditor/advice/` holds notes for the commander · `skills/` holds copies of the skills, for installing on another account.

Second Claude account: read [[SECOND-ACCOUNT-HANDOFF]].
