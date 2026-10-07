# Architecture

## Product boundary

This package is a framework-neutral React implementation of Material 3
Expressive for general use. Private downstream applications are not architectural layers or
API sources, and their internals are not recorded in this public repository.
ADR 0025 records the information boundary between public package contracts and
private consumer data.

React and React DOM are the only framework peers. Next.js and Vite are
development fixtures used to prove portability in an SSR framework and a
framework-neutral client application. Source, public types, and public APIs must
not import or expose either fixture framework. The published package declares no
runtime dependencies at all.

## Dependency direction

Dependencies flow downward only:

```text
public entry points
        |
components and providers
        |
theme and motion services
        |
internal web/React primitives
        |
serializable types and token data
```

- `types/` and `tokens/` must not depend on React, DOM globals, or components.
- `internal/` may depend on types and tokens.
- `theme/` and `motion/` may depend on types, tokens, and internal primitives.
- `components/` may depend on those foundation layers. A component may consume
  another component only through that component's public `index.ts`.
- `index.ts` assembles the public API and must not contain implementation logic.
- Nothing in `src/` may import from outside `src/`.

The `check:architecture` command enforces the rules that can be checked
statically without interpreting component behavior.

## Token foundation

`src/tokens/schema.ts` is the canonical inventory for every foundation token
domain and path. Runtime validation, reference resolution, public types, default
data, and CSS generation derive from that inventory. Token data stays JSON-like,
and parsing returns an independent deeply frozen value.

Defaults live in one file per domain under `src/tokens/defaults/`. Source
revisions and web adaptations are recorded in `docs/TOKEN_PROVENANCE.md` and
cross-cutting policy in ADR 0002. A later component task adds tokens through the
typed component registry only after recording its primary Material source; the
default registry stays empty otherwise.

Foundation paths use canonical dot notation in TypeScript and deterministic
namespaced custom properties in CSS:

```text
ref.palette.primary-40          -> --m3e-ref-palette-primary-40
sys.color.light.primary         -> --m3e-sys-color-primary (light scope)
sys.motion.expressive.fast.*    -> --m3e-sys-motion-expressive-fast-*
comp.button.container.color     -> --m3e-comp-button-container-color
```

This mapping is centralized rather than repeated in component code. The build
regenerates token CSS from the validated public default and checks it byte for
byte, so contributors do not manually edit generated output.

T07 establishes the CSS motion projection at this serialization boundary. Each
validated spring slot deterministically emits a calculated settlement duration
and sampled `linear()` easing beside its source damping/stiffness values. Theme
overrides therefore produce scoped motion CSS without browser measurement,
React state, or a runtime stylesheet. ADR 0007 records the calculation and
reduced-motion contract.

## Theme runtime

`src/theme/theme.ts` is the only conversion boundary between public
`Material3Theme` data and `FoundationTokenSet`. Theme creation and extension
merge plain data, then validate and deep-freeze a detached result. This keeps
React, browser globals, and provider concerns out of server-safe theme data.

`Material3Provider/` renders the `.m3e-theme` token scope. The generated token
stylesheet assigns a complete default foundation to both the root and provider
scopes, while inline custom properties contain only validated differences.
Light/dark aliases let CSS media queries resolve custom system themes before
hydration. React tracks that browser preference only for the resolved-mode
context, which is separate from the theme context.

The root entry is a client boundary. `./theme` and `./tokens` are
React-free data entries for SSR and server modules. Architecture checks protect
those files from React imports and protect the entire theme layer from upward
component imports. ADR 0003 records the full decision and measured cost.

## Component layout

Every public component uses the same mirrored layout:

```text
src/components/ComponentName/
  ComponentName.tsx
  ComponentName.types.ts
  ComponentName.css
  index.ts

tests/components/ComponentName/
  ComponentName.test.tsx
  ComponentName.ssr.test.tsx
  ComponentName.a11y.test.tsx
  ComponentName.conformance.md

playground/examples/ComponentName.example.tsx
```

Files may be added when behavior genuinely needs separation, but the canonical
files keep discovery predictable. Private helpers remain inside the component
directory. Cross-component behavior moves to a named `internal/` primitive only
when it represents a shared web/platform rule or has at least two real users.

Tests normally import from the component's public `index.ts`; package and
consumer tests import from the package entry. Conformance records contain
primary Material references, access dates, supported states, tokens, semantics,
keyboard behavior, and documented web deviations.

