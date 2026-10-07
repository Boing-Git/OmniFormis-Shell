import { readFileSync } from 'node:fs'
import { fileURLToPath } from 'node:url'

const css = readFileSync(
  fileURLToPath(new URL('../../../src/components/ButtonGroup/ButtonGroup.css', import.meta.url)),
  'utf8',
)

describe('ButtonGroup stylesheet contract', () => {
  it('lays out children in a row with the sourced gap', () => {
    expect(css).toContain('display: flex')
    expect(css).toContain('var(--m3e-comp-button-group-between-space)')
  })

  it('reads each child\'s own native :active state for the compression interaction', () => {
    expect(css).toContain(':active')
    expect(css).toContain(':has(+ *:active)')
    expect(css).toContain('var(--m3e-comp-button-group-pressed-scale)')
    expect(css).toContain('var(--m3e-comp-button-group-neighbor-scale)')
  })

  it('transitions on the shared expressive fast-spatial motion slot, matching the source\'s own FastSpatial spec', () => {
    expect(css).toContain('var(--m3e-sys-motion-expressive-fast-spatial-duration)')
    expect(css).toContain('var(--m3e-sys-motion-expressive-fast-spatial-easing)')
  })

  it('becomes immediate under reduced motion', () => {
    expect(css).toContain('@media (prefers-reduced-motion: reduce)')
    expect(css).toContain('transition: none')
  })

  it('defines no colors of its own -- children handle their own forced-colors styling', () => {
    expect(css).not.toMatch(/#[0-9a-f]{3,8}/i)
    expect(css).not.toContain('color:')
    expect(css).not.toContain('background')
  })
})
