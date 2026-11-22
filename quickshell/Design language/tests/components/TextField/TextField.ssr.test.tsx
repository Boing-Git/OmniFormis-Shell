// @vitest-environment jsdom

import { act } from '@testing-library/react'
import { hydrateRoot } from 'react-dom/client'
import { renderToString } from 'react-dom/server'
import { TextField } from '../../../src'

describe('TextField server rendering', () => {
  it('renders deterministic markup for every resolved state', () => {
    const render = () => renderToString(
      <>
        <TextField label="Name" />
        <TextField variant="outlined" label="Email" defaultValue="ada@example.com" />
        <TextField label="Locked" disabled defaultValue="Read only" />
        <TextField label="Promo code" error supportingText="This code has expired" />
      </>,
    )

    expect(render()).toBe(render())
    expect(render()).toContain('class="m3e-text-field"')
    expect(render()).toContain('data-m3e-variant="filled"')
    expect(render()).toContain('data-m3e-variant="outlined"')
    expect(render()).toContain('data-m3e-error="true"')
    expect(render()).toContain('data-m3e-disabled="true"')
    expect(render()).toContain('placeholder=" "')
    expect(render()).toContain('class="m3e-text-field__hit-target"')
  })

  it('hydrates without changing markup or injecting styles', async () => {
    const tree = (
      <div>
        <TextField label="Name" defaultValue="Ada" />
        <TextField
          variant="outlined"
          label="Search"
          leadingIcon={<span>*</span>}
          supportingText="Press enter to search"
        />
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
