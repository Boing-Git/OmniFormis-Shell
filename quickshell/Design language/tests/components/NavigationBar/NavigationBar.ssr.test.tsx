// @vitest-environment jsdom

import { act } from '@testing-library/react'
import { hydrateRoot } from 'react-dom/client'
import { renderToString } from 'react-dom/server'
import { NavigationBar } from '../../../src/components/NavigationBar'
import type { NavigationItem } from '../../../src/components/NavigationBar'

const items: NavigationItem[] = [
  { value: 'home', label: 'Home', icon: <span /> },
  { value: 'search', label: 'Search', icon: <span /> },
]

describe('NavigationBar server rendering', () => {
  it('renders deterministic markup with no inline styles injected', () => {
    const render = () => renderToString(<NavigationBar items={items} />)
    const first = render()
    expect(first).toBe(render())
    expect(first).toContain('m3e-navigation-bar')
    expect(first).not.toContain('<style')
  })

  it('hydrates without changing markup or injecting styles', async () => {
    const tree = <NavigationBar items={items} />
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
