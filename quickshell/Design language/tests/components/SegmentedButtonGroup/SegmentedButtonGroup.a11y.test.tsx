// @vitest-environment jsdom

import { cleanup, render, screen } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { afterEach } from 'vitest'
import { SegmentedButtonGroup } from '../../../src/components/SegmentedButtonGroup'

const viewSegments = [
  { value: 'day', label: 'Day' },
  { value: 'week', label: 'Week' },
  { value: 'month', label: 'Month' },
] as const

afterEach(cleanup)

describe('SegmentedButtonGroup accessibility', () => {
  it('exposes radiogroup semantics with an accessible group name in single-choice mode', () => {
    render(<SegmentedButtonGroup segments={viewSegments} aria-label="View" />)
    expect(screen.getByRole('radiogroup', { name: 'View' })).not.toBeNull()
  })

  it('exposes group semantics with an accessible group name in multi-choice mode', () => {
    render(<SegmentedButtonGroup multiple segments={viewSegments} aria-label="Filters" />)
    expect(screen.getByRole('group', { name: 'Filters' })).not.toBeNull()
  })

  it('supports aria-labelledby for the group name', () => {
    render(
      <>
        <h2 id="view-heading">View</h2>
        <SegmentedButtonGroup segments={viewSegments} aria-labelledby="view-heading" />
      </>,
    )
    expect(screen.getByRole('radiogroup', { name: 'View' })).not.toBeNull()
  })

  it('reaches the checked segment first through sequential focus, relying on native radio grouping for the rest', async () => {
    // Arrow-key roving between grouped radios is native `<input
    // type="radio">` browser behavior with no JS in this component; jsdom's
    // own radio-group keyboard emulation is unreliable in this test
    // environment, so only the zero-JS entry point (Tab reaches the checked
    // segment, matching every browser's native single-tab-stop-per-group
    // rule) is asserted here.
    const user = userEvent.setup()
    render(<SegmentedButtonGroup segments={viewSegments} aria-label="View" defaultValue="week" />)
    const week = screen.getByRole('radio', { name: 'Week' })

    await user.tab()
    expect(document.activeElement).toBe(week)
  })

  it('lets every checkbox reach sequential focus independently in multi-choice mode', async () => {
    const user = userEvent.setup()
    render(<SegmentedButtonGroup multiple segments={viewSegments} aria-label="Filters" />)
    const [day, week, month] = screen.getAllByRole('checkbox') as HTMLInputElement[]

    await user.tab()
    expect(document.activeElement).toBe(day)
    await user.tab()
    expect(document.activeElement).toBe(week)
    await user.tab()
    expect(document.activeElement).toBe(month)
  })

  it('removes every segment from sequential focus when the group is disabled', async () => {
    const user = userEvent.setup()
    render(
      <>
        <SegmentedButtonGroup segments={viewSegments} aria-label="View" disabled />
        <button type="button">After</button>
      </>,
    )

    await user.tab()
    expect(document.activeElement).toBe(screen.getByRole('button', { name: 'After' }))
  })

  it('keeps segment labels stable inside an RTL scope', () => {
    render(
      <div dir="rtl">
        <SegmentedButtonGroup
          segments={[
            { value: 'day', label: 'يوم' },
            { value: 'week', label: 'أسبوع' },
          ]}
          aria-label="عرض"
        />
      </div>,
    )
    expect(screen.getByRole('radiogroup', { name: 'عرض' })).not.toBeNull()
    expect(screen.getByRole('radio', { name: 'يوم' })).not.toBeNull()
  })
})
