# The lock screen: five concepts

For Dial-E first (its lock is `quickshell/lock/`), with a variant for Puffy and Droplet. Written
with the gux-expert skill: the ideas come from the shell's own grammar, so they could only
exist here. Recommendation at the end. Nothing is built yet: the lock is yours to design
(quickshell/CLAUDE.md), and it is the one surface where a bug locks you out.

## The grammar they grow from

- **Nouns**: dials (circles out of a spot), rings that turn, beads (one M3 shape per thing),
  gems on a mark, the sheet that grows out of a spot, liquid glass, the mascots.
- **Verbs**: peek, grow out of a spot, spin, tick, morph, flick away.
- **Laws**: everything is a circle out of a spot; the centre of a dial is "now"; one ring
  turns, one notch per thing, with a tick; nothing teleports.

Today's lock already follows them: a sheet out of the power dial's spot, a whole-circle dial,
the password ring turning a notch per letter. It is a good first concept (the safe dial), so
the five below go somewhere else, and every one keeps the same PAM path, the same crash-safe
re-lock and the same "no unlock call by design".

## 1. Eclipse: the clock gives its beads to the password

**Idea.** The time fills the dial as large dot-matrix digits made of M3 beads (this is the
"interactive dot matrix" from the todo). The beads drift a little towards the pointer.

**Typing.** Each letter pulls one bead out of the digits into the password ring: the clock
thins as the password grows, so you see your progress without seeing a single character.
**Wrong**: the beads fly back into the digits and the ring shakes once (Vars.shakeSpring).
**Right**: every bead flies out to the corner it belongs to and becomes the dials of the
desktop: lock and desktop are one continuous object.

**Glass, dots, mascot.** The dial's disc is liquid glass over the wallpaper (the same Liquid
settings); the dot matrix is the clock; the mascot isn't needed (the beads are the character).

**Per shell.** Puffy: the beads are its spikes. Droplet: drops that pool into the ring.

**Performance and security.** ~60 beads as one Shape or a Repeater of rectangles: cheap. The
digits show nothing new (the time). Bead count leaks the password length, as every dotted
field does; a setting can show a fixed number of beads instead.

**Effort.** Medium: a DotMatrix of beads (reusable for the media visualizer), the flight paths
on springs, and the hand-over to the dials on unlock.

## 2. Mascot guard

**Idea.** The running shell's mascot sleeps on the lock, breathing. A key wakes it.

**Typing.** Each letter: Dial-E's pupils draw together in concentration, Puffy puffs a notch,
Droplet fills a little. **Wrong**: Dial-E shakes its head (the pupils swing), Puffy deflates
with a pop of spikes, Droplet splashes. **Right**: it cheers and shrinks into its corner.

**Glass, dots, mascot.** The mascot sits on a glass disc; the clock above it in dots.

**Per shell.** Built in: the mascot is the shell.

**Performance and security.** `Mascot.qml` exists already. Nothing private shown. Watch for
the 500th unlock: the wake and cheer must be short, and calm under Bounce 0.

**Effort.** Low: the mascots exist; the work is the lock's states mapped to theirs.

## 3. Lens reveal

**Idea.** The whole screen is frosted glass (Lock sheet: Liquid glass, built today). A small
clear lens follows the pointer, showing the wallpaper sharp beneath it.

**Typing.** The lens grows a notch per letter. **Wrong**: it snaps back small and frosts over.
**Right**: it opens until it is the whole screen, and the frost is gone: the desktop is just
there, unblurred.

**Glass, dots, mascot.** All glass; a dot-matrix clock etched into the frost.

**Per shell.** Droplet: the lens is a drop of water on the glass.

**Performance and security.** One full-screen shader (the glass already is one). The lens shows
only the wallpaper, never the windows.

**Effort.** Low to medium: the lock's glass sheet with a second, inverted disc.

## 4. Glance gems

**Idea.** "At a glance" (Nothing's lesson) on the dial's own vocabulary: media, battery, the
next calendar event, the number of notifications waiting, as gems resting on the ring.

**Typing.** The ring turns as you type and the gems step aside, one per letter. **Wrong**: they
roll back. **Right**: each gem flies to the dial it belongs to (media to the control center).

**Glass, dots, mascot.** Gems of glass; numbers in dots.

**Per shell.** Puffy: the gems are the bar's own pills.

**Performance and security.** A privacy setting hides contents (a gem shows "3", not who wrote).
Notification contents never show: counts only.

**Effort.** Medium: data sources exist (Notifs, Mpris, UPower).

## 5. Tide

**Idea.** The lock is water. The level rises from the bottom a notch per letter, with a ripple.

**Typing.** Wrong drains it with a wobble; right overflows, and the water runs off into the
corners where the dials are. Droplet's own lock; for Dial-E it is a ring that fills.

**Effort.** Medium, and the most likely to tire: water on every keystroke.

## Recommendation: 1, Eclipse, with 2's mascot only at the edges

Eclipse is the one that could exist nowhere else: it is made of the shell's own beads, it gives
the todo's dot matrix a real job, and its unlock is continuous with the desktop (the beads become
the dials) instead of a sheet going away. Its frequent part (a bead per letter) is small and
quiet; its rare parts (wrong, right) carry the character. The mascot from 2 can appear only on
wake and on the first unlock of the day, so it never becomes a tax.

To build it safely: in the hidden test session first (it locks for real there, with a test PAM
stack), keep today's lock as the fallback behind a setting until it passes, and keep the TTY
escape in CONTEXT.md at hand.

**Ask**: what isn't good about today's lock (looks, speed, the typing, missing information)?
The choice between these depends on it.
