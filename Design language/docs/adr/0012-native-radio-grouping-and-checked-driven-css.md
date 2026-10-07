# ADR 0012: Native Radio grouping, checked-driven CSS, and motion asymmetry

Status: accepted
Date: 2026-07-20
Task: T12

## Context

AndroidX publishes one `RadioButton` composable taking `selected`/`onClick`.
Compose has no native concept of a shared control group; the source's own
doc comment shows `RadioButton`s achieving "radio group-like behaviour" only
by composing several instances inside an ordinary layout with caller-owned
selection state. HTML already models exactly this with `<input type="radio">`
sharing a `name`: the browser owns mutual exclusivity and roving arrow-key
focus for free.

The pinned source paints its outer ring and inner dot with one shared
`radioColor` value and animates them with two independently gated specs: the
dot's `animateDpAsState` scale runs unconditionally, while `radioColor()`'s
`animateColorAsState` only runs while `enabled`, snapping to
`rememberUpdatedState` while disabled.

While implementing the behavior test for native mutual exclusivity, two
uncontrolled `Radio`s sharing a `name` exposed a real defect: clicking one
correctly deselects its sibling at the DOM level (`sibling.checked` becomes
`false`), but the browser fires no `change`/`input` event on the sibling that
lost selection, so a purely React-state-driven `data-m3e-state` attribute on
that sibling's own root stayed `"checked"` until something else caused that
sibling to re-render.

## Decision

1. One `Radio` export renders one native `input type="radio"`, forwards its
   ref to that input, and owns no label, supporting text, error state, size,
   or variant that the pinned first-party API does not define.
2. `name` is a required prop rather than an optional native pass-through.
   Grouping is this task's required result, and a nameless radio cannot form
   a group.
3. The controlled/uncontrolled prop is named `checked`/`onCheckedChange`, not
   Compose's `selected`/`onClick`, matching the native `HTMLInputElement` IDL
   property and this library's existing `Checkbox` shape.
4. A decorative root wrapper owns the 48px target, the resolved state
   attributes, and the consumer `className`/`style`; every other prop belongs
   to the input, matching the Checkbox precedent for a decorative visual
   sibling next to a semantic native control.
5. **CSS keys checkedness and disabledness off the input's own `:checked` and
   `:disabled` pseudo-classes, not off `data-m3e-state`/`data-m3e-disabled`.**
   The root still carries those attributes, computed from this component's
   own resolved state, for deterministic server markup and test/assistive
   convenience, but no styling rule depends on them. This is a correctness
   requirement, not a style preference: since a sibling in the same native
   group can be deselected with no event firing on it, only a pseudo-class
   the browser itself maintains is guaranteed live-accurate for every radio
   in a group, independent of which one last re-rendered.
6. No `RadioGroup` wrapper is implemented. Native grouping through a shared
   `name` already supplies mutual exclusivity and roving keyboard focus.
7. The dot's scale-in/out reproduces the source's unconditional
   `animateDpAsState` as a `transform: scale()` transition that runs
   regardless of disabled state. The shared icon color reproduces the
   source's enabled-only `animateColorAsState` by removing its own transition
   whenever `:disabled` matches, snapping immediately, exactly mirroring the
   source's `rememberUpdatedState` fallback.
8. The pinned source paints the ring and dot from one `radioColor` value, so
   one icon-color role per state (selected, unselected, disabled-selected,
   disabled-unselected) covers both shapes instead of separate roles.
9. Two documented deviations restore required web behavior: the state layer
   uses the same-state icon-color role because the pinned `ripple()` call
   carries no explicit per-state color, and a token-backed focus ring is
   drawn from the secondary role because the source defines no RadioButton
   focus-indicator token at all, matching the Checkbox precedent for both.
10. Error state, sizes, and a `RadioGroup` orchestration component are
    excluded until a separately sourced contract defines them.
11. T12 re-measures the post-build baselines against the T11 ceilings and
    changes no ceiling, because every artifact stays inside the headroom T11
    recorded:

    - public v1 JavaScript closure: 136,798 bytes / 25,984 aggregate gzip;
      ceiling 144,000 / 28,000;
    - public v1 declaration closure: 39,055 / 10,281 aggregate gzip; ceiling
      43,000 / 12,000;
    - full CSS: 183,651 / 15,706 gzip; ceiling 197,000 / 17,000;
    - token CSS: 86,737 / 7,331 gzip; ceiling 97,000 / 8,500;
    - packed package: 267,427 bytes; ceiling 294,000.

    The pre-task reference is commit `0c24d9d86ee6ef97e80583f532e031f324c57294`
    (the run-v1-playground skill, landed after the T11 Checkbox commit
    `6a67180`). The increase comprises 14 sourced Radio component tokens, the
    native control, and its explicit state stylesheet.

## Consequences

- Consumers get real form participation, native grouping, and browser-owned
  keyboard behavior without the library reimplementing any of it.
- Visual correctness for grouped radios no longer depends on every instance
  in a group re-rendering when a sibling changes; the browser's own
  `:checked` state is the single source of truth for style.
- The `data-m3e-state`/`data-m3e-disabled` attributes remain useful for
  deterministic server markup and tests, but are documented as non-styling
  signals for this component, unlike Checkbox where they are load-bearing.
- The library does not claim a `RadioGroup` component, an error state, or
  Expressive sizes that the current first-party implementation does not
  provide.
