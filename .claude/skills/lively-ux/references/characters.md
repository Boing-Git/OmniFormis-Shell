# Characters: mascots, faces, anything with eyes

A mascot is the most alive thing on a screen or the deadest: people read a face as *someone*,
so a face that ignores them reads as a sticker. Treat it as a small actor with a few rules,
not as an animation to play.

## Build it in layers (what Rive and Duolingo do)

1. **Idle at the bottom**: breathing and blinking at irregular intervals (2.5–6 s, never in step
   with another character). This is the only idle loop a character needs. It stops under reduced
   motion and while the character can't be seen.
2. **Continuous tracking above it**: gaze, and the body following an input *every frame*. Feed
   it one normalized value (a point from -1 to 1, an angle), never a trigger.
3. **Short reactions on top**: a bob, a flinch, crying, a hop. They take over for a moment and
   hand control back to layers 1 and 2 without a reset or a snap.

A character driven only by layer 3 (one canned bob per event) is the most common failure. It
feels alive the first time and like a sticker by the tenth.

## Couple it to continuous inputs, physically

When the user turns, drags or scrolls something next to the character, the character should
move *with* that value while it moves, momentum included, not react once when a selection
changes. Pick a physical relationship people already know, so it never feels arbitrary:

- **A gear**: a body meshed with a ring turns with it at the radius ratio (inside the ring: the
  same way round; outside it: the opposite way). Free, honest, and it never gets old. Gear it
  down when the shape is symmetric: a 12-lobed body looks the same every 30°, so once it turns
  more than ~15° a frame (a fling at the true radius ratio) it strobes, seeming to stand still
  or spin backwards. Keep the ratio low enough (2–4×) that a fast fling stays under that.
- **Inertia**: loose parts (googly pupils, ears, a tail) lag the body's motion and swing back on a
  loose spring. Kick them by the per-frame change, clamped so that a jump (a list replaced) can't
  fling them.
- **Attention**: the eyes follow the thing that moves (the pointer, the newest item).

Size it to frequency: a ring turned 200 times a day gets the coupling (no extra flourish); a
fast fling, which is rare, may add something (dizzy eyes).

## Gaze is the strongest signal you have

- **Eye contact means "I'm with you."** When the user isn't doing anything, look at them: pupils
  centred toward the viewer, not at a fixed point on the screen. Undo any resting offset the eye
  rig has (googly pupils hanging low under gravity).
- **Looking away is politeness.** While a secret is typed (a password, a PIN), the character
  looks away or covers its eyes (Senneff's yeti login, Rive's Teddy login). It looks back when
  the field is empty or the answer comes. It is the single most recognisable "it's a character"
  moment in UI.
- **Watching is engagement.** While ordinary text is typed, the eyes can follow the caret or the
  newest item.
- **Eyes lead, the body follows.** In a gaze shift the eyes move first and the head or body
  catches up a beat later (gaze research: Andrist et al. 2012). In a small 2D mascot: the pupils
  move on a quick spring, the body turns or narrows on a slower one. A blink on a big gaze change
  (looking away, looking back) makes it read as deliberate instead of a glitch.
- **Parts move by different amounts.** Pupils move the most, then the features, then the body;
  something can move opposite (ears) to sell depth (Rive's Teddy rig).

## One emotion at a time, always answered

- Every input the character could plausibly notice gets an answer: a key (a tiny bob), a
  deletion (a flinch), wrong (sad: frown, tears, eyes down; the big one, because it's rare), right
  (joy: a hop, a smile, squinting eyes), a click on it (startled).
- Show one feeling at a time and let it end on a timer (sad ~2.4 s, happy ~1.8 s). Moods override
  gaze (sad looks down, happy looks up).
- Sleep only after a real idle period (10–20 s with no input), not whenever a field is empty:
  "empty" is exactly when it should be looking at the user.

## Reduced motion

The face still tells the story with nothing travelling: the eyes look away or at the user (an
instant change), the mouth and tears show the mood, nothing breathes, bobs or swings. A still
face that changes expression is the calm version of a character, never a hidden one.

## Don'ts

- Never cover content or a field with the character, and never make it the only signal (the
  wrong-password text still says so).
- No reaction that waits for the previous one to finish: retarget the springs.
- No face that stares at a fixed point while the user acts, and no sleeping while they're there.

## In this repo

`shared/Mascot.qml` (linked into all three shells) has the layers: `look` (tracking), `shy`
(looks away, with a blink and a slight turn), `turn` (degrees from outside: the control center's
rings turn Dial-E like a gear, its pupils lagging), `asleep`, `react("type" | "delete" | "wrong"
| "right" | "poke")`, `mood`, and `calm` for reduced motion. `look: Qt.point(0, -0.35)` is eye
contact (it cancels the googly pupils' resting droop).
