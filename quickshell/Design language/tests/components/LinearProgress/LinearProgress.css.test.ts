import { readFileSync } from 'node:fs'
import { fileURLToPath } from 'node:url'

const css = readFileSync(
  fileURLToPath(new URL('../../../src/components/LinearProgress/LinearProgress.css', import.meta.url)),
  'utf8',
)

describe('LinearProgress stylesheet contract', () => {
  it('maps sourced geometry and color through stable component variables', () => {
    expect(css).toContain('var(--m3e-comp-linear-progress-active-indicator-color)')
    expect(css).toContain('var(--m3e-comp-linear-progress-track-color)')
    expect(css).toContain('var(--m3e-comp-linear-progress-container-height)')
    expect(css).not.toMatch(/#[0-9a-f]{3,8}/i)
  })

  it('drives the determinate fill via inline-size, transitioning on the shared spatial motion slot', () => {
    expect(css).toContain('.m3e-linear-progress__fill')
    expect(css).toContain('inline-size')
    expect(css).toContain('var(--m3e-sys-motion-expressive-default-spatial-duration)')
  })

  it('drives indeterminate motion with CSS @keyframes, not a JS animation loop', () => {
    expect(css).toContain('@keyframes m3e-linear-progress-indeterminate-bar1')
    expect(css).toContain('@keyframes m3e-linear-progress-indeterminate-bar2')
    expect(css).toContain('animation-name: m3e-linear-progress-indeterminate-bar1')
  })

  it('uses an immediate reduced-motion outcome with a static partial fallback', () => {
    expect(css).toContain('@media (prefers-reduced-motion: reduce)')
    expect(css).toContain('animation: none')
    expect(css).toContain('transition: none')
  })

  it('uses logical layout only, and keeps every part visibly distinct in forced colors', () => {
    expect(css).toContain('inline-size')
    expect(css).toContain('inset-inline-start')
    expect(css).toContain('inset-block')
    expect(css).toContain('@media (forced-colors: active)')
    expect(css).toContain('GrayText')
    expect(css).toContain('Highlight')
    expect(css).not.toMatch(
      /^\s*(?:left|right|width|height|margin-left|margin-right|padding-left|padding-right)\s*:/m,
    )
  })
})
