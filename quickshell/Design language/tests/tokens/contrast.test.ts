import {
  colorContrastRatio,
  defaultTokenSet,
  resolveColorScheme,
  validateColorContrasts,
} from '../../src/tokens'

describe('Material color contrast', () => {
  it('resolves the current light and dark Material role values', () => {
    const light = resolveColorScheme(defaultTokenSet, 'light')
    const dark = resolveColorScheme(defaultTokenSet, 'dark')
    expect(light.primary).toBe('#6750a4')
    expect(light.onPrimaryContainer).toBe('#4f378b')
    expect(dark.primary).toBe('#d0bcff')
    expect(dark.surfaceContainerHighest).toBe('#36343b')
  })

  it('passes every required foreground/background pair at 4.5:1 or better', () => {
    const results = validateColorContrasts(defaultTokenSet)
    expect(results).toHaveLength(48)
    expect(results.every((result) => result.passes)).toBe(true)
    expect(Math.min(...results.map((result) => result.ratio))).toBeGreaterThanOrEqual(4.5)
  })

  it('uses the WCAG relative-luminance contrast calculation', () => {
    expect(colorContrastRatio('#000000', '#ffffff')).toBe(21)
    expect(colorContrastRatio('#ffffff', '#ffffff')).toBe(1)
  })
})
