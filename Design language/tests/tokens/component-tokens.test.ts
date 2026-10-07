import {
  TokenValidationError,
  createComponentTokenRegistry,
  defaultTokenSet,
  defineComponentTokens,
  generateTokenCss,
  isDeeplyFrozen,
  parseTokenSet,
} from '../../src/tokens'

const source = {
  id: 'material-button',
  url: 'https://developer.android.com/reference/kotlin/androidx/compose/material3/Button',
  revision: '1.5.0-alpha24',
  accessed: '2026-07-19',
} as const

describe('component-token registrations', () => {
  it('defines a typed, immutable registration against foundation tokens', () => {
    const registration = defineComponentTokens({
      component: 'example-button',
      task: 'T07',
      source,
      tokens: {
        'container-color': { kind: 'color', value: { $ref: 'sys.color.primary' } },
        'container-height': { kind: 'dimension', value: '40px' },
      },
    })
    expect(isDeeplyFrozen(registration)).toBe(true)
    expect(registration.tokens['container-color'].value).toEqual({ $ref: 'sys.color.primary' })
  })

  it('generates deterministic component custom properties when a component task registers values', () => {
    const registrations = createComponentTokenRegistry([
      {
        component: 'example-button',
        task: 'T07',
        source,
        tokens: {
          'container-color': { kind: 'color', value: { $ref: 'sys.color.primary' } },
          'container-height': { kind: 'dimension', value: '40px' },
        },
      },
    ])
    const tokenSet = parseTokenSet({ ...defaultTokenSet, componentTokens: registrations })
    const css = generateTokenCss(tokenSet)
    expect(css).toContain('--m3e-comp-example-button-container-color: var(--m3e-sys-color-primary);')
    expect(css).toContain('--m3e-comp-example-button-container-height: 40px;')
  })

  it('rejects duplicate components, invalid names, and incompatible reference kinds', () => {
    const valid = {
      component: 'example-button',
      task: 'T07',
      source,
      tokens: { color: { kind: 'color', value: { $ref: 'sys.color.primary' } } },
    } as const
    expect(() => createComponentTokenRegistry([valid, valid])).toThrow(TokenValidationError)
    expect(() =>
      defineComponentTokens({ ...valid, component: 'ExampleButton' }),
    ).toThrow(TokenValidationError)
    expect(() =>
      defineComponentTokens({
        ...valid,
        tokens: { color: { kind: 'color', value: { $ref: 'sys.density.scale' } } },
      }),
    ).toThrow(TokenValidationError)
  })
})
