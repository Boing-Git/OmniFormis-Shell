import { readFileSync } from 'node:fs'
import { fileURLToPath } from 'node:url'

const css = readFileSync(
  fileURLToPath(new URL('../../../src/components/TextArea/TextArea.css', import.meta.url)),
  'utf8',
)

describe('TextArea stylesheet contract', () => {
  it('only layers multiline deltas on top of the shared field chrome', () => {
    expect(css).toContain('textarea.m3e-text-field__input')
    expect(css).toContain(
      'min-block-size: var(--m3e-sys-typescale-baseline-body-large-line-height)',
    )
    expect(css).toContain('resize: vertical')
    expect(css).not.toContain('.m3e-text-field__label {')
    expect(css).not.toContain('.m3e-text-field__outline {')
  })

  it('keeps a one-line native content floor while the shared grid owns outer spacing', () => {
    const textareaRule = css.slice(css.indexOf('textarea.m3e-text-field__input'))
    const textareaRuleBody = textareaRule.slice(0, textareaRule.indexOf('}'))

    expect(textareaRuleBody).toContain(
      'min-block-size: var(--m3e-sys-typescale-baseline-body-large-line-height)',
    )
    expect(textareaRuleBody).toContain('resize: vertical')
  })

  it('does not override the shared chrome’s source-aligned icon centering', () => {
    expect(css).not.toContain('[data-m3e-multiline="true"] .m3e-text-field__icon')
    expect(css).not.toContain('inset-block: 0 auto')
  })
})
