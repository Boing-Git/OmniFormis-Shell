import { useCallback, useEffect, useLayoutEffect, useRef, useState, type RefObject } from 'react'
import { computeOverlayPosition } from './overlayPosition'

type Phase = 'closed' | 'entering' | 'open' | 'closing'

export interface AnchoredOverlayStyle {
  readonly position: 'fixed'
  readonly top: number
  readonly left: number
  readonly width?: number
}

export interface AnchoredOverlayPositionArgs {
  readonly anchor: { readonly top: number; readonly left: number; readonly width: number; readonly height: number }
  readonly overlay: { readonly width: number; readonly height: number }
  readonly viewport: { readonly width: number; readonly height: number }
}

export interface AnchoredOverlayComputedPosition {
  readonly top: number
  readonly left: number
  readonly width?: number
}

export interface UseAnchoredOverlayOptions {
  readonly open: boolean
  readonly anchorRef: RefObject<HTMLElement | null>
  readonly onRequestClose: () => void
  readonly matchAnchorWidth?: boolean
  readonly gap?: number
  /**
   * Overrides the default `Menu`/`Select` positioning algorithm
   * (`computeOverlayPosition`) entirely — used by `Tooltip`, whose
   * center-aligned, flip-on-collision, zero-margin placement is a
   * genuinely different algorithm (see `computeTooltipPosition`), not a
   * parameterization of the default one. `Menu`/`Select` omit this and are
   * unaffected.
   */
  readonly computePosition?: (args: AnchoredOverlayPositionArgs) => AnchoredOverlayComputedPosition
}

export interface UseAnchoredOverlayResult {
  /** Whether the popover should be mounted in the portal at all right now. */
  readonly mounted: boolean
  /** `true` once the entrance transition has been kicked off (drives the "open" visual state). */
  readonly entered: boolean
  readonly popoverRef: (node: HTMLElement | null) => void
  readonly style: AnchoredOverlayStyle
  /** Attach to the popover root's `onTransitionEnd`. */
  readonly handleTransitionEnd: (event: { readonly target: unknown }) => void
  /**
   * Moves focus back to the anchor. Callers invoke this explicitly from an
   * unambiguous "return to the trigger" dismissal (Escape, a keyboard-
   * activated selection) — never from a generic outside-click dismissal,
   * where the click's own natural focus target should stand undisturbed.
   */
  readonly restoreFocus: () => void
}

const FALLBACK_CLOSE_MS = 400

function prefersReducedMotion(): boolean {
  return (
    typeof window !== 'undefined' &&
    typeof window.matchMedia === 'function' &&
    window.matchMedia('(prefers-reduced-motion: reduce)').matches
  )
}

/**
 * Shared portal, positioning, and dismissal lifecycle for `Menu` and
 * `Select`'s popup. See ADR 0017: neither native top-layer promotion nor a
 * native backdrop/focus-trap is available here, unlike Dialog's `<dialog>`,
 * so this hook owns outside-click/Escape dismissal and focus restoration to
 * the anchor explicitly, and defers unmounting until the exit transition
 * finishes (or immediately, under reduced motion or before the entrance
 * transition ever completed) rather than relying on a native closing step.
 */
