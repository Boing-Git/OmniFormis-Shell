// @vitest-environment jsdom

import { cleanup, render, screen } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { afterEach, vi } from 'vitest'
import {
  Button,
  Icon,
  type IconSourceProps,
} from '../../../src'

function ActionSource(props: IconSourceProps) {
  return (
    <svg {...props} viewBox="0 0 24 24">
      <path d="M4 11h12l-4-4 2-2 7 7-7 7-2-2 4-4H4Z" />
    </svg>
  )
}

afterEach(() => {
  cleanup()
  vi.restoreAllMocks()
})

describe('Button accessibility', () => {
  it('exposes one native button named by its label', () => {
    render(<Button aria-describedby="save-help">Save changes</Button>)
    const button = screen.getByRole('button', { name: 'Save changes' })

    expect(screen.getAllByRole('button')).toHaveLength(1)
    expect(button.getAttribute('role')).toBeNull()
    expect(button.getAttribute('aria-describedby')).toBe('save-help')
    expect(button.hasAttribute('aria-pressed')).toBe(false)
    expect(button.hasAttribute('aria-busy')).toBe(false)
  })

  it('keeps both icon slots out of the accessibility tree and the name stable', () => {
    render(
      <Button
        leadingIcon={<Icon source={ActionSource} decorative={false} label="Arrow" />}
        trailingIcon={<Icon source="check" decorative={false} label="Check" />}
      >
        Continue
      </Button>,
    )

    expect(screen.getByRole('button', { name: 'Continue' })).toBeInstanceOf(HTMLButtonElement)
    expect(screen.queryByRole('img')).toBeNull()
  })

  it('uses native Enter and Space activation exactly once per key', async () => {
    const user = userEvent.setup()
    const onClick = vi.fn()
    render(<Button onClick={onClick}>Run</Button>)
    const button = screen.getByRole('button', { name: 'Run' })

    await user.tab()
    expect(document.activeElement).toBe(button)
    await user.keyboard('{Enter}')
    expect(onClick).toHaveBeenCalledTimes(1)
    await user.keyboard(' ')
    expect(onClick).toHaveBeenCalledTimes(2)
  })

  it('removes a disabled button from sequential keyboard focus', async () => {
    const user = userEvent.setup()
    render(
      <>
        <Button disabled>Unavailable</Button>
        <Button>Available</Button>
      </>,
    )

    await user.tab()
    expect(document.activeElement).toBe(screen.getByRole('button', { name: 'Available' }))
  })

  it('keeps logical icon source order under an explicit RTL scope', () => {
    render(
      <div dir="rtl">
        <Button
          leadingIcon={<span>start</span>}
          trailingIcon={<span>end</span>}
        >
          Next
        </Button>
      </div>,
    )
    const button = screen.getByRole('button', { name: 'Next' })
    const positions = [...button.querySelectorAll('[data-m3e-position]')].map(
      (slot) => slot.getAttribute('data-m3e-position'),
    )
    expect(positions).toEqual(['leading', 'trailing'])
  })
})
