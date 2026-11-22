# ADR 0008: Native Expressive IconButton and toggle state

Status: accepted
Date: 2026-07-19
Task: T08

## Context

Current AndroidX Material 3 exposes standard, filled, filled-tonal, and outlined
icon actions and parallel toggle overloads. Its Expressive defaults add five
size tiers, three width options, round/square resting shapes, a pressed shape,
and selected shapes that invert the round/square silhouette. AndroidX models
toggle state through Compose selection semantics and separate callbacks;
Material Web models the distinction explicitly with toggle and selected state.

On the web, an icon-only action must remain a named native button. Momentary and
toggle buttons must be distinguishable in the accessibility tree without
replacing native Enter, Space, forms, disabled behavior, or event cancellation.
Controlled/uncontrolled state and event ordering will also recur in later v1
controls.

## Decision

1. `IconButton` always renders a native `<button>`, defaults to `type="button"`,
   and forwards the `HTMLButtonElement` ref and relevant native props. Links,
   tooltip ownership, menus, FAB behavior, and custom keyboard activation are
   excluded.
2. Literal unions expose standard/filled/tonal/outlined variants; five current
   Expressive sizes; narrow/uniform/wide visual widths; and round/square shapes.
   The semantic root independently reserves the theme's 48px target.
3. Momentary mode is the default and omits `aria-pressed`. `toggle={true}`
   enables either controlled `selected` plus required `onSelectedChange`, or
   uncontrolled `defaultSelected` plus an optional callback. Toggle state maps
   to boolean `aria-pressed`, not Compose's checkbox role, because the WAI-ARIA
   toggle-button pattern is the native web contract.
4. The default and optional selected visual slots remain mounted in stable
   source order and are hidden as one decorative subtree. The button requires
   `aria-label` or `aria-labelledby`; the label stays stable while
   `aria-pressed` communicates state.
5. Consumer `onClick` runs before internal selection. `preventDefault()` is the
   cancellation signal, so a consumer can reject a state change or native form
   action through the existing event contract. Two named internal primitives
   centralize this ordering and controlled/uncontrolled state for later
   controls.
6. Per-size component tokens retain exact generated dimensions: heights
   32/40/56/96/136px; narrow widths 28/32/48/64/104px; uniform widths
   32/40/56/96/136px; wide widths 40/52/72/128/184px; icons
   20/24/24/32/40px; and outlines 1/1/1/2/3px.
7. Round resting and selected-square radii use exact half-heights so CSS can
   interpolate them. Square, pressed, and selected-round shapes retain their
   system corner-role references. Pressed takes visual precedence over
   selected while active.
8. Shape and color transitions consume the existing Expressive default-effects
   spring projection. Reduced motion makes transitions immediate. Forced colors
   provides visible borders and uses Highlight/HighlightText for selection.
9. T08 records the complete post-build baselines and explicit ceilings:

   - public v1 JavaScript closure: 104,671 bytes / 21,935 aggregate gzip;
     ceiling 121,000 / 25,500;
   - public v1 declaration closure: 31,104 / 8,935 aggregate gzip; ceiling
     37,000 / 11,000;
   - full CSS: 144,587 / 12,161 gzip; ceiling 167,000 / 14,500;
   - token CSS: 77,164 / 6,546 gzip; ceiling 89,000 / 7,800;
   - packed package: 243,145 bytes; ceiling 280,000.

   The pre-task reference is T07 commit
   `9c5a04dcca8d8f25b43eedb62f39807987f16fa0`. The increase comprises 85
   sourced IconButton component tokens, the native toggle runtime and shared
   state/event primitives, and the explicit four-variant/five-size/three-width
   stylesheet. The ceilings restore measured task headroom and remain checked
   against aggregate imported closures.

## Consequences

- React consumers get the complete current Expressive IconButton geometry and
  predictable toggle behavior without React Aria, an animation runtime, an icon
  registry, or a framework adapter.
- `toggle` is an explicit semantic mode. A false `selected` value is not
  confused with a momentary button, and invalid mixed modes are rejected by
  public types and warned about for untyped runtime callers.
- Native click cancellation composes with internal behavior once. Upcoming
  switches, segmented buttons, and composite controls can reuse the small
  internal primitives rather than inventing event/state conventions.
- Selected shape is still applied while disabled, but disabled colors take
  precedence. Selected outlined toggles have no outline, matching the pinned
  first-party border function.
- Alternate selected artwork remains optional to match first-party behavior;
  documentation recommends it when a standard toggle would otherwise
  communicate visual state only through color.
