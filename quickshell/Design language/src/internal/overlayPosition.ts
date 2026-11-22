export interface OverlayPositionRect {
  readonly top: number
  readonly left: number
  readonly width: number
  readonly height: number
}

export interface OverlayPositionSize {
  readonly width: number
  readonly height: number
}

export interface OverlayPositionOptions {
  /** The trigger's own viewport-relative box. */
  readonly anchor: OverlayPositionRect
  /** The popover's own measured size, before this computation repositions it. */
  readonly overlay: OverlayPositionSize
  readonly viewport: OverlayPositionSize
  /**
   * Minimum clearance kept between the popover and every viewport edge,
   * reproducing the pinned source's `MenuHorizontalMargin` (8dp) reused on
   * both axes — see ADR 0017 for why Android's separate, larger
   * `MenuVerticalMargin` (48dp, reserved for system status/navigation bars)
   * has no web equivalent and is not ported as a second number.
   */
  readonly margin?: number
  /** Gap between the anchor's own edge and the popover's facing edge. */
  readonly gap?: number
  /**
   * Forces the popover to the anchor's own width and skips the horizontal
   * start/end search, reproducing `ExposedDropdownMenuBox`'s own
   * `exposedDropdownSize(matchAnchorWidth = true)` — the popover's left edge
   * always aligns with the anchor's, since a width-matched popover has no
   * independent alignment freedom to search.
   */
  readonly matchAnchorWidth?: boolean
}

export interface OverlayPosition {
  readonly top: number
  readonly left: number
  readonly width: number
  readonly placement: 'below' | 'above'
}

const DEFAULT_MARGIN = 8
const DEFAULT_GAP = 0

/**
 * Reproduces `DropdownMenuPositionProvider`'s own behavior: try the anchor's
 * own alignment first, fall back to the opposite alignment, and finally
 * clamp inside the viewport margin — horizontally start-of-anchor then
 * end-of-anchor then the viewport edge, vertically below-anchor then
 * above-anchor then the viewport edge. A pure function over plain rects
 * (not `DOMRect`) so it is directly unit-testable without a real layout
 * engine; `useAnchoredOverlay` is the only caller that feeds it real
 * measurements.
 */
export function computeOverlayPosition(options: OverlayPositionOptions): OverlayPosition {
  const { anchor, overlay, viewport, matchAnchorWidth = false } = options
  const margin = options.margin ?? DEFAULT_MARGIN
  const gap = options.gap ?? DEFAULT_GAP

  const width = matchAnchorWidth ? anchor.width : overlay.width

  let left: number
  if (matchAnchorWidth) {
    left = anchor.left
  } else {
    const startAligned = anchor.left
    const endAligned = anchor.left + anchor.width - width
    if (startAligned + width <= viewport.width - margin) {
      left = startAligned
    } else if (endAligned >= margin) {
      left = endAligned
    } else {
      left = clamp(startAligned, margin, viewport.width - width - margin)
    }
  }

  const below = anchor.top + anchor.height + gap
  const above = anchor.top - overlay.height - gap
  const spaceBelow = viewport.height - below
  const spaceAbove = anchor.top - gap

  let top: number
  let placement: 'below' | 'above'
  if (overlay.height <= spaceBelow - margin) {
    top = below
    placement = 'below'
  } else if (overlay.height <= spaceAbove - margin) {
    top = above
    placement = 'above'
  } else if (spaceBelow >= spaceAbove) {
    top = clamp(below, margin, viewport.height - overlay.height - margin)
    placement = 'below'
  } else {
    top = clamp(above, margin, viewport.height - overlay.height - margin)
    placement = 'above'
  }

  return { top, left, width, placement }
}

function clamp(value: number, min: number, max: number): number {
  return Math.min(Math.max(value, min), Math.max(min, max))
}

export type TooltipPlacement = 'top' | 'bottom' | 'start' | 'end'

export interface TooltipPositionOptions {
  readonly anchor: OverlayPositionRect
  readonly overlay: OverlayPositionSize
  readonly viewport: OverlayPositionSize
  readonly placement: TooltipPlacement
  /** Gap between the anchor's own edge and the tooltip's facing edge. */
  readonly gap?: number
}

export interface TooltipPosition {
  readonly top: number
  readonly left: number
  readonly placement: 'top' | 'bottom' | 'left' | 'right'
}

const TOOLTIP_DEFAULT_GAP = 4

/**
 * Reproduces `TooltipPositionProviderImpl`'s own above/below/left/right
 * behavior: center-aligned on the cross axis, a single flip to the opposite
 * side on collision, then clamped flush to the viewport edge with **zero**
 * margin — the pinned source's own `coerceIn(0, ...)`, not a fabricated
 * margin (contrast `computeOverlayPosition`'s sourced 8px `Menu` margin).
 * `'start'`/`'end'` resolve to physical left/right unconditionally, the
 * same no-RTL-branching precedent `computeOverlayPosition` already set.
 */
export function computeTooltipPosition(options: TooltipPositionOptions): TooltipPosition {
  const { anchor, overlay, viewport } = options
  const gap = options.gap ?? TOOLTIP_DEFAULT_GAP
  const resolved: 'top' | 'bottom' | 'left' | 'right' =
    options.placement === 'start' ? 'left' : options.placement === 'end' ? 'right' : options.placement

  if (resolved === 'left' || resolved === 'right') {
    return horizontalTooltipPlacement(resolved, anchor, overlay, viewport, gap)
  }
  return verticalTooltipPlacement(resolved, anchor, overlay, viewport, gap)
}

function verticalTooltipPlacement(
  preferred: 'top' | 'bottom',
  anchor: OverlayPositionRect,
  overlay: OverlayPositionSize,
  viewport: OverlayPositionSize,
  gap: number,
): TooltipPosition {
  const left = clamp(
    anchor.left + (anchor.width - overlay.width) / 2,
    0,
    Math.max(0, viewport.width - overlay.width),
  )

  let top: number
  let placement: 'top' | 'bottom'
  if (preferred === 'top') {
    top = anchor.top - overlay.height - gap
    placement = 'top'
    if (top < 0) {
      top = anchor.top + anchor.height + gap
      placement = 'bottom'
    }
  } else {
    top = anchor.top + anchor.height + gap
    placement = 'bottom'
    if (top + overlay.height > viewport.height) {
      top = anchor.top - overlay.height - gap
      placement = 'top'
    }
  }
  top = clamp(top, 0, Math.max(0, viewport.height - overlay.height))
  return { top, left, placement }
}

function horizontalTooltipPlacement(
  preferred: 'left' | 'right',
  anchor: OverlayPositionRect,
  overlay: OverlayPositionSize,
  viewport: OverlayPositionSize,
  gap: number,
): TooltipPosition {
  const top = clamp(
    anchor.top + (anchor.height - overlay.height) / 2,
    0,
    Math.max(0, viewport.height - overlay.height),
  )

  let left: number
  let placement: 'left' | 'right'
  if (preferred === 'left') {
    left = anchor.left - overlay.width - gap
    placement = 'left'
    if (left < 0) {
      left = anchor.left + anchor.width + gap
      placement = 'right'
    }
  } else {
    left = anchor.left + anchor.width + gap
    placement = 'right'
    if (left + overlay.width > viewport.width) {
      left = anchor.left - overlay.width - gap
      placement = 'left'
    }
  }
  left = clamp(left, 0, Math.max(0, viewport.width - overlay.width))
  return { top, left, placement }
}
