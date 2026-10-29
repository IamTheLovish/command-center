# Revision round, Oct 29 night (Command Center Erin)

lovish (typed ~21:05Z): "lets make sure to revise and improve". The source is every reviewer's non-blocking notes on tonight's heads (reviews/pr-N-modeA.md).

Rule for this round: queued proof runs are not thrown away.
- **A, before merge:** spec mismatches and real game bugs on PRs that are not yet proven, or that wait anyway.
- **B, improvement PR right after merge:** one per builder, branched from main, normal Mode A review plus red 3 / green 8 where game code changes.
- **C, taste calls for lovish:** none of these are decided without him.

## A. Before merge
- **366 Tombcaller** (it waits on #374 anyway):
  - Lobber shells must hit tombstones at the defence rate of 54, per Revision 1 (draft line 79). BombardShell.onHit gives them only unit splash. Add the rule and a test.
  - Raise Tombstone accepts 1-deep water (RaiseTombstone.java:124, :132). Refuse it, or place on the floor under the water.
- **371 Grave Adept:** r2 blockers B1 (save/reload) and B2 (EventPriority.LOW), already sent.

## B. Improvement PRs after each merge
- **391 bots tier-2:**
  - Cache the structure footprint (NBT) per building type: a fully failed search on rolling ground is still ~261 reads against main's 65, and the Horde nether fallback repeats it per zone every think.
  - Run techDiag only when logging.
  - Fix the cut comment at BotPlayer.java:605.
  - Make the 3-min cap stop re-arming on every army dip.
  - Now, in the PR body only: correct "a failed search costs what it did before", and add the floating-annex order (:629-635) to Scope.
- **362 Verdant:**
  - useEmpower skips stunned/frozen/uncontrollable casters (as AutoCaster.java:106-108 does).
  - Prune SproutGuardian.GUARDIANS when autocast is off (it leaks until server stop).
  - Add tests where CROWD / ALLY_HURT / SUMMON_WHEN_FREE autocasts succeed.
  - Find the heal-test damage source.
  - Fix the stray javadocs (BotPlayer.java:2197, ThornweaverGameTests.java:146).
- **365 Horde:** add a test that fails if `autocastEssence` is removed from Hex/BloodTotem.
- **370 Stormcallers:** add a test where a kited Sage autocasts after its step ends.
- **372 Brassworks:**
  - Go through the r1-r5 non-blocking list in pr-372-modeA.md: boil survives capture, multiplicative stacking, client prediction, furnace outlives caster, the autoBoil gates comment, the `boiler_idle` wording, the cap-window comment.
  - Fix what is a bug; list the rest.
- **364 Sunforged:** with #363 in, check the r3 note: no "short of essence" HUD spam or behaviour reset from a refused autocast. A test asserts that a low-essence autocast orders nothing.
- **366 Tombcaller:**
  - Multi-select Raise Tombstone stops at the first off-cooldown Tombcaller even when it refuses (UnitActionItem.java:569-584). This is shared code, so it gets a careful fix.
  - Add a vertical reach limit / line of sight.
  - Add tests for a skeleton crumbling at its end tick and for the creep ending.
- **380 AI faction:** the stale lang lines go in slice 1b, as agreed.
- **386 shader slice 2:**
  - Normalise paths (backslash, case, ./, ..) before the shaderpacks rule.
  - Require every repo file in the built pack.
  - oculus.properties must be absent or shaderPack=BeyondAndTabs.
  - Lift publish-pack.yml:223-225 together with the test.

## C. Taste calls for lovish
- Verdant:
  - Roots hits ground enemies only.
  - The Thornweaver is 1 of 6 uniform bot T2 picks (with the Priestess, up to a third of T2 can be non-fighters).
  - Ranges 10/8/8 are placeholders.
- Sunforged: Mender Angel flies 6 blocks up; Sword Seraph stats.
- Stormcallers:
  - Captured Spark throws 10 blocks; Thunderhead has a 12-block cast range.
  - The cloud ends when its Sage dies.
  - A Sage being chased autocasts a second or two late. Faster means a shared SupportBrain change.
- Gravebound: about 2 skeletons per 90 s stone (a beat with one standing is skipped).
- AI faction: a visible enemy crossing a grid cannot hide for up to 2 s after leaving it.
- Siege lobber (Archon's open question): double it to 108 per shell (a wall in ~10 s)?
