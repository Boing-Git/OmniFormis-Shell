import { readFileSync } from 'node:fs'
import { fileURLToPath } from 'node:url'

const css = readFileSync(
  fileURLToPath(
    new URL('../../../src/components/CircularProgress/CircularProgress.css', import.meta.url),
  ),
  'utf8',
)

describe('CircularProgress stylesheet contract', () => {
  it('maps sourced geometry and color through stable component variables', () => {
    expect(css).toContain('var(--m3e-comp-circular-progress-active-indicator-color)')
    expect(css).toContain('var(--m3e-comp-circular-progress-track-color)')
    expect(css).toContain('var(--m3e-comp-circular-progress-diameter)')
    expect(css).not.toMatch(/#[0-9a-f]{3,8}/i)
  })

  it('drives determinate sweep via stroke-dasharray, transitioning on the shared spatial motion slot', () => {
    expect(css).toContain('stroke-dasharray')
    expect(css).toContain('stroke-linecap: round')
    expect(css).toContain('var(--m3e-sys-motion-expressive-default-spatial-duration)')
  })

  it('composes three independent CSS animations for indeterminate motion, matching the three composed animateFloat values in the source', () => {
    expect(css).toContain('@keyframes m3e-circular-progress-global-rotate')
    expect(css).toContain('@keyframes m3e-circular-progress-additional-rotate')
    expect(css).toContain('@keyframes m3e-circular-progress-sweep-pulse')
  })

  it('rotates nested SVG layers around the fixed view box rather than their changing fill bounds', () => {
    expect(css).toContain('transform-box: view-box')
    expect(css).not.toContain('transform-box: fill-box')
    expect(css).toContain('transform-origin: center')
  })

  it('uses an immediate reduced-motion outcome with a static partial arc fallback', () => {
    expect(css).toContain('@media (prefers-reduced-motion: reduce)')
    expect(css).toContain('animation: none')
    expect(css).toContain('stroke-dasharray: 25 75')
  })

  it('keeps every part visibly distinct in forced colors', () => {
    expect(css).toContain('@media (forced-colors: active)')
    expect(css).toContain('GrayText')
    expect(css).toContain('Highlight')
    expect(css).not.toMatch(
      /^\s*(?:left|right|width|height|margin-left|margin-right|padding-left|padding-right)\s*:/m,
    )
  })
})
