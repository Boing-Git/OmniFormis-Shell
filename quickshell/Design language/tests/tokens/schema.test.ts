import {
  COLOR_ROLE_NAMES,
  MOTION_CATEGORY_NAMES,
  MOTION_SCHEME_NAMES,
  MOTION_SPEED_NAMES,
  PALETTE_TOKEN_NAMES,
  SHAPE_CORNER_VALUE_NAMES,
  SHAPE_ROLE_NAMES,
  STATE_OPACITY_NAMES,
  TYPOGRAPHY_EMPHASES,
  TYPOGRAPHY_ROLE_NAMES,
  defaultTokenSet,
  isDeeplyFrozen,
  validateTokenSet,
} from '../../src/tokens'

describe('default token schema', () => {
  it('contains every approved foundation domain and role', () => {
    expect(PALETTE_TOKEN_NAMES).toHaveLength(96)
    expect(COLOR_ROLE_NAMES).toHaveLength(49)
    expect(TYPOGRAPHY_EMPHASES).toEqual(['baseline', 'emphasized'])
    expect(TYPOGRAPHY_ROLE_NAMES).toHaveLength(15)
    expect(SHAPE_CORNER_VALUE_NAMES).toHaveLength(9)
    expect(SHAPE_ROLE_NAMES).toHaveLength(15)
    expect(MOTION_SCHEME_NAMES).toEqual(['standard', 'expressive'])
    expect(MOTION_SPEED_NAMES).toEqual(['fast', 'default', 'slow'])
    expect(MOTION_CATEGORY_NAMES).toEqual(['spatial', 'effects'])
    expect(STATE_OPACITY_NAMES).toEqual(['disabled', 'dragged', 'focus', 'hover', 'pressed'])
    expect(defaultTokenSet.system.elevation).toHaveProperty('level5')
    expect(defaultTokenSet.system.density).toEqual({
      scale: 0,
      minimumInteractiveTarget: '48px',
    })
  })

  it('is complete, source-traced, deeply immutable, and serializable', () => {
    expect(validateTokenSet(defaultTokenSet)).toEqual({ success: true, issues: [] })
    expect(defaultTokenSet.metadata.materialVersion).toBe('34.0.21')
    expect(defaultTokenSet.metadata.sources).toHaveLength(2)
    expect(defaultTokenSet.metadata.sources.every((source) => source.accessed === '2026-07-19')).toBe(true)
    expect(isDeeplyFrozen(defaultTokenSet)).toBe(true)
    expect(defaultTokenSet.componentTokens).toHaveLength(27)
    expect(defaultTokenSet.componentTokens).toContainEqual(expect.objectContaining({
      component: 'surface',
      task: 'T04',
      source: expect.objectContaining({ accessed: '2026-07-19' }),
    }))
    expect(defaultTokenSet.componentTokens).toContainEqual(expect.objectContaining({
      component: 'icon',
      task: 'T06',
      source: expect.objectContaining({ accessed: '2026-07-19' }),
    }))
    expect(defaultTokenSet.componentTokens).toContainEqual(expect.objectContaining({
      component: 'button',
      task: 'T07',
      source: expect.objectContaining({ accessed: '2026-07-19' }),
    }))
    expect(defaultTokenSet.componentTokens).toContainEqual(expect.objectContaining({
      component: 'button-group',
      task: 'T23',
      source: expect.objectContaining({
        revision: '225f50d42bf0adeb2abf4b6109befb5ab6ce4efc',
        accessed: '2026-07-20',
      }),
    }))
    expect(defaultTokenSet.componentTokens).toContainEqual(expect.objectContaining({
      component: 'split-button',
      task: 'T23',
      source: expect.objectContaining({
        revision: '225f50d42bf0adeb2abf4b6109befb5ab6ce4efc',
        accessed: '2026-07-20',
      }),
    }))
    expect(defaultTokenSet.componentTokens).toContainEqual(expect.objectContaining({
      component: 'icon-button',
      task: 'T08',
      source: expect.objectContaining({
        revision: 'f0793303999c933a40c10d79212e0580d21bdc68',
        accessed: '2026-07-19',
      }),
    }))
    expect(defaultTokenSet.componentTokens).toContainEqual(expect.objectContaining({
      component: 'floating-toolbar',
      task: 'T24',
      source: expect.objectContaining({
        revision: '225f50d42bf0adeb2abf4b6109befb5ab6ce4efc',
        accessed: '2026-07-20',
      }),
    }))
    expect(defaultTokenSet.componentTokens).toContainEqual(expect.objectContaining({
      component: 'fab-menu',
      task: 'T24',
      source: expect.objectContaining({
        revision: '225f50d42bf0adeb2abf4b6109befb5ab6ce4efc',
        accessed: '2026-07-20',
      }),
    }))
    expect(defaultTokenSet.componentTokens).toContainEqual(expect.objectContaining({
      component: 'floating-action-button',
      task: 'T09',
      source: expect.objectContaining({
        revision: 'b0ef6d36c141931a051272e39ad3f4783dcb28e0',
        accessed: '2026-07-19',
      }),
    }))
    expect(defaultTokenSet.componentTokens).toContainEqual(expect.objectContaining({
      component: 'card',
      task: 'T10',
      source: expect.objectContaining({
        revision: '0be207d91046b7376beeef5544d331a02d6fa87c',
        accessed: '2026-07-19',
      }),
    }))
    expect(defaultTokenSet.componentTokens).toContainEqual(expect.objectContaining({
      component: 'checkbox',
      task: 'T11',
      source: expect.objectContaining({
        revision: '225f50d42bf0adeb2abf4b6109befb5ab6ce4efc',
        accessed: '2026-07-19',
      }),
    }))
    expect(defaultTokenSet.componentTokens).toContainEqual(expect.objectContaining({
      component: 'radio',
      task: 'T12',
      source: expect.objectContaining({
        revision: '225f50d42bf0adeb2abf4b6109befb5ab6ce4efc',
        accessed: '2026-07-20',
      }),
    }))
    expect(defaultTokenSet.componentTokens).toContainEqual(expect.objectContaining({
      component: 'switch',
      task: 'T13',
      source: expect.objectContaining({
        revision: '225f50d42bf0adeb2abf4b6109befb5ab6ce4efc',
        accessed: '2026-07-20',
      }),
    }))
    expect(defaultTokenSet.componentTokens).toContainEqual(expect.objectContaining({
      component: 'text-field',
      task: 'T14',
      source: expect.objectContaining({
        revision: '225f50d42bf0adeb2abf4b6109befb5ab6ce4efc',
        accessed: '2026-07-20',
      }),
    }))
    expect(defaultTokenSet.componentTokens).toContainEqual(expect.objectContaining({
      component: 'segmented-button-group',
      task: 'T15',
      source: expect.objectContaining({
        revision: '225f50d42bf0adeb2abf4b6109befb5ab6ce4efc',
        accessed: '2026-07-20',
      }),
    }))
    expect(defaultTokenSet.componentTokens).toContainEqual(expect.objectContaining({
      component: 'dialog',
      task: 'T16',
      source: expect.objectContaining({
        revision: '225f50d42bf0adeb2abf4b6109befb5ab6ce4efc',
        accessed: '2026-07-20',
      }),
    }))
    expect(defaultTokenSet.componentTokens).toContainEqual(expect.objectContaining({
      component: 'menu',
      task: 'T17',
      source: expect.objectContaining({
        revision: '225f50d42bf0adeb2abf4b6109befb5ab6ce4efc',
        accessed: '2026-07-20',
      }),
    }))
    expect(defaultTokenSet.componentTokens).toContainEqual(expect.objectContaining({
      component: 'tooltip',
      task: 'T18',
      source: expect.objectContaining({
        revision: '225f50d42bf0adeb2abf4b6109befb5ab6ce4efc',
        accessed: '2026-07-20',
      }),
    }))
    expect(defaultTokenSet.componentTokens).toContainEqual(expect.objectContaining({
      component: 'snackbar',
      task: 'T18',
      source: expect.objectContaining({
        revision: '225f50d42bf0adeb2abf4b6109befb5ab6ce4efc',
        accessed: '2026-07-20',
      }),
    }))
    expect(defaultTokenSet.componentTokens).toContainEqual(expect.objectContaining({
      component: 'tabs',
      task: 'T19',
      source: expect.objectContaining({
        revision: '225f50d42bf0adeb2abf4b6109befb5ab6ce4efc',
        accessed: '2026-07-20',
      }),
    }))
    expect(defaultTokenSet.componentTokens).toContainEqual(expect.objectContaining({
      component: 'navigation-bar',
      task: 'T20',
      source: expect.objectContaining({
        revision: '225f50d42bf0adeb2abf4b6109befb5ab6ce4efc',
        accessed: '2026-07-20',
      }),
    }))
    expect(defaultTokenSet.componentTokens).toContainEqual(expect.objectContaining({
      component: 'navigation-rail',
      task: 'T20',
      source: expect.objectContaining({
        revision: '225f50d42bf0adeb2abf4b6109befb5ab6ce4efc',
        accessed: '2026-07-20',
      }),
    }))
    expect(defaultTokenSet.componentTokens).toContainEqual(expect.objectContaining({
      component: 'navigation-drawer',
      task: 'T20',
      source: expect.objectContaining({
        revision: '225f50d42bf0adeb2abf4b6109befb5ab6ce4efc',
        accessed: '2026-07-20',
      }),
    }))
    expect(defaultTokenSet.componentTokens).toContainEqual(expect.objectContaining({
      component: 'linear-progress',
      task: 'T21',
      source: expect.objectContaining({
        revision: '225f50d42bf0adeb2abf4b6109befb5ab6ce4efc',
        accessed: '2026-07-20',
      }),
    }))
    expect(defaultTokenSet.componentTokens).toContainEqual(expect.objectContaining({
      component: 'circular-progress',
      task: 'T21',
      source: expect.objectContaining({
        revision: '225f50d42bf0adeb2abf4b6109befb5ab6ce4efc',
        accessed: '2026-07-20',
      }),
    }))
    expect(defaultTokenSet.componentTokens).toContainEqual(expect.objectContaining({
      component: 'wavy-progress',
      task: 'T21',
      source: expect.objectContaining({
        revision: '225f50d42bf0adeb2abf4b6109befb5ab6ce4efc',
        accessed: '2026-07-20',
      }),
    }))
    expect(defaultTokenSet.componentTokens).toContainEqual(expect.objectContaining({
      component: 'loading-indicator',
      task: 'T22',
      source: expect.objectContaining({
        revision: '225f50d42bf0adeb2abf4b6109befb5ab6ce4efc',
        accessed: '2026-07-20',
      }),
    }))

    const roundTrip = JSON.parse(JSON.stringify(defaultTokenSet))
    expect(validateTokenSet(roundTrip)).toEqual({ success: true, issues: [] })
  })

  it('keeps baseline and emphasized typography visually aligned except for emphasis weight', () => {
    for (const role of TYPOGRAPHY_ROLE_NAMES) {
      const baseline = defaultTokenSet.system.typography.baseline[role]
      const emphasized = defaultTokenSet.system.typography.emphasized[role]
      expect(emphasized.fontFamily).toEqual(baseline.fontFamily)
      expect(emphasized.fontSize).toBe(baseline.fontSize)
      expect(emphasized.lineHeight).toBe(baseline.lineHeight)
      expect(emphasized.letterSpacing).toBe(baseline.letterSpacing)
      expect(emphasized.axes.wght).toBeGreaterThan(baseline.axes.wght)
    }
  })
})
