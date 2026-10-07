# ADR 0013: Native Switch role, thumb-anchored ripple, and pressed-shape motion

Status: accepted
Date: 2026-07-20
Task: T13

## Context

AndroidX publishes one `Switch` composable taking `checked`/`onCheckedChange`,
an optional `thumbContent` icon slot, and a bespoke `ThumbNode` layout
modifier that animates the thumb's own size and inset directly, rather than
delegating to a generic transform. Two behaviors make this the most
geometrically complex control implemented so far:

1. The thumb's diameter itself changes with state — 16px at rest, 24px when
   checked or carrying `thumbContent`, 28px while pressed — and its inset
   changes correspondingly so it stays flush against the near or far track
   edge at every size.
2. The thumb's own size/inset animation uses `MotionSchemeKeyTokens.FastSpatial`
   normally, but snaps to a zero-duration `SnapSpec` specifically while a
   press is active, so pressing down is instant and releasing animates back
   out — an asymmetry, not a single spec.

HTML has no switch input type interoperable across this library's supported
browser matrix. WAI-ARIA APG's own Switch pattern is built on
`input type="checkbox" role="switch"`, and ARIA-in-HTML confirms that role is
allowed on a checkbox input with its accessible checked state still derived
from the native `checked` property — no explicit `aria-checked` required.

`SwitchTokens` also generates Hover/Focus/Pressed-suffixed handle, track, and
icon color roles that `SwitchColors`/`defaultSwitchColors` never read, and
the pinned `ripple()` call for the thumb's state layer carries no explicit
per-state color, exactly the same unread-token and ambient-ripple-color
shapes already resolved for Checkbox and Radio.

## Decision

1. One `Switch` export renders one native `input type="checkbox"
   role="switch"`, forwards its ref to that input, and owns no label,
   supporting text, error state, size, or variant that the pinned first-party
   API does not define.
2. `role` is fixed the same way `type` already is: omitted from the public
   prop type so a caller cannot override the accessible mapping this
   component depends on.
3. `thumbIcon?: ReactNode` reproduces the pinned `thumbContent` slot. Its
   presence is computed once from this component's own render into
   `data-m3e-has-thumb-icon`, which is safe to key CSS off directly — unlike
   Radio's checked state, nothing external can change it without this
   component re-rendering. A T13 geometry repair makes the slot reproduce the
   source's `contentAlignment = Alignment.Center` and documented
   `SwitchDefaults.IconSize`: direct v1 `Icon`, SVG, and image artwork is
   centered and constrained to 16×16px inside the 24px icon-bearing handle.
4. Every thumb inset is expressed with `calc()` directly on the registered
   `track-width`/`track-height`/`track-outline-width`/handle-size tokens,
   adapting `ThumbNode.measure`'s outer-box formulas rather than pre-computing
   opaque pixel offsets. CSS absolute positioning starts at the bordered
   track's padding box, already one 2px outline width inward; each resting
   formula therefore subtracts that consumed outline once, the near pressed
   inset becomes zero, and the far pressed formula subtracts it twice. This
   preserves the source's outer starts (8/4/24px resting and 2/22px pressed)
   while keeping the token relationship visible in the stylesheet.
5. The state layer is a pseudo-element on the thumb, not the track, centered
   on the thumb's own position via `inset: 50%` plus `translate: -50% -50%`,
   matching the source attaching its ripple `Modifier.indication` to the
   `ThumbElement` rather than the track `Box`.
6. The press-driven size/inset transition duration is overridden to zero
   only while `:active` matches, reproducing the source's own
   `if (isPressed) SnapSpec else animationSpec` guard: pressing down snaps
   instantly, and releasing the press falls back to the base rule's normal
   fast-spatial transition.
7. Colors follow the same conventions Checkbox and Radio already established:
   the unread Hover/Focus/Pressed-suffixed roles are not registered; the
   ambient, colorless `ripple()` call is given a concrete
   primary/on-surface-variant identity pairing instead; and a token-backed
   focus ring is drawn from the (this time literal, sourced)
   `FocusIndicatorColor` secondary role.
8. Disabled colors use the `color-mix(..., transparent)` technique already
   established for Checkbox and Radio instead of the source's
   `compositeOver(colorScheme.surface)`, so a disabled Switch composites
   correctly against whatever backdrop it actually sits on.
9. `DisabledTrackOpacity` is one source constant read by three different
   disabled roles (checked track, unchecked track, unchecked border); it is
   registered once and reused, rather than duplicated per role the way
   Checkbox's genuinely distinct opacity constants were kept separate.
10. Error state, sizes, and label/supporting-text slots are excluded until a
    separately sourced contract defines them.
11. T13 is the first task since the ceilings were set at T10 whose measured
    JavaScript closure exceeds its ceiling — 144,103 bytes against a 144,000
    ceiling, a 103-byte overshoot. Per §11.3 of `docs/SPEC.md`, "bundle
    budgets... may change only through a recorded decision"; this is that
    decision. Rather than raise only the one breached ceiling, every artifact
    receives fresh headroom in the same proportion T04 through T10 used when
    they last grew the ceilings (roughly 10-15% above the new baseline),
    since CSS and declaration headroom were also down to single-digit
    percentages and would very likely block T14 otherwise:

    - public v1 JavaScript closure: 144,103 bytes / 26,736 aggregate gzip;
      ceiling raised 144,000 → 160,000 / 28,000 → 30,000;
    - public v1 declaration closure: 40,503 / 10,525 aggregate gzip; ceiling
      raised 43,000 → 46,000 / 12,000 → 13,000;
    - full CSS: 193,224 / 16,567 gzip; ceiling raised 197,000 → 215,000 /
      17,000 → 19,000;
    - token CSS: 88,795 / 7,513 gzip; ceiling raised 97,000 → 100,000 /
      8,500 → 9,500;
    - packed package: 273,441 bytes; ceiling raised 294,000 → 300,000.

    The pre-task reference is the T12 Radio commit
    `88f0c159968839195c45d3ec09423baa4e98a846`. The increase comprises 27
    sourced Switch component tokens, the native control, and its explicit
    state stylesheet — the largest single-component CSS addition since
    Checkbox, driven by the thumb's four-way size/inset `calc()` geometry.

## Consequences

- Consumers get real form participation and browser-owned keyboard behavior
  without the library reimplementing any of it, and `role="switch"` requires
  no manual `aria-checked` bookkeeping.
- The thumb's size/inset formulas stay legible and auditable against the
  source's own measure function and CSS containing-block semantics, instead of
  hiding the same relationship behind precomputed magic-number tokens.
- Default v1 `Icon` artwork no longer overflows the 16px thumb-content slot or
  inherits its 24px standalone size; raw direct SVG/image artwork follows the
  same centered slot geometry.
- The pressed-shape snap-vs-animate asymmetry is reproduced with zero
  JavaScript, entirely through native `:active` plus a scoped
  `transition-duration` override.
- The library does not claim a `RadioGroup`-style container, an error state,
  or Expressive sizes that the current first-party implementation does not
  provide.
