import {
  ThemeValidationError,
  createTheme,
  defaultTheme,
  extendTheme,
  isDeeplyFrozen,
  parseTheme,
  validateTheme,
} from '../../src'

function cloneDefaultTheme(): any {
  return JSON.parse(JSON.stringify(defaultTheme))
}

describe('Material 3 theme data', () => {
  it('provides a complete, serializable, deeply frozen default', () => {
    expect(validateTheme(defaultTheme)).toEqual({ success: true, issues: [] })
    expect(isDeeplyFrozen(defaultTheme)).toBe(true)
    expect(defaultTheme.colorSchemes.light).toHaveProperty('primary')
    expect(defaultTheme.colorSchemes.dark).toHaveProperty('primary')
    expect(defaultTheme.motion).toHaveProperty('expressive')
    expect(() => JSON.stringify(defaultTheme)).not.toThrow()
  })

  it('creates a detached theme by merging validated overrides', () => {
    const theme = createTheme({ density: { scale: -1 } })

    expect(theme).not.toBe(defaultTheme)
    expect(theme.density.scale).toBe(-1)
    expect(defaultTheme.density.scale).toBe(0)
    expect(theme.typography).not.toBe(defaultTheme.typography)
    expect(isDeeplyFrozen(theme)).toBe(true)
  })

  it('extends a supplied base without mutating either input', () => {
    const base = createTheme({ density: { scale: -1 } })
    const overrides = { density: { scale: -2 } } as const
    const extended = extendTheme(base, overrides)

    expect(base.density.scale).toBe(-1)
    expect(overrides.density.scale).toBe(-2)
    expect(extended.density.scale).toBe(-2)
    expect(extended).not.toBe(base)
    expect(isDeeplyFrozen(extended)).toBe(true)
  })

  it('rejects incomplete, unknown, and invalid fields with theme paths', () => {
    const missing = cloneDefaultTheme()
    delete missing.motion
    expect(validateTheme(missing)).toEqual(
      expect.objectContaining({
        success: false,
        issues: expect.arrayContaining([
          expect.objectContaining({ code: 'missing-key', path: 'theme.motion' }),
        ]),
      }),
    )

    const unknown = cloneDefaultTheme()
    unknown.application = { languageLit: true }
    expect(validateTheme(unknown)).toEqual(
      expect.objectContaining({
        success: false,
        issues: expect.arrayContaining([
          expect.objectContaining({ code: 'unknown-key', path: 'theme.application' }),
        ]),
      }),
    )

    const invalid = cloneDefaultTheme()
    invalid.density.minimumInteractiveTarget = '40px'
    expect(() => parseTheme(invalid)).toThrow(ThemeValidationError)
    try {
      parseTheme(invalid)
    } catch (error) {
      expect((error as ThemeValidationError).issues).toContainEqual(
        expect.objectContaining({ path: 'theme.density.minimumInteractiveTarget' }),
      )
    }
  })

  it('rejects unsafe or non-serializable extension values', () => {
    expect(() => createTheme({ density: { scale: Number.NaN } })).toThrow(
      ThemeValidationError,
    )
    expect(() => createTheme({ shapes: { corners: { cornerFull: (() => '50%') as never } } })).toThrow(
      ThemeValidationError,
    )

    const polluted = JSON.parse('{"__proto__":{"application":"private consumer"}}')
    expect(() => createTheme(polluted)).toThrow(ThemeValidationError)
    expect(({} as { application?: string }).application).toBeUndefined()
  })
})
