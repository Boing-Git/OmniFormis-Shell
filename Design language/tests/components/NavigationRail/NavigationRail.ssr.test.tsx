// @vitest-environment jsdom

import { act } from '@testing-library/react'
import { hydrateRoot } from 'react-dom/client'
import { renderToString } from 'react-dom/server'
import { NavigationRail } from '../../../src/components/NavigationRail'
import type { NavigationItem } from '../../../src/components/NavigationRail'

const items: NavigationItem[] = [{ value: 'home', label: 'Home', icon: <span /> }]

describe('NavigationRail server rendering', () => {
  it('renders deterministic markup with no inline styles injected', () => {
    const render = () => renderToString(<NavigationRail items={items} />)
    const first = render()
    expect(first).toBe(render())
    expect(first).toContain('m3e-navigation-rail')
    expect(first).not.toContain('<style')
  })

  it('hydrates without changing markup or injecting styles', async () => {
    const tree = <NavigationRail items={items} />
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

    await act(async () => root.unmount())
    container.remove()
  })
})
