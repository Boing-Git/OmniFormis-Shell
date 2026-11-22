// @vitest-environment jsdom

import { cleanup, render, screen } from '@testing-library/react'
import { afterEach, beforeAll } from 'vitest'
import { Tabs } from '../../../src/components/Tabs'
import type { TabItem } from '../../../src/components/Tabs'
import { installTabsNativePolyfills } from './tabs-native-polyfill'

beforeAll(installTabsNativePolyfills)
afterEach(cleanup)

const items: TabItem[] = [
  { value: 'photos', label: 'Photos' },
  { value: 'files', label: 'Files', disabled: true },
]

describe('Tabs accessibility', () => {
  it('requires an accessible name on the tablist via aria-label', () => {
    render(<Tabs aria-label="Library" items={items} />)
    expect(screen.getByRole('tablist', { name: 'Library' })).not.toBeNull()
  })

  it('supports aria-labelledby as an alternative accessible name', () => {
    render(
      <>
        <h2 id="library-heading">Library</h2>
        <Tabs aria-labelledby="library-heading" items={items} />
      </>,
    )
    expect(screen.getByRole('tablist', { name: 'Library' })).not.toBeNull()
  })

  it('marks a disabled tab with aria-disabled and excludes it from the tab order', () => {
    render(<Tabs aria-label="Library" items={items} />)
    const disabled = screen.getByRole('tab', { name: 'Files' })
    expect(disabled.getAttribute('aria-disabled')).toBe('true')
    expect(disabled.getAttribute('tabindex')).toBe('-1')
  })

  it('hides the sliding indicator from assistive technology', () => {
    render(<Tabs aria-label="Library" items={items} />)
    const indicator = document.querySelector('.m3e-tabs__indicator')
    expect(indicator?.getAttribute('aria-hidden')).toBe('true')
  })

  it('keeps tabs readable inside an RTL scope', () => {
    render(
      <div dir="rtl">
        <Tabs aria-label="Library" items={items} />
      </div>,
    )
    expect(screen.getByRole('tablist', { name: 'Library' })).not.toBeNull()
    expect(screen.getAllByRole('tab')).toHaveLength(2)
  })
})
