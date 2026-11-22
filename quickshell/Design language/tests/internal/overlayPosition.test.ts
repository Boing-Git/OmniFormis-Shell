import { computeOverlayPosition, computeTooltipPosition } from '../../src/internal/overlayPosition'

const viewport = { width: 1000, height: 800 }

describe('computeOverlayPosition', () => {
  it('prefers start-aligned, below the anchor by default', () => {
    const result = computeOverlayPosition({
      anchor: { top: 100, left: 100, width: 50, height: 20 },
      overlay: { width: 200, height: 100 },
      viewport,
    })
    expect(result).toEqual({ top: 120, left: 100, width: 200, placement: 'below' })
  })

  it('flips to end-aligned when start-aligned would overflow the right edge', () => {
    const result = computeOverlayPosition({
      anchor: { top: 100, left: 900, width: 50, height: 20 },
      overlay: { width: 200, height: 100 },
      viewport,
    })
    // end-aligned: anchor.left + anchor.width - overlay.width = 900+50-200 = 750
    expect(result.left).toBe(750)
  })

  it('clamps horizontally against the viewport margin when neither alignment fits', () => {
    // start-aligned: 10 + 990 = 1000 > 992 (viewport - margin) — overflows.
    // end-aligned: 10 + 5 - 990 = -975 < 8 (margin) — overflows the other way.
    const result = computeOverlayPosition({
      anchor: { top: 100, left: 10, width: 5, height: 20 },
      overlay: { width: 990, height: 100 },
      viewport,
      margin: 8,
    })
    expect(result.left).toBe(8)
  })

  it('flips above the anchor when there is not enough space below', () => {
    const result = computeOverlayPosition({
      anchor: { top: 750, left: 100, width: 50, height: 20 },
      overlay: { width: 200, height: 100 },
      viewport,
    })
    expect(result.placement).toBe('above')
    expect(result.top).toBe(750 - 100)
  })

  it('clamps vertically against the viewport margin when neither placement fits', () => {
    const result = computeOverlayPosition({
      anchor: { top: 400, left: 100, width: 50, height: 20 },
      overlay: { width: 200, height: 780 },
      viewport,
      margin: 8,
    })
    expect(result.top).toBeGreaterThanOrEqual(8)
    expect(result.top + 780).toBeLessThanOrEqual(viewport.height - 8 + 1)
  })

  it('respects a gap between the anchor and the overlay', () => {
    const result = computeOverlayPosition({
      anchor: { top: 100, left: 100, width: 50, height: 20 },
      overlay: { width: 100, height: 50 },
      viewport,
      gap: 4,
    })
    expect(result.top).toBe(124)
  })

  it('matchAnchorWidth forces the overlay to the anchor width and left edge, skipping the horizontal search', () => {
    const result = computeOverlayPosition({
      anchor: { top: 100, left: 900, width: 250, height: 20 },
      overlay: { width: 50, height: 100 },
      viewport,
      matchAnchorWidth: true,
    })
    expect(result.left).toBe(900)
    expect(result.width).toBe(250)
  })

  it('uses the default 8px margin and 0 gap when unspecified', () => {
    const result = computeOverlayPosition({
      anchor: { top: 0, left: 0, width: 50, height: 20 },
      overlay: { width: 200, height: 50 },
      viewport,
    })
    expect(result.left).toBe(0)
    expect(result.top).toBe(20)
  })
})

describe('computeTooltipPosition', () => {
  it('centers on the cross axis and places above with the default 4px gap', () => {
    const result = computeTooltipPosition({
      anchor: { top: 300, left: 400, width: 100, height: 40 },
      overlay: { width: 60, height: 30 },
      viewport,
      placement: 'top',
    })
    expect(result).toEqual({ top: 266, left: 420, placement: 'top' })
  })

  it('flips to below when above would collide with the top viewport edge', () => {
    const result = computeTooltipPosition({
      anchor: { top: 10, left: 400, width: 100, height: 40 },
      overlay: { width: 60, height: 30 },
      viewport,
      placement: 'top',
    })
    expect(result).toEqual({ top: 54, left: 420, placement: 'bottom' })
  })

  it('flips to above when below would collide with the bottom viewport edge', () => {
    const result = computeTooltipPosition({
      anchor: { top: 780, left: 400, width: 100, height: 40 },
      overlay: { width: 60, height: 30 },
      viewport,
      placement: 'bottom',
    })
    expect(result).toEqual({ top: 746, left: 420, placement: 'top' })
  })

  it("resolves 'start'/'end' to physical left/right", () => {
    const anchor = { top: 300, left: 500, width: 40, height: 100 }
    const overlay = { width: 60, height: 30 }
    expect(computeTooltipPosition({ anchor, overlay, viewport, placement: 'start' })).toEqual({
      top: 335,
      left: 436,
      placement: 'left',
    })
    expect(computeTooltipPosition({ anchor, overlay, viewport, placement: 'end' })).toEqual({
      top: 335,
      left: 544,
      placement: 'right',
    })
  })

  it('flips left to right when it would collide with the left viewport edge', () => {
    const result = computeTooltipPosition({
      anchor: { top: 300, left: 20, width: 40, height: 100 },
      overlay: { width: 60, height: 30 },
      viewport,
      placement: 'left',
    })
    expect(result).toEqual({ top: 335, left: 64, placement: 'right' })
  })

  it('flips right to left when it would collide with the right viewport edge', () => {
    const result = computeTooltipPosition({
      anchor: { top: 300, left: 950, width: 40, height: 100 },
      overlay: { width: 60, height: 30 },
      viewport,
      placement: 'right',
    })
    expect(result).toEqual({ top: 335, left: 886, placement: 'left' })
  })

  it('clamps flush to the viewport edge with zero margin when the overlay is larger than the viewport', () => {
    const result = computeTooltipPosition({
      anchor: { top: 300, left: 10, width: 20, height: 20 },
      overlay: { width: 1200, height: 30 },
      viewport,
      placement: 'top',
    })
    expect(result).toEqual({ top: 266, left: 0, placement: 'top' })
  })

  it('respects a custom gap', () => {
    const result = computeTooltipPosition({
      anchor: { top: 100, left: 0, width: 0, height: 0 },
      overlay: { width: 10, height: 10 },
      viewport,
      placement: 'bottom',
      gap: 12,
    })
    expect(result.top).toBe(112)
  })
})
