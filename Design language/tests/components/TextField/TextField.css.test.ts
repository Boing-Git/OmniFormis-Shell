import { readFileSync } from 'node:fs'
import { fileURLToPath } from 'node:url'

const css = readFileSync(
  fileURLToPath(new URL('../../../src/components/TextField/TextField.css', import.meta.url)),
  'utf8',
)

describe('TextField stylesheet contract', () => {
  it('maps sourced geometry through stable component variables', () => {
    expect(css).toContain('var(--m3e-comp-text-field-min-container-block-size)')
    expect(css).toContain('var(--m3e-comp-text-field-min-container-inline-size)')
    expect(css).toContain('var(--m3e-comp-text-field-minimum-interactive-target)')
    expect(css).toContain('var(--m3e-comp-text-field-content-padding)')
    expect(css).not.toMatch(/#[0-9a-f]{3,8}/i)
  })

  it('drives the floating label and border weight from the input’s own focus/placeholder-shown state, not a React-rendered attribute', () => {
    expect(css).toContain('.m3e-text-field__input:focus ~ .m3e-text-field__label')
    expect(css).toContain('.m3e-text-field__input:not(:placeholder-shown) ~ .m3e-text-field__label')
    expect(css).toContain('.m3e-text-field__input:focus ~ .m3e-text-field__indicator')
    expect(css).toContain('.m3e-text-field__input:focus ~ .m3e-text-field__outline')
    expect(css).toContain('.m3e-text-field__input:disabled ~ .m3e-text-field__label')
    expect(css).not.toMatch(/\[data-m3e-state=/)
  })

  it('reads error and disabled from root attributes, the only states unreachable by a sibling combinator', () => {
    expect(css).toContain('[data-m3e-error="true"] .m3e-text-field__label')
    expect(css).toContain('[data-m3e-error="true"] .m3e-text-field__supporting-text')
    expect(css).toContain('[data-m3e-disabled="true"] .m3e-text-field__supporting-text')
  })

  it('interpolates the label between the baseline body-large and body-small typescale roles', () => {
    expect(css).toContain('var(--m3e-sys-typescale-baseline-body-large-font-size)')
    expect(css).toContain('var(--m3e-sys-typescale-baseline-body-small-font-size)')
    expect(css).toContain('var(--m3e-sys-typescale-baseline-body-large-line-height)')
    expect(css).toContain('var(--m3e-sys-typescale-baseline-body-small-line-height)')
  })

  it('draws the outlined notch with intrinsic-width segmented panels', () => {
    expect(css).toContain('.m3e-text-field__outline')
    expect(css).toContain('.m3e-text-field__outline-start')
    expect(css).toContain('.m3e-text-field__notch')
    expect(css).toContain('.m3e-text-field__notch::before')
    expect(css).toContain('.m3e-text-field__outline-end')
    expect(css).toContain('visibility: hidden')
    expect(css).toContain('transform: scaleX(0)')
    expect(css).not.toContain('max-inline-size: 1000px')
  })

  it('allocates source-aligned logical start/content/end regions instead of padding the input beneath icons', () => {
    const inputRule = css.slice(css.indexOf('.m3e-text-field__input {'))
    const inputRuleBody = inputRule.slice(0, inputRule.indexOf('}'))
    const leadingRegionRule = css.slice(
      css.indexOf('.m3e-text-field__field[data-m3e-has-leading-icon="true"] {'),
    )
    const leadingRegionBody = leadingRegionRule.slice(0, leadingRegionRule.indexOf('}'))

    expect(css).toContain('--m3e-text-field-start-space:')
    expect(css).toContain('--m3e-text-field-end-space:')
    expect(css).toContain('grid-template-columns:')
    expect(inputRuleBody).toContain('grid-column: 2')
    expect(inputRuleBody).toContain('padding-inline: 0')
    expect(leadingRegionBody).toContain(
      'var(--m3e-comp-text-field-minimum-interactive-target) +',
    )
    expect(leadingRegionBody).toContain('var(--m3e-comp-text-field-icon-content-gap)')
    expect(css).not.toContain(
      '[data-m3e-has-leading-icon="true"] .m3e-text-field__input',
    )
    expect(css).not.toContain(
      '[data-m3e-has-trailing-icon="true"] .m3e-text-field__input',
    )
  })

  it('allocates source-aligned top/content/bottom rows instead of padding the native control', () => {
    const fieldRule = css.slice(css.indexOf('.m3e-text-field__field {'))
    const fieldRuleBody = fieldRule.slice(0, fieldRule.indexOf('}'))
    const inputRule = css.slice(css.indexOf('.m3e-text-field__input {'))
    const inputRuleBody = inputRule.slice(0, inputRule.indexOf('}'))
    const filledFieldRule = css.slice(
      css.indexOf('.m3e-text-field[data-m3e-variant="filled"] .m3e-text-field__field {'),
    )
    const filledFieldRuleBody = filledFieldRule.slice(0, filledFieldRule.indexOf('}'))

    expect(fieldRuleBody).toContain('--m3e-text-field-block-start-space:')
    expect(fieldRuleBody).toContain('--m3e-text-field-block-end-space:')
    expect(fieldRuleBody).toContain('grid-template-rows:')
    expect(fieldRuleBody).toContain(
      'minmax(var(--m3e-sys-typescale-baseline-body-large-line-height), auto)',
    )
    expect(filledFieldRuleBody).toContain(
      '8px + var(--m3e-sys-typescale-baseline-body-small-line-height)',
    )
    expect(filledFieldRuleBody).toContain('--m3e-text-field-block-end-space: 8px')
    expect(inputRuleBody).toContain('grid-row: 2')
    expect(inputRuleBody).toContain('padding-block: 0')
    expect(css).not.toContain('padding-block: 24px 8px')
    expect(css).not.toContain('padding-block: 16px')
  })

  it('separates icon-aware resting content from the outlined floating inset', () => {
    const outlinedFloatRule = css.slice(
      css.indexOf('.m3e-text-field[data-m3e-variant="outlined"]\n    .m3e-text-field__input:focus'),
    )
    const outlinedFloatBody = outlinedFloatRule.slice(0, outlinedFloatRule.indexOf('}'))

    expect(outlinedFloatBody).toContain(
      'inset-inline-start: var(--m3e-comp-text-field-content-padding)',
    )
    expect(outlinedFloatBody).toContain(
      'max-inline-size: calc(100% - 2 * var(--m3e-comp-text-field-content-padding))',
    )
  })

  it('preserves a whole-field click target outside the native control region', () => {
    expect(css).toContain('.m3e-text-field__hit-target')
    expect(css).toContain('inset: 0')
    expect(css).toContain('z-index: 0')
  })

  it('starts a resting multiline label at the sourced top padding', () => {
    expect(css).toContain(
      '.m3e-text-field[data-m3e-multiline="true"] .m3e-text-field__label',
    )
    expect(css).toContain('top: var(--m3e-comp-text-field-content-padding)')
  })

  it('uses the true-alpha color-mix technique for every disabled color', () => {
    expect(css).toContain('color-mix(')
    expect(css).toContain('var(--m3e-comp-text-field-disabled-input-opacity)')
    expect(css).toContain('var(--m3e-comp-text-field-outlined-disabled-outline-opacity)')
  })

  it('uses semantic Expressive motion with an immediate reduced-motion outcome', () => {
    expect(css).toContain('var(--m3e-sys-motion-expressive-fast-spatial-duration)')
    expect(css).toContain('var(--m3e-sys-motion-expressive-fast-spatial-easing)')
    expect(css).toContain('var(--m3e-sys-motion-expressive-fast-effects-duration)')
    expect(css).toContain('@media (prefers-reduced-motion: reduce)')
    expect(css).toContain('transition: none')
  })

  it('uses logical layout and retains visible state in forced colors', () => {
    expect(css).toContain('inline-size:')
    expect(css).toContain('inset-inline')
    expect(css).toContain('@media (forced-colors: active)')
    expect(css).toContain('Highlight')
    expect(css).toContain('GrayText')
    expect(css).not.toMatch(
      /^\s*(?:left|right|width|height|margin-left|margin-right|padding-left|padding-right)\s*:/m,
    )
  })
})
