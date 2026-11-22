# Deliberate web deviations

The library follows Material 3 Expressive geometry and visual state while preferring
native HTML, WCAG 2.2, and WAI-ARIA Authoring Practices when Compose behavior
does not map directly to the web.

| Area | Web implementation | Reason |
| --- | --- | --- |
| Actions and form controls | Native `button`, `input`, `textarea`, and form behavior own activation and values. | Browser semantics, forms, autofill, reset, and keyboard behavior are more reliable than ported gesture nodes. |
| Interaction targets | Small Expressive visuals retain a separate minimum 48×48 CSS-pixel target. | Preserves Material geometry and accessible pointer targets. |
| Icons | `Icon` adapts SVG components or Material Symbols text; it bundles no painter, registry, or font. | Web asset delivery and localization remain consumer-owned. |
| Cards | Interactive cards are native buttons; rich/nested-interactive content uses passive cards. | HTML forbids nested interactive content inside buttons. |
| Switch | A checkbox with fixed `role="switch"` owns forms and semantics. | Native checkbox mechanics provide the closest web form primitive. |
| Text fields | Native `:focus`/`:placeholder-shown` state drives label position; textarea resizing remains available. | Keeps browser-owned value/focus truth and a useful web affordance. |
| Dialog | Native `<dialog>` owns modal state and focus lifecycle; entrance motion progressively enhances it. | Uses the web top layer and native focus restoration. |
| Menu and Select | Menu uses roving focus; Select keeps focus on a combobox trigger with `aria-activedescendant`. | They are distinct APG patterns, not one shared Compose selection surface. |
| Tooltip | Tooltip content is non-interactive and described from its anchor. | `role="tooltip"` is not an interactive hover card on the web. |
| Snackbar | One controlled snackbar owns a pausable timeout rather than exposing a host queue. | Pausing on hover/focus satisfies timing accessibility; queue policy remains application-owned. |
| Tabs | Navigation items may render real anchors; panels are optional and only emitted when supplied. | Preserves native navigation instead of nesting links in tab buttons. |
| App navigation | Bar, rail, and drawer use `<nav>`/`aria-current`, not tab roles or arrow-key navigation. | Persistent application navigation is not an in-page tablist. |
| Adaptive navigation | `NavigationSuite` uses compact, medium, and expanded browser-width tiers and server-renders compact markup. | The web has no viewport during SSR; three layouts use the available primitives. |
| Progress | Native `<progress>` carries value semantics while custom DOM/SVG draws Material geometry. | Retains accessible determinate/indeterminate behavior without exposing native browser visuals. |
| Expressive motion | Theme springs are projected deterministically into CSS durations and sampled `linear()` easing; continuous indicators use CSS keyframes. | CSS has no direct general spring primitive and SSR must not depend on runtime measurement. |
| Reduced motion | Spatial transitions snap and infinite decorative motion stops while state remains visible. | Preserves comprehension without requiring animation. |
| Forced colors | Components use system colors and explicit focus outlines where authored state layers would disappear. | Allows the user agent's high-contrast palette to remain authoritative. |

Component-specific details and source revisions live in the conformance records
under `tests/components/`. Cross-component rationale lives in the public ADRs.
