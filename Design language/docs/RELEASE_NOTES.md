# Release notes

## 1.0.0 — 2026-07-21

Status: prepared stable release. The cutover replaces the 0.3 surface; it does
not publish to the registry or create a remote release.

### Added

- `.`, `/theme`, `/tokens`, and `/styles.css` as the complete public surface.
- A validated serializable theme/token system with light, dark, system, custom,
  and nested provider scopes.
- Thirty-two conformant public components listed in the generated
  [supported-component matrix](SUPPORTED_COMPONENTS.md).
- Native form, keyboard, focus, RTL, reduced-motion, forced-colors, SSR, and
  hydration behavior covered by component conformance gates.
- Framework-neutral Vite and Next.js packed-package fixtures.
- Public installation, theming, SSR, migration, and web-deviation guides.

### Removed

The 0.3 implementation was deleted rather than deprecated in place, because its
only known consumer completed migration first. `0.3.x` remains published for
applications that are not ready.

- The 0.3 components, hooks, utilities, provider, showcase, and token CSS.
- The `components/*`, `hooks`, `utils`, `context/*`, `showcase`, `styles`, and
  `tailwind-preset` subpath exports.
- The Tailwind preset and the optional `tailwindcss` peer dependency.
- All fourteen runtime dependencies. React and React DOM are the only peers.

### Breaking changes

`1.0.0` reuses the package root for a new API, so upgrading from `0.3.x` is a
deliberate migration rather than a version bump:

- component import paths and many prop contracts;
- stylesheet and CSS custom-property namespaces;
- provider responsibilities and theme representation;
- icon source handling;
- composite component state and semantic models;
- the supported-component scope.

See [MIGRATION.md](MIGRATION.md) for public concept mappings.

### Limitations

- The complete `/styles.css` file is the supported stylesheet; component CSS
  subpaths and token-only CSS are not public package exports.
- The support claim is limited to the generated conformant matrix. Chips,
  sliders, search, sheets, list items, app bars, carousel, and other possible
  1.x components are not included.
- Material 3 Expressive sources are evolving; each conformance record pins the
  source revision used by this release.
- Publication, registry dist-tags, and remote release creation require separate
  explicit approval.

### Verification target

The release must pass `npm run check:docs` and `npm run verify`, including
packed Vite/Next builds, the release contract, and bundle budgets. The
release-readiness record is [RELEASE_READINESS.md](RELEASE_READINESS.md).
