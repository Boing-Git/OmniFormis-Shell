---
name: lively-ux
description: Makes boring, dead-feeling interfaces lively with motion, feedback, reactions and a bit of personality, and audits a UI for where it feels static or unresponsive. Use it whenever the user says a UI feels boring, dead, flat, static, stiff, lifeless, robotic or "not alive", asks for animation, bounce, springs, overshoot, squash and stretch, micro-interactions, hover or press feedback, juice, delight, playful or fun, transitions, or wants empty, loading, error and success states that feel alive. Use it too for any mascot, character, avatar or face in a UI (where it looks, how it reacts to typing, a password, a wrong or right answer, a ring or slider being turned), or when one "feels like a sticker" or decoration. Also use it when building or changing any interactive UI (Quickshell/QML, web, GTK, a game menu), even if the user doesn't say "lively". It covers motion and feedback; for uniqueness, brand and premium feel it hands over to gux-expert, and for game feel to game-expert.
---

# Lively UX

A lively interface feels like it notices you. Two things make the difference, and almost every fix
comes back to one of them:

1. **Things that move have weight.** A move that stops dead (a linear or ease-out tween with no
   overshoot) reads as a slide on rails. A spring that overshoots a little and settles reads as an
   object with mass. Bounce is what makes motion feel alive, so spatial moves (position, size,
   rotation, scale, shape) ride springs with some overshoot.
