// @vitest-environment jsdom

import { act } from '@testing-library/react'
import { hydrateRoot } from 'react-dom/client'
import { renderToString } from 'react-dom/server'
import { WavyProgress } from '../../../src/components/WavyProgress'

describe('WavyProgress server rendering', () => {
  it('renders deterministic markup for both shapes with no inline styles injected as <style> tags', () => {
    const renderLinear = () => renderToString(<WavyProgress aria-label="Upload" value={0.4} />)
    const first = renderLinear()
    expect(first).toBe(renderLinear())
    expect(first).toContain('role="progressbar"')
    expect(first).toContain('aria-valuenow="0.4"')
    expect(first).not.toContain('<style')

    const renderCircular = () =>
      renderToString(<WavyProgress aria-label="Progress" shape="circular" value={0.4} />)
    const firstCircular = renderCircular()
    expect(firstCircular).toBe(renderCircular())
    expect(firstCircular).not.toContain('<style')
  })

  it('renders deterministic indeterminate markup with no aria-valuenow', () => {
    const render = () => renderToString(<WavyProgress aria-label="Syncing" />)
    const first = render()
    expect(first).toBe(render())
    expect(first).not.toContain('aria-valuenow')
  })

  it('hydrates with zero markup delta — this component is a pure function of props with no client-only measurement effect', async () => {
    const tree = <WavyProgress aria-label="Upload" value={0.4} />
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
