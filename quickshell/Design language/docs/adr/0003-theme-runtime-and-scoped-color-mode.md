# ADR 0003: Theme runtime and scoped color mode

Status: accepted
Date: 2026-07-19
Task: T03

> Path note: this ADR names the `./v1*` export paths and `src/v1/` layout that
> ADR 0027 replaced. The decision still stands; read `./v1` as the package root
> and `./v1/theme`, `./v1/tokens`, `./v1/styles.css` as `./theme`, `./tokens`,
> `./styles.css`.

## Context

The v1 theme runtime must work in ordinary React applications, SSR renderers,
and framework fixtures without becoming a Next.js-specific API. It must support
validated custom themes, nested scopes, and the browser's color preference while
leaving `document.documentElement` under application ownership.

The default token stylesheet is the no-JavaScript visual contract. Custom themes
therefore cannot depend on a client effect or injected stylesheet to select their
first light or dark paint. At the same time, components that need the resolved
mode should not re-render because an unrelated theme field changed.

React documents `useSyncExternalStore` with `getServerSnapshot` as the supported
way to subscribe to a browser API while providing a matching server and hydration
snapshot: <https://react.dev/reference/react/useSyncExternalStore> (accessed
2026-07-19).

## Decision

1. `Material3Theme` is a serializable public projection of the validated token
   set. It exposes reference tokens, light and dark color schemes, typography,
   shapes, motion, elevation, state, density, and registered component tokens.
   `createTheme`, `extendTheme`, and `parseTheme` all return independent deeply
   frozen values through the token validator.
2. `Material3Provider` renders one `.m3e-theme` element. Generated CSS assigns
   the complete default non-color token set to `:root, .m3e-theme`, so every
   provider starts a complete scope and a nested default provider resets a custom
   ancestor.
3. Generated theme aliases retain both light and dark color roles. Static
   `prefers-color-scheme` rules select those aliases for system-mode provider
   scopes before React hydrates. Fixed modes use the canonical system variables.
   A custom provider writes only differences from the default as inline custom
   properties; it never inserts a runtime stylesheet.
4. Theme data and resolved mode use separate React contexts. System preference
   changes are read through `useSyncExternalStore` with a caller-configurable,
   deterministic server fallback.
5. The optional initialization script only synchronizes the provider's resolved
   mode data attribute before hydration. It is static, opt-in, scoped through
   `document.currentScript.parentElement`, and accepts a CSP nonce. Visual system
   mode does not require the script.
6. The convenience `./v1` entry is a React client boundary because it exports
   providers and hooks. Serializable data utilities remain server-safe through
   `./v1/theme` and `./v1/tokens`; the packed Next fixture creates a custom theme
   from the server-safe entry and passes it to the provider.
7. Bundle accounting follows relative JavaScript and declaration imports so code
   splitting cannot hide bytes in shared chunks. Raw bytes and the sum of each
   independently compressed file are counted across the closure. T03 records
   these measured baselines and explicit ceilings:

   - public v1 JavaScript closure: 69,496 bytes / 16,211 aggregate gzip;
     ceiling 78,000 / 18,000;
   - public v1 declaration closure: 20,463 / 6,101 aggregate gzip; ceiling
     24,000 / 7,000;
   - full CSS: 62,702 / 5,067 gzip; ceiling 70,000 / 6,000;
   - token CSS: 62,498 / 5,007 gzip; ceiling 70,000 / 6,000;
   - packed package: 202,989 bytes; ceiling 225,000.

## Consequences

- A provider introduces a real `div` scope. Consumers may pass standard div
  attributes and styling when the wrapper participates in layout.
- Custom inline output stays small for typical overrides, while every nested
  provider still has a complete default fallback.
- System visuals respond directly to CSS media queries. React's resolved-mode
  context follows the same preference after hydration and on later changes.
- Server code that only needs theme or token data imports the documented
  server-safe subpaths instead of the client convenience entry.
- The token stylesheet gains explicit light/dark theme aliases. This cost is
  measured and bounded rather than shifted into per-provider server markup.
