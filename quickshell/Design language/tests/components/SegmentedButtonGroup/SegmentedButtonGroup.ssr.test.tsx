// @vitest-environment jsdom

import { act } from '@testing-library/react'
import { hydrateRoot } from 'react-dom/client'
import { renderToString } from 'react-dom/server'
import { SegmentedButtonGroup } from '../../../src/components/SegmentedButtonGroup'

const viewSegments = [
  { value: 'day', label: 'Day' },
  { value: 'week', label: 'Week' },
  { value: 'month', label: 'Month' },
] as const

describe('SegmentedButtonGroup server rendering', () => {
  it('renders deterministic markup for every resolved state', () => {
    const render = () =>
      renderToString(
        <>
          <SegmentedButtonGroup segments={viewSegments} aria-label="View" defaultValue="week" />
          <SegmentedButtonGroup
            multiple
            segments={viewSegments}
            aria-label="Filters"
            defaultValue={['day', 'month']}
          />
          <SegmentedButtonGroup segments={viewSegments} aria-label="Locked" disabled />
          <SegmentedButtonGroup
            segments={[{ value: 'only', label: 'Only', icon: <span>*</span> }]}
            aria-label="Solo"
          />
        </>,
      )

    expect(render()).toBe(render())
    expect(render()).toContain('role="radiogroup"')
    expect(render()).toContain('role="group"')
    expect(render()).toContain('data-m3e-position="start"')
    expect(render()).toContain('data-m3e-position="middle"')
    expect(render()).toContain('data-m3e-position="end"')
    expect(render()).toContain('data-m3e-position="only"')
    expect(render()).toContain('data-m3e-disabled="true"')
    expect(render()).toContain('data-m3e-has-icon="true"')
  })

  it('hydrates without changing markup or injecting styles', async () => {
    const tree = (
      <div>
        <SegmentedButtonGroup segments={viewSegments} aria-label="View" defaultValue="day" />
        <SegmentedButtonGroup
          multiple
          segments={viewSegments}
          aria-label="Filters"
          defaultValue={['week']}
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
