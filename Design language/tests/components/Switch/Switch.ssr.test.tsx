// @vitest-environment jsdom

import { act } from '@testing-library/react'
import { hydrateRoot } from 'react-dom/client'
import { renderToString } from 'react-dom/server'
import { Switch } from '../../../src'

describe('Switch server rendering', () => {
  it('renders deterministic markup for every resolved state', () => {
    const render = () => renderToString(
      <>
        <Switch aria-label="Unchecked" />
        <Switch aria-label="Checked" defaultChecked />
        <Switch aria-label="Disabled" disabled />
        <Switch aria-label="With icon" thumbIcon={<span>*</span>} />
      </>,
    )

    expect(render()).toBe(render())
    expect(render()).toContain('type="checkbox"')
    expect(render()).toContain('role="switch"')
    expect(render()).toContain('data-m3e-state="unchecked"')
    expect(render()).toContain('data-m3e-state="checked"')
    expect(render()).toContain('data-m3e-disabled="true"')
    expect(render()).toContain('data-m3e-has-thumb-icon="true"')
  })

  it('hydrates without changing markup or injecting styles', async () => {
    const tree = (
      <div>
        <Switch aria-label="Notifications" defaultChecked />
        <Switch aria-label="Wi-Fi" thumbIcon={<span>*</span>} />
      </div>
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
    expect(container.innerHTML).toBe(serverHtml)
    expect(recoverableErrors).toEqual([])
    expect(document.querySelector('style')).toBeNull()

    await act(async () => root.unmount())
    container.remove()
  })
})
