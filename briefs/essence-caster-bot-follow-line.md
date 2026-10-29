# Essence casters: the bot follow-the-army line (identical in every caster PR)

Bots train casters, but `BotPlayer`'s army list holds only attackers, so a caster that isn't one idles at its lab with 0 essence (found in the PR 364 round 3 review). Every caster PR adds the SAME edit to `bar/src/main/java/com/solegendary/reignofnether/bot/BotPlayer.java`, in the "healers follow the army" block (on main around lines 1340-1347). Identical text lets the PRs merge one after another without conflicts.

Replace this line:
```
                        && !(le instanceof com.solegendary.reignofnether.unit.units.storm.LanternFortressUnit))   // the Fortress shields it
```
with exactly these two lines:
```
                        && !(le instanceof com.solegendary.reignofnether.unit.units.storm.LanternFortressUnit)    // the Fortress shields it
                        && !(le instanceof com.solegendary.reignofnether.essence.EssenceCarrier))   // essence casters follow the army too
```
Then check that this block runs for YOUR faction's bot. It sits in `verdantHabits`, so confirm where that method is called. If it does not run for your faction, tell Command Center Rust before adding anything else.

Add a test that a bot's lagging caster of your race is ordered to the army centre.
