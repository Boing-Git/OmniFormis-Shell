// @vitest-environment jsdom

import { act } from '@testing-library/react'
import { hydrateRoot } from 'react-dom/client'
import { renderToString } from 'react-dom/server'
import { beforeAll } from 'vitest'
import { NavigationDrawer } from '../../../src/components/NavigationDrawer'
import type { NavigationItem } from '../../../src/components/NavigationDrawer'
import { installDialogPolyfill } from '../Dialog/dialog-native-polyfill'

beforeAll(installDialogPolyfill)

const items: NavigationItem[] = [{ value: 'inbox', label: 'Inbox', icon: <span /> }]

describe('NavigationDrawer server rendering', () => {
  it('permanent variant renders deterministic markup with no inline styles injected', () => {
    const render = () => renderToString(<NavigationDrawer items={items} variant="permanent" />)
    const first = render()
    expect(first).toBe(render())
    expect(first).toContain('m3e-navigation-drawer')
    expect(first).not.toContain('<style')
  })

  it('modal variant renders closed (no open attribute) on the server', () => {
    const html = renderToString(
      <NavigationDrawer items={items} variant="modal" open onOpenChange={() => undefined} />,
    )
    expect(html).not.toContain(' open')
  })

  it('hydrates the permanent variant without changing markup or injecting styles', async () => {
    const tree = <NavigationDrawer items={items} variant="permanent" />
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
