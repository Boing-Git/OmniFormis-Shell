// @vitest-environment jsdom

import { act } from '@testing-library/react'
import { hydrateRoot } from 'react-dom/client'
import { renderToString } from 'react-dom/server'
import { beforeAll } from 'vitest'
import { Tabs } from '../../../src/components/Tabs'
import type { TabItem } from '../../../src/components/Tabs'
import { installTabsNativePolyfills } from './tabs-native-polyfill'

beforeAll(installTabsNativePolyfills)

const items: TabItem[] = [
  { value: 'photos', label: 'Photos' },
  { value: 'files', label: 'Files' },
]

describe('Tabs server rendering', () => {
  it('renders deterministic markup, selecting the first item, with no inline styles injected', () => {
    const render = () => renderToString(<Tabs aria-label="Library" items={items} />)
    const first = render()
    expect(first).toBe(render())
    expect(first).toContain('role="tablist"')
    expect(first).toContain('aria-selected="true"')
    expect(first).not.toContain('<style')
  })

  it('hydrates without changing markup (beyond the imperative indicator measurement), then measures the indicator on the client', async () => {
    const tree = <Tabs aria-label="Library" items={items} />
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

    // The only post-hydration markup delta is the imperative indicator
    // measurement (`data-m3e-ready` + an inline `style`) — the same
    // "imperative client-only mutation, visible in innerHTML" category as
    // Tooltip's aria-describedby delta, since a plain `useEffect` (not
    // `useLayoutEffect`, to avoid an SSR warning) performs the first
    // measurement imperatively after mount.
    const indicator = document.querySelector('.m3e-tabs__indicator')!
    expect(indicator.getAttribute('data-m3e-ready')).toBe('true')
    indicator.setAttribute('data-m3e-ready', 'false')
    indicator.removeAttribute('style')
    expect(container.innerHTML).toBe(serverHtml)

    await act(async () => root.unmount())
    container.remove()
  })
})