`Surface` establishes the containment boundary for later component tasks. It is
passive and accepts only a bounded set of non-interactive block/landmark
elements. Components that own click, selection, toggle, focus, or form behavior
must keep that behavior in their own semantic implementation rather than making
Surface polymorphic to an interactive element. ADR 0004 records the elevation,
color-pairing, and semantic decisions.

`Text` establishes the typography/semantics boundary. Its visual `variant` and
Expressive `emphasis` map literally to system type-scale tokens, while a bounded
native `as` prop alone determines document semantics. It inherits content color
and does not fetch fonts, generate token names, or subscribe to theme context.
The explicit 30-style CSS table keeps every baseline/emphasized mapping
searchable and distribution-checkable. ADR 0005 records the public contract.

`Icon` establishes the icon-source/accessibility boundary. Its passive span
owns decorative or meaningful semantics while a hidden visual child adapts
either a consumer React SVG component or a Material Symbols glyph. The SVG
source contract is deliberately minimal and the glyph adapter consumes literal
component variables for all current symbol axes, including Expressive `ROND`.
Icon inherits content color, loads no asset, and mirrors directional artwork
only through an explicit RTL opt-in. ADR 0006 records the public contract.

`Button` establishes the native action/form boundary. A semantic button root
owns browser activation, focus, disabled state, forms, consumer events, a 48px
minimum target, and the forwarded ref. Its nested visual container owns the five
Material variants, five Expressive sizes, width, resting/pressed shape,
elevation, and state layer, while public `Text` supplies sourced typography.
Decorative leading/trailing visual slots do not alter the accessible name.
ADR 0007 records the public contract and shared CSS spring projection.

`IconButton` establishes the icon-only action/toggle boundary. Its named native
button owns activation, forms, cancellation, disabled, focus, a 48px target,
and optional `aria-pressed` state while one hidden visual subtree owns the four
variants, five sizes, three widths, round/square/pressed/selected shapes, and
alternate selected artwork. Controlled/uncontrolled state and consumer-first
cancelable event composition live in named internal primitives for later
controls. ADR 0008 records the web toggle semantics and API.

`FloatingActionButton` establishes the promoted-action boundary. One native
button API statically separates icon-only momentary, label-driven extended, and
icon-only toggle modes. Its visual container owns current 56/80/96px geometry,
extended expansion, size-aware typography/spacing, state elevation, and the
Expressive toggle transition to a 56px round primary close control. The native
root preserves forms and stable naming; shared event/state primitives preserve
cancelable controlled/uncontrolled selection. ADR 0009 records the public mode,
accessibility, motion, and elevation decisions.

`Card` establishes the coherent-content and whole-card action boundary. One
discriminated API renders a passive `article`/bounded semantic container for
rich content or a native `button` for a single whole-card action. Filled,
elevated, and outlined variants own current container, outline, disabled, and
state-elevation tokens without imposing content slots or padding. Interactive
children follow the HTML button phrasing-content model; nested controls and rich
flow structure belong inside passive cards. ADR 0010 records the semantic split,
content boundary, and use of the shared Expressive effects projection.

`Checkbox` establishes the native form-control boundary. A native
`input type="checkbox"` owns semantics, naming, activation, forms, reset,
disabled state, and the forwarded ref, while a decorative wrapper owns only the
48px target, the resolved state attributes, and the consumer class and style. Its
sibling container draws the sourced 18px box, inset outline, and state layer, and
an SVG polyline reproduces the first-party check reveal and indeterminate
gravitation from component tokens. Mixed state stays a controlled prop because
the DOM property cannot be serialized. Ref composition joined the shared internal
primitives for the remaining form controls. ADR 0011 records the tri-state
model, geometry selection, and motion mapping.

`Radio` establishes the native grouping boundary. A native `input
type="radio"` owns semantics, naming, activation, native grouping through a
required `name`, forms, reset, disabled state, and the forwarded ref, while a
decorative wrapper owns only the 48px target, the resolved state attributes,
and the consumer class and style. Its sibling container draws the sourced
20px ring and dot from one shared icon-color role per state. Visual state is
read from the input's own `:checked`/`:disabled` pseudo-classes rather than
from the wrapper's data attributes, because a sibling in the same native
group can be deselected with no event firing on it, and only a
browser-owned pseudo-class stays accurate for every radio in the group
regardless of which one last re-rendered. ADR 0012 records the grouping
model, the checked-driven CSS decision, and the motion asymmetry between the
dot's unconditional scale and the disabled-snapped color transition.

