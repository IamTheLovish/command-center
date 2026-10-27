# Codemap: legacy-mod-engine
sha: bbbdac21 (bbbdac211d7d355181c00da37dc416b82fa04ff9)   date: 2026-10-27   source: dossier of bar/ at that sha + traps from review/plans/lessons/AGENTS
drift: `git -C D:\btr diff bbbdac21..origin/main --stat -- mod engine`

## Purpose
Older from-scratch prototype kept for reference (mod/ 37 java + engine/ 37 java + 8 tests, ~12.6k lines). The live game is bar/. Not shipped.
## Key classes
See `git -C D:\btr ls-files mod engine`; read only when porting an old idea. Nothing in bar/ imports it.
## Entry points and events
none (prototype).
## Server vs client
n/a. ## Data flow: none to bar/. ## Instrumentation and tests: engine/src/test/java (8 files, not part of the bar GameTest suite).

## TRAPS (source tag in brackets: REV overnight-review, LES lessons.md, AGM AGENTS.md, P0xx plans, RUL RULES.md)
- Not shipped; the live game is bar/ (AGM s3).
