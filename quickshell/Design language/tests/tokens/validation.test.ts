import {
  TokenValidationError,
  defaultTokenSet,
  isDeeplyFrozen,
  parseTokenSet,
  serializeTokenSet,
  validateTokenSet,
} from '../../src/tokens'

function cloneDefaults(): any {
  return JSON.parse(JSON.stringify(defaultTokenSet))
}

function issueCodes(value: unknown): string[] {
  const result = validateTokenSet(value)
  return result.success ? [] : result.issues.map((issue) => issue.code)
}

describe('token validation', () => {
  it('rejects missing and unknown keys', () => {
    const missing = cloneDefaults()
    delete missing.system.color.light.primary
    expect(issueCodes(missing)).toContain('missing-key')

    const extra = cloneDefaults()
    extra.system.state.longPressed = 0.2
    expect(issueCodes(extra)).toContain('unknown-key')
  })

  it('rejects malformed values and unsupported JSON data', () => {
    const badLength = cloneDefaults()
    badLength.system.shape.cornerValues.small = '8dp'
    expect(issueCodes(badLength)).toContain('value')

    const functionValue = cloneDefaults()
    functionValue.metadata.materialVersion = () => '34.0.21'
    expect(issueCodes(functionValue)).toContain('non-serializable')

    const circular = cloneDefaults()
    circular.componentTokens = circular
    expect(issueCodes(circular)).toContain('non-serializable')
  })

  it('rejects unresolved and kind-incompatible references', () => {
    const unresolved = cloneDefaults()
    unresolved.system.color.light.primary.$ref = 'ref.palette.missing-40'
    expect(issueCodes(unresolved)).toContain('unresolved-reference')

    const wrongKind = cloneDefaults()
    wrongKind.system.typography.baseline.bodyLarge.fontFamily.$ref = 'ref.palette.primary-40'
    expect(issueCodes(wrongKind)).toContain('reference-kind')
  })

  it('rejects color schemes that break required role-pair contrast', () => {
    const lowContrast = cloneDefaults()
    lowContrast.reference.palette['primary-40'] = '#ffffff'
    const result = validateTokenSet(lowContrast)
    expect(result.success).toBe(false)
    if (!result.success) {
      expect(result.issues).toContainEqual(
        expect.objectContaining({ code: 'contrast', path: 'tokens.system.color.light.onPrimary' }),
      )
    }
  })

  it('parses to a detached, deeply frozen value without mutating the input', () => {
    const input = cloneDefaults()
    const parsed = parseTokenSet(input)
    expect(parsed).not.toBe(input)
    expect(isDeeplyFrozen(parsed)).toBe(true)
    expect(Object.isFrozen(input)).toBe(false)
    expect(() => {
      ;(parsed.system.state as any).hover = 1
    }).toThrow(TypeError)
  })

  it('throws a structured validation error from parse', () => {
    const invalid = cloneDefaults()
    invalid.system.density.minimumInteractiveTarget = '47px'
    expect(() => parseTokenSet(invalid)).toThrow(TokenValidationError)
    try {
      parseTokenSet(invalid)
    } catch (error) {
      expect(error).toBeInstanceOf(TokenValidationError)
      expect((error as TokenValidationError).issues[0]).toEqual(
        expect.objectContaining({ path: 'tokens.system.density.minimumInteractiveTarget' }),
      )
    }
  })

  it('serializes deterministically regardless of object insertion order', () => {
    const reordered = {
      componentTokens: defaultTokenSet.componentTokens,
      system: defaultTokenSet.system,
      reference: defaultTokenSet.reference,
      metadata: defaultTokenSet.metadata,
    }
    expect(serializeTokenSet(reordered)).toBe(serializeTokenSet(defaultTokenSet))
  })
})
