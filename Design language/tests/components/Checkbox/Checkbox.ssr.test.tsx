// @vitest-environment jsdom

import { act } from '@testing-library/react'
import { hydrateRoot } from 'react-dom/client'
import { renderToString } from 'react-dom/server'
import { Checkbox } from '../../../src'

describe('Checkbox server rendering', () => {
  it('renders deterministic markup for every resolved state', () => {
    const render = () => renderToString(
      <>
        <Checkbox aria-label="Unchecked" />
        <Checkbox aria-label="Checked" defaultChecked />
        <Checkbox aria-label="Mixed" indeterminate />
        <Checkbox aria-label="Disabled" disabled />
      </>,
    )

    expect(render()).toBe(render())
    expect(render()).toContain('type="checkbox"')
    expect(render()).toContain('data-m3e-state="unchecked"')
    expect(render()).toContain('data-m3e-state="checked"')
    // The indeterminate DOM property cannot be serialized, so server markup
    // carries the mixed state that assistive technology reads.
    expect(render()).toContain('data-m3e-state="indeterminate"')
    expect(render()).toContain('aria-checked="mixed"')
    expect(render()).toContain('data-m3e-disabled="true"')
  })

  it('hydrates without changing markup or injecting styles', async () => {
    const tree = (
      <div>
        <Checkbox aria-label="Terms" defaultChecked />
        <Checkbox aria-label="Partial" indeterminate />
      </div>
    )
    const container = document.createElement('div')
    container.innerHTML = renderToString(tree)
    document.body.append(container)
    // Compare parsed markup so void-element serialization differences between
    // the server string and the DOM cannot mask a real hydration change.
    const serverHtml = container.innerHTML
    const recoverableErrors: unknown[] = []
    const root = hydrateRoot(container, tree, {
      onRecoverableError: (error) => recoverableErrors.push(error),
    })

    await act(async () => {})
    expect(container.innerHTML).toBe(serverHtml)
    expect(recoverableErrors).toEqual([])
    expect(document.querySelector('style')).toBeNull()

    const mixed = container.querySelectorAll('input')[1] as HTMLInputElement
    expect(mixed.indeterminate).toBe(true)

    await act(async () => root.unmount())
    container.remove()
  })
})
