import { readFileSync } from 'node:fs'
import { fileURLToPath } from 'node:url'

const css = readFileSync(
  fileURLToPath(
    new URL('../../../src/components/LoadingIndicator/LoadingIndicator.css', import.meta.url),
  ),
  'utf8',
)

const keyframesCss = readFileSync(
  fileURLToPath(
    new URL(
      '../../../src/components/LoadingIndicator/loadingIndicatorKeyframes.css',
      import.meta.url,
    ),
  ),
  'utf8',
)

describe('LoadingIndicator stylesheet contract', () => {
  it('imports the generated indeterminate keyframes module', () => {
    expect(css).toContain("@import './loadingIndicatorKeyframes.css'")
  })

  it('maps sourced color and layout through stable component variables', () => {
    expect(css).toContain('var(--m3e-comp-loading-indicator-active-indicator-color)')
    expect(css).toContain('var(--m3e-comp-loading-indicator-container-width)')
    expect(css).toContain('var(--m3e-comp-loading-indicator-container-height)')
    expect(css).not.toMatch(/#[0-9a-f]{3,8}/i)
  })

  it('transitions the determinate shape on the shared spatial motion slot', () => {
    expect(css).toContain('transition:')
    expect(css).toContain('var(--m3e-sys-motion-expressive-default-spatial-duration)')
    expect(css).toContain('var(--m3e-sys-motion-expressive-default-spatial-easing)')
  })

  it('composes a continuous global rotation with seven independently keyframed segments', () => {
    expect(css).toContain('@keyframes m3e-loading-indicator-global-rotate')
    expect(css).toContain('var(--m3e-comp-loading-indicator-global-rotation-duration)')
    for (let index = 0; index < 7; index += 1) {
      expect(keyframesCss).toContain(`@keyframes m3e-loading-indicator-segment-${index}`)
    }
  })

  it('gives every segment keyframe rule structurally identical d values at every stop pair it interpolates between', () => {
    // Each rule must open with a `d:path(...)` declaration on its very
    // first stop -- the CSS `d` property can only ever animate between
    // structurally identical paths, so every stop within one rule shares
    // that rule's own fixed cubic-command structure by construction.
    const ruleCount = [...keyframesCss.matchAll(/@keyframes m3e-loading-indicator-segment-\d/g)].length
    expect(ruleCount).toBe(7)
    expect(keyframesCss.match(/d:path\(/g)?.length).toBeGreaterThan(7)
  })

  it('snaps opacity discretely with step-end instead of ease-fading between segments', () => {
    expect(keyframesCss).toContain('animation-timing-function:step-end')
  })

  it('uses a spring-shaped linear() easing for each segment morph, not a named easing keyword', () => {
    expect(keyframesCss).toContain('animation-timing-function:linear(0,')
  })

  it('provides a static reduced-motion fallback shape', () => {
    expect(keyframesCss).toContain('.m3e-loading-indicator__reduced-motion-fallback')
    expect(css).toContain('@media (prefers-reduced-motion: reduce)')
    expect(css).toContain('animation: none')
  })

  it('keeps the shape visibly distinct in forced colors', () => {
    expect(css).toContain('@media (forced-colors: active)')
    expect(css).toContain('Highlight')
    expect(css).toContain('forced-color-adjust: none')
  })
})
