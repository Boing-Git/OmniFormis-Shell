/**
 * jsdom implements `<dialog>` markup and the reflected `open` attribute but,
 * as of the pinned jsdom version, none of `showModal()`/`show()`/`close()` —
 * calling any of them throws `TypeError: ... is not a function`. This is a
 * test-environment gap (every target browser implements all three natively
 * since March 2022), not a product concern, so the shim lives here rather
 * than in any application code. It reproduces just enough of the real
 * `HTMLDialogElement` contract for Dialog's own effects to run: toggling the
 * reflected `open` attribute and firing a `close` event when `close()` runs
 * on an open dialog.
 */
export function installDialogPolyfill(): void {
  const proto = window.HTMLDialogElement.prototype as HTMLDialogElement & {
    showModal?: () => void
    show?: () => void
    close?: (returnValue?: string) => void
  }
  if (typeof proto.showModal === 'function') return

  if (!('returnValue' in proto)) {
    Object.defineProperty(proto, 'returnValue', {
      configurable: true,
      writable: true,
      value: '',
    })
  }

  proto.showModal = function (this: HTMLDialogElement) {
    this.setAttribute('open', '')
  }
  proto.show = function (this: HTMLDialogElement) {
    this.setAttribute('open', '')
  }
  proto.close = function (this: HTMLDialogElement, returnValue?: string) {
    if (returnValue !== undefined) this.returnValue = returnValue
    const wasOpen = this.hasAttribute('open')
    this.removeAttribute('open')
    if (wasOpen) this.dispatchEvent(new Event('close'))
  }
}
