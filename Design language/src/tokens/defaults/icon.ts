import type { ComponentTokenRegistration } from '../schema'

/**
 * Defaults for the passive Material Icon contract and the web Material Symbols
 * adapter. The component never loads these fonts; the names are styling hooks
 * for a font supplied by the consumer.
 */
export const defaultIconTokens = {
  component: 'icon',
  task: 'T06',
  source: {
    id: 'material-symbols-web',
    url: 'https://developers.google.com/fonts/docs/material_symbols',
    revision: '2024-09-26',
    accessed: '2026-07-19',
  },
  tokens: {
    size: { kind: 'dimension', value: '24px' },
    'symbol-family-outlined': { kind: 'font-family', value: '"Material Symbols Outlined"' },
    'symbol-family-rounded': { kind: 'font-family', value: '"Material Symbols Rounded"' },
    'symbol-family-sharp': { kind: 'font-family', value: '"Material Symbols Sharp"' },
    'symbol-fill': { kind: 'number', value: 0 },
    'symbol-weight': { kind: 'font-weight', value: 400 },
    'symbol-grade': { kind: 'number', value: 0 },
    'symbol-optical-size': { kind: 'number', value: 24 },
    'symbol-roundness': { kind: 'number', value: 50 },
  },
} as const satisfies ComponentTokenRegistration
