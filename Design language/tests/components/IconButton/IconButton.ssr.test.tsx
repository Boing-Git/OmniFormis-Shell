// @vitest-environment jsdom

import { act } from '@testing-library/react'
import { hydrateRoot } from 'react-dom/client'
import { renderToString } from 'react-dom/server'
import { Icon, IconButton } from '../../../src'

describe('IconButton server rendering', () => {
  it('renders deterministic native toggle markup', () => {
    const render = () => renderToString(
      <IconButton
        aria-label="Favorite"
        variant="outlined"
        size="large"
        width="wide"
        shape="square"
        toggle
        defaultSelected
        selectedIcon={<Icon source="favorite" fill={1} />}
      >
        <Icon source="favorite" />
      </IconButton>,
    )

    expect(render()).toBe(render())
    expect(render()).toContain('<button')
    expect(render()).toContain('type="button"')
    expect(render()).toContain('aria-pressed="true"')
    expect(render()).toContain('data-m3e-variant="outlined"')
    expect(render()).toContain('data-m3e-size="large"')
    expect(render()).toContain('data-m3e-width="wide"')
    expect(render()).toContain('data-m3e-shape="square"')
    expect(render()).not.toContain('tabindex')
  })

  it('hydrates uncontrolled state without changing markup or injecting styles', async () => {
    const tree = (
      <IconButton aria-label="Favorite" variant="tonal" toggle defaultSelected>
        <Icon source="favorite" />
      </IconButton>
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
