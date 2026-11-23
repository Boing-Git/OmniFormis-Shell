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

## Where it lives: in the empty space, never on the content

A character sits *in* the interface's empty space, never on top of what the user came for: not
on a ring, a pill, a tile, a line of text or a badge. Near a ring it lives inside it, like a
hamster in its wheel (feet on the ring's inner edge, body in the empty middle), not on the band.

- Find the free space from the layout's own numbers (the band's inner edge minus the
  character's size), not by eye. A ring's band usually reaches past its items (a margin each
  side of the pills): clear of the pills but on that margin is still sitting on the ring.
  Check it at every size the container takes: a dial that
  shrinks for one view may have no room left there. Show the character only where there is room;
  hiding where it doesn't fit is part of "hiding in plain sight".
- Make the layout keep clear of it: text that shares the space takes the bigger side of what is
  left beside the character (a keep-clear stretch the text avoids), and a fixed badge keeps its
  corner. Reserve space by the character's *home*, not its momentary position, or the text
  reflows every frame it runs.
- Keep it inside the screen at the edges: an angle range shrunk by its own half-width.

## Couple it to continuous inputs, physically

When the user turns, drags or scrolls something next to the character, the character should
move *with* that value while it moves, momentum included, not react once when a selection
changes. Pick a physical relationship people already know, so it never feels arbitrary:

- **A hamster in its wheel** (the best one for a character next to a ring): measure the ring's
  speed every frame (deg/s, smoothed; ignore a jump, e.g. a list replaced at once) and let the
  character *run against the turn*: feet patter at that speed, the body bobs and leans into it.
  A fast turn carries it up the side of the wheel and it slides back as the turn slows; a fling
  hard enough throws it round (a whole tumble) and it comes out dizzy. Measure what a real
  fling reaches before choosing that threshold (here ~600 deg/s; set the trigger under it).
- **A gear** (for a part rather than an animal): a body meshed with a ring turns with it at
  the radius ratio (inside the ring: the same way round; outside it: the opposite way). Gear
  it down when the shape is symmetric: a 12-lobed body looks the same every 30°, so once it
  turns more than ~15° a frame it strobes, seeming to stand still or spin backwards.
- **Inertia**: loose parts (googly pupils, ears, a tail) lag the body's motion and swing back on a
  loose spring. Kick them by the per-frame change, clamped so that a jump can't fling them.
- **Attention**: the eyes follow the thing that moves (the pointer, the newest item).

Size it to frequency: a ring turned 200 times a day gets the coupling (no extra flourish); a
fast fling, which is rare, may add something (dizzy eyes).

## Gaze is the strongest signal you have

- **Eye contact means "I'm with you."** When the user isn't doing anything, look at them: pupils
  centred toward the viewer, not at a fixed point on the screen. Undo any resting offset the eye
  rig has (googly pupils hanging low under gravity). A pointer moving nearby can be watched;
  once it rests (~3 s), come back to eye contact.
- **Looking away is politeness.** While a secret is typed (a password, a PIN), the character
  looks away or covers its eyes (Senneff's yeti login, Rive's Teddy login). It looks back when
  the field is empty or the answer comes. It is the single most recognisable "it's a character"
  moment in UI.
- **Watching is engagement.** While ordinary text is typed (a search, a question for an AI),
  the eyes follow the newest letter, and each key gets a tiny answer (a bob, a step of the
  run). Its own name typed there makes it glad. Never this for a secret: there it looks away.
- **Eyes lead, the body follows.** In a gaze shift the eyes move first and the head or body
  catches up a beat later (gaze research: Andrist et al. 2012). In a small 2D mascot: the pupils
  move on a quick spring, the body turns or narrows on a slower one. A blink on a big gaze change
  (looking away, looking back) makes it read as deliberate instead of a glitch.
- **Parts move by different amounts.** Pupils move the most, then the features, then the body;
  something can move opposite (ears) to sell depth (Rive's Teddy rig).
- A character that stands turned (feet to a ring) looks in its *own* frame: rotate the target
  direction by minus its rotation before handing it to the eyes.

## Express with everything it has

A feeling shown by the face alone is a sticker with a mood. Give each feeling all four channels,
so it reads at a glance and from across the room:

| Channel | How | Example (happy / sad / cross / in love / dizzy / asleep) |
|---|---|---|
| Shape | the body morphs into the feeling's own shape (M3 shapes measured alike, blended on a spring that pops past a little) | Sunny / GhostIsh (droops) / Burst (spikes) / Heart / SoftBoom (wobbly) / Arch (curled up) |
| Colour | crossfade to a role from the theme, never a fixed hex, never a bounce | tertiary container / secondary container / error container / tertiary / body / body |
| Size | a spring on scale | 1.06 / 0.9 / 1.14 (puffed up) / 1.08 / 1 / 0.97 |
| Face | brows, eyes, mouth | squint + smile / brows up + tears + frown / brows down + frown / squint + hearts / eyes going round / shut + z's |

- One feeling at a time, ended by a timer (sad ~2.4 s, happy ~1.8 s), and moods override gaze
  (sad looks down, happy up).
- Every input it could notice gets an answer: a key (a tiny bob), a deletion (a flinch), wrong
  (sad: the big one, because it's rare), right (happy), a click on it (startled).
- Sleep only after a real idle period (10–20 s with no input), not whenever a field is empty:
  "empty" is exactly when it should be looking at the user.

## Let people pick it up

A character you can only look at is decoration; one you can pick up is a toy. Let the pointer
take it: it dangles while held (stretched, eyes wide and down, an "o" mouth, feet kicking),
squashes when put down, and gets dizzy when thrown hard. The host decides where it may go
(along its ring's inner edge, anywhere on a lock screen), and remembers the spot.

Two traps in QML (both met building this):
- **Petting with a hovering MouseArea steals the hover** from whatever the character sits on;
  a container that closes when the pointer leaves it then closes. Detect resting / petting with
  a `HoverHandler` (it shares the hover) and keep the MouseArea for presses only.
- **A press on the character still makes the container think the pointer left**, and the exit
  arrives before the press is registered. The character should say `hovered` and `pressed`, and
  the container shouldn't close on leave while either is true.

## Hide a few secrets

Secrets are what make people play with a character, and tell each other about it. Keep them:
- found by play, never by reading (no menu, no hint): five quick pokes make it cross; resting the
  pointer on it makes it love you; throwing it makes it dizzy; its name makes it glad; woken in the
  small hours it yawns;
- cheap (the same channels as any feeling) and short (a few seconds, then back to normal);
- never in the way: a secret never blocks a task, never fires during one, and **never depends
  on what is typed into a secret field** (nothing about a password may change how it looks);
- written down for maintainers (a "Spoilers" section in the project notes), so nobody removes
  one as a bug.

## Reduced motion

The face still tells the story with nothing travelling: the eyes look away or at the user (an
instant change), the shape, the colour and the face show the feeling, nothing breathes, bobs,
runs, tumbles or swings. A still character that changes expression is the calm version of a
character, never a hidden one.

## Don'ts

- Never cover content or a field with the character, and never make it the only signal (the
  wrong-password text still says so).
- No reaction that waits for the previous one to finish: retarget the springs.
- No face that stares at a fixed point while the user acts, and no sleeping while they're there.

## In this repo

`shared/Mascot.qml` (linked into all three shells, with `shared/m3shapes.js`: the M3 paths and
their measuring) has the layers: `look` (tracking, in its own frame), `shy`, `run` (the hamster's
run), `asleep`, `mood` ("happy", "sad", "angry", "love", "dizzy"), `react("type" | "delete" |
"wrong" | "right" | "name" | "dizzy" | "land" | "poke")`, the feelings' colours (`happyColor`,
`sadColor`, `angryColor`), `interactive` / `draggable` (`grabbed`, `dragTo(p)`, `dropped(vx, vy)`;
`hovered`, `pressed`, `held`), and `calm` for reduced motion. `look: Qt.point(0, -0.35)` is eye
contact (it cancels the googly pupils' resting droop). The control center's hamster
(`quickshell/ControlCenter.qml`, `hiding`) and the lock's (`quickshell/lock/LockSurface.qml`,
`keeper`) show the wheel, the keep-clear (`dial.keepClear`, `ReaderCard`) and the remembered
spot (`MascotSpots.qml`).
