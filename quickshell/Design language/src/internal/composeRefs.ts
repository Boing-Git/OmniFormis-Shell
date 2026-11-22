import type { ForwardedRef, RefCallback } from 'react'

/**
 * Assigns one node to a consumer ref and a library-owned ref. Components that
 * must read their own DOM node still forward the primary semantic element.
 */
export function composeRefs<TElement>(
  ...refs: readonly (ForwardedRef<TElement> | undefined)[]
): RefCallback<TElement> {
  return (node) => {
    for (const ref of refs) {
      if (typeof ref === 'function') {
        ref(node)
        continue
      }
      if (ref) ref.current = node
    }
  }
}
