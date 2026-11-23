# Motion recipes

Small, reusable answers to "make this react". QML first (the dial shell's tokens), then the
same idea for the web. Each one names the rule it serves: weight, reaction, continuity, limits,
state.

## Contents
1. Press squish (reaction)
2. Hover lift (reaction)
3. Selection that grows on a spring (weight, continuity)
4. Shake on wrong or at a limit (limits)
5. Rubber band past an end (limits)
6. Crossfade a value that changes (continuity)
7. Count a number up (continuity)
8. Staggered entrance (continuity, personality)
9. Breathing "live" indicator (idle life)
10. Pop when a value changes elsewhere (reaction to the world)

## 1. Press squish
```qml
scale: squish.value
SpringValue {
    id: squish
    to: mouse.pressed ? 0.92 : 1
    stiffness: Vars.springs.expressive.fast.spatial.stiffness
    dampingRatio: Vars.springs.expressive.fast.spatial.dampingRatio
    epsilon: 0.001
}
```
Web: `transition: transform 250ms cubic-bezier(0.42, 1.67, 0.21, 0.9)` with `:active { transform: scale(.92) }`.
Squish 0.9–0.95: smaller reads as broken.

## 2. Hover lift
A state layer (primary at 8%) plus a 2–4 px lift or a 4% scale, on the effects curve for the
layer and the spatial curve for the lift. Never a sound.

## 3. Selection that grows on a spring
The pattern `ControlTile.qml` uses: `scale: grow.value` with `grow.to: selected ? big : small`.
A spring keeps its speed when the selection moves on mid-growth (a fast spin), where a curve
would restart from rest and stutter.

## 4. Shake on wrong or at a limit
```qml
SpringValue { id: shaker; stiffness: Vars.shakeSpring.stiffness; dampingRatio: Vars.shakeSpring.dampingRatio; epsilon: 0.05 }
x: base + shaker.value
// on the event:
shaker.kick(Vars.kickFor(6, Vars.shakeSpring))   // first swing 6 px
```
Once per event, never on a timer. Reduced motion: flash the error colour instead.

## 5. Rubber band past an end
Resistance that grows and caps (`KnobRing.rubber()`): `max * (1 - exp(-over * k / max))`. Drop
hand movement past ~95% of the cap so turning back answers at once.

## 6. Crossfade a value that changes
Two labels stacked; the outgoing fades out while sliding 4 px away, the incoming fades in from
4 px the other side (effects curve for opacity, fast spatial for the slide). Cheaper than it
sounds and removes the most common teleport.

## 7. Count a number up
`NumberAnimation on shown { to: value; duration: 200 }` on a real property, displayed rounded.
Only for numbers that change by more than one step at a time.

## 8. Staggered entrance
Items of a ring or list come in 20–30 ms apart (index × delay), each on the spatial curve. Total
under 300 ms or it reads as slow. Skip under reduced motion.

## 9. Breathing "live" indicator
Opacity 0.6 → 1 over 1.2 s, infinite, only `running: visible && !Prefs.calm`. Only on something
that is actually live (recording, playing, connecting).

## 10. Pop when a value changes elsewhere
The knob's `bump()`: scale 1 → 1.12 in 60 ms, back in 300 ms, on the fast spatial curve. Tells
the user "this moved, not because of you" (volume keys, another app).
