// @vitest-environment jsdom

import { act } from '@testing-library/react'
import { hydrateRoot } from 'react-dom/client'
import { renderToString } from 'react-dom/server'
import { NavigationSuite } from '../../../src/components/NavigationSuite'
import type { NavigationItem } from '../../../src/components/NavigationSuite'
import { installWidthMatchMedia } from './navigation-suite-native-polyfill'

const items: NavigationItem[] = [{ value: 'home', label: 'Home', icon: <span /> }]

describe('NavigationSuite server rendering', () => {
  it('renders the compact tier (NavigationBar) deterministically — no real viewport exists to measure', () => {
    const render = () => renderToString(<NavigationSuite items={items} />)
    const first = render()
    expect(first).toBe(render())
    expect(first).toContain('m3e-navigation-bar')
    expect(first).not.toContain('m3e-navigation-rail')
    expect(first).not.toContain('<style')
  })

  it('hydrates at the compact tier, then corrects to the real tier once measured on the client', async () => {
    installWidthMatchMedia(900)
    const tree = <NavigationSuite items={items} />
    const container = document.createElement('div')
    container.innerHTML = renderToString(tree)
    document.body.append(container)

    const recoverableErrors: unknown[] = []
    const root = hydrateRoot(container, tree, {
      onRecoverableError: (error) => recoverableErrors.push(error),
    })

    await act(async () => {})
    expect(recoverableErrors).toEqual([])
    expect(document.querySelector('style')).toBeNull()
    // The post-hydration client effect measures the real viewport and
    // corrects the layout — the same "renders a reasonable default before
    // a real measurement is available" category Tabs'/Snackbar's own
    // defaults already established.
    expect(document.querySelector('.m3e-navigation-drawer')).not.toBeNull()

    await act(async () => root.unmount())
    container.remove()
  })
})
