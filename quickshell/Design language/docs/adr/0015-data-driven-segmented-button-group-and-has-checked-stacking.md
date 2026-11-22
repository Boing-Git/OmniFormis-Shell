# ADR 0015: Data-driven SegmentedButtonGroup, `:has()`-driven stacking, and a fresh bundle-budget raise

Status: accepted
Date: 2026-07-20
Task: T15

## Context

The pinned AndroidX revision (`225f50d42bf0adeb2abf4b6109befb5ab6ce4efc`)
defines `SegmentedButton` as two nearly identical `@Composable` extension
functions scoped to `MultiChoiceSegmentedButtonRowScope`/
`SingleChoiceSegmentedButtonRowScope`, each meant to be called as a child of
the matching row composable
(`MultiChoiceSegmentedButtonRow`/`SingleChoiceSegmentedButtonRow`). Those row
composables exist to do three things for their children: apply
`Arrangement.spacedBy(-BorderWidth)` so adjacent borders overlap instead of
doubling, apply `.selectableGroup()` (single-choice only, giving
`Role.RadioButton` semantics their intended group meaning), and let each
child compute its own shape via `SegmentedButtonDefaults.itemShape(index,
count, baseShape)` — `baseShape.start()` for index 0, `.end()` for the last
index, `RectangleShape` otherwise, `baseShape` itself when `count == 1`.

Each `SegmentedButton` renders through the shared `Surface(checked =
..., onCheckedChange = ...)`/`Surface(selected = ..., onClick = ...)`
overloads, stacks with `z-index = interactionCount + (checked ?
CheckedZIndexFactor(5) : 0)` so a checked or currently-interacting segment's
border paints over an idle neighbor's, and renders an icon slot via
`SegmentedButtonDefaults.Icon`: with no `inactiveContent` supplied, only the
checkmark (`Icons.Filled.Check`, defined in this revision's own
`androidx.compose.material3.internal.Icons`, not the classic
`material-icons-core` artifact) ever appears, entering with
`AnimatedVisibility(enter = fadeIn(DefaultEffects) + scaleIn(0f →
1f, transformOrigin = (0f, 1f), FastSpatial), exit = ExitTransition.None)`;
with an `inactiveContent` supplied, the two crossfade symmetrically via
`Crossfade(DefaultEffects)`. A custom `SegmentedButtonContentMeasurePolicy`
animates the label's horizontal offset with its own `Animatable<Int>` (using
`FastSpatial`) whenever the icon column's width changes, keeping the
icon+label ensemble centered as a unit as the icon reveals or hides.

`defaultSegmentedButtonColors()` (`ColorScheme.kt`) resolves every color role
from `OutlinedSegmentedButtonTokens`: the active and inactive border both
read the identical `OutlineColor` constant; the disabled active and disabled
inactive content both read the identical `DisabledLabelTextColor`/
`DisabledLabelTextOpacity` pair; the disabled active container reuses the
enabled `SelectedContainerColor` undimmed (no disabled container role exists
in the token file at all); and the icon is never tinted explicitly, so it
always inherits whatever `LocalContentColor` the label text resolved,
leaving `SelectedIconColor`/`UnselectedIconColor`/`DisabledIconColor`/
`DisabledIconOpacity` and every `Hover*`/`Focus*`/`Pressed*`-suffixed role in
the token file completely unread.

## Decision

1. One public, data-driven `SegmentedButtonGroup` component replaces the
   pinned source's two-composable-plus-child-scope API. A
   `segments: readonly { value, label, icon?, disabled? }[]` prop lets the
   component compute each item's own index and count directly — exactly
   what the sourced row composables compute for their children — with no
   `Children.map`/context indirection needed. This also matches the single
   export the component inventory already named for this task.
