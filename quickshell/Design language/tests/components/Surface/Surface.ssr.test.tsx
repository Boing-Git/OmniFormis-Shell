// @vitest-environment jsdom

import { act } from '@testing-library/react'
import { hydrateRoot } from 'react-dom/client'
import { renderToString } from 'react-dom/server'
import { Surface } from '../../../src/components/Surface'

describe('Surface server rendering', () => {
  it('renders deterministic semantic markup', () => {
    const render = () =>
      renderToString(
        <Surface as="section" color="surface-container-high" shape="large" shadowElevation={2}>
          Server surface
        </Surface>,
      )

    expect(render()).toBe(render())
    expect(render()).toContain('<section')
    expect(render()).toContain('data-m3e-color="surface-container-high"')
    expect(render()).not.toContain('tabindex')
    expect(render()).not.toContain('role=')
  })

  it('hydrates without changing the rendered contract', async () => {
    const tree = (
      <Surface as="article" color="surface" tonalElevation={3} shape="medium">
        Hydrated surface
      </Surface>
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
    await act(async () => root.unmount())
    container.remove()
  })
})
