import type { FoundationTokenSet } from './schema'
import { assertTokenSet } from './validation'

function sortJson(value: unknown): unknown {
  if (Array.isArray(value)) return value.map(sortJson)
  if (value === null || typeof value !== 'object') return value
  return Object.fromEntries(
    Object.keys(value)
      .sort()
      .map((key) => [key, sortJson((value as Record<string, unknown>)[key])]),
  )
}

export function serializeTokenSet(value: unknown, spacing = 2): string {
  assertTokenSet(value)
  return JSON.stringify(sortJson(value as FoundationTokenSet), null, spacing)
}