`Switch` establishes the native role-mapped boundary. A native `input
type="checkbox" role="switch"` owns semantics, naming, activation, forms,
reset, disabled state, and the forwarded ref; `role`, like `type`, is fixed
and cannot be overridden by a caller. A decorative track and thumb draw the
sourced 52×32px pill, sliding circle, and an optional icon slot. Every thumb
inset is expressed with `calc()` directly on the registered track/handle
dimension tokens, reproducing the source's outer-box measure-function formulas
while subtracting the 2px border already consumed by CSS's padding-box
positioning origin. The 16×16px icon slot centers and constrains direct
`Icon`, SVG, and image artwork inside the 24px icon-bearing handle. The
thumb's own state layer is anchored to its current position rather than the
track's center, matching
the source attaching its ripple to the thumb element. ADR 0013 records the
role mapping, the thumb-anchored ripple, and the pressed-shape snap/animate
asymmetry.

`TextField` and `TextArea` establish the shared-foundation boundary: an
internal `TextFieldChrome` primitive under `src/internal` renders the
label, indicator/outline, icon, and supporting-text decoration once, and
each public component supplies only its own native control (`input` or
`textarea`) as that primitive's first child. The field lays out logical
start, native-control, and end regions explicitly: the ordinary regions are
16px, icon-bearing regions are the sourced 48px interactive target plus 4px
gap, and the control occupies only the middle region rather than stretching
under an icon and relying on reset-sensitive input padding. A transparent,
associated label preserves whole-field click-to-focus behavior outside that
middle control box. The same field grid owns top, control, and bottom rows:
filled uses 24/24/8px (an 8px inset plus the minimized 16px label, then the
24px input line, then 8px), while outlined uses 16/24/16px. Native controls
occupy the middle row with zero block padding, so downstream resets cannot
collapse the label/value relationship either. This mirrors the pinned
source's own architecture directly — `TextField`/`OutlinedTextField` have no
distinct multiline composable, and `SecureTextField` establishes the
precedent of swapping the underlying text-input primitive under one
unchanged decoration layer. The floating label's position and type size are
read from the control's own `:focus`/`:placeholder-shown` pseudo-classes,
extending the checked-driven-CSS precedent from Radio and Switch from a
discrete boolean to a continuous has-value signal. The outlined variant's
label-notched border uses three CSS flex panels: a hidden body-small label
clone gives the middle panel its intrinsic width, and that panel's top stroke
scales away when the label floats. The panels paint against the field's own
border box, keeping the outline, floating label, input, and icons in one
coordinate system with no JS measurement. The native textarea retains vertical
resizing; its `rows` height grows the middle row while the shared grid keeps the
Material top and bottom regions around it.
`error` and `disabled` are the only two states mirrored onto the root as
`data-m3e-*` attributes, because they are the only states unreachable by a
plain sibling combinator from the control and neither can change without
this component re-rendering. ADR 0014 records the shared-foundation
decision, the native-truth label float, and the segmented outline.

`SegmentedButtonGroup` establishes the data-driven-group boundary: one
`segments` array replaces the pinned source's two row composables plus a
child-scope `SegmentedButton`, computing each item's own index/count
directly instead of through `Children.map`/context indirection. Each
segment is one native `<input type="radio">` (single-choice, sharing one
`name` for native mutual exclusivity and roving-tabindex) or
`<input type="checkbox">` (multi-choice, independent), wrapped in its own
native `<label>`. Shape is driven by a computed `data-m3e-position` through
logical corner-radius properties; stacking order is an ordinal flattening
of the source's `interactionCount + (checked ? CheckedZIndexFactor : 0)`
z-index, driven by `:has(:checked)`/`:hover`/`:active`/
`:has(:focus-visible)` instead of literally counting interactions. Checked,
hover, press, and focus visuals read from the native control's own
pseudo-classes, extending the same native-truth precedent Radio and
TextField already rely on; `disabled` is the only state mirrored onto a
segment root as a `data-m3e-*` attribute, for the same re-render-safety
reason TextField's `error`/`disabled` are. ADR 0015 records the data-driven
API, the `:has()`-based stacking flattening, and a bundle-budget ceiling
raise.

