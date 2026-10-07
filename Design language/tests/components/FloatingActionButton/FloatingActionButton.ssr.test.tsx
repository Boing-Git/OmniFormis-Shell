// @vitest-environment jsdom

import { act } from '@testing-library/react'
import { hydrateRoot } from 'react-dom/client'
import { renderToString } from 'react-dom/server'
import { FloatingActionButton, Icon } from '../../../src'

describe('FloatingActionButton server rendering', () => {
  it('renders deterministic native extended markup', () => {
    const render = () => renderToString(
      <FloatingActionButton
        icon={<Icon source="edit" />}
        label="Compose"
        size="large"
        elevation="lowered"
        expanded={false}
      />,
    )

    expect(render()).toBe(render())
    expect(render()).toContain('<button')
    expect(render()).toContain('type="button"')
    expect(render()).toContain('data-m3e-size="large"')
    expect(render()).toContain('data-m3e-elevation="lowered"')
    expect(render()).toContain('data-m3e-extended="true"')
    expect(render()).toContain('data-m3e-expanded="false"')
    expect(render()).toContain('Compose')
    expect(render()).not.toContain('aria-pressed')
    expect(render()).not.toContain('tabindex')
  })

  it('hydrates uncontrolled toggle state without changing markup or injecting styles', async () => {
    const tree = (
      <FloatingActionButton
        aria-label="Open actions"
        icon={<Icon source="add" />}
        toggle
        defaultSelected
        selectedIcon={<Icon source="close" />}
      />
    )
    const serverHtml = renderToString(tree)
    const container = document.createElement('div')
    container.innerHTML = serverHtml
    document.body.append(container)
    const recoverableErrors: unknown[] = []
    const root = hydrateRoot(container, tree, {
      onRecoverableError: (error) => recoverableErrors.push(error),
    })

    await act(async () => {})
    expect(container.innerHTML).toBe(serverHtml)
    expect(recoverableErrors).toEqual([])
    expect(document.querySelector('style')).toBeNull()
    await act(async () => root.unmount())
    container.remove()
  })
})
