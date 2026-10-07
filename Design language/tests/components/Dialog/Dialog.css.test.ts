import { readFileSync } from 'node:fs'
import { fileURLToPath } from 'node:url'

const css = readFileSync(
  fileURLToPath(new URL('../../../src/components/Dialog/Dialog.css', import.meta.url)),
  'utf8',
)

describe('Dialog stylesheet contract', () => {
  it('maps sourced container geometry and color through stable component variables', () => {
    expect(css).toContain('var(--m3e-comp-dialog-container-color)')
    expect(css).toContain('var(--m3e-comp-dialog-container-shape)')
    expect(css).toContain('var(--m3e-comp-dialog-container-shadow)')
    expect(css).toContain('var(--m3e-comp-dialog-container-padding)')
    expect(css).not.toMatch(/#[0-9a-f]{3,8}/i)
  })

  it('bounds width between the sourced 280–560px range, clamped against the viewport margin', () => {
    expect(css).toContain('var(--m3e-comp-dialog-container-min-width)')
    expect(css).toContain('var(--m3e-comp-dialog-container-max-width)')
    expect(css).toContain('var(--m3e-comp-dialog-container-viewport-margin)')
    expect(css).toContain('100vw')
    expect(css).toContain('overflow-y: auto')
  })

  it('drives open state entirely from the native [open] attribute, not a library-owned class', () => {
    expect(css).toContain('.m3e-dialog[open]')
    expect(css).toContain('.m3e-dialog[open]::backdrop')
    expect(css).not.toMatch(/\.m3e-dialog--open/)
  })

  it('animates entrance and exit with @starting-style and allow-discrete, degrading to instant show/hide', () => {
    expect(css).toContain('@starting-style')
    expect(css).toContain('allow-discrete')
    expect(css).toContain('transform: scale(0.8)')
    expect(css).toContain('transform: scale(1)')
  })

  it('styles the native ::backdrop as the scrim using the sourced scrim color and opacity', () => {
    expect(css).toContain('::backdrop')
    expect(css).toContain('var(--m3e-comp-dialog-scrim-color)')
    expect(css).toContain('var(--m3e-comp-dialog-scrim-opacity)')
  })

  it('centers the title only when an icon is present, matching the sourced alignment branch', () => {
    expect(css).toContain('[data-m3e-has-icon="true"] .m3e-dialog__title')
    expect(css).toContain('text-align: start')
    expect(css).toContain('text-align: center')
  })

  it('spaces icon, title, and content by their sourced values, collapsing for whichever slot is last', () => {
    expect(css).toContain('.m3e-dialog__icon:not(:last-child)')
    expect(css).toContain('.m3e-dialog__title:not(:last-child)')
    expect(css).toContain('.m3e-dialog__content:not(:last-child)')
    expect(css).toContain('var(--m3e-comp-dialog-icon-spacing)')
    expect(css).toContain('var(--m3e-comp-dialog-headline-spacing)')
    expect(css).toContain('var(--m3e-comp-dialog-supporting-text-spacing)')
  })

  it('end-aligns and wraps the actions row with the sourced gap', () => {
    expect(css).toContain('.m3e-dialog__actions')
    expect(css).toContain('justify-content: flex-end')
    expect(css).toContain('flex-wrap: wrap')
    expect(css).toContain('var(--m3e-comp-dialog-action-spacing)')
  })

  it('uses the theme’s own headline-small and body-medium typescale roles directly', () => {
    expect(css).toContain('var(--m3e-sys-typescale-baseline-headline-small-font-size)')
    expect(css).toContain('var(--m3e-sys-typescale-baseline-body-medium-font-size)')
  })

  it('uses semantic Expressive motion with an immediate reduced-motion outcome', () => {
    expect(css).toContain('var(--m3e-sys-motion-expressive-default-spatial-duration)')
    expect(css).toContain('var(--m3e-sys-motion-expressive-default-effects-duration)')
    expect(css).toContain('@media (prefers-reduced-motion: reduce)')
    expect(css).toContain('transition: none')
  })

  it('uses logical layout and retains a visible boundary in forced colors', () => {
    expect(css).toContain('inline-size')
    expect(css).toContain('margin-block-end')
    expect(css).toContain('@media (forced-colors: active)')
    expect(css).toContain('CanvasText')
    expect(css).not.toMatch(
      /^\s*(?:left|right|width|height|margin-left|margin-right|padding-left|padding-right)\s*:/m,
    )
  })
})
