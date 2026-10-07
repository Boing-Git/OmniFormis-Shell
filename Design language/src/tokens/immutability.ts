function cloneValue(value: unknown): unknown {
  if (value === null || typeof value !== 'object') return value
  if (Array.isArray(value)) return value.map(cloneValue)
  return Object.fromEntries(Object.entries(value).map(([key, nested]) => [key, cloneValue(nested)]))
}

function freezeValue<T>(value: T): T {
  if (value === null || typeof value !== 'object' || Object.isFrozen(value)) return value
  for (const nested of Object.values(value)) freezeValue(nested)
  return Object.freeze(value)
}

export function cloneAndDeepFreeze<T>(value: T): Readonly<T> {
  return freezeValue(cloneValue(value)) as Readonly<T>
}

export function isDeeplyFrozen(value: unknown): boolean {
  if (value === null || typeof value !== 'object') return true
  if (!Object.isFrozen(value)) return false
  return Object.values(value).every(isDeeplyFrozen)
}