2. **Everything answers the hand.** If the user does something and nothing changes, the UI is dead
   at that spot, however pretty it is. Every input gets an answer within ~100 ms: hover, press,
   release, drag, scroll, typing, focus, and especially the limits (the end of a list, a wrong
   password, a value that can't go higher).

Everything below serves those two, with a third that keeps them from turning into noise:

3. **Life is sized to the moment.** The 500th use wants the quiet version. Big, bouncy motion
   belongs to rare moments (opening, success, a first time); the frequent, tiny actions get a
   small, fast answer. A UI where everything wobbles all the time is as dead as one where nothing
   moves, because the eye stops reading it.

## How to work

1. **Walk it with your hands, not your eyes.** For each interactive thing on the surface, list
   what the user can do to it (hover, press, drag, scroll, type, release, reach a limit) and what
   currently happens. Read the real code: the Behaviors, springs, state changes and handlers.
   A blank cell in that table is a finding.
2. **Audit with the checklist below**, collecting evidence as `file:line`.
3. **Pick one hero motion per interaction** (usually position or shape) and let the rest be fast,
   non-bouncing effects. Rank findings by how often the user hits them: a dead hover on the most
   used button beats a missing flourish on a settings page.
4. **Write the change in the project's own tokens** (next section), never new magic numbers. If
   the project says UI changes are the user's to make (a CLAUDE.md may say so), teach the change:
   file, line, the concept, a small snippet, what to tweak. Otherwise implement it.
5. **Check the calm path.** Turn reduced motion on and check that every answer still happens, as
   a fade or an instant change instead of travel.

## The liveliness checklist

- **Reaction**: hover shows something (a state layer, a lift, a cursor); press shows something
  different (squish, darker layer); release finishes it. A drag follows the hand exactly, with no
  lag. Scroll moves at once and keeps momentum.
- **Continuity**: nothing teleports. A thing that changes state travels or morphs from where it
  was (the same element, not a swap). Lists insert and remove with motion, not a jump.
- **Weight**: spatial moves on springs with a little overshoot; colour and opacity on curves
  without any (a bouncing colour looks broken, not lively).
- **Anticipation and follow-through**: a big move can dip back before it goes, and things that
  stop can settle with a small wobble. Rarely both on the same move.
- **Limits answer**: the end of a ring rubber-bands, a wrong input shakes, a full value bumps.
  Hitting a wall silently is the most common dead spot.
- **States are alive**: loading moves (and moves *towards* something), success celebrates
  briefly, error shakes once, empty states say something warm and point to the next action.
- **Characters are actors, not stickers**: a mascot or face tracks continuous input every frame
  (the pointer, a turning ring), meets the user's eyes when they're idle, looks away while a
  secret is typed, and answers every key. Read `references/characters.md` before touching one.
- **Idle life only where it means something**: a breathing "live" dot, a slow drift on a playing
  track. An idle animation that means nothing is decoration and tires the eye.
- **Sound and haptics** (if the platform has them) sized to the event: a tick per detent, nothing
  for hover, never more often than the eye can follow (~40 a second).

## This repo's motion tokens (the dial shell, Dotfiles/quickshell)

Use these instead of numbers; they already follow the user's Bounce and Speed settings.

| Need | Use | Notes |
|---|---|---|
| A size, position, rotation or scale change | `Prefs.fastSpatial` (quick) / `Prefs.defaultSpatial` (bigger moves) | `{ duration, bezier }`; with Bounce 0 they turn calm by themselves. Never `Vars.expressive*Spatial` directly |
| Colour, opacity | `Vars.expressiveFastEffects` / `Vars.expressiveDefaultEffects` | no overshoot, ever |
| A value that keeps its speed when retargeted (selection moving mid-spin, a knob) | `SpringValue { to; stiffness; dampingRatio }` with `Vars.springs.expressive.fast.spatial` | `kick(v)` adds velocity; damping ≥ 1 when `Prefs.calm` |
| A dial opening | `Prefs.openSpring` | the user's Bounce and Speed |
| A shake (wrong, limit) | `Vars.shakeSpring` + `shaker.kick(Vars.kickFor(px, Vars.shakeSpring))` | see `primitive/SearchBar.qml`, `controlcenter/KnobRing.qml` |
| One shape becoming another | `ShapeMorph` | M3 shapes morph on a spring when `shape` changes |
| Rubber band at an end | `KnobRing.rubber()` pattern | resistance grows, capped |
| Ticks | `Prefs.tickGain(dt)` | quieter in a fast spin and while music plays |

Elsewhere (web, GTK, another QML project) start from M3 Expressive's springs: fast spatial
damping 0.6 / stiffness 800, default spatial 0.8 / 380, effects damping 1 (no overshoot).

## Reduced motion

Reduced motion removes travel and overshoot, never the answer. The user still sees that
something happened, as a fade or an instant change of state.

- In this repo the calm switch is Bounce 0 (`Prefs.calm`): springs run at damping ≥ 1, the two
  spatial curves turn calm, overshoot flourishes (wiggles, the springy loading morph) skip. New
  motion follows the same switch: read `Prefs.calm`, or use the tokens above that already do.
- Every spring needs a fade fallback, every morph a crossfade, every shake a colour flash.
- Idle loops stop entirely under reduced motion.

## Performance budget

Lively that drops frames is worse than still. On a 240 Hz screen a frame is 4 ms.

- Animate transform, scale, rotation and opacity. Avoid animating things that relayout every
  frame (anchors, implicit sizes of text, a Repeater's model).
- No live effects per item (blur, shadow, MultiEffect); on Qt 6.12 MultiEffect masks also crash
  the shell. Pre-render or use the shader the project already has.
- Idle animations run only while visible (`running: visible && !Prefs.calm`), never on a Timer
  that keeps firing behind a closed dial.
- A spring with an `epsilon` stops; one without may tick forever.
- Measure, don't guess: watch the frame rate and the process's CPU/GPU while it plays
  (`scripts/tests/glass-bench.sh` in this repo shows how).

## Before and after

Real cases from this repo; `references/tested-screens.md` has three whole screens audited,
`references/motion-recipes.md` the reusable recipes, and `references/characters.md` how to make a
mascot or face feel like someone (layers, gaze, coupling to a turning ring).

**A size that stops dead** (no weight):
```qml
// before: a fixed curve with no overshoot, on a spatial change
Behavior on width { NumberAnimation { duration: 200 } }
// after: the shared spatial curve (overshoots a little, calm with Bounce 0)
Behavior on width { NumberAnimation { duration: Prefs.fastSpatial.duration; easing.type: Easing.BezierSpline; easing.bezierCurve: Prefs.fastSpatial.bezier } }
```

**A button that ignores the press** (no reaction):
```qml
// before: only `onClicked`, the shape never changes
// after: it squishes while held and springs back on release
scale: press.value
SpringValue { id: press; to: area.pressed ? 0.92 : 1; stiffness: Vars.springs.expressive.fast.spatial.stiffness; dampingRatio: Vars.springs.expressive.fast.spatial.dampingRatio; epsilon: 0.001 }
```

**A text that swaps in one frame** (a teleport): crossfade the old and new value (two labels, the
effects curve), and if the value is a number, let it count over 200 ms.

## Anti-patterns

- Bouncing colour or opacity.
- Everything moving at once on one interaction (the eye reads noise; pick the hero).
- A delay before the response, or a response that waits for the animation to finish. Input
  stays live during every animation: retarget the spring, don't queue.
- Big overshoot on the most frequent action (it becomes a tax by the 50th time).
- Idle loops that mean nothing, or never stop.
- Motion that hides content the user came for (a celebration over the result).
- Lively by sound alone: a click without a visible change still feels dead.

## Hand-overs

- Uniqueness, brand, premium feel, colour weight (60:30:10), hierarchy: **gux-expert**. Ask it
  when the question is "does this feel premium / like mine", ask this skill when it's "does this
  feel alive / does it answer".
- Game feel (hit stop, screen shake, rewards, juice in a game): **game-expert**.
