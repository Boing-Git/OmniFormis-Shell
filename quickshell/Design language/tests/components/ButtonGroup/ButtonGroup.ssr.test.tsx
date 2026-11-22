// @vitest-environment jsdom

import { act } from '@testing-library/react'
import { hydrateRoot } from 'react-dom/client'
import { renderToString } from 'react-dom/server'
import { Button } from '../../../src/components/Button'
import { ButtonGroup } from '../../../src/components/ButtonGroup'

describe('ButtonGroup server rendering', () => {
  it('renders deterministic markup with no inline styles injected as <style> tags', () => {
    const render = () =>
      renderToString(
        <ButtonGroup aria-label="Actions">
          <Button>One</Button>
          <Button>Two</Button>
        </ButtonGroup>,
      )
    const first = render()
    expect(first).toBe(render())
    expect(first).toContain('role="group"')
    expect(first).not.toContain('<style')
  })

  it('hydrates with zero markup delta -- this component is a pure function of props with no client-only measurement effect', async () => {
    const tree = (
      <ButtonGroup aria-label="Actions">
        <Button>One</Button>
        <Button>Two</Button>
      </ButtonGroup>
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
    expect(recoverableErrors).toEqual([])
    expect(document.querySelector('style')).toBeNull()
    expect(container.innerHTML).toBe(serverHtml)

    await act(async () => root.unmount())
    container.remove()
  })
})