export function useAnchoredOverlay({
  open,
  anchorRef,
  onRequestClose,
  matchAnchorWidth = false,
  gap = 0,
  computePosition,
}: UseAnchoredOverlayOptions): UseAnchoredOverlayResult {
  const [phase, setPhase] = useState<Phase>('closed')
  const [style, setStyle] = useState<AnchoredOverlayStyle>({
    position: 'fixed',
    top: 0,
    left: 0,
  })
  const popoverElementRef = useRef<HTMLElement | null>(null)
  const hasEnteredRef = useRef(false)
  const fallbackTimeoutRef = useRef<ReturnType<typeof setTimeout> | undefined>(undefined)
  const onRequestCloseRef = useRef(onRequestClose)
  onRequestCloseRef.current = onRequestClose

  const popoverRef = useCallback((node: HTMLElement | null) => {
    popoverElementRef.current = node
  }, [])

  const measure = useCallback(() => {
    const anchor = anchorRef.current
    const popover = popoverElementRef.current
    if (!anchor || !popover) return
    const anchorRect = anchor.getBoundingClientRect()
    const overlayRect = popover.getBoundingClientRect()
    const overlay = { width: overlayRect.width, height: overlayRect.height }
    const viewport = { width: window.innerWidth, height: window.innerHeight }
    if (computePosition) {
      const position = computePosition({ anchor: anchorRect, overlay, viewport })
      setStyle({ position: 'fixed', top: position.top, left: position.left, width: position.width })
      return
    }
    const position = computeOverlayPosition({
      anchor: anchorRect,
      overlay,
      viewport,
      matchAnchorWidth,
      gap,
    })
    setStyle({
      position: 'fixed',
      top: position.top,
      left: position.left,
      width: matchAnchorWidth ? position.width : undefined,
    })
  }, [anchorRef, matchAnchorWidth, gap, computePosition])

  // Open request: mount (closed -> entering). Close request: either an
  // immediate unmount (never finished entering) or a deferred one (closing).
  useEffect(() => {
    if (open) {
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
  }, [open])

  useEffect(() => {
    return () => {
      if (fallbackTimeoutRef.current !== undefined) clearTimeout(fallbackTimeoutRef.current)
    }
  }, [])

  // Measure before the entrance transition is kicked off, and flip to
  // "entered" one frame later so the browser has a from-state to transition
  // out of, matching the double-rAF technique CSS-transition-on-mount needs.
  useLayoutEffect(() => {
    if (phase !== 'entering') return
    measure()
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
  }, [phase, measure])

  useEffect(() => {
    if (phase !== 'open') return
    const reposition = () => measure()
    window.addEventListener('scroll', reposition, true)
    window.addEventListener('resize', reposition)
    return () => {
      window.removeEventListener('scroll', reposition, true)
      window.removeEventListener('resize', reposition)
    }
  }, [phase, measure])

  const restoreFocus = useCallback(() => {
    anchorRef.current?.focus()
  }, [anchorRef])

  useEffect(() => {
    if (phase !== 'open' && phase !== 'entering') return
    const handlePointerDown = (event: PointerEvent) => {
      const target = event.target as Node | null
      const popover = popoverElementRef.current
      const anchor = anchorRef.current
      if (!target || !popover) return
      if (popover.contains(target)) return
      if (anchor?.contains(target)) return
      // Outside click: the click's own natural focus target should stand,
      // so this does not call restoreFocus().
      onRequestCloseRef.current()
    }
    const handleKeyDown = (event: KeyboardEvent) => {
      if (event.key !== 'Escape') return
      onRequestCloseRef.current()
      restoreFocus()
    }
    document.addEventListener('pointerdown', handlePointerDown, true)
    document.addEventListener('keydown', handleKeyDown, true)
    return () => {
      document.removeEventListener('pointerdown', handlePointerDown, true)
      document.removeEventListener('keydown', handleKeyDown, true)
    }
  }, [phase, anchorRef, restoreFocus])

  const handleTransitionEnd = useCallback(
    (event: { readonly target: unknown }) => {
      if (phase !== 'closing') return
      if (event.target !== popoverElementRef.current) return
      if (fallbackTimeoutRef.current !== undefined) {
        clearTimeout(fallbackTimeoutRef.current)
        fallbackTimeoutRef.current = undefined
      }
      hasEnteredRef.current = false
      setPhase('closed')
    },
    [phase],
  )

  return {
    mounted: phase !== 'closed',
    entered: phase === 'open',
    popoverRef,
    style,
    handleTransitionEnd,
    restoreFocus,
  }
}
