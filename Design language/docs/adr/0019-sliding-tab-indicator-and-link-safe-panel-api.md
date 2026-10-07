# ADR 0019: First sliding-indicator infrastructure, and a link-safe, optionally-paneled Tabs API

Status: accepted
Date: 2026-07-20
Task: T19

## Context

The pinned AndroidX revision (`225f50d42bf0adeb2abf4b6109befb5ab6ce4efc`,
still the branch's current HEAD since T17/T18) implements tabs across
`Tab.kt` (`Tab`/`LeadingIconTab` composables, `role = Role.Tab` via
`Modifier.selectable`, `TabBaselineLayout`'s baseline-relative stacked
icon-above-label layout at `LargeTabHeight` (72dp) when both are present)
and `TabRow.kt` (`PrimaryTabRow`/`SecondaryTabRow`/their scrollable
variants, `TabRowDefaults.PrimaryIndicator`/`SecondaryIndicator`,
`Modifier.tabIndicatorOffset` animating a shared indicator's position and,
for `matchContentSize = true`, its width, using
`MotionSchemeKeyTokens.DefaultSpatial`). `PrimaryNavigationTabTokens`
supplies the indicator's own color/height/shape and active/inactive
label/icon color; `SecondaryNavigationTabTokens` supplies only
label/icon/divider color (no indicator fields of its own — the source's
`SecondaryIndicator` reads the primary token file directly) plus the
secondary variant's own, deliberately non-brand-colored active tint.

The component inventory names one export, `Tabs`/`TabsProps`, matching
this library's established data-driven-array precedent rather than the
pinned source's separate `Tab`/`TabRow`/indicator/divider composable
family.

## Decision

1. One public, data-driven `Tabs` component: `items: readonly TabItem[]`
   (`{ value, label?, icon?, disabled?, href?, panel? }`), extending the
   Menu/SegmentedButtonGroup data-array precedent to a fourth/fifth
   component. `aria-label`/`aria-labelledby` describe the `role="tablist"`
   region, the same required-naming contract SegmentedButtonGroup's own
   `role="radiogroup"`/`role="group"` already has.
2. **First sliding-indicator infrastructure in v1**: no prior component
   measures and animates a shared element between sibling positions (Menu/
   Select/Tooltip's shared `useAnchoredOverlay` positions one popover
   relative to one anchor; this positions one indicator relative to
   whichever of several sibling tabs is currently selected). A plain
   `useEffect` — not `useLayoutEffect` — measures the selected tab's own
   bounding rect (or, for `'primary'`, its inner content-wrapper rect, to
   reproduce `matchContentSize = true`) relative to the tablist container,
   applied as the indicator's `transform`/`inline-size`; a `ResizeObserver`
   plus a window `resize` listener keep it correct across reflow. `plain
   useEffect over useLayoutEffect` is deliberate: `Tabs` renders its full
   DOM tree during server rendering, unlike Menu/Snackbar's client-only
   portal, so `useLayoutEffect` would emit React's server-rendering
   warning for a one-frame positioning delay nobody would perceive on an
   always-rendered, non-portaled element. This logic stays local to
   `Tabs.tsx` rather than a new shared `src/internal` primitive, since
   no other planned component needs it; a future one that does can prompt
   extraction then, the same "don't extract ahead of a second caller"
   discipline this project already follows elsewhere.
3. The indicator's own transition uses the sourced `DefaultSpatial` motion
   slot, not `FastSpatial` like every prior overlay-entrance task (Menu/
   Select/Tooltip/Snackbar) — this is a content-shift transition between
   sibling positions, not an overlay's own entrance/exit, and the pinned
   source itself specifically animates `tabIndicatorOffset` with
   `MotionSchemeKeyTokens.DefaultSpatial`, not `FastSpatial`.
4. `'primary'` (default) renders the short, rounded, content-hugging
   indicator (`24dp` default width before any real measurement,
   `ActiveIndicatorHeight` 3dp, `ActiveIndicatorShape`
   `RoundedCornerShape(3dp)`, tinted `primary`); `'secondary'` renders a
   full-tab-width underline reusing the identical
   `ActiveIndicatorColor`/`Height` pair, since
   `SecondaryNavigationTabTokens` defines no indicator fields of its own.
   Active content tints `primary` for `'primary'` but stays plain
   `onSurface` for `'secondary'` — a genuine, sourced visual distinction
   (secondary tabs are deliberately more subdued), not an oversight.
5. **Link-safe API**: an item with `href` renders a real
   `<a role="tab" href>` instead of `<button role="tab">`. Arrow-key
   movement still updates the local selected/indicator state (the APG
   tabs pattern's own automatic-activation model, applied purely
   visually), but actual navigation is left entirely to the browser's
   native anchor behavior (Enter or click) — arrow keys never synthesize a
   navigation. This lets a consumer drive `Tabs` from a router's current
   route (`value` as a controlled prop reflecting the active route)
   without `Tabs` owning any routing concept itself, matching this
   library's consistent "no router/framework dependency" boundary. A
   disabled `href` item omits the `href` attribute entirely rather than
   attempting a CSS-only disabled affordance, since anchors have no native
   disabled state the way buttons do.
6. **Panels**: an item with `panel` gets one `role="tabpanel"` region for
   the selected item only, associated via `id`/`aria-controls`/
   `aria-labelledby`. If no item defines `panel` at all — a pure
   link-tabs/external-page-switch usage — `Tabs` renders no tabpanel
   region whatsoever, since a router owns the destination content in that
   case. This dual mode (in-place content switching vs. pure navigation)
   is resolved per-item rather than via a separate top-level prop, since a
   real application can plausibly mix the two (e.g., most tabs switch
   local panels, one opens an external help page).
7. Row height is `48px` (`ContainerHeight`/`SmallTabHeight`) unless any
   item combines both `icon` and `label`, in which case the whole row uses
   `72px` (`LargeTabHeight`, the value `TabBaselineLayout` actually reads —
   not the token file's unread `64px` `IconAndLabelTextContainerHeight`).
   The source's separate side-by-side `LeadingIconTab` composable (icon
   beside, not above, the label) is excluded — `Tabs` only supports the
   stacked combined layout, the same "one clean composition over several
   alternate overload variants" precedent prior tasks already applied
   (e.g. Card's convenience overloads, Menu's folded checked-item
   overloads).
8. A full-width divider renders under the tablist for both variants,
   reading `SecondaryNavigationTabTokens.DividerColor`/`DividerHeight`
   even though the pinned source's own default `divider` composable for
   *both* `PrimaryTabRow`/`SecondaryTabRow` is actually a generic,
   non-tab-specific `HorizontalDivider()` — this project surfaces the
   actually-defined, traceable token value instead of an untraceable
   system-generic one, the same "prefer the specific sourced value"
   reasoning used throughout.
9. Disabled tabs dim to the universal `onSurface`-at-`0.38`-opacity
   treatment every other v1 interactive component already uses. The
   pinned source has no disabled color axis at all for tabs (`enabled`
   removes interactivity only; `TabTransition`'s color interpolation takes
   only a `selected` axis) — this is a deliberate, documented web addition
   for visual disabled communication, the same basis Menu's
   `FocusIndicatorColor` registration and Checkbox/Radio's own disabled
   treatments already used.
10. ArrowLeft/ArrowRight never flip meaning under RTL — the same
    no-JS-direction-branching precedent `Menu`/`Select`'s physical-
    coordinate positioning and `overlayPosition.ts`'s own start/end
    resolution already established; Left always means "previous" and
    Right always means "next" by DOM order, matching this codebase's
    existing convention rather than introducing a new one.
11. T19 is the first task since the T17 ceiling raise whose measured public
    JavaScript closure exceeds a bundle-budget ceiling. Per §11.3 of
    `docs/SPEC.md`, this is that recorded decision. As at T13/T15/T17,
    several other artifacts had already drifted to single-digit headroom
    even though only the JavaScript closure actually breached (declaration
    closure 1.5% remaining, its gzip 1.6%, JavaScript gzip 2.6%, full-CSS
    gzip 3.6%, full CSS 5.4%), so every artifact receives fresh headroom in
    the same proportion (roughly 12% above the new baseline) rather than
    only the one that breached:

    - packed package: 341,763 bytes; ceiling raised 359,000 → 385,000;
    - public v1 JavaScript closure: 218,865 bytes / 38,483 gzip; ceiling
      raised 216,000 → 246,000 / 39,500 → 43,500;
    - public v1 declaration closure: 58,591 / 14,856 gzip; ceiling raised
      59,500 → 66,000 / 15,100 → 17,000;
    - full CSS: 243,198 / 22,390 gzip; ceiling raised 257,000 → 273,000 /
      23,200 → 25,000;
    - token CSS: 99,368 / 8,592 gzip; ceiling raised 108,000 → 112,000; the
      gzip ceiling (9,500) already had adequate headroom (10.6% remaining)
      and is unchanged, the same pattern T15/T17 recorded for this exact
      metric.

    The pre-task reference is the T18 Tooltip/Snackbar commit
    `8d01a5f578a9c3547690ceb6f313231fd0c6db0f`. The increase comprises 25
    sourced `tabs` component tokens, one new public component, and the
    first sliding-indicator measurement/`ResizeObserver` infrastructure —
    genuinely new logic, not just markup, the same category of growth
    T17's shared overlay primitives caused.

## Consequences

- A future component needing to slide a shared element between sibling
  positions (unlikely among the remaining task list, but plausible for a
  future navigation indicator) has this task's `Tabs.tsx` measurement
  logic as a working reference to extract from, rather than starting from
  nothing — the same forward-looking posture ADR 0017 recorded for
  `useAnchoredOverlay`.
- The link-safe API's contract (`Tabs` never navigates on its own) is a
  hard boundary: a future enhancement must not make arrow-key navigation
  "helpfully" follow a link automatically, since that would silently break
  any consumer relying on manual Enter/click-only activation for
  `href`-carrying tabs.
- The per-item `panel` opt-in means a consumer mixing local-panel tabs and
  external-link tabs in one `Tabs` instance gets exactly the tabpanel
  region a local tab needs and none for a link tab, with no extra prop to
  reconcile the two modes.
- Every raised ceiling sits at roughly the same ~12% headroom above its new
  baseline; a task with comparably large JavaScript or CSS may need another
  recorded budget decision within a few tasks, consistent with the cadence
  T10 through T17 already showed.
