// @vitest-environment jsdom

import { act } from '@testing-library/react'
import { useRef } from 'react'
import { hydrateRoot } from 'react-dom/client'
import { renderToString } from 'react-dom/server'
import { Tooltip } from '../../../src/components/Tooltip'

function Anchored({ open }: { readonly open: boolean }) {
  const anchorRef = useRef<HTMLButtonElement>(null)
  return (
    <>
      <button type="button" ref={anchorRef}>
        Save
      </button>
      <Tooltip anchorRef={anchorRef} content="Save the document" open={open} onOpenChange={() => undefined} />
    </>
  )
}

describe('Tooltip server rendering', () => {
  it('renders no popover markup at all, open or closed — a portal has no server container', () => {
    const render = () => renderToString(<Anchored open />)
    const first = render()
    expect(first).toBe(render())
    expect(first).not.toContain('role="tooltip"')
    expect(first).not.toContain('m3e-tooltip')

    expect(renderToString(<Anchored open={false} />)).not.toContain('role="tooltip"')
  })

  it('hydrates without changing button markup (beyond the imperative aria-describedby link) or injecting styles, then mounts the popover on the client', async () => {
    const tree = <Anchored open />
    const container = document.createElement('div')
    container.innerHTML = renderToString(tree)
    document.body.append(container)
    const serverHtml = container.innerHTML

    const recoverableErrors: unknown[] = []
    const root = hydrateRoot(container, tree, {
      onRecoverableError: (error) => recoverableErrors.push(error),
    })

    await act(async () => {})
    expect(recoverableErrors).toEqual([])
    expect(document.querySelector('style')).toBeNull()
    const tooltip = document.querySelector('[role="tooltip"]')
    expect(tooltip).not.toBeNull()

    // The only post-hydration markup delta is the imperative
    // `aria-describedby` link (see Tooltip.a11y.test.tsx) — not part of
    // React's own reconciled output for the consumer's button, the same
    // "library owns unambiguous wiring" imperative-DOM category as Menu's
    // imperative focus() call, except this one is visible in innerHTML
    // since it is a real attribute rather than a non-serializable DOM
    // state like focus.
    const button = document.querySelector('button')!
    expect(button.getAttribute('aria-describedby')).toBe(tooltip!.id)
    button.removeAttribute('aria-describedby')
    expect(container.innerHTML).toBe(serverHtml)

    await act(async () => root.unmount())
    container.remove()
  })
})
