# Three screens of the dial shell, audited with this skill

How the skill reads a real surface: the hand table first (what the user can do, what happens),
then the dead spots with evidence, then the change in the project's tokens. These were the test
run when the skill was written (2026-11-23); the shell's own code is the user's to change (its
CLAUDE.md), so each "after" is written to be taught, not applied.

## 1. The notification dial with nothing waiting (NotifyOsd.qml)

| The user… | What happens now |
|---|---|
| opens it with nothing waiting | "Nothing waiting" in the body, a bell tile (`notifications_none`), all still |
| hovers or presses the bell tile | nothing (dead) |
| scrolls the ring | the ring is empty: nothing turns, nothing says so (dead limit) |

Dead spots: the empty state neither celebrates "all clear" nor points anywhere
(`NotifyOsd.qml:327`, `:365`), and its only control answers nothing.

After:
- On opening empty, the bell tile gives one small settle (a 4° wiggle on `Vars.shakeSpring`,
  kicked once): "nothing to do" as a gesture, not a sentence. Skipped under `Prefs.calm`.
- Pressing the bell squishes it (recipe 1) and toggles Do not disturb, with the text changing to
  "Do not disturb is on" through a crossfade (recipe 6): the empty state now leads somewhere.
- A scroll on the empty ring rubber-bands the tile a few degrees (recipe 5): the limit answers.

## 2. The media player with nothing playing (controlcenter/MediaPlayer.qml)

| The user… | What happens now |
|---|---|
| opens Media with no player | the title reads "Nothing playing" (`MediaPlayer.qml:36`), the timeline ring lies flat |
| presses play | nothing: there is no player (dead, and the worst kind: a control that silently fails) |
| scrolls the timeline | nothing moves |

After:
- Play with no player shakes the play gem once (recipe 4) and the title crossfades to a short
  "Open a player to start" for two seconds: the failure answers and teaches.
- The flat timeline breathes very slowly while empty (recipe 9 at 10% amplitude), only while the
  dial is open and not under `Prefs.calm`; it stops the moment a track starts, and that start is
  the hero motion (the wave growing out of the flat line on `Prefs.defaultSpatial`).

## 3. A setting's value changing (controlcenter/ReaderCard.qml)

| The user… | What happens now |
|---|---|
| turns a value | the number pops (1 → 1.18 → 1, `ReaderCard.qml:84`) and swaps: lively already |
| turns it fast | each change restarts the pop: it stutters at the top |
| has Bounce 0 (reduced motion) | the swell still runs |

Dead spots are small here, which is the point of checking a good screen too: a skill that finds
ten problems everywhere is noise.

After:
- The pop's numbers move to the card's settings (like `knobPopScale`), and the swell skips when
  `Prefs.calm` (reduced motion keeps the swap, loses the swell).
- A SpringValue instead of the restarting SequentialAnimation, kicked on each change: quick turns
  add up into one swell instead of restarting it (the same reason `DialRotation` springs).
