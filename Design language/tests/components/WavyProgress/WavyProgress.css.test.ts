import { readFileSync } from 'node:fs'
import { fileURLToPath } from 'node:url'

const css = readFileSync(
  fileURLToPath(
    new URL('../../../src/components/WavyProgress/WavyProgress.css', import.meta.url),
  ),
  'utf8',
)

describe('WavyProgress stylesheet contract', () => {
  it('maps sourced geometry and color through stable component variables', () => {
    expect(css).toContain('var(--m3e-comp-wavy-progress-active-indicator-color)')
    expect(css).toContain('var(--m3e-comp-wavy-progress-track-color)')
    expect(css).toContain('var(--m3e-comp-wavy-progress-linear-container-height)')
    expect(css).toContain('var(--m3e-comp-wavy-progress-circular-diameter)')
    expect(css).not.toMatch(/#[0-9a-f]{3,8}/i)
  })

  it('animates the wave travel via CSS @keyframes transform, one wavelength per wave-travel-duration', () => {
    expect(css).toContain('@keyframes m3e-wavy-progress-linear-wave-travel-determinate')
    expect(css).toContain('@keyframes m3e-wavy-progress-linear-wave-travel-indeterminate')
    expect(css).toContain('@keyframes m3e-wavy-progress-wave-rotate')
    expect(css).toContain('@keyframes m3e-wavy-progress-wave-dash-travel')
    expect(css).toContain('stroke-dashoffset: -11.111111')
    expect(css).toContain('var(--m3e-comp-wavy-progress-wave-travel-duration)')
  })

  it('transitions the amplitude ramp on its own dedicated duration/easing tokens', () => {
    expect(css).toContain('var(--m3e-comp-wavy-progress-amplitude-transition-duration)')
    expect(css).toContain('var(--m3e-comp-wavy-progress-amplitude-transition-easing)')
    expect(css).toContain('var(--m3e-comp-wavy-progress-amplitude-decreasing-transition-easing)')
    expect(css).toMatch(/transition:\s*d /)
    expect(css).not.toContain('scaleY(')
  })

  it('composes three independent circular indeterminate animations, matching CircularProgress', () => {
    expect(css).toContain('@keyframes m3e-wavy-progress-global-rotate')
    expect(css).toContain('@keyframes m3e-wavy-progress-additional-rotate')
    expect(css).toContain('@keyframes m3e-wavy-progress-sweep-pulse')
    expect(css).toContain('@keyframes m3e-wavy-progress-track-sweep-pulse')
  })

  it('rotates every circular animation layer around the fixed SVG view box', () => {
    expect(css).toContain('transform-box: view-box')
    expect(css).not.toContain('transform-box: fill-box')
    expect(css).toMatch(/to\s*{\s*transform:\s*rotate\(-40deg\);\s*}/)
    expect(css).toMatch(/from\s*{\s*transform:\s*rotate\(90deg\);\s*}/)
    expect(css).toContain('stroke-linecap: round')
  })

  it('drives linear indeterminate motion with CSS @keyframes, not a JS animation loop', () => {
    expect(css).toContain('@keyframes m3e-wavy-progress-indeterminate-bar1')
    expect(css).toContain('@keyframes m3e-wavy-progress-indeterminate-bar2')
  })

  it('uses an immediate reduced-motion outcome', () => {
    expect(css).toContain('@media (prefers-reduced-motion: reduce)')
    expect(css).toContain('animation: none')
    expect(css).toContain('transition: none')
  })

  it('uses logical layout only, and keeps every part visibly distinct in forced colors', () => {
    expect(css).toContain('inline-size')
    expect(css).toContain('inset-inline-start')
    expect(css).toContain('@media (forced-colors: active)')
    expect(css).toContain('GrayText')
    expect(css).toContain('Highlight')
    expect(css).not.toMatch(
      /^\s*(?:left|right|width|height|margin-left|margin-right|padding-left|padding-right)\s*:/m,
    )
  })
})
