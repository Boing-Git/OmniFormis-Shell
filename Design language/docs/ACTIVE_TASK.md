# Active v1 task

## T29 — Expressive rendering audit and defect repair

Status: complete
Approved: 2026-07-21
Completed: 2026-07-21

Reopens the conformance record of every component this task changes. `FabMenu`
belongs to T24, whose record is reopened first; any further component touched
here has its own record reopened alongside it.

### Scope

Publishing the documentation site put all 32 conformant components on screen
together for the first time, and rendering that no test asserts turned out to be
wrong in at least one place. This task audits how the components actually paint
and behave in a browser, and repairs the defects it finds.

- Repair the known defect: `.m3e-fab-menu__item-slot` sets `overflow: hidden`
  while being exactly the size of the item it wraps, so the item's elevation
  shadow is clipped to a rectangle and only its corners survive. Confirmed
  against the playground, so it is a library defect and not a site one.
- Audit every conformant component in a real browser for defects of the same
  class — visual contract failures that compile, pass their unit tests, and are
  still wrong on screen. The audit covers, at minimum: elevation shadows clipped
  by an ancestor, content escaping or being cut by a container, interaction
  states (hover, focus-visible, pressed) that never paint, touch targets below
  the documented minimum, and text that fails contrast against the surface it
  sits on.
- Check the audited behavior against Material 3 Expressive as the specification
  defines it in `SPEC.md` §3 — first-party Material documentation, with
  `WEB_DEVIATIONS.md` as the record of deliberate divergence. A difference from
  Material that is already recorded there is not a defect; an unrecorded one is
  either a defect to fix or a deviation to document.
- Add a regression test for every defect repaired, in the component's existing
  test layout. A repair without a test that fails before it is not complete.
- Where a defect is a class rather than an instance, add a gate that catches the
  class, in preference to fixing the single instance.

Component APIs, public exports, token values, and the export map are out of
scope. This task changes how existing components render, not what they offer. A
repair that would alter a public type or add an export stops and returns to the
owner.

### Expected files

- Modified: `src/components/**` — stylesheets, and component source only where a
  defect cannot be repaired in CSS.
- Modified: `tests/components/**` — a regression test per repair, and the
  affected conformance records.
- Modified: `docs/WEB_DEVIATIONS.md` — only if the audit finds a divergence from
  Material that is deliberate and currently unrecorded.
- Possibly added: a gate under `scripts/` for any defect class worth enforcing.
- Modified: `docs/component-inventory.json` only if a component's status must
  change; a component whose defect is repaired stays `conformant`.

### Acceptance checks

- The `FabMenu` item shadow renders unclipped at rest, and the expand and
  collapse animations are unchanged at default motion, under
  `prefers-reduced-motion: reduce`, and in `forced-colors: active`.
- Every repair has a test that fails against the unrepaired source.
- The browser audit reports no remaining defect in its covered classes across
  all 32 components, or each remaining one is recorded as a deliberate deviation
  with its rationale.
- `npm run verify` passes every gate, and the documentation site still builds.
- No public export, prop type, or token value changed.

### Audit log

Audited in Chromium against the built playground, so every observation is of
library CSS with no site styles present.

**Repaired — 1 defect.**

- `FabMenu` item elevation clipped to a rectangle by
  `.m3e-fab-menu__item-slot { overflow: hidden }`. Repaired by removing the
  declaration; the reveal does not depend on it. Regression test added in
  `FabMenu.css.test.ts`, rationale recorded in the component's conformance file.
  Animation re-verified at default motion, under `prefers-reduced-motion:
  reduce`, and under `forced-colors: active`, expanding and collapsing.

**Judged correct — 4 findings, no change made.**

- `Surface` clipping a nested surface's shadow. `overflow: clip` is Surface's
  documented shape contract and matches Compose's `Modifier.clip(shape)`, which
  clips child shadows the same way. The visible artifact is the example placing
  a level-5 shadow inside 24px of padding, not a component fault.
- The navigation rail example's FAB shadow being cut. The clip belongs to
  `playground.css`'s demo frame, not the library, and a rail against a real
  application edge would clip identically.
- `SegmentedButtonGroup` segments at 40px tall. The conformance record already
  documents that the pinned Compose source applies no
  `minimumInteractiveComponentSize` here; 40px clears WCAG 2.2 SC 2.5.8 (24px).
- `SplitButton` trailing segments at 32–40px wide. The width is the sum of the
  pinned `trailing-leading-space`, icon size, and `trailing-trailing-space`
  tokens per size tier, so it is spec geometry; 48px tall and ≥32px wide clears
  SC 2.5.8. Token values are out of this task's scope regardless.

**Checked and clean.**

- Hover, focus-visible, and pressed rendering across every interactive
  component. An early pass reported all of them broken; that was a harness
  fault — the library correctly gates hover behind `@media (hover: hover)`, the
  headless context reported no fine pointer, and the state layers live on a
  sibling or descendant rather than on the control itself. Measured correctly,
  every component paints hover and focus, and `:focus-visible` applies.
- RTL, `forced-colors: active`, and `prefers-reduced-motion: reduce` across the
  full playground: no horizontal overflow, no controls collapsed to zero size,
  no page errors, and every part stays distinguishable in forced colors.
- All 32 component routes on the documentation site: no content escaping a
  clipping ancestor and no console errors.

**Gate added.**

`scripts/audit-rendering.mjs` (`npm run audit:rendering`) checks elevation
shadows clipped by an ancestor and undersized interactive targets in a real
browser, with allowlists carrying the reason for each cleared finding. Validated
both ways: it fails when the `FabMenu` defect is reintroduced and passes once
repaired. It is not wired into `npm run verify` because it needs a browser; it
is documented in `AGENTS.md` instead.

Hover/focus/pressed detection was built, produced only false positives, and was
deliberately removed from the committed gate rather than shipped noisy. The
reasoning is recorded in the script so it is not re-attempted blindly.
