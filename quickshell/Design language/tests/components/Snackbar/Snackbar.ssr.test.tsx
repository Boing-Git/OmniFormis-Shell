// @vitest-environment jsdom

import { act } from '@testing-library/react'
import { hydrateRoot } from 'react-dom/client'
import { renderToString } from 'react-dom/server'
import { Snackbar } from '../../../src/components/Snackbar'

describe('Snackbar server rendering', () => {
  it('renders no popover markup at all, open or closed — a portal has no server container', () => {
    const render = () => renderToString(<Snackbar message="Saved" open onOpenChange={() => undefined} />)
    const first = render()
    expect(first).toBe(render())
    expect(first).not.toContain('role="status"')
    expect(first).not.toContain('m3e-snackbar')

    expect(
      renderToString(<Snackbar message="Saved" open={false} onOpenChange={() => undefined} />),
    ).not.toContain('role="status"')
  })

  it('hydrates without changing markup or injecting styles, then mounts the snackbar on the client', async () => {
    const tree = <Snackbar message="Saved" open onOpenChange={() => undefined} />
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
    expect(document.querySelector('[role="status"]')).not.toBeNull()

    await act(async () => root.unmount())
    container.remove()
  })
})
