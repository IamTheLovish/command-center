---
name: "lean-session"
description: "Use in any long agentic session (browser pane, GitHub web editor, Desktop Commander on the PC, Beyond and Tabs work) to keep token usage low while doing the same work."
---

# Lean session - same work, less usage

What costs usage is text that lands in the conversation, and every later turn re-reads all of it. A tool call is cheap when its result is small. So: do the heavy lifting where the data already lives (the browser page, the PC's shell, the cloud container) and bring back only answers. (Our own take on output filters like RTK and Caveman's "read less / say less" - no third-party proxy, no model router.)

## Rules

1. **One task per session.** When a task is done (or paused), write a short handoff note (the project's inbox note) and stop. Start the next task in a fresh session from that note. Never continue a long session for a new task.
2. **Search in place, return only matches.**
   - Browser pane: fetch files into the page's JS memory (`window._all = {...}`) and grep there; return hit lines or a line range (`lines(file, a, b)`), never a whole file.
   - PC: Desktop Commander `read_file` with `offset`/`length`, or `start_search`; never read a whole large file.
   - Rule of thumb: no file over ~150 lines comes back whole. Read the 20-60 lines around the symbol you need.
3. **Edit without echoing.** Build the changed file in the page (fetch raw, apply exact string replaces in JS that throw if the match count is not 1), keep it in `localStorage`, paste it into the editor via the CodeMirror view, and verify with a true/false equality check. Never print the new file to check it. In a shell: edit with a short Python read-modify-write that asserts the old text occurs once.
4. **Text, not pictures.** Prefer `get_page_text` / `find` / `read_page filter=interactive` with `max_chars` 2000-4000. Take a screenshot only when a click needs coordinates, at `scale` 0.5. Group predictable steps in one `browser_batch`.
5. **Read memory by its head.** The start-here file, the top ~10 lines of the change log, and the one note the task names. Don't re-read docs that note already summarises.
6. **CI: one look per run.** Read check-run annotations (`gh api repos/<r>/check-runs/<job>/annotations --jq '.[] | select(.annotation_level=="failure") | .message[0:300]'`), never whole job logs. To wait, run one background waiter (`until [ status = completed ]; do sleep 45; done`) and get notified; never poll by hand. Waiting costs nothing.
7. **Report briefly.** Final replies say the outcome, the blocker and the next step - not a replay of the steps.
8. **Effort to match.** Low effort is enough for reading, notes and status checks; ask for high effort only for blind code edits that CI must compile.

## Output filters (use these shapes by default)
- git: `git status -sb | head -20`, `git log --oneline -n 10`, `git diff --stat | tail -5`; full diffs only for the file you are reviewing, and then `-U3`.
- gh: always `--jq` to the fields you need (`.number`, `.state`, `.head.sha[0:8]`); lists with `per_page` and a filter.
- Builds/tests: `2>&1 | tail -20`, or `| grep -E "FAIL|ERROR|error:|failed!" | head -20`; counts with `grep -c`; never stream a full build log.
- Logs (server/client): `Select-String -Pattern ... | Select -Last 12` and cut lines to ~250 chars.
- JSON/large files: pull fields with `jq`/`python -c`; print sizes and counts, not content.
- Downloads: write to a file and print `wc -c` plus the first useful lines.
- Quiet flags first: `-q`, `--quiet`, `-s`, `--silent`, `--no-progress`.

## Images and video
- Video: never read frames one by one. `ffmpeg -vf "fps=N/<duration>,scale=480:-1,tile=4x3" -frames:v 1 sheet.png` for one contact sheet; zoom a time window at 1-4 fps only where motion matters; crop to the area that matters.
- Comparisons: one side-by-side or 2x2 grid per question, ~1200-1600 px wide; 3x nearest-neighbour crops for pixel faults.
- Measure what you can (luma, noise, coverage) in code and read numbers instead of looking at more pictures.

## Say less
- Between tool calls: no narration. Final reply: outcome, file/PR, one next step, open questions as a numbered list.
- Agent briefs ask for a word-capped final reply and for big outputs to go to files you read selectively.

## Delegate the heavy reads
- A big read across many files, a video, or a long log goes to a subagent that returns the conclusion with a word cap; you keep the conclusion, not the dump.

## Quick self-check before each tool call
- Will the result be more than ~4,000 characters? Narrow it (line range, grep, `--jq`, tail, max_chars).
- Am I about to print something I only need to verify? Compare instead (assert, hash, equality).
- Am I about to look at many images? Grid them or measure them.
- Has this task finished? Write the note and suggest a fresh session.