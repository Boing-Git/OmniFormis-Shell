# ADR 0014: Shared TextField/TextArea foundation, native-truth label float, and segmented outline

Status: accepted
Date: 2026-07-20
Amended: 2026-07-21 (T14 outlined-geometry, TextArea resize, and shared-content repairs)
Task: T14

## Context

The pinned AndroidX revision (`225f50d42bf0adeb2abf4b6109befb5ab6ce4efc`)
defines `TextField`/`OutlinedTextField` with **no distinct multiline
composable** — `lineLimits`/`singleLine` select multiline behavior on the
exact same composables, sharing 100% of their label/cutout/indicator/icon/
supporting-text decoration (`TextFieldDefaults`/`OutlinedTextFieldDefaults`,
`CommonDecorationBox`, `TextFieldMeasurePolicy`). `SecureTextField`/
`OutlinedSecureTextField` in the same revision establish the source's own
precedent for building a specialized input mode this way: swap the
underlying text-input primitive (`BasicSecureTextField` for
`BasicTextField`) while reusing the decoration layer unchanged.

The label animates between a large resting state (centered, `bodyLarge`
type) and a small floating state (top-aligned or border-straddling,
`bodySmall` type) driven by a 3-way `InputPhase` derived from both focus and
has-text state, with a continuous `lerp(bodyLarge, bodySmall, progress)`
`TextStyle` interpolation animated by a spring (`MotionSchemeKeyTokens.FastSpatial`).

The outlined variant's border gap around the floating label is drawn by
rendering a full rounded stroke, then clipping a label-width rectangle out
of it with `drawWithContent` + `ClipOp.Difference` (`Modifier.outlineCutout`),
sized to the label's own measured width plus a 4dp margin on each side.

The initial T14 web adaptation used a native `fieldset`/`legend` to obtain an
intrinsic-width gap. Browser verification after T14 found that a fieldset's
painted top stroke follows the legend's special layout rather than the
fieldset border box used to position the separate visible label. This placed
the painted top edge and label in different block-axis coordinate systems.
The same implementation also kept a leading icon's 52px expanded-label inset
after the outlined label minimized, although the pinned measure policy moves
that minimized label back to the ordinary 16px start padding. Decision 6
below supersedes the original fieldset/legend adaptation.

Browser verification during the 2026-07-21 T14 repair exposed a second
transposition defect in the shared horizontal layout. AndroidX measures the
48dp leading/trailing icon placeables separately, subtracts their widths from
the text-control constraints, and places the text control after the leading
placeable. Material Web likewise renders distinct `.start`, `.middle`/
`.content`, and `.end` flex regions. The v1 adaptation instead stretched the
native input across the complete field underneath absolutely positioned icons
and depended on a single 52px `padding-inline-*` declaration to move its
content clear. Because component CSS is intentionally layered, a representative
unlayered native-control reset could override that padding and put the caret at
the field edge beneath the icon. It also left the native control's own region,
including browser-owned affordances, underneath trailing decoration even when
the text happened to be padded clear.

The same audit exposed the corresponding block-axis defect. The port encoded
the source's filled 8px + 16px label / 24px input / 8px bottom placement and
outlined 16px / 24px / 16px placement as native-control padding. An unlayered
form-control reset therefore removed the vertical reservation and put the
value/caret into the label. AndroidX instead measures and places label and
input as separate placeables; its filled input starts exactly at
`topPadding + labelPlaceable.height` (8dp + the 16dp body-small line).

Every content color role (input, placeholder, label, leading icon, trailing
icon, supporting text) is identical between `FilledTextFieldTokens` and
`OutlinedTextFieldTokens` — Kotlin has no shared-token-file mechanism, so
AndroidX repeats each constant under both names rather than defining it
once. Disabled colors resolve as true alpha
(`fromToken(...).copy(alpha = ...)`), unlike the `compositeOver(colorScheme.surface)`
pattern seen in Checkbox, Radio, and Switch. `FilledTextFieldTokens.DisabledContainerColor`/
`DisabledContainerOpacity` are defined but never read by
`ColorScheme.defaultTextFieldColors()`, so a disabled filled field keeps a
full-opacity container in the pinned source despite the token file
documenting a dimmed one.

## Decision

1. One internal `TextFieldChrome` primitive under `src/internal` renders
   the label, indicator/outline, icon, and supporting-text decoration once.
   `TextField` and `TextArea` each supply only their own native control
   (`input`/`textarea`) as that primitive's first child. This is the direct
   web equivalent of the pinned source's own shared decoration layer and
   `SecureTextField` precedent, not a bonus abstraction — the task's own
   required result is a "shared field foundation."
2. `variant: 'filled' | 'outlined'` reproduces the two sourced defaults —
   `Inside` label position for filled, `Cutout` for outlined.
   `TextFieldLabelPosition.Above`, deprecated `Attached`, and the
   provisional Expressive `roundedShape`/`tonalColors()` are excluded: the
   pinned source itself marks the latter two `TODO(b/448727879): reference
   the actual token once it is in place`, with no shipped token yet, so
   claiming them would not be reproducing a stable source.
3. The label's floating position and type size are read from the control's
   own native `:focus`/`:placeholder-shown` pseudo-classes, not
   React-rendered state — the same native-truth precedent ADR 0012
   established for Radio's checked state, extended here from a discrete
   boolean to a continuous has-value signal. A value change made outside a
   normal input event (browser autofill, a form reset, an imperative ref
   write) still repositions the label correctly, because the browser, not
   this component's last render, is the source of truth for
   `:placeholder-shown`.
4. A non-empty native `placeholder` (a single space when the caller
   supplies none) is required for `:placeholder-shown` to ever match; this
   is what makes decision 3 possible. The same attribute is reused for the
   caller's actual placeholder text, shown only while focused via a
   `::placeholder` color transition, matching the pinned source's own
   placeholder slot visibility rule.
5. The label's continuous `lerp(bodyLarge, bodySmall, progress)` spring
   interpolation is reproduced as a CSS transition between the theme's own
   baseline `body-large` and `body-small` typescale roles' concrete
   font-size/line-height/letter-spacing values, using the semantic
   fast-spatial motion token in place of the spring — the same
   spring-to-token-driven-transition flattening every other component's
   motion already uses at this layer, applied here to a typographic
   property set instead of a transform.
6. The outlined variant uses three logical CSS flex panels rather than a
   native `fieldset`/`legend` or a canvas clip. A `visibility: hidden` clone
   of the label at the floating body-small type size gives the center panel
   its intrinsic width. That panel always draws the bottom stroke and draws
   its top stroke only while the label rests; focus or a populated value
   scales the top stroke away to reveal the label-sized gap. The start and
   end panels draw the remaining rounded outline against the field's own
   border box. The floating label and cutout start at the ordinary 16px
   content padding even with a leading icon, while the input and expanded
   label retain the sourced 48px icon slot plus 4px gap (52px). This matches
   the pinned AndroidX placement formulas and Material Web's first-party
   segmented-outline adaptation with no JS measurement.
7. Every content color role registers once, unprefixed, instead of a
   `filled-*`/`outlined-*` pair that would only ever hold identical values;
   only the container fill/shape and the indicator/outline border — where
   the two token files' values genuinely differ, including the outlined
   border's own 0.12 disabled opacity versus every other role's shared
   0.38 — are registered per variant.
8. `error` and `disabled` are the only two states mirrored onto the field
   root as `data-m3e-*` attributes rather than read from a native pseudo
   class. `error` has no native HTML equivalent at all. `disabled` could be
   read from `:disabled` for the chrome nested inside `.m3e-text-field__field`
   (and is, via sibling combinators, exactly like focus and has-value) but
   supporting text sits one DOM branch outside that box, unreachable by a
   plain sibling combinator; mirroring `disabled` onto the root is safe
   specifically because — unlike Radio's checked state — nothing outside
   this component instance can change it without a re-render.
9. Disabled colors use this library's established `color-mix(..., transparent)`
   technique. Unlike Checkbox, Radio, and Switch, this is not a deviation
   from the pinned source here: the pinned source's own disabled colors are
   already true alpha, not pre-composited over a fixed backdrop, so
   `color-mix(..., transparent)` reproduces the pinned source's semantics
   exactly.
10. The pinned source's unread `FilledTextFieldTokens.DisabledContainerColor`/
    `DisabledContainerOpacity` are reproduced as unread here too: a
    disabled filled field keeps its full-opacity container, matching
    `defaultTextFieldColors()`'s actual behavior rather than the token
    file's documented, unapplied value.
11. No custom `warnForInvalidProps` is added for controlled/uncontrolled
    value misuse, unlike Checkbox/Radio/Switch. Those components need one
    because their custom `useControllableState` hook bypasses React's own
    warning. `TextField`/`TextArea` pass `value`/`defaultValue` straight
    through to a plain native `input`/`textarea`, so React's built-in
    development warning for conflicting `value`/`defaultValue` already
    covers this case with no duplicate warning needed.
12. `TextArea` renders a native `textarea` through the same
    `TextFieldChrome` primitive and the same `.m3e-text-field__input` class
    used by `TextField`, so every shared CSS rule applies unchanged. The
    pinned measure policy centers a single-line resting label but starts a
    multiline resting label at the ordinary 16px top padding; a
    `data-m3e-multiline` selector reproduces that branch. Leading/trailing
    icon slots continue to use the shared vertically centered placement,
    matching the source placing both icons with `Alignment.CenterVertically`
    regardless of `singleLine`. Its native vertical resize handle is retained,
    and `rows` remains the native content-row height. The shared block grid
    contributes the fixed Material edge regions around that row while retaining
    native vertical resizing.
13. This project's stylesheet assembler (`assembleAuthoredCss` in
    `scripts/build-styles.mjs`) inlines every `@import` with no
    deduplication. Because `styles.css` must import both `TextField.css`
    and `TextArea.css` directly (the architecture check requires each
    conformant component's own stylesheet to be assembled), the shared
    chrome rules live in `TextField.css` alone; `TextArea.css` contains
    only its native `resize: vertical` delta, layering on top within the
    same cascade layer rather than re-declaring shared rules a second time.
14. Bundle budgets are unchanged from T13's ceilings; measured output
    (154,653 / 28,045 gzip JS; 44,338 / 11,358 gzip declarations; 208,286 /
    18,494 gzip full CSS; 91,974 / 7,820 gzip token CSS; 284,749 packed)
    fits within them, so no recorded ceiling change is needed this task.
15. The shared field now projects AndroidX's separately measured icon/control
    placeables and Material Web's start/middle/end regions into three logical
    CSS grid tracks. An ordinary edge track is the sourced 16px content
    padding; an icon-bearing edge track is the sourced 48px minimum interactive
    target plus 4px content gap. The native input/textarea occupies only the
    middle track with zero inline padding, so its caret, text, placeholder, and
    browser-owned affordances retain exact 16px/52px geometry even when a
    downstream reset changes native-control padding. The control stays first in
    DOM order so all native-truth sibling selectors remain intact. Because it
    no longer spans the complete field, an empty, `aria-hidden` native `label`
    associated through `htmlFor` covers the field behind the z-indexed control
    and visible label, preserving whole-field click-to-focus/activation without
    adding JavaScript or accessible-name content. The outlined floating label
    continues to override its start and maximum width back to the ordinary 16px
    cutout coordinate, while filled/resting labels consume the resolved edge
    tracks.
16. Block geometry is likewise projected into structural grid rows instead of
    native-control padding. Filled uses a 24px start row (8px top inset plus the
    minimized 16px label line), a minimum 24px native-control row, and an 8px
    end row. Outlined uses 16px / 24px / 16px. The control has zero block
    padding and occupies only the middle row, so unlayered
    `input, textarea, button { padding: 0 }` resets cannot move content into the
    label. Multiline `rows` and native resize grow that middle row; resting and
    floating labels retain their existing source-aligned positions.

## Consequences

- `TextField` and `TextArea` share their entire visual contract through one
  primitive and one stylesheet owner, matching the task's required result
  and the pinned source's own architecture, rather than two independently
  maintained decoration trees that could silently drift apart.
- The floating label, the notch, and the placeholder visibility rule are
  all reproduced with zero JavaScript and zero measurement, entirely
  through native pseudo-classes, intrinsic CSS flex sizing, and CSS
  transitions — consistent with every prior selection control's zero-JS
  state precedent, now extended to a continuous (not just discrete) native
  signal.
- Future form-control tasks that need label/description/error anatomy
  (e.g. `Select` in T17) have a direct, already-adversarially-considered
  precedent for extending or reusing this shared foundation rather than
  reinventing floating-label mechanics from scratch.
- Native controls and their browser-owned affordances no longer overlap icon
  slots. TextField, TextArea, and Select inherit that guarantee from one shared
  layout, and representative input/textarea resets cannot collapse their
  horizontal content origin back beneath a leading icon.
- Native-control resets can no longer collapse the source's vertical
  label/value placement. Filled, outlined, single-line, multiline, and Select
  consumers all inherit the same structural block rows.
- The full CSS budget's remaining headroom is the tightest of the five
  bundle artifacts (208,286 of 215,000 bytes, ~97% used); a task with
  comparably large CSS may need a recorded budget decision sooner than the
  other artifacts.
