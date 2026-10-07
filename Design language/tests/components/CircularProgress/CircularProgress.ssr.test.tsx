// @vitest-environment jsdom

import { act } from '@testing-library/react'
import { hydrateRoot } from 'react-dom/client'
import { renderToString } from 'react-dom/server'
import { CircularProgress } from '../../../src/components/CircularProgress'

describe('CircularProgress server rendering', () => {
  it('renders deterministic markup with no inline styles injected as <style> tags', () => {
    const render = () => renderToString(<CircularProgress aria-label="Progress" value={0.4} />)
    const first = render()
    expect(first).toBe(render())
    expect(first).toContain('role="progressbar"')
    expect(first).toContain('aria-valuenow="0.4"')
    expect(first).not.toContain('<style')
  })

  it('renders deterministic indeterminate markup with no aria-valuenow and no track element', () => {
    const render = () => renderToString(<CircularProgress aria-label="Loading" />)
    const first = render()
    expect(first).toBe(render())
    expect(first).not.toContain('aria-valuenow')
    expect(first).not.toContain('m3e-circular-progress__track')
  })

  it('hydrates with zero markup delta — this component is a pure function of props with no client-only measurement effect', async () => {
    const tree = <CircularProgress aria-label="Progress" value={0.4} />
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
