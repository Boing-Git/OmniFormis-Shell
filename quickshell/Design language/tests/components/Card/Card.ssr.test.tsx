// @vitest-environment jsdom

import { act } from '@testing-library/react'
import { hydrateRoot } from 'react-dom/client'
import { renderToString } from 'react-dom/server'
import { Card } from '../../../src'

describe('Card server rendering', () => {
  it('renders deterministic passive and interactive markup', () => {
    const render = () => renderToString(
      <>
        <Card as="section" variant="outlined" aria-label="Summary">
          <h2>Overview</h2>
          <p>Passive rich content</p>
        </Card>
        <Card interactive variant="elevated" type="submit" name="intent" value="open">
          <span>Open overview</span>
        </Card>
      </>,
    )

    expect(render()).toBe(render())
    expect(render()).toContain('<section')
    expect(render()).toContain('<button')
    expect(render()).toContain('type="submit"')
    expect(render()).toContain('data-m3e-variant="outlined"')
    expect(render()).toContain('data-m3e-interactive="true"')
    expect(render()).not.toContain('aria-pressed')
  })

  it('hydrates both modes without changing markup or injecting styles', async () => {
    const tree = (
      <div>
        <Card variant="filled">Server summary</Card>
        <Card interactive variant="outlined" aria-describedby="details">
          <span>Open</span>
          <small id="details">Details</small>
        </Card>
      </div>
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
