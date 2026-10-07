import {
  forwardRef,
  useEffect,
  useLayoutEffect,
  useMemo,
  useRef,
  useState,
  type CSSProperties,
  type ForwardedRef,
  type ReactElement,
} from 'react'
import { createPortal } from 'react-dom'
import { composeRefs } from '../../internal/composeRefs'
import { useControllableState } from '../../internal/useControllableState'
import type { SnackbarProps } from './Snackbar.types'

interface SnackbarComponent {
  (props: SnackbarProps): ReactElement | null
  displayName?: string
}

type Phase = 'closed' | 'entering' | 'open' | 'closing'

const FALLBACK_CLOSE_MS = 400
const SHORT_DURATION_MS = 4000
const LONG_DURATION_MS = 10000

function prefersReducedMotion(): boolean {
  return (
    typeof window !== 'undefined' &&
    typeof window.matchMedia === 'function' &&
    window.matchMedia('(prefers-reduced-motion: reduce)').matches
  )
}

function resolveDurationMs(duration: SnackbarProps['duration'], hasAction: boolean): number | null {
  if (typeof duration === 'number') return duration
  const resolved = duration ?? (hasAction ? 'indefinite' : 'short')
  if (resolved === 'indefinite') return null
  return resolved === 'long' ? LONG_DURATION_MS : SHORT_DURATION_MS
}

function CloseIcon() {
  return (
    <svg
      viewBox="0 0 24 24"
      width="24"
      height="24"
      fill="none"
      stroke="currentColor"
      strokeWidth={2}
      strokeLinecap="round"
      strokeLinejoin="round"
      aria-hidden="true"
    >
      <path d="M18 6 6 18M6 6l12 12" />
    </svg>
  )
}

function SnackbarRender(
  {
    open,
    defaultOpen = false,
    onOpenChange,
    message,
    action,
    dismissible = false,
    dismissLabel = 'Dismiss',
    duration,
    className,
    style,
    ...divProps
  }: SnackbarProps,
  forwardedRef: ForwardedRef<HTMLDivElement>,
) {
  const [resolvedOpen, setOpen] = useControllableState({
    value: open,
    defaultValue: defaultOpen,
    onChange: onOpenChange,
  })

  const [phase, setPhase] = useState<Phase>('closed')
  const hasEnteredRef = useRef(false)
  const fallbackTimeoutRef = useRef<ReturnType<typeof setTimeout> | undefined>(undefined)
  const rootRef = useRef<HTMLDivElement | null>(null)

  useEffect(() => {
    if (resolvedOpen) {
      if (fallbackTimeoutRef.current !== undefined) {
        clearTimeout(fallbackTimeoutRef.current)
        fallbackTimeoutRef.current = undefined
      }
      setPhase((current) => (current === 'closed' ? 'entering' : current === 'closing' ? 'open' : current))
      return
    }
    if (!hasEnteredRef.current || prefersReducedMotion()) {
      hasEnteredRef.current = false
      setPhase('closed')
      return
    }
    setPhase('closing')
    fallbackTimeoutRef.current = setTimeout(() => {
      hasEnteredRef.current = false
      setPhase('closed')
    }, FALLBACK_CLOSE_MS)
  }, [resolvedOpen])

  useEffect(() => {
    return () => {
      if (fallbackTimeoutRef.current !== undefined) clearTimeout(fallbackTimeoutRef.current)
    }
  }, [])

  useLayoutEffect(() => {
    if (phase !== 'entering') return
    let frame2 = 0
    const frame1 = requestAnimationFrame(() => {
      frame2 = requestAnimationFrame(() => {
        hasEnteredRef.current = true
        setPhase('open')
      })
    })
    return () => {
      cancelAnimationFrame(frame1)
      if (frame2) cancelAnimationFrame(frame2)
    }
  }, [phase])

  const handleTransitionEnd = (event: { readonly target: unknown }) => {
    if (phase !== 'closing') return
    if (event.target !== rootRef.current) return
    if (fallbackTimeoutRef.current !== undefined) {
      clearTimeout(fallbackTimeoutRef.current)
      fallbackTimeoutRef.current = undefined
    }
    hasEnteredRef.current = false
    setPhase('closed')
  }

  const durationMs = useMemo(() => resolveDurationMs(duration, action != null), [duration, action])

  const [paused, setPaused] = useState(false)
  const remainingRef = useRef(durationMs)
  const wasOpenRef = useRef(false)

  // Auto-dismiss timer, matching the pinned source's own `SnackbarHost`
  // `delay(duration)` — but pausable on hover/focus (see cleanup below),
  // a deliberate WCAG 2.2.1 (timing adjustable) addition the source has no
  // need for, since Android's own accessibility services extend timing a
  // different way with no web equivalent.
  useEffect(() => {
    if (!resolvedOpen || durationMs === null) {
      wasOpenRef.current = resolvedOpen
      return
    }
    if (!wasOpenRef.current) remainingRef.current = durationMs
    wasOpenRef.current = true
    if (paused) return

    const remaining = remainingRef.current ?? durationMs
    const deadline = Date.now() + remaining
    const timeout = setTimeout(() => setOpen(false), remaining)
    return () => {
      clearTimeout(timeout)
      remainingRef.current = Math.max(0, deadline - Date.now())
    }
  }, [resolvedOpen, paused, durationMs, setOpen])

  if (phase === 'closed') return null

  return createPortal(
    <div
      {...divProps}
      ref={composeRefs(forwardedRef, rootRef)}
      role="status"
      className={className ? `m3e-snackbar ${className}` : 'm3e-snackbar'}
      data-m3e-open={phase === 'open'}
      style={{ ...(style as CSSProperties) }}
      onTransitionEnd={handleTransitionEnd}
      onMouseEnter={() => setPaused(true)}
      onMouseLeave={() => setPaused(false)}
      onFocus={() => setPaused(true)}
      onBlur={(event) => {
        if (!event.currentTarget.contains(event.relatedTarget as Node | null)) setPaused(false)
      }}
    >
      <span className="m3e-snackbar__message">{message}</span>
      {action != null && (
        <button
          type="button"
          className="m3e-snackbar__action"
          onClick={() => {
            action.onClick()
            setOpen(false)
          }}
        >
          {action.label}
        </button>
      )}
      {dismissible && (
        <button
          type="button"
          className="m3e-snackbar__dismiss"
          aria-label={dismissLabel}
          onClick={() => setOpen(false)}
        >
          <CloseIcon />
        </button>
      )}
    </div>,
    document.body,
  )
}

const ForwardedSnackbar = forwardRef<HTMLDivElement, SnackbarProps>(SnackbarRender)
ForwardedSnackbar.displayName = 'Snackbar'

export const Snackbar = ForwardedSnackbar as SnackbarComponent
