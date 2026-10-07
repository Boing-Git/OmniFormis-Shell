// @vitest-environment jsdom

import { act } from '@testing-library/react'
import { useRef } from 'react'
import { hydrateRoot } from 'react-dom/client'
import { renderToString } from 'react-dom/server'
import { Menu } from '../../../src/components/Menu'
import type { MenuItem } from '../../../src/components/Menu'

const items: MenuItem[] = [{ value: 'copy', label: 'Copy' }]

function Anchored({ open }: { readonly open: boolean }) {
  const anchorRef = useRef<HTMLButtonElement>(null)
  return (
    <>
      <button type="button" ref={anchorRef}>
        Actions
      </button>
      <Menu anchorRef={anchorRef} items={items} open={open} onOpenChange={() => undefined} />
    </>
  )
}

describe('Menu server rendering', () => {
  it('renders no popover markup at all, open or closed — a portal has no server container', () => {
    const render = () => renderToString(<Anchored open />)
    const first = render()
    expect(first).toBe(render())
    expect(first).not.toContain('role="menu"')
    expect(first).not.toContain('m3e-menu')

    expect(renderToString(<Anchored open={false} />)).not.toContain('role="menu"')
  })

  it('hydrates without changing markup or injecting styles, then mounts the popover on the client', async () => {
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
    expect(container.innerHTML).toBe(serverHtml)
    expect(document.querySelector('style')).toBeNull()
    // The post-hydration client effect performs the first mount imperatively.
    expect(document.querySelector('[role="menu"]')).not.toBeNull()

    await act(async () => root.unmount())
    container.remove()
  })
})
