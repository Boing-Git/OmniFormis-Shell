// @vitest-environment jsdom

import { act } from '@testing-library/react'
import { hydrateRoot } from 'react-dom/client'
import { renderToString } from 'react-dom/server'
import { Radio } from '../../../src'

describe('Radio server rendering', () => {
  it('renders deterministic markup for every resolved state', () => {
    const render = () => renderToString(
      <>
        <Radio name="plan" aria-label="Unchecked" />
        <Radio name="plan" aria-label="Checked" defaultChecked />
        <Radio name="plan" aria-label="Disabled" disabled />
      </>,
    )

    expect(render()).toBe(render())
    expect(render()).toContain('type="radio"')
    expect(render()).toContain('data-m3e-state="unchecked"')
    expect(render()).toContain('data-m3e-state="checked"')
    expect(render()).toContain('data-m3e-disabled="true"')
  })

  it('hydrates without changing markup or injecting styles', async () => {
    const tree = (
      <div>
        <Radio name="plan" aria-label="Basic" defaultChecked />
        <Radio name="plan" aria-label="Pro" />
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
