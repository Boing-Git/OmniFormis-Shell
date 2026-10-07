// @vitest-environment jsdom

import { act, cleanup, fireEvent, render, screen } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { createRef } from 'react'
import { afterEach, vi } from 'vitest'
import { Snackbar } from '../../../src/components/Snackbar'

afterEach(() => {
  cleanup()
  vi.restoreAllMocks()
  vi.useRealTimers()
})

describe('Snackbar', () => {
  it('renders nothing when closed and portals role="status" to document.body when open', () => {
    const { rerender } = render(<Snackbar message="Saved" open={false} onOpenChange={() => undefined} />)
    expect(screen.queryByRole('status')).toBeNull()

    rerender(<Snackbar message="Saved" open onOpenChange={() => undefined} />)
    const snackbar = screen.getByRole('status')
    expect(snackbar.parentElement).toBe(document.body)
    expect(snackbar.textContent).toBe('Saved')
  })

  it('supports uncontrolled defaultOpen', () => {
    render(<Snackbar message="Saved" defaultOpen />)
    expect(screen.getByRole('status')).not.toBeNull()
  })

  it('auto-dismisses after the default short duration (4000ms) when there is no action', () => {
    vi.useFakeTimers({
      toFake: ['requestAnimationFrame', 'cancelAnimationFrame', 'setTimeout', 'clearTimeout', 'Date'],
    })
    const onOpenChange = vi.fn()
    render(<Snackbar message="Saved" defaultOpen onOpenChange={onOpenChange} />)
    act(() => {
      vi.advanceTimersByTime(3999)
    })
    expect(onOpenChange).not.toHaveBeenCalled()
    act(() => {
      vi.advanceTimersByTime(1)
    })
    expect(onOpenChange).toHaveBeenCalledWith(false)
  })

  it('defaults to indefinite (no auto-dismiss) when an action is present', () => {
    vi.useFakeTimers({
      toFake: ['requestAnimationFrame', 'cancelAnimationFrame', 'setTimeout', 'clearTimeout', 'Date'],
    })
    const onOpenChange = vi.fn()
    render(
      <Snackbar
        message="Item removed"
        action={{ label: 'Undo', onClick: vi.fn() }}
        defaultOpen
        onOpenChange={onOpenChange}
      />,
    )
    act(() => {
      vi.advanceTimersByTime(60_000)
    })
    expect(onOpenChange).not.toHaveBeenCalled()
  })

  it('supports an exact millisecond duration override', () => {
    vi.useFakeTimers({
      toFake: ['requestAnimationFrame', 'cancelAnimationFrame', 'setTimeout', 'clearTimeout', 'Date'],
    })
    const onOpenChange = vi.fn()
    render(<Snackbar message="Saved" duration={1000} defaultOpen onOpenChange={onOpenChange} />)
    act(() => {
      vi.advanceTimersByTime(999)
    })
    expect(onOpenChange).not.toHaveBeenCalled()
    act(() => {
      vi.advanceTimersByTime(1)
    })
    expect(onOpenChange).toHaveBeenCalledWith(false)
  })

  it('supports the long duration (10000ms)', () => {
    vi.useFakeTimers({
      toFake: ['requestAnimationFrame', 'cancelAnimationFrame', 'setTimeout', 'clearTimeout', 'Date'],
    })
    const onOpenChange = vi.fn()
    render(<Snackbar message="Saved" duration="long" defaultOpen onOpenChange={onOpenChange} />)
    act(() => {
      vi.advanceTimersByTime(9999)
    })
    expect(onOpenChange).not.toHaveBeenCalled()
    act(() => {
      vi.advanceTimersByTime(1)
    })
    expect(onOpenChange).toHaveBeenCalledWith(false)
  })

  it('pauses the auto-dismiss timer while hovered and resumes the remaining time on leave', () => {
    vi.useFakeTimers({
      toFake: ['requestAnimationFrame', 'cancelAnimationFrame', 'setTimeout', 'clearTimeout', 'Date'],
    })
    const onOpenChange = vi.fn()
    render(<Snackbar message="Saved" defaultOpen onOpenChange={onOpenChange} />)
    act(() => {
      vi.advanceTimersByTime(2000)
    })
    act(() => {
      fireEvent.mouseEnter(screen.getByRole('status'))
    })
    act(() => {
      vi.advanceTimersByTime(5000)
    })
    expect(onOpenChange).not.toHaveBeenCalled()

    act(() => {
      fireEvent.mouseLeave(screen.getByRole('status'))
    })
    act(() => {
      vi.advanceTimersByTime(1999)
    })
    expect(onOpenChange).not.toHaveBeenCalled()
    act(() => {
      vi.advanceTimersByTime(1)
    })
    expect(onOpenChange).toHaveBeenCalledWith(false)
  })

  it('pauses the auto-dismiss timer while focused and resumes on blur', () => {
    vi.useFakeTimers({
      toFake: ['requestAnimationFrame', 'cancelAnimationFrame', 'setTimeout', 'clearTimeout', 'Date'],
    })
    const onOpenChange = vi.fn()
    render(<Snackbar message="Saved" dismissible defaultOpen onOpenChange={onOpenChange} />)
    const snackbar = screen.getByRole('status')
    act(() => {
      fireEvent.focus(screen.getByRole('button', { name: 'Dismiss' }))
    })
    act(() => {
      vi.advanceTimersByTime(10_000)
    })
    expect(onOpenChange).not.toHaveBeenCalled()

    act(() => {
      fireEvent.blur(screen.getByRole('button', { name: 'Dismiss' }), { relatedTarget: document.body })
    })
    expect(snackbar).not.toBeNull()
    act(() => {
      vi.advanceTimersByTime(4000)
    })
    expect(onOpenChange).toHaveBeenCalledWith(false)
  })

  it('activating the action calls onClick and closes', async () => {
    const user = userEvent.setup()
    const onClick = vi.fn()
    const onOpenChange = vi.fn()
    render(
      <Snackbar
        message="Item removed"
        action={{ label: 'Undo', onClick }}
        defaultOpen
        onOpenChange={onOpenChange}
      />,
    )
    await user.click(screen.getByRole('button', { name: 'Undo' }))
    expect(onClick).toHaveBeenCalledTimes(1)
    expect(onOpenChange).toHaveBeenCalledWith(false)
  })

  it('dismissible renders a close button that closes on click, with a customizable label', async () => {
    const user = userEvent.setup()
    const onOpenChange = vi.fn()
    render(
      <Snackbar message="Saved" dismissible dismissLabel="Close" defaultOpen onOpenChange={onOpenChange} />,
    )
    await user.click(screen.getByRole('button', { name: 'Close' }))
    expect(onOpenChange).toHaveBeenCalledWith(false)
  })

  it('omits the dismiss button by default', () => {
    render(<Snackbar message="Saved" defaultOpen />)
    expect(screen.queryByRole('button', { name: 'Dismiss' })).toBeNull()
  })

  it('forwards ref, className, and style to the root', () => {
    const ref = createRef<HTMLDivElement>()
    render(
      <Snackbar
        ref={ref}
        message="Saved"
        open
        onOpenChange={() => undefined}
        className="consumer-class"
        data-owner="consumer"
      />,
    )
    const snackbar = screen.getByRole('status')
    expect(ref.current).toBe(snackbar)
    expect(snackbar.className).toContain('m3e-snackbar')
    expect(snackbar.className).toContain('consumer-class')
    expect(snackbar.getAttribute('data-owner')).toBe('consumer')
  })

  it('exposes a stable component name for React tooling', () => {
    expect(Snackbar.displayName).toBe('Snackbar')
  })

  it('defers unmount past a close request once opened, then unmounts via the fallback timer', () => {
    vi.useFakeTimers({
      toFake: ['requestAnimationFrame', 'cancelAnimationFrame', 'setTimeout', 'clearTimeout', 'Date'],
    })
    const { rerender } = render(<Snackbar message="Saved" open onOpenChange={() => undefined} />)
    act(() => {
      vi.advanceTimersByTime(100)
    })
    expect(screen.getByRole('status').getAttribute('data-m3e-open')).toBe('true')

    rerender(<Snackbar message="Saved" open={false} onOpenChange={() => undefined} />)
    expect(screen.queryByRole('status')).not.toBeNull()

    act(() => {
      vi.advanceTimersByTime(500)
    })
    expect(screen.queryByRole('status')).toBeNull()
  })
})
