// @vitest-environment jsdom

import { act } from '@testing-library/react'
import { hydrateRoot } from 'react-dom/client'
import { renderToString } from 'react-dom/server'
import { TextArea } from '../../../src'

describe('TextArea server rendering', () => {
  it('renders deterministic markup for every resolved state', () => {
    const render = () => renderToString(
      <>
        <TextArea label="Notes" />
        <TextArea variant="outlined" label="Feedback" defaultValue="Great work" />
        <TextArea label="Locked" disabled defaultValue="Read only" />
        <TextArea label="Notes" error supportingText="Required" />
      </>,
    )

    expect(render()).toBe(render())
    expect(render()).toContain('data-m3e-multiline="true"')
    expect(render()).toContain('data-m3e-variant="filled"')
    expect(render()).toContain('data-m3e-variant="outlined"')
    expect(render()).toContain('data-m3e-error="true"')
    expect(render()).toContain('data-m3e-disabled="true"')
    expect(render()).toContain('class="m3e-text-field__hit-target"')
  })

  it('hydrates without changing markup or injecting styles', async () => {
    const tree = (
      <div>
        <TextArea label="Notes" defaultValue="Draft" rows={4} />
        <TextArea variant="outlined" label="Feedback" supportingText="Optional" />
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