`Dialog` is the first overlay-kind component and establishes the
native-`<dialog>`-as-primitive boundary: a single root element, driven
imperatively by `showModal()`/`show()`/`close()` in an effect rather than a
JSX-rendered `open` attribute, since a true modal only exists once
`showModal()` runs. `modal` (default `true`) is a deliberate capability
addition beyond the always-modal pinned source, mapping directly onto
`showModal()` vs `show()`. Initial focus placement and close-time focus
restoration are both native behavior for either mode, requiring no
library-owned focus-management code — the same "the platform already does
this" posture Radio's native mutual exclusivity and TextField's native
label association already established, now extended to an entire modal
lifecycle. `dismissOnOutsideClick` uses a manual bounding-rect click check
rather than the native `closedby` attribute, which postdates this library's
browser floor. Entrance/exit motion is the one deliberate exception to this
library's hard floor-support commitment: `@starting-style`/
`transition-behavior: allow-discrete` postdates the `:has()` floor, but
because an unsupporting browser still produces a fully functional, correctly
stateful instant show/hide, the trade is a pure progressive enhancement, not
a functional regression. A controlled dialog's own native dismissal is
reported through `onOpenChange` but is not forcibly reverted if unacknowledged,
since nothing forces a further render absent an `open` prop change — this
mirrors the native-truth precedent Radio/Checkbox/SegmentedButtonGroup
already established, that platform state can move ahead of an
unacknowledged controlled prop. ADR 0016 records the native-dialog adoption,
the modal/non-modal mapping, and the `@starting-style` progressive
enhancement.

`Menu` and `Select` are the first components with no native top-layer
primitive to lean on — neither the Popover API nor CSS anchor positioning is
available across this library's browser floor — so a new, non-exported
`overlayPosition`/`useAnchoredOverlay` pair in `src/internal` owns portal
mounting, live repositioning, outside-click/Escape dismissal, and
deferred-unmount exit animation, the first such infrastructure here. Both
are data-driven (`items`/`options` arrays), extending the SegmentedButtonGroup
precedent. `Menu` follows the APG menu-button pattern with real roving-focus
keyboard navigation and no focus trap; `Select` follows the APG select-only
combobox pattern instead, keeping focus on its trigger and tracking the
highlighted option with `aria-activedescendant` — a deliberate per-pattern
divergence, not an inconsistency. `Select`'s visible trigger is a read-only
input built on the same `TextFieldChrome` foundation `TextField`/`TextArea`
already share, and its popup listbox reuses `Menu`'s own container/item
classes and tokens unchanged, so `Select` registers no component tokens of
its own — the T14 shared-token-domain precedent extended to a third and
fourth component. A companion `<input type="hidden">`, rendered when `name`
is supplied, is `Select`'s own new pattern for form participation, since no
native form-associated element can render Material's option rows. ADR 0017
records the shared overlay primitives, the per-component focus-model
divergence, and the token-reuse chain.

`Tooltip` and `Snackbar` are transient-feedback components built on top of
T17's overlay infrastructure. `useAnchoredOverlay` gained an optional
`computePosition` override — used only by `Tooltip`, whose center-aligned,
flip-on-collision, zero-margin placement (`computeTooltipPosition`) is a
genuinely different algorithm from `Menu`/`Select`'s own, while still
sharing the same portal/measure/dismiss lifecycle; `Menu`/`Select` are
unaffected. Unlike `Menu`, `Tooltip` wires its own show/hide interaction
directly on the consumer's `anchorRef` (hover, focus, `Escape`) rather than
asking the consumer to, since hover/focus tooltip triggering is a single,
standardized WAI-ARIA APG interaction with no app-specific ambiguity. It
also imperatively sets/removes `aria-describedby` on the anchor while
mounted — the first imperative ARIA-attribute technique here. Both
`Tooltip` variants stay non-interactive (`role="tooltip"` disallows
focusable content), so the pinned source's rich-tooltip action button has
no web port. `Snackbar` is a single controlled component, not the pinned
source's separate host/queue pair, and owns its own lightweight
mount/measure/dismiss phase machine (no anchor, so it does not use
`useAnchoredOverlay`) with a pausable auto-dismiss timer — the countdown
pauses on hover/focus and resumes on leave, a deliberate WCAG 2.2.1
addition. ADR 0018 records both design decisions.

