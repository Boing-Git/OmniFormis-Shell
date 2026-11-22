import {
  forwardRef,
  useCallback,
  useEffect,
  useId,
  useRef,
  type CSSProperties,
  type ForwardedRef,
  type ReactElement,
} from 'react'
import { createPortal } from 'react-dom'
import { composeRefs } from '../../internal/composeRefs'
import { computeTooltipPosition } from '../../internal/overlayPosition'
import { useAnchoredOverlay, type AnchoredOverlayPositionArgs } from '../../internal/useAnchoredOverlay'
import { useControllableState } from '../../internal/useControllableState'
import type { TooltipProps } from './Tooltip.types'

interface TooltipComponent {
  (props: TooltipProps): ReactElement | null
  displayName?: string
}

function TooltipRender(
  {
    anchorRef,
    content,
    variant = 'plain',
    subhead,
    placement = 'top',
    open,
    defaultOpen = false,
    onOpenChange,
    className,
    style,
    id: idProp,
    ...divProps
  }: TooltipProps,
  forwardedRef: ForwardedRef<HTMLDivElement>,
) {
  const generatedId = useId()
  const tooltipId = idProp ?? generatedId

  const [resolvedOpen, setOpen] = useControllableState({
    value: open,
    defaultValue: defaultOpen,
    onChange: onOpenChange,
  })

  const computePosition = useCallback(
    (args: AnchoredOverlayPositionArgs) => computeTooltipPosition({ ...args, placement }),
    [placement],
  )

  const { mounted, entered, popoverRef, style: overlayStyle, handleTransitionEnd } = useAnchoredOverlay({
    open: resolvedOpen,
    anchorRef,
    onRequestClose: () => setOpen(false),
    computePosition,
  })

  const anchorHoveredRef = useRef(false)
  const popoverHoveredRef = useRef(false)
  const focusedRef = useRef(false)

  const evaluate = useCallback(() => {
    setOpen(anchorHoveredRef.current || popoverHoveredRef.current || focusedRef.current)
  }, [setOpen])

  // Hover/focus is a single, standardized interaction (WAI-ARIA APG
  // Tooltip pattern) with no app-specific ambiguity, unlike Menu's click —
  // so Tooltip wires it directly on the consumer-owned anchor instead of
  // asking the consumer to. Shown/hidden immediately, matching the pinned
  // source's own `handleGestures` (no invented warm-up delay). The popover
  // itself also participates (`popoverHoveredRef`), so a pointer crossing
  // from anchor to popover does not flicker-close it — bridged for free by
  // the deferred-unmount fade-out window `useAnchoredOverlay` already
  // provides, not a fabricated timing buffer.
  useEffect(() => {
    const anchor = anchorRef.current
    if (!anchor) return
    const handleMouseEnter = () => {
      anchorHoveredRef.current = true
      evaluate()
    }
    const handleMouseLeave = () => {
      anchorHoveredRef.current = false
      evaluate()
    }
    const handleFocus = () => {
      focusedRef.current = true
      evaluate()
    }
    const handleBlur = () => {
      focusedRef.current = false
      evaluate()
    }
    anchor.addEventListener('mouseenter', handleMouseEnter)
    anchor.addEventListener('mouseleave', handleMouseLeave)
    anchor.addEventListener('focus', handleFocus)
    anchor.addEventListener('blur', handleBlur)
    return () => {
      anchor.removeEventListener('mouseenter', handleMouseEnter)
      anchor.removeEventListener('mouseleave', handleMouseLeave)
      anchor.removeEventListener('focus', handleFocus)
      anchor.removeEventListener('blur', handleBlur)
    }
  }, [anchorRef, evaluate])

  // Imperative `aria-describedby`: the first ARIA attribute v1 sets on a
  // consumer-owned element, justified by the same "library owns
  // unambiguous wiring" reasoning as Dialog's imperative native calls and
  // Menu/Select's imperative focus calls — merges with, rather than
  // clobbers, any `aria-describedby` the consumer already set declaratively.
  useEffect(() => {
    const anchor = anchorRef.current
    if (!anchor || !mounted) return
    const previous = anchor.getAttribute('aria-describedby')
    const ids = previous ? previous.split(' ').filter(Boolean) : []
    if (!ids.includes(tooltipId)) {
      anchor.setAttribute('aria-describedby', [...ids, tooltipId].join(' '))
    }
    return () => {
      const current = anchor.getAttribute('aria-describedby')
      if (!current) return
      const next = current
        .split(' ')
        .filter((id) => id && id !== tooltipId)
        .join(' ')
      if (next) anchor.setAttribute('aria-describedby', next)
      else anchor.removeAttribute('aria-describedby')
    }
  }, [anchorRef, mounted, tooltipId])

  if (!mounted) return null

  return createPortal(
    <div
      {...divProps}
      ref={composeRefs(forwardedRef, popoverRef)}
      id={tooltipId}
      role="tooltip"
      className={
        className
          ? `m3e-tooltip m3e-tooltip--${variant} ${className}`
          : `m3e-tooltip m3e-tooltip--${variant}`
      }
      data-m3e-open={entered}
      style={{ ...overlayStyle, ...(style as CSSProperties) }}
      onTransitionEnd={handleTransitionEnd}
      onMouseEnter={() => {
        popoverHoveredRef.current = true
      }}
      onMouseLeave={() => {
        popoverHoveredRef.current = false
        evaluate()
      }}
    >
      {variant === 'rich' && subhead != null && <div className="m3e-tooltip__subhead">{subhead}</div>}
      <div className="m3e-tooltip__content">{content}</div>
    </div>,
    document.body,
  )
}

const ForwardedTooltip = forwardRef<HTMLDivElement, TooltipProps>(TooltipRender)
ForwardedTooltip.displayName = 'Tooltip'

export const Tooltip = ForwardedTooltip as TooltipComponent
