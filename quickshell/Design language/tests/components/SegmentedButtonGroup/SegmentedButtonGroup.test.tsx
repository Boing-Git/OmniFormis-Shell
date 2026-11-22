// @vitest-environment jsdom

import { cleanup, render, screen } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { createRef } from 'react'
import { afterEach, vi } from 'vitest'
import { SegmentedButtonGroup } from '../../../src/components/SegmentedButtonGroup'

const viewSegments = [
  { value: 'day', label: 'Day' },
  { value: 'week', label: 'Week' },
  { value: 'month', label: 'Month' },
] as const

afterEach(() => {
  cleanup()
  vi.restoreAllMocks()
})

describe('SegmentedButtonGroup', () => {
  it('renders one native radio per segment with the sourced shape position', () => {
    render(<SegmentedButtonGroup segments={viewSegments} aria-label="View" />)
    const group = screen.getByRole('radiogroup', { name: 'View' })
    const radios = screen.getAllByRole('radio') as HTMLInputElement[]

    expect(group.getAttribute('class')).toBe('m3e-segmented-button-group')
    expect(radios).toHaveLength(3)
    expect(radios.every((input) => input.type === 'radio')).toBe(true)
    expect(radios[0].closest('.m3e-segmented-button')?.getAttribute('data-m3e-position')).toBe(
      'start',
    )
    expect(radios[1].closest('.m3e-segmented-button')?.getAttribute('data-m3e-position')).toBe(
      'middle',
    )
    expect(radios[2].closest('.m3e-segmented-button')?.getAttribute('data-m3e-position')).toBe(
      'end',
    )
  })

  it('marks a lone segment as fully rounded', () => {
    render(<SegmentedButtonGroup segments={[{ value: 'only', label: 'Only' }]} aria-label="Solo" />)
    expect(
      screen.getByRole('radio').closest('.m3e-segmented-button')?.getAttribute('data-m3e-position'),
    ).toBe('only')
  })

  it('associates each segment label as the control’s accessible name via a native label', () => {
    render(<SegmentedButtonGroup segments={viewSegments} aria-label="View" />)
    expect(screen.getByRole('radio', { name: 'Day' })).toBeInstanceOf(HTMLInputElement)
    expect(screen.getByRole('radio', { name: 'Week' })).toBeInstanceOf(HTMLInputElement)
    expect(screen.getByRole('radio', { name: 'Month' })).toBeInstanceOf(HTMLInputElement)
  })

  it('sends className and style to the root while ref forwards to the root', () => {
    const ref = createRef<HTMLDivElement>()
    render(
      <SegmentedButtonGroup
        ref={ref}
        segments={viewSegments}
        aria-label="View"
        className="settings-view"
        style={{ marginInlineEnd: 8 }}
        data-owner="consumer"
      />,
    )
    const group = screen.getByRole('radiogroup', { name: 'View' })

    expect(ref.current).toBe(group)
    expect(group.getAttribute('class')).toBe('m3e-segmented-button-group settings-view')
    expect(group.getAttribute('style')).toContain('margin-inline-end: 8px')
    expect(group.getAttribute('data-owner')).toBe('consumer')
  })

  it('toggles uncontrolled single-choice selection through the browser', async () => {
    const user = userEvent.setup()
    const onValueChange = vi.fn()
    render(
      <SegmentedButtonGroup
        segments={viewSegments}
        aria-label="View"
        defaultValue="day"
        onValueChange={onValueChange}
      />,
    )
    const [day, week] = screen.getAllByRole('radio') as HTMLInputElement[]

    expect(day.checked).toBe(true)
    await user.click(week)
    expect(onValueChange).toHaveBeenCalledWith('week')
    expect(week.checked).toBe(true)
    expect(day.checked).toBe(false)
  })

  it('keeps a controlled value authoritative until the consumer commits it', async () => {
    const user = userEvent.setup()
    const onValueChange = vi.fn()
    render(
      <SegmentedButtonGroup
        segments={viewSegments}
        aria-label="View"
        value="day"
        onValueChange={onValueChange}
      />,
    )
    const [day, week] = screen.getAllByRole('radio') as HTMLInputElement[]

    await user.click(week)
    expect(onValueChange).toHaveBeenCalledWith('week')
    expect(day.checked).toBe(true)
    expect(week.checked).toBe(false)
  })

  it('renders independent checkboxes and toggles membership in multi-choice mode', async () => {
    const user = userEvent.setup()
    const onValueChange = vi.fn()
    render(
      <SegmentedButtonGroup
        multiple
        segments={viewSegments}
        aria-label="Filters"
        defaultValue={['day']}
        onValueChange={onValueChange}
      />,
    )
    const group = screen.getByRole('group', { name: 'Filters' })
    const [day, week] = screen.getAllByRole('checkbox') as HTMLInputElement[]

    expect(group).toBeInstanceOf(HTMLDivElement)
    expect(day.checked).toBe(true)
    await user.click(week)
    expect(onValueChange).toHaveBeenCalledWith(['day', 'week'])
    expect(day.checked).toBe(true)
    expect(week.checked).toBe(true)

    await user.click(day)
    expect(onValueChange).toHaveBeenLastCalledWith(['week'])
  })

  it('disables every segment at the group level', async () => {
    const user = userEvent.setup()
    const onValueChange = vi.fn()
    render(
      <SegmentedButtonGroup
        segments={viewSegments}
        aria-label="View"
        disabled
        onValueChange={onValueChange}
      />,
    )
    const radios = screen.getAllByRole('radio') as HTMLInputElement[]

    expect(radios.every((input) => input.disabled)).toBe(true)
    await user.click(radios[0])
    expect(onValueChange).not.toHaveBeenCalled()
  })

  it('disables an individual segment without affecting its siblings', async () => {
    const user = userEvent.setup()
    render(
      <SegmentedButtonGroup
        segments={[
          { value: 'day', label: 'Day' },
          { value: 'week', label: 'Week', disabled: true },
        ]}
        aria-label="View"
      />,
    )
    const week = screen.getByRole('radio', { name: 'Week' }) as HTMLInputElement
    const day = screen.getByRole('radio', { name: 'Day' }) as HTMLInputElement

    expect(week.disabled).toBe(true)
    expect(day.disabled).toBe(false)
    expect(week.closest('.m3e-segmented-button')?.getAttribute('data-m3e-disabled')).toBe('true')
    expect(day.closest('.m3e-segmented-button')?.getAttribute('data-m3e-disabled')).toBe('false')
    await user.click(week)
    expect(week.checked).toBe(false)
  })

  it('shares one auto-generated name across segments and honors a supplied name', () => {
    const { rerender } = render(<SegmentedButtonGroup segments={viewSegments} aria-label="View" />)
    const radios = screen.getAllByRole('radio') as HTMLInputElement[]
    const generatedName = radios[0].name

    expect(generatedName.length).toBeGreaterThan(0)
    expect(radios.every((input) => input.name === generatedName)).toBe(true)

    rerender(<SegmentedButtonGroup segments={viewSegments} aria-label="View" name="view" />)
    expect(screen.getAllByRole('radio').every((input) => (input as HTMLInputElement).name === 'view')).toBe(
      true,
    )
  })

  it('participates in single-choice form submission and resynchronizes on native reset', async () => {
    const user = userEvent.setup()
    const submitted: string[] = []
    render(
      <form
        onSubmit={(event) => {
          event.preventDefault()
          submitted.push(String(new FormData(event.currentTarget).get('view')))
        }}
      >
        <SegmentedButtonGroup segments={viewSegments} aria-label="View" name="view" defaultValue="day" />
        <button type="submit">Save</button>
        <button type="reset">Reset</button>
      </form>,
    )
    const [day, week] = screen.getAllByRole('radio') as HTMLInputElement[]

    await user.click(screen.getByRole('button', { name: 'Save' }))
    expect(submitted).toEqual(['day'])

    await user.click(week)
    expect(week.checked).toBe(true)

    await user.click(screen.getByRole('button', { name: 'Reset' }))
    expect(day.checked).toBe(true)
    expect(week.checked).toBe(false)
  })

  it('exposes every checked value through FormData in multi-choice mode', async () => {
    const user = userEvent.setup()
    let submittedValues: string[] = []
    render(
      <form
        onSubmit={(event) => {
          event.preventDefault()
          submittedValues = new FormData(event.currentTarget).getAll('filters').map(String)
        }}
      >
        <SegmentedButtonGroup multiple segments={viewSegments} aria-label="Filters" name="filters" />
        <button type="submit">Save</button>
      </form>,
    )
    const [day, , month] = screen.getAllByRole('checkbox') as HTMLInputElement[]

    await user.click(day)
    await user.click(month)
    await user.click(screen.getByRole('button', { name: 'Save' }))
    expect(submittedValues).toEqual(['day', 'month'])
  })

  it('warns for conflicting and incomplete runtime value props', () => {
    const warning = vi.spyOn(console, 'warn').mockImplementation(() => undefined)
    render(
      <SegmentedButtonGroup
        segments={viewSegments}
        aria-label="View"
        value="day"
        defaultValue="week"
      />,
    )
    expect(warning).toHaveBeenCalledWith(
      'SegmentedButtonGroup: use either value or defaultValue, not both.',
    )
    expect(warning).toHaveBeenCalledWith(
      'SegmentedButtonGroup: a controlled value requires onValueChange.',
    )
  })

  it('exposes a stable component name for React tooling', () => {
    expect(SegmentedButtonGroup.displayName).toBe('SegmentedButtonGroup')
  })
})