2. `multiple` (default `false`) selects single-choice or multi-choice mode.
   Single-choice renders one native `<input type="radio">` per segment
   sharing one `name` (`useId()`-generated when the caller supplies none),
   the direct web equivalent of the pinned source's own `Role.RadioButton`
   choice for this mode — native mutual exclusivity and roving-tabindex
   keyboard behavior come for free, with no custom keyboard handling.
   Multi-choice renders independent `<input type="checkbox">` controls
   sharing one `name`, so `FormData.getAll(name)` yields every checked value
   natively. `value`/`defaultValue`/`onValueChange` are `string` in
   single-choice mode and `readonly string[]` in multi-choice mode,
   discriminated by the `multiple` literal so the two shapes cannot be
   mixed at the type level.
3. Each segment's shape is driven by a computed `data-m3e-position`
   (`start`/`middle`/`end`/`only`) using the four logical corner-radius
   properties (`border-start-start-radius`, `border-start-end-radius`,
   `border-end-start-radius`, `border-end-end-radius`) — the web equivalent
   of `baseShape.start()`/`.end()`/`RectangleShape`/`baseShape`, and RTL-safe
   by construction since logical properties, not physical ones, carry the
   start/end distinction.
4. Adjacent segments overlap by exactly one border width via a negative
   logical margin, reproducing `Arrangement.spacedBy(-BorderWidth)`.
   Stacking order is the ordinal flattening of `interactionCount + (checked
   ? CheckedZIndexFactor : 0)` into a small fixed scale (0 idle, 1
   interacting, 2 checked, 3 checked-and-interacting) driven by
   `:has(:checked)`, `:hover`, `:active` (which already bubble to ancestors
   under plain CSS, needing no `:has()`), and `:has(:focus-visible)`. The
   same relative ranking survives — a checked segment always outranks a
   merely-interacting neighbor — without literally counting simultaneous
   interactions. `:has()` is supported at this library's pinned Firefox 121
   floor (the version that first shipped it), so no browser-matrix change
   is needed to rely on it here, extending its use beyond ADR 0014's
   text-field notch to selector-level state composition.
5. Checked, hover, press, and focus visuals are read from the native
   input's own pseudo-classes reached through `:has()`/sibling combinators,
   not a React-rendered attribute — the same native-truth precedent ADR
   0012 established for Radio, since single-choice mode has the exact same
   sibling-desync exposure (the browser unchecking a sibling radio fires no
   event on that sibling). `disabled` is the only state mirrored onto a
   segment root as a `data-m3e-*` attribute, because it is fully determined
   by props on every render (group-level `disabled` or a segment's own
   `disabled`) and nothing outside this component instance can change it
   without a re-render — the same safety argument ADR 0014 made for
   TextField's `error`/`disabled`.
6. The checkmark reproduces
   `androidx.compose.material3.internal.Icons.Filled.Check` as a static
   inline SVG path (`M9 16.17L4.83 12l-1.42 1.41L9 19 21 7l-1.41-1.41z`,
   sourced from this revision's own internal vector data, not the classic
   `material-icons-core` artifact) — a solid filled glyph, not the Checkbox
   stroke-draw polyline technique, because that is what the pinned source
   itself paints here. A segment without a supplied `icon` shows only that
   checkmark, entering with a fade+scale transition
   (`transform-origin: 0% 100%`, matching the sourced `TransformOrigin(0f,
   1f)`) and disappearing with no exit transition, matching
   `AnimatedVisibility(exit = ExitTransition.None)` exactly: the base
   (unchecked) rule carries `transition: none` so reverting out of the
   `:checked` selector snaps instantly. A segment with a supplied `icon`
   keeps a constant-width icon column whose content crossfades
   symmetrically between the icon and the checkmark via a plain two-way
   opacity transition, matching `Crossfade`.
7. The sourced `Animatable<Int>`-driven horizontal content recentering when
   the icon column's width changes is reproduced as a CSS width/margin
   transition on the icon column inside a centered flex row, not a ported
   measure policy — the same spring/custom-layout-to-CSS-transition
   flattening every prior component in this library has already applied at
   this layer.
