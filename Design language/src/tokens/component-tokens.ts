import { defaultTokenSet } from './defaults'
import type { ComponentTokenRegistration, FoundationTokenSet } from './schema'
import { parseTokenSet } from './validation'

export function createComponentTokenRegistry(
  registrations: readonly ComponentTokenRegistration[],
  foundation: FoundationTokenSet = defaultTokenSet,
): readonly ComponentTokenRegistration[] {
  return parseTokenSet({ ...foundation, componentTokens: registrations }).componentTokens
}

export function defineComponentTokens<const TRegistration extends ComponentTokenRegistration>(
  registration: TRegistration,
  foundation: FoundationTokenSet = defaultTokenSet,
): Readonly<TRegistration> {
  const registrations = createComponentTokenRegistry(
    [...foundation.componentTokens, registration],
    foundation,
  )
  return registrations[registrations.length - 1] as Readonly<TRegistration>
}
