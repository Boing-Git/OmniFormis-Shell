// @vitest-environment jsdom

import { act } from '@testing-library/react'
import { hydrateRoot } from 'react-dom/client'
import { renderToString } from 'react-dom/server'
import { FloatingToolbar } from '../../../src/components/FloatingToolbar'

describe('FloatingToolbar server rendering', () => {
  it('renders deterministic markup with no inline styles injected as <style> tags', () => {
    const render = () =>
      renderToString(
        <FloatingToolbar aria-label="Actions">
          <button type="button">One</button>
          <button type="button">Two</button>
        </FloatingToolbar>,
      )
    const first = render()
    expect(first).toBe(render())
    expect(first).toContain('role="toolbar"')
    expect(first).toContain('tabindex="0"')
    expect(first).toContain('tabindex="-1"')
    expect(first).not.toContain('<style')
  })

  it('hydrates with zero markup delta -- this component is a pure function of props with no client-only measurement effect', async () => {
    const tree = (
      <FloatingToolbar aria-label="Actions">
        <button type="button">One</button>
        <button type="button">Two</button>
      </FloatingToolbar>
    )
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
    expect(container.innerHTML).toBe(serverHtml)

    await act(async () => root.unmount())
    container.remove()
  })
})