`Tabs` is one data-driven component (`items: readonly TabItem[]`) with the
first sliding-indicator infrastructure here: a plain `useEffect` measures
the selected tab's own bounding rect (or, in the `'primary'` variant, its
inner content-wrapper rect) relative to the tablist, applying the result as
the indicator's `transform`/`inline-size`, kept correct across reflow by a
`ResizeObserver` and a window `resize` listener. Unlike every prior
overlay-entrance task, the indicator's transition uses the sourced
`DefaultSpatial` motion slot, not `FastSpatial` — a content-shift
transition, not an overlay entrance, matching the pinned source's own
choice. An item with `href` renders a real `<a role="tab">` instead of
`<button role="tab">` (a link-safe API for router-driven navigation tabs,
leaving actual navigation to the browser's native anchor behavior); an item
with `panel` gets one `role="tabpanel"` region for the selected item only,
and no tabpanel region exists at all when no item defines one. ADR 0019
records the indicator infrastructure and the link/panel API.

`NavigationBar`, `NavigationRail`, and `NavigationDrawer` share one
`NavigationItem` data type (canonically defined in `NavigationBar.types.ts`
and re-exported by the other two through their own public barrels — the
first cross-component-folder type reuse here, since these components are
explicitly designed to interoperate rather than merely sharing styling).
All three render web-native `<nav>`/`aria-current` navigation semantics
instead of the pinned source's ported `role="tab"` — a persistent app-
navigation region is a different pattern from `Tabs`' own in-page
panel-switching, so no roving `tabindex` or arrow-key model exists here;
items sit in normal tab order like any navigation link list. `NavigationDrawer`'s
`'modal'` variant independently duplicates Dialog's own small native-
`<dialog>` lifecycle rather than sharing an extracted primitive, sliding in
by animating `inset-inline-start` (not `transform`) so the direction
auto-corrects under RTL with no JS branching. `NavigationSuite` is the
first component to render another public component internally: it
composes `NavigationBar`/`NavigationRail`/`NavigationDrawer` directly,
switching between them with a new `window.matchMedia`-driven hook using
the pinned source's own real Compact/Medium/Expanded width breakpoints —
a deliberate 3-tier mapping that diverges from the pinned source's own
2-tier `calculateFromAdaptiveInfo` (see ADR 0020 for why). Server
rendering and pre-hydration always reflect the compact tier, corrected by
a client effect once a real viewport exists to measure. Bar and rail item
icons retain their sourced 24×24px geometry in every state; a separate
centered background layer alone expands from zero width to the 56×32px active
pill, while the full-size state-layer target and item layout remain stable.

`LinearProgress`, `CircularProgress`, and `WavyProgress` share the native
`<progress>` determinate/indeterminate value contract while rendering custom
DOM/SVG geometry. Their continuous motion uses component-owned CSS
`@keyframes`, not a JavaScript frame loop. Circular animation layers rotate
around explicit SVG view-box centers, and round-capped endpoint paths are
omitted when their visible length is zero. `WavyProgress` builds the pinned
linear quadratic wave inside its stroke-safe 10px container and uses matched
27-cubic circle/rounded-nine-point-star endpoints generated from the faithful
offline `RoundedPolygon`/`Morph` port established by `LoadingIndicator`.
Amplitude changes interpolate path geometry so stroke width remains constant.
ADR 0021 records the progress-specific geometry and motion decisions; ADR
0022 records the shared offline geometry provenance.

## Styling

Component CSS is authored beside the component. `src/styles/styles.css`
assembles the complete supported stylesheet in a fixed cascade-layer order.
Tokens and public selectors use the `m3e` namespace. Components use literal,
searchable class names and stable `data-*` states.

The authored style entry imports colocated component CSS with relative paths.
The style build recursively inlines imports contained by `src`, rejects
cycles and path escapes, appends generated token CSS, and emits one compiled
artifact. Source checks validate import boundaries; distribution checks require
every custom-property reference to resolve in the assembled file.

The stylesheet resets no global elements and emits no application selectors;
every rule is namespaced under `m3e`.

## Public inventory

`docs/component-inventory.json` is the source of truth for public component
names, owner paths, task IDs, dependencies, conformance status, and exports. A
planned entry makes no support claim. Only conformant entries may be presented as
stable in generated documentation.

`scripts/check-docs.mjs` deterministically projects that inventory into
`docs/SUPPORTED_COMPONENTS.md` and verifies that every conformant component
has a discoverable public page covering its example, anatomy, variants/states,
accessibility, and tokens. The same gate validates the public setup, theming,
SSR, migration, deviation, and release guides against package metadata. ADR 0026
records the inventory-backed documentation decision; ADR 0027 records the 1.0
cutover that removed the 0.3 surface and its Tailwind peer.

## Decisions and generated output

Cross-cutting decisions live in `docs/adr/`. Generated files must identify
their source and regeneration command. CI reproduces and compares contract
artifacts rather than accepting manually edited output.
