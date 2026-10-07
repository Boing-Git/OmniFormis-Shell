import { readFileSync } from 'node:fs'
import { fileURLToPath } from 'node:url'

const css = readFileSync(
  fileURLToPath(
    new URL(
      '../../../src/components/SegmentedButtonGroup/SegmentedButtonGroup.css',
      import.meta.url,
    ),
  ),
  'utf8',
)

describe('SegmentedButtonGroup stylesheet contract', () => {
  it('maps sourced geometry through stable component variables', () => {
    expect(css).toContain('var(--m3e-comp-segmented-button-group-container-height)')
    expect(css).toContain('var(--m3e-comp-segmented-button-group-minimum-width)')
    expect(css).toContain('var(--m3e-comp-segmented-button-group-border-width)')
    expect(css).toContain('var(--m3e-comp-segmented-button-group-icon-size)')
    expect(css).not.toMatch(/#[0-9a-f]{3,8}/i)
  })

  it('rounds only the outer corners of the first and last segments with logical corner properties', () => {
    expect(css).toContain('[data-m3e-position="start"]')
    expect(css).toContain('[data-m3e-position="middle"]')
    expect(css).toContain('[data-m3e-position="end"]')
    expect(css).toContain('[data-m3e-position="only"]')
    expect(css).toContain('border-start-start-radius')
    expect(css).toContain('border-end-start-radius')
    expect(css).toContain('border-start-end-radius')
    expect(css).toContain('border-end-end-radius')
  })

  it('overlaps adjacent segments by one border width and stacks checked/interacting segments above the rest', () => {
    expect(css).toContain('margin-inline-start: calc(-1 * var(--m3e-comp-segmented-button-group-border-width));')
    expect(css).toContain(':has(:checked)')
    expect(css).toContain(':has(:focus-visible)')
  })

  it('drives checked, hover, press, and focus visuals from the input’s own pseudo-classes, not a React-rendered attribute', () => {
    expect(css).toContain('.m3e-segmented-button__input:checked')
    expect(css).toContain('.m3e-segmented-button:hover')
    expect(css).toContain('.m3e-segmented-button:active')
    expect(css).not.toMatch(/\[data-m3e-state=/)
  })

  it('reads disabled from a mirrored root attribute, the one state this instance fully owns', () => {
    expect(css).toContain('[data-m3e-disabled="true"]')
  })

  it('reproduces the asymmetric no-icon reveal and the symmetric icon crossfade separately', () => {
    expect(css).toContain('[data-m3e-has-icon="false"]')
    expect(css).toContain('[data-m3e-has-icon="true"]')
    expect(css).toContain('transform: scale(0)')
    expect(css).toContain('transform: scale(1)')
    expect(css).toContain('transform-origin: 0% 100%')
  })

  it('uses the theme’s own label-large typescale role directly', () => {
    expect(css).toContain('var(--m3e-sys-typescale-baseline-label-large-font-size)')
    expect(css).toContain('var(--m3e-sys-typescale-baseline-label-large-font-weight)')
  })

  it('uses semantic Expressive motion with an immediate reduced-motion outcome', () => {
    expect(css).toContain('var(--m3e-sys-motion-expressive-fast-spatial-duration)')
    expect(css).toContain('var(--m3e-sys-motion-expressive-default-effects-duration)')
    expect(css).toContain('@media (prefers-reduced-motion: reduce)')
    expect(css).toContain('transition: none')
  })

  it('uses logical layout and retains visible state in forced colors', () => {
    expect(css).toContain('inline-size:')
    expect(css).toContain('margin-inline-start')
    expect(css).toContain('@media (forced-colors: active)')
    expect(css).toContain('Highlight')
    expect(css).toContain('GrayText')
    expect(css).not.toMatch(
      /^\s*(?:left|right|width|height|margin-left|margin-right|padding-left|padding-right)\s*:/m,
    )
  })
})
