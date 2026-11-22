# ADR 0024: `FloatingToolbar` unifies orientation into one component with roving focus; `FabMenu` renders its own fixed-size, shape-morphing trigger FAB

Status: accepted
Date: 2026-07-20
Task: T24

## Context

The pinned AndroidX revision (`225f50d42bf0adeb2abf4b6109befb5ab6ce4efc`)
implements `FloatingToolbar.kt` (2061 lines: `HorizontalFloatingToolbar`/
`VerticalFloatingToolbar`, each with a plain overload and a second
overload that co-locates a resizing/re-elevating FAB, a
`FloatingToolbarScrollBehavior` built on `NestedScrollConnection`, and
Android touch-exploration-service detection that force-expands the
toolbar) and `FloatingActionButtonMenu.kt` (745 lines:
`FloatingActionButtonMenu`, `ToggleFloatingActionButton`, and
`FloatingActionButtonMenuItem`, together implementing a FAB that morphs
into a menu trigger with a staggered-reveal item list above it).
`docs/SPEC.md` §9 lists `FloatingToolbar` and `FabMenu`, matching the
existing `docs/component-inventory.json` placeholder rows.

## Decisions

1. **`FloatingToolbar` is one component with an `orientation` prop**,
   not two exports. The inventory placeholder names only
   `FloatingToolbar`/`FloatingToolbarProps`, and the source's own
   `Horizontal`/`Vertical` composables share every default
   (`FloatingToolbarDefaults`, `FloatingToolbarColors`, `ContainerShape`)
   and differ only in main-axis direction — exactly the shape of a single
   component with a direction prop, not two materially different APIs.

2. **No integrated FAB slot, no `FloatingToolbarScrollBehavior`, no
   touch-exploration force-expand.** Three separate, substantial cuts,
   each independently justified:
   - The FAB-integrated overload is a genuinely different layout and
     animation contract (a co-resizing, re-elevating FAB inside the
     toolbar's own measure pass) layered on top of the plain toolbar —
     this task's own `FabMenu` already delivers a FAB-morph
     implementation; a second, toolbar-flavored one is out of scope.
   - `FloatingToolbarScrollBehavior` is built on Compose's
     `NestedScrollConnection`, a scroll-coordination API with no direct
     web analog short of a real `onScroll` listener plus fling/snap
     physics — a project of its own. `expanded`/`onExpandedChange` are
     exposed directly so a consumer can wire up their own scroll
     listener against them.
   - Touch-exploration detection (`rememberTouchExplorationService`) is
     an Android-platform API — a screen reader's presence isn't
     observable from web content at all, so this isn't a cut so much as
     inapplicable.

3. **Roving focus** — named explicitly in this task's own table
   description — reads and clones direct children (`Children.toArray` +
   `cloneElement`, injecting `tabIndex` and a focus-tracking ref composed
   with the child's own ref via this project's existing `composeRefs`
   utility) rather than requiring a structured `items` array, the same
   "arbitrary children, not a data-driven API" precedent `ButtonGroup`
   (T23) established for this exact category of composite. Arrow keys
   move both DOM focus and the roving `tabIndex`; `Home`/`End` jump to
   the ends; matches the WAI-ARIA APG toolbar pattern.

4. **`FabMenu` renders its own trigger FAB directly**, not a separately-
   composed `ToggleFloatingActionButton` — the inventory placeholder
   names only `FabMenu`/`FabMenuProps` as public exports (later expanded
   to include `FabMenuItem`/`FabMenuItemProps`, since a `FabMenu` with no
   way to style its own items would be incomplete). `icon`/`closeIcon`
   are both required props, cross-faded internally via CSS opacity,
   rather than the source's generic `Modifier.animateIcon` the caller
   must apply to their own conditionally-swapped icon.

5. **The trigger FAB's size never actually changes.** The source exposes
   a generic `containerSize: (Float) -> Dp` interpolation callback that
   *suggests* the FAB resizes between collapsed and expanded — but
   reading the actual sourced values,
   `FabBaselineTokens.ContainerHeight` (the collapsed size) and
   `FabMenuBaselineTokens.CloseButtonContainerHeight` (the expanded
   size) are both `56dp`. Only shape (`CornerLarge` rounded-square →
   `CornerFull` circle), color (`primaryContainer`/`onPrimaryContainer`
   → `primary`/`onPrimary`), and icon size (`24dp` → `20dp`) actually
   morph. This project registers one fixed trigger size and animates
   only the properties that actually change — a plain CSS state
   transition, not a per-frame size interpolation.

6. **Collapsed `FabMenuItem`s are marked `inert`** (a standard HTML
   global attribute, not a custom ARIA pattern) rather than removed from
   the DOM outright. Removing and re-adding an element can't transition;
   `inert` keeps it present (so the reveal animation works) while fully
   removing it from both the accessibility tree and the tab order — a
   more direct single mechanism than the source's own two-part approach
   (`SemanticsModifierNode.shouldClearDescendantSemantics` for
   assistive-technology visibility, combined separately with a
   width-collapse-to-zero for hit-testing/tab-stop removal).

7. **The disclosure pattern, not the menu pattern, for `FabMenu`'s
   ARIA.** The trigger exposes `aria-expanded`/`aria-haspopup="true"`/
   `aria-controls`, and items are plain buttons with no `menu`/
   `menuitem` roles — matching the actual interaction model (a button
   revealing more buttons, tab-navigable) rather than a `role="menu"`
   widget's implied arrow-key roving navigation, which the source itself
   never implements for this item list (`FocusRequester` only moves
   focus forward from the trigger to the first item; there is no
   subsequent up/down navigation between items in the source).

## Consequences

- `FloatingToolbar`'s roving-focus implementation is the first v1
  component to `cloneElement` arbitrary children to inject behavior
  (`tabIndex`, a composed ref) rather than either rendering fully
  self-owned markup (`SplitButton`, `FabMenu`'s own item column) or
  reading children's state purely through CSS (`ButtonGroup`). This adds
  a dependency on children being valid, ref-forwarding React elements —
  true for every v1 interactive component, but worth remembering if a
  future consumer ever passes a bare string or fragment as a toolbar
  item.
- Both components register their own copies of shared-shaped tokens
  (color pairs, elevation) rather than depending on another component's
  registration, the established duplication-over-premature-extraction
  precedent used throughout this project.
- Bundle budgets were raised to accommodate both components' full CSS
  and behavior code, following the established proportional-raise
  precedent, if measured output justified it.