8. Every color role the source reads from one identical upstream constant
   for both active/inactive or both disabled call sites is registered once
   instead of as a pair — the active/inactive border (`OutlineColor` both
   times) and the disabled content color/opacity (`DisabledLabelTextColor`/
   `DisabledLabelTextOpacity` both times) — matching the T14 content-color
   consolidation precedent. The disabled active container needs no
   dedicated token at all: it reuses the enabled `active-container-color`
   token undimmed, and the disabled inactive container reuses the same
   `Color.Transparent` literal the enabled inactive container already
   expresses directly in the stylesheet (matching the Button/IconButton/
   Checkbox transparent-literal precedent, not a registered token). Every
   `Hover*`/`Focus*`/`Pressed*`-suffixed role, and even the base
   `SelectedIconColor`/`UnselectedIconColor`/`DisabledIconColor`/
   `DisabledIconOpacity` roles, are left unregistered: the icon is never
   tinted explicitly in the pinned source, so it always inherits the same
   content-color custom property the label text resolves.
9. No `minimumInteractiveComponentSize`-equivalent modifier is added. The
   pinned source applies no such modifier to `SegmentedButton`, unlike
   Checkbox/Radio/Switch, so the rendered control stays at its sourced 40px
   height with no 48px touch-target wrapper.
10. T15 is the first task since the T13 ceiling raise whose measured output
    exceeds a bundle-budget ceiling — full CSS at 217,199 bytes against a
    215,000 ceiling, plus a smaller JavaScript and declaration overshoot.
    Per §11.3 of `docs/SPEC.md`, this is that recorded decision. As at
    T13, every artifact receives fresh headroom in the same proportion
    (roughly 11-13% above the new baseline) rather than raising only the
    breached ones, since the token-CSS ceiling was also down to single-digit
    headroom (93,208 of 100,000 bytes, 6.8% remaining) and the packed-package
    ceiling was similarly tight (292,949 of 300,000, 2.4% remaining):

    - public v1 JavaScript closure: 161,996 bytes / 29,274 gzip; ceiling
      raised 160,000 → 180,000 / 30,000 → 33,000;
    - public v1 declaration closure: 46,571 / 11,850 gzip; ceiling raised
      46,000 → 52,000 / 13,000 → 13,300;
    - full CSS: 217,199 / 19,360 gzip; ceiling raised 215,000 → 245,000 /
      19,000 → 22,000;
    - token CSS: 93,208 / 7,932 gzip; ceiling raised 100,000 → 105,000; the
      gzip ceiling (9,500) already had adequate headroom and is unchanged;
    - packed package: 292,949 bytes; ceiling raised 300,000 → 330,000.

    The pre-task reference is the T14 TextField/TextArea commit
    `a348f0bf5f22df3c290a01f4d53b3624b236d849`. The increase comprises 15
    sourced `segmented-button-group` component tokens, one new native
    control with per-segment shape/stacking/crossfade CSS, and the inline
    checkmark SVG — comparable in scale to Switch's own T13 addition.

## Consequences

- Consumers describe an entire segmented control with one `segments` array
  and one `value`/`onValueChange` pair; there is no compound-children API to
  learn, and adding, removing, or reordering segments needs no manual
  `key`/shape bookkeeping.
- Single-choice mutual exclusivity, roving-tabindex keyboard behavior, and
  multi-choice independent toggling are all native `<input>` behavior with
  zero JavaScript selection logic in this component.
- The checked/hover/press/focus-driven container color and stacking order
  stay correct even when a native radio-group side effect changes a
  sibling's checked state with no event firing on that sibling, the same
  guarantee ADR 0012 established for bare Radio.
- `:has()` is now used for a second, structurally different purpose beyond
  ADR 0014's notch (selector-level ancestor state composition rather than a
  layout technique), reinforcing that this library's pinned browser floor
  was chosen, at least in part, with `:has()` availability in mind.
- Future grouped-control tasks (`ButtonGroup`/`SplitButton` in T23) have a
  direct precedent for reproducing the pinned source's `interactionCount +
  checked`-style z-index stacking with a small ordinal `:has()`-driven scale
  instead of literally counting interactions.
- The full CSS budget is again the tightest of the five bundle artifacts
  after this raise (217,199 of 245,000 bytes, ~89% used); a task with
  comparably large CSS may need another recorded budget decision within a
  few tasks, consistent with the cadence T10 through T13 already showed.
