// @vitest-environment jsdom

import { cleanup, render, screen } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { afterEach, vi } from 'vitest'
import { Icon, IconButton } from '../../../src'

afterEach(() => {
  cleanup()
  vi.restoreAllMocks()
})

describe('IconButton accessibility', () => {
  it('exposes one native button named independently from decorative icon content', () => {
    render(
      <IconButton aria-label="Search" aria-describedby="search-help">
        <Icon source="search" decorative={false} label="Magnifying glass" />
      </IconButton>,
    )
    const button = screen.getByRole('button', { name: 'Search' })

    expect(screen.getAllByRole('button')).toHaveLength(1)
    expect(screen.queryByRole('img')).toBeNull()
    expect(button.getAttribute('role')).toBeNull()
    expect(button.getAttribute('aria-describedby')).toBe('search-help')
    expect(button.hasAttribute('aria-pressed')).toBe(false)
  })

  it('uses aria-labelledby and hides both toggle visuals from the accessibility tree', () => {
    render(
      <>
        <span id="bookmark-label">Bookmark article</span>
        <IconButton
          aria-labelledby="bookmark-label"
          toggle
          defaultSelected
          selectedIcon={<Icon source="bookmark" decorative={false} label="Filled bookmark" />}
        >
          <Icon source="bookmark_border" decorative={false} label="Outline bookmark" />
        </IconButton>
      </>,
    )

    expect(screen.getByRole('button', { name: 'Bookmark article' }).getAttribute('aria-pressed')).toBe('true')
    expect(screen.queryByRole('img')).toBeNull()
  })

  it('uses native Enter and Space activation exactly once per key', async () => {
    const user = userEvent.setup()
    const onClick = vi.fn()
    const onSelectedChange = vi.fn()
    render(
      <IconButton aria-label="Favorite" toggle onClick={onClick} onSelectedChange={onSelectedChange}>
        <Icon source="favorite" />
      </IconButton>,
    )
    const button = screen.getByRole('button', { name: 'Favorite' })

    await user.tab()
    expect(document.activeElement).toBe(button)
    await user.keyboard('{Enter}')
    expect(onClick).toHaveBeenCalledTimes(1)
    expect(onSelectedChange).toHaveBeenNthCalledWith(1, true)
    await user.keyboard(' ')
    expect(onClick).toHaveBeenCalledTimes(2)
    expect(onSelectedChange).toHaveBeenNthCalledWith(2, false)
  })

  it('removes a disabled icon button from sequential focus', async () => {
    const user = userEvent.setup()
    render(
      <>
        <IconButton aria-label="Unavailable" disabled><Icon source="block" /></IconButton>
        <IconButton aria-label="Available"><Icon source="check" /></IconButton>
      </>,
    )

    await user.tab()
    expect(document.activeElement).toBe(screen.getByRole('button', { name: 'Available' }))
  })

  it('preserves source order and state under an explicit RTL scope', () => {
    render(
      <div dir="rtl">
        <IconButton
          aria-label="Forward"
          shape="square"
          width="wide"
          toggle
          defaultSelected
          selectedIcon={<Icon source="arrow_forward" mirrored />}
        >
          <Icon source="arrow_forward" mirrored />
        </IconButton>
      </div>,
    )
    const button = screen.getByRole('button', { name: 'Forward' })

    expect(button.getAttribute('data-m3e-shape')).toBe('square')
    expect(button.getAttribute('data-m3e-width')).toBe('wide')
    expect(button.getAttribute('aria-pressed')).toBe('true')
    expect(button.querySelectorAll('[data-m3e-icon-state]')[0]?.getAttribute('data-m3e-icon-state')).toBe('default')
    expect(button.querySelectorAll('[data-m3e-icon-state]')[1]?.getAttribute('data-m3e-icon-state')).toBe('selected')
  })
})
