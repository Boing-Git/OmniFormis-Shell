/**
 * jsdom implements no layout engine and so has neither `ResizeObserver` nor
 * `Element.scrollIntoView` — a test-environment gap, not a product concern,
 * since every target browser (Chrome 120+, Firefox 121+, Safari 17.2+)
 * implements both natively. Mirrors the Select `scrollIntoView` and Dialog
 * `showModal`/`show`/`close` test-only polyfill precedents.
 */
export function installTabsNativePolyfills(): void {
  if (typeof Element.prototype.scrollIntoView !== 'function') {
    Element.prototype.scrollIntoView = function scrollIntoView() {
      // No-op: jsdom has no scroll position to update.
    }
  }
  if (typeof globalThis.ResizeObserver !== 'function') {
    globalThis.ResizeObserver = class ResizeObserver {
      observe() {
        // No-op: jsdom performs no layout, so there is nothing to observe.
      }
      unobserve() {}
      disconnect() {}
    }
  }
}
