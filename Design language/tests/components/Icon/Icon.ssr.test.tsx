// @vitest-environment jsdom

import { act } from '@testing-library/react'
import { hydrateRoot } from 'react-dom/client'
import { renderToString } from 'react-dom/server'
import {
  Icon,
  type IconSourceProps,
} from '../../../src/components/Icon'

function ServerSource(props: IconSourceProps) {
  return (
    <svg {...props} viewBox="0 0 24 24">
      <path d="M4 4h16v16H4Z" />
    </svg>
  )
}

describe('Icon server rendering', () => {
  it('renders deterministic meaningful SVG markup', () => {
    const render = () =>
      renderToString(
        <Icon
          source={ServerSource}
          decorative={false}
          label="Application"
          size={32}
          mirrored
          id="application-icon"
        />,
      )

    expect(render()).toBe(render())
    expect(render()).toContain('role="img"')
    expect(render()).toContain('aria-label="Application"')
    expect(render()).toContain('data-m3e-source="svg"')
    expect(render()).toContain('--m3e-icon-size:32px')
    expect(render()).not.toContain('tabindex')
  })

  it('hydrates a configured Material Symbol without changing its contract', async () => {
    const tree = (
      <Icon
        source="favorite"
        symbolStyle="rounded"
        fill={1}
        weight={550}
        roundness={100}
        className="favorite"
      />
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
