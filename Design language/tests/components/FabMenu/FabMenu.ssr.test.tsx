// @vitest-environment jsdom

import { act } from '@testing-library/react'
import { hydrateRoot } from 'react-dom/client'
import { renderToString } from 'react-dom/server'
import { FabMenu, FabMenuItem } from '../../../src/components/FabMenu'

describe('FabMenu server rendering', () => {
  it('renders deterministic collapsed markup with no inline styles injected as <style> tags', () => {
    const render = () =>
      renderToString(
        <FabMenu triggerLabel="Create" icon={<svg />} closeIcon={<svg />}>
          <FabMenuItem icon={<svg />}>Edit</FabMenuItem>
        </FabMenu>,
      )
    const first = render()
    expect(first).toBe(render())
    expect(first).toContain('aria-expanded="false"')
    expect(first).toContain('inert=""')
    expect(first).not.toContain('<style')
  })

  it('hydrates with zero markup delta -- this component is a pure function of props with no client-only measurement effect', async () => {
    const tree = (
      <FabMenu triggerLabel="Create" icon={<svg />} closeIcon={<svg />}>
        <FabMenuItem icon={<svg />}>Edit</FabMenuItem>
      </FabMenu>
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

  it('hydrates a defaultExpanded menu with zero markup delta', async () => {
    const tree = (
      <FabMenu triggerLabel="Create" icon={<svg />} closeIcon={<svg />} defaultExpanded>
        <FabMenuItem icon={<svg />}>Edit</FabMenuItem>
      </FabMenu>
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
    expect(container.innerHTML).toBe(serverHtml)

    await act(async () => root.unmount())
    container.remove()
  })
})
