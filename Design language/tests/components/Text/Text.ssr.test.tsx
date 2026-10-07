// @vitest-environment jsdom

import { act } from '@testing-library/react'
import { hydrateRoot } from 'react-dom/client'
import { renderToString } from 'react-dom/server'
import { Text } from '../../../src/components/Text'

describe('Text server rendering', () => {
  it('renders deterministic semantic markup', () => {
    const render = () =>
      renderToString(
        <Text as="h3" variant="displaySmall" emphasis="emphasized" id="release-title">
          Expressive release
        </Text>,
      )

    expect(render()).toBe(render())
    expect(render()).toContain('<h3')
    expect(render()).toContain('data-m3e-variant="displaySmall"')
    expect(render()).toContain('data-m3e-emphasis="emphasized"')
    expect(render()).not.toContain('tabindex')
    expect(render()).not.toContain('role=')
  })

  it('hydrates without changing the rendered contract', async () => {
    const tree = (
      <Text as="p" variant="bodyMedium" emphasis="baseline" className="summary">
        Hydrated text
      </Text>
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
