// @vitest-environment jsdom

import { act } from '@testing-library/react'
import { hydrateRoot } from 'react-dom/client'
import { renderToString } from 'react-dom/server'
import { LoadingIndicator } from '../../../src/components/LoadingIndicator'

describe('LoadingIndicator server rendering', () => {
  it('renders deterministic determinate markup with no inline styles injected as <style> tags', () => {
    const render = () => renderToString(<LoadingIndicator aria-label="Loading" value={0.4} />)
    const first = render()
    expect(first).toBe(render())
    expect(first).toContain('role="progressbar"')
    expect(first).toContain('aria-valuenow="0.4"')
    expect(first).not.toContain('<style')
  })

  it('renders deterministic indeterminate markup with seven segments and no aria-valuenow', () => {
    const render = () => renderToString(<LoadingIndicator aria-label="Loading" />)
    const first = render()
    expect(first).toBe(render())
    expect(first).not.toContain('aria-valuenow')
    expect(first.match(/m3e-loading-indicator__segment-\d/g)).toHaveLength(7)
  })

  it('hydrates with zero markup delta — this component is a pure function of props with no client-only measurement effect', async () => {
    const tree = <LoadingIndicator aria-label="Loading" value={0.4} />
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

  it('hydrates the indeterminate variant with zero markup delta', async () => {
    const tree = <LoadingIndicator aria-label="Loading" />
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

    await act(async () => root.unmount())
    container.remove()
  })
})
