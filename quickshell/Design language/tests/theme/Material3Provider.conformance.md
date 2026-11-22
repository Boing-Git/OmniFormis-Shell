# Material3Provider conformance

Task: T03
Status: conformant
Reviewed: 2026-07-19

## Primary references

- Theme requirements: `docs/SPEC.md` section 6.
- AndroidX Material Expressive theme API:
  <https://developer.android.com/reference/kotlin/androidx/compose/material3/MaterialExpressiveTheme.composable>
- React SSR external-store contract:
  <https://react.dev/reference/react/useSyncExternalStore>

## Covered contract

- Complete validated default theme and immutable creation/extension.
- Light, dark, and system modes with deterministic server fallback.
- Static-CSS system selection for default and custom themes.
- Element-scoped custom properties and isolated nested providers.
- No document-root mutation.
- Separate theme and resolved-mode subscriptions.
- Optional static initialization script and CSP nonce forwarding.
- Stable server rendering and hydration without recoverable errors.
- Packed Vite client and Next SSR/client consumer builds.

## Web adaptation

Compose theme propagation has no DOM element. The React provider intentionally
renders a div because CSS custom-property inheritance needs a concrete scope for
nested themes. Standard div attributes are forwarded so applications can place
that scope deliberately in their layout.
