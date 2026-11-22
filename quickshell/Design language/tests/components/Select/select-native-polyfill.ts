/**
 * jsdom implements no layout engine and so has no `Element.scrollIntoView`
 * at all — a test-environment gap, not a product concern, since every
 * target browser (Chrome 120+, Firefox 121+, Safari 17.2+) implements it
 * natively. Mirrors the Dialog `showModal`/`show`/`close` test-only
 * polyfill precedent.
 */
export function installScrollIntoViewPolyfill(): void {
  if (typeof Element.prototype.scrollIntoView === 'function') return
  Element.prototype.scrollIntoView = function scrollIntoView() {
    // No-op: jsdom has no scroll position to update.
  }
}
