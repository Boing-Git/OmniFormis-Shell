# ADR 0011: Native Checkbox tri-state, geometry, and check-draw motion

Status: accepted
Date: 2026-07-19
Task: T11

## Context

AndroidX publishes `Checkbox` and `TriStateCheckbox`, where the former delegates
to the latter through `ToggleableState`. Neither overload accepts a label, a
size, or an error parameter, and the generated `CheckboxTokens` error roles are
never read by the implementation. HTML models the same three states on one
element: `checked` is an attribute and property, while `indeterminate` is a
property that cannot be serialized and is cleared by the browser on activation.

The pinned source is mid-migration. `ComposeMaterial3Flags.isCheckboxStylingFixEnabled`
still defaults to false, so two geometries and two checkmark polylines are live
in the same file, with an open `TODO(b/188529841)` on the older constants.

Unlike Button, IconButton, and FAB, this component has no shape morph. Its only
expressive behavior is a checkmark reveal driven by `PathMeasure.getSegment` and
a gravitation that interpolates the checkmark into the indeterminate dash.

## Decision

1. One `Checkbox` export renders one native `input type="checkbox"`, forwards
   its ref to that input, and owns no label, supporting text, error state, size,
   or variant that the pinned first-party API does not define.
2. A decorative root wrapper owns the 48px target, the resolved state
   attributes, and the consumer `className`/`style`; every other prop belongs to
   the input. The wrapper exists because a faithful checkmark needs a real SVG
   child, which an input element cannot contain.
3. `indeterminate` is a controlled prop, not owned state. It renders
   `aria-checked="mixed"` and a state attribute in server markup, applies the
   DOM property after hydration, and is reapplied on every commit. Activation
   resolves the control to a browser-owned checked value and the consumer clears
   the prop, mirroring Compose's caller-owned `ToggleableState` transitions.
4. Controlled `checked` stays authoritative. Uncontrolled `defaultChecked`
   leaves checkedness to the DOM so native form reset still works, and a reset
   listener resynchronizes the resolved visual state.
5. Geometry follows the token-backed `CheckboxTokens` path: 18px container, 2px
   corner, 2px outline, 2px checkmark stroke, 40px state layer. This matches the
   generated tokens and the direction of the upstream fix; the record notes that
   AndroidX still ships the older 20dp-plus-2dp geometry.
6. The outline is an inset ring rather than a CSS border so the 18px box stays
   exact and the checkmark viewBox shares one coordinate space with it.
7. The checkmark is an SVG polyline whose reveal uses a stroke dash and whose
   indeterminate morph animates the `d` property between two paths with
   identical command structure. Both reproduce the sourced coordinates exactly.
   Leaving the drawn states reproduces `snap(delayMillis = 100)` as a
   zero-duration transition after the same delay.
8. All thirteen first-party color roles are registered. The three transparent
   roles stay CSS `transparent` because the source uses `Color.Transparent`
   literals rather than tokens for them, and the two 0.38 opacity constants stay
   separate tokens because the source reads them from two different names.
9. Two documented deviations restore required web behavior: the unchecked state
   layer uses the unselected outline role instead of the source's transparent
   `indicatorColor` result, and a token-backed focus ring is drawn from the
   otherwise unread `FocusIndicatorColor` secondary role.
10. Error state, sizes, stroke overloads, and parent/child group orchestration
    are excluded until a separately sourced contract defines them.
11. T11 re-measures the post-build baselines against the T10 ceilings and
    changes no ceiling, because every artifact stays inside the headroom T10
    recorded:

    - public v1 JavaScript closure: 131,373 bytes / 25,388 aggregate gzip;
      ceiling 144,000 / 28,000;
    - public v1 declaration closure: 37,743 / 10,088 aggregate gzip; ceiling
      43,000 / 12,000;
    - full CSS: 178,464 / 15,198 gzip; ceiling 197,000 / 17,000;
    - token CSS: 85,791 / 7,241 gzip; ceiling 97,000 / 8,500;
    - packed package: 264,716 bytes; ceiling 294,000.

    The pre-task reference is T10 commit
    `5ecf3b0891474cc5c913c157b6f9c929d465946b`. The increase comprises 28
    sourced Checkbox component tokens, the native control, and its explicit
    state stylesheet.

## Consequences

- Consumers get real form participation, native labelling, and browser-owned
  keyboard behavior without the library reimplementing any of it.
- Mixed state stays honest across server and client because the assistive
  signal does not depend on a property that cannot be serialized.
- Ref composition became a shared internal primitive, which Radio, Switch, and
  the field components in T12 through T14 will reuse.
- Components whose visual is not expressible on the semantic element itself now
  have a precedent for a decorative wrapper that owns only class, style, and
  state attributes.
- The library does not claim Expressive checkbox geometry, sizes, or an error
  state that the current first-party implementation does not provide.
