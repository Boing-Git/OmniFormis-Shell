// @vitest-environment jsdom

import { act } from '@testing-library/react'
import { hydrateRoot } from 'react-dom/client'
import { renderToString } from 'react-dom/server'
import { Button, Icon } from '../../../src'

describe('Button server rendering', () => {
  it('renders deterministic native markup for a configured button', () => {
    const render = () => renderToString(
      <Button
        variant="outlined"
        size="large"
        width="full"
        shape="square"
        type="submit"
        name="intent"
        value="publish"
        leadingIcon={<Icon source="publish" />}
        id="publish"
      >
        Publish
      </Button>,
    )

    expect(render()).toBe(render())
    expect(render()).toContain('<button')
    expect(render()).toContain('type="submit"')
    expect(render()).toContain('data-m3e-variant="outlined"')
    expect(render()).toContain('data-m3e-size="large"')
    expect(render()).toContain('data-m3e-width="full"')
    expect(render()).toContain('data-m3e-shape="square"')
    expect(render()).not.toContain('tabindex')
  })

  it('hydrates without changing markup or injecting styles', async () => {
    const tree = (
      <Button
        variant="tonal"
        size="medium"
        trailingIcon={<Icon source="arrow_forward" mirrored />}
        aria-describedby="continue-help"
      >
        Continue
      </Button>
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
