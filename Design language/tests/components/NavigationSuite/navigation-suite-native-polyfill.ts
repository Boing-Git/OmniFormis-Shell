/**
 * jsdom implements no layout engine and so has no real viewport width, and
 * throws on `window.matchMedia` unless a test explicitly stubs it — a
 * test-environment gap, not a product concern, since every target browser
 * implements `matchMedia` natively. Reproduces enough of `MediaQueryList`
 * for `NavigationSuite`'s own `min-width` breakpoint queries: each query
 * string gets its own stable `MediaQueryList`, and `setWidth` recomputes
 * `matches` for every registered query and fires its `change` listeners.
 */
export interface WidthMatchMediaController {
  readonly setWidth: (widthPx: number) => void
}

export function installWidthMatchMedia(initialWidthPx = 320): WidthMatchMediaController {
  let width = initialWidthPx
  const registry = new Map<
    string,
    { readonly mql: MediaQueryList; readonly listeners: Set<(event: MediaQueryListEvent) => void> }
  >()

  function computeMatches(query: string): boolean {
    const match = /min-width:\s*(\d+)px/.exec(query)
    if (!match) return false
    return width >= Number(match[1])
  }

  Object.defineProperty(window, 'matchMedia', {
    configurable: true,
    value: (query: string): MediaQueryList => {
      const existing = registry.get(query)
      if (existing) return existing.mql
      const listeners = new Set<(event: MediaQueryListEvent) => void>()
      const mql = {
        media: query,
        get matches() {
          return computeMatches(query)
        },
        onchange: null,
        addEventListener: (_type: string, listener: (event: MediaQueryListEvent) => void) => {
          listeners.add(listener)
        },
        removeEventListener: (_type: string, listener: (event: MediaQueryListEvent) => void) => {
          listeners.delete(listener)
        },
        addListener: () => {},
        removeListener: () => {},
        dispatchEvent: () => true,
      } as MediaQueryList
      registry.set(query, { mql, listeners })
      return mql
    },
  })

  return {
    setWidth(widthPx: number) {
      width = widthPx
      for (const { mql, listeners } of registry.values()) {
        const event = { matches: mql.matches, media: mql.media } as MediaQueryListEvent
        listeners.forEach((listener) => listener(event))
      }
    },
  }
}
