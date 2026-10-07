# Migrating from 0.3 to 1.0

This guide maps public package contracts. It intentionally contains no
application-specific imports, routes, data models, dependency revisions, gap
analysis, or rollout status.

## What changed

`1.0.0` is a full replacement, not an additive release. The 0.3 implementation,
its Tailwind preset, its stylesheet, and every one of its subpath exports were
removed from the package. There is no compatibility path inside `1.0.0`:
applications upgrade deliberately or stay on `0.3.x`, which remains published
and installable.

| 0.3 contract | 1.0 contract |
| --- | --- |
| `@language-lit/material3-expressive` (0.3 API) | `@language-lit/material3-expressive` (new API) |
| `@language-lit/material3-expressive/styles` | `@language-lit/material3-expressive/styles.css` |
| Component-group subpaths (`/components/*`) | Named exports from the package root |
| `tailwind-preset` plus package content glob | Removed; no equivalent and none required |
| Provider for link/image adapters | Theme-scoping `Material3Provider` |
| Hooks and utilities subpaths | Removed; use the exported theme/token/component APIs |
| — | `@language-lit/material3-expressive/theme` (React-free) |
| — | `@language-lit/material3-expressive/tokens` (React-free) |

Because both releases now occupy the same import paths, an application cannot
render 0.3 and 1.0 side by side from a single installed version. Stage the
upgrade in a branch rather than incrementally in production code.

## Setup changes

1. Install `1.0.0` in an isolated migration branch.
2. Remove the Tailwind preset import, the package content glob, and the
   `./styles` import.
3. Import `@language-lit/material3-expressive/styles.css` once at an
   application-level entry.
4. Render `Material3Provider`; select `light`, `dark`, or `system` mode.
5. Move custom design values into `createTheme`/`extendTheme` data rather than
   CSS or Tailwind configuration.
6. Replace components by semantic area and verify forms, keyboard behavior,
   focus, RTL, forced colors, reduced motion, SSR, and production CSS.

## Common public concept mappings

| 0.3 concept | 1.0 direction |
| --- | --- |
| `Button`, `IconButton` | Use the same named concepts with native button/form semantics and new variant/size contracts. |
| `FAB` | Use `FloatingActionButton`; momentary, extended, and toggle modes have explicit prop shapes. |
| Name-based `Icon` registry | Pass a Material Symbols ligature or an SVG source to `Icon`; font delivery remains consumer-owned. |
| `Input` | Use `TextField`; choose filled/outlined styling through its public variant. |
| `TextArea` | Use `TextArea`, which shares TextField chrome and preserves native vertical resizing. |
| `SegmentedButtons` | Use data-driven `SegmentedButtonGroup` in single or multiple mode. |
| `Modal` | Use `Dialog`; choose modal or non-modal behavior and follow its controlled open lifecycle. |
| Menu/select components | Use `Menu` for APG menu semantics and `Select` for combobox/listbox semantics. |
| `Tabs`, `TabItem`, `TabsContainer` | Use one data-driven `Tabs` component with link-safe items and optional panels. |
| Navigation bar/rail/drawer | Use the shared `NavigationItem` shape or `NavigationSuite` for adaptive switching. |
| Linear/circular progress | Use `LinearProgress`/`CircularProgress`; omit `value` for indeterminate mode. `WavyProgress` is the Expressive treatment. |
| Theme/font loader hooks | Create serializable theme data through `/theme`; font loading remains application-owned. |

Consult the [supported-component matrix](SUPPORTED_COMPONENTS.md) and each linked
page for exact props. Similar names do not promise prop-level compatibility.

## 0.3 APIs without a 1.0 primitive

The 0.3 package included utilities and application-level presentation patterns
that are not Material primitives in the 1.0 matrix: data and display recipes,
framework adapter context, and hooks that load application fonts or themes.
Replace those with application composition, or propose a future generic
component through the public task process. Their prior existence does not
expand the advertised surface.

## Breaking changes

- Every subpath except `/theme`, `/tokens`, and `/styles.css` was removed.
- The Tailwind preset, the package content glob, and the `./styles` entry no
  longer exist.
- CSS uses the `m3e` namespace and consumes no Tailwind tokens. The 0.3
  `--md-*` custom properties are gone.
- `Material3Provider` scopes themes on a real `div`; it no longer owns framework
  link or image adapters.
- Components favor native elements and APG semantics over ported application or
  Compose roles.
- Stateful composites use explicit controlled/uncontrolled value callbacks and
  data arrays rather than child or router coupling.
- Icons bundle no registry and no font loader.
- The package declares no runtime dependencies; React and React DOM are the only
  peers.
- Only the generated conformant matrix is a support promise.

## Validation and rollback

Run the application's own typecheck, tests, accessibility checks, SSR build, and
production bundle after each migrated area. Public package validation is
`npm run verify` in this repository.

Rollback means restoring the `0.3.x` dependency and its imports and styles in
the consumer's own change. Consumer-specific rollout and rollback procedures
belong outside this public repository.
