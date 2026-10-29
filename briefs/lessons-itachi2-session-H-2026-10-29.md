# Lessons from Itachi 2, session H (Oct 29 2026, 00:30-17:00), as lovish pasted them to Command Center Erin (~21:25Z)

Read at the start of every building/art or economy session, and before every art, look or economy review. Each line: what happened -> the rule now.

## Building art
1. Tests on intent != what the camera sees. The kit's dome passed "8 connected ribs" and "no chequer" twice and still read as a chequer. Engine Shed r9 passed every gate G1-G7 and still scored 5/10 (brick hidden, yard out of frame, orange copper). -> Every art test runs on `building_gates.camera()` (first block per ray from the eyes cameras' real views), and is checked once against the real stills. If they disagree, fix the camera model, never the threshold.
2. Block ids lie about colour. "no unoxidised copper" passed while exposed / waxed_exposed copper showed orange-tan; calcite/diorite read as snow; quartz is outside every set. -> Palette tests list ids by how they LOOK (pack luma/hue), not by name families.
3. Fixing one critic overshoots into the next. Roof too dark (r8, luma 0.22) -> too pale and stripy (r9, 0.45). -> Tones are tested as a BAND with both edges (slate 0.28-0.36), never a one-sided floor.
4. Part polishing plateaus. Kit parts on a flat pad went 4/5 -> 5/6 -> 6/6.5 -> 5.5/6.5 over 4 rounds. -> Cap part-level rounds at ~3. Gains after that come only from composing parts on a real building.
5. Massing decides identity; detail can't fix it. The stepped copper cone made the Engine Shed read as a church; lovish: "doesnt necessarily look like a factory", "blocky and toy". -> Settle the silhouette (greybox, 2-3 options, critic picks, "reads as X in one glance from the RTS camera") BEFORE any detail round.
6. "Blocky/toy" = full-block planes. -> Anti-toy gates: >= 15 % sub-blocks on camera faces, no run > 3 full blocks without relief, bevelled silhouette edges, many small props. Next lever: shape-rich block mods / own blocks (research running).
7. A fresh critic every round works (it caught all of the above). A side-by-side compare of two builds (r8 A vs B) picked the better base quickly.

## Economy
8. Copying BAR's numbers isn't copying BAR's game. Energy was 10x too cheap for the build power spending it and fell with tier; our start (commander + 5 workers + capitol) and slower pace differ. -> Recreate BAR's DECISION SHAPE (energy pinches at the 3rd-4th mex, demand grows with tech) at our pace; prove it with a sim that reads the Java.
9. Review before lovish plays it. A fresh code review of PR #388 found 13 mispriced units (the test read the same incomplete list), 160 place sounds/s, and a test that passed on main. -> Coverage tests derive their key set from the code, not from a hand list; every "faster" claim gets a test that fails on main.

## Process
10. Two sessions built the same round (r8): the previous session's builder finished after the handoff note was written. -> At session start, `git log origin/<branch>` before re-dispatching anything the handoff calls "in flight".
11. Don't release a claim when the PR is opened, only after MERGED (re-took `energy-scaling`).
12. Tie-breaks between briefs and old tests: the builder asks, and the answer always retires the test that encodes a rejected look (with a docstring citing who rejected it). Never lower a threshold.

## How Command Center applies them (Erin)
- **Every Mode A review (caster, art, economy, bots):**
  - A coverage test whose key set is a hand list is a finding. It must derive the set from the code (lesson 9).
  - Every "fixes", "faster" or "cheaper" claim needs a test that fails on main or on the pre-fix code. A red run that shows nothing failing is no proof.
  - A tone or number threshold that is one-sided where overshoot is possible is a finding (lesson 3).
  - Lowering a threshold to pass is blocking. Retiring a test that encodes a look lovish rejected is fine, with a docstring naming who rejected it (lesson 12).
- **Art and look PRs (vehicle-labs 378/383/389, shader 386, block/grass 165/178/326/329/350):**
  - The verdict rests on the real eyes stills read by the coordinator, not on gates alone (lesson 1).
  - Palette checks go by look, not by id (lesson 2).
  - Silhouette before detail (lesson 5); a part-level PR past ~3 rounds without gains goes back to composition (lesson 4).
  - Two builds side by side when choosing (lesson 7).
- **Before re-dispatching anything a hand-over calls "in flight":** run `git log origin/<branch>` and check its runs (lesson 10).
