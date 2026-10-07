import { useCallback, useSyncExternalStore } from 'react'
import type { ResolvedColorMode } from './theme.types'

const darkModeQuery = '(prefers-color-scheme: dark)'
const removeNoop = () => {}

function readSystemMode(fallback: ResolvedColorMode): ResolvedColorMode {
  if (typeof window === 'undefined' || typeof window.matchMedia !== 'function') return fallback
  return window.matchMedia(darkModeQuery).matches ? 'dark' : 'light'
}

export function useSystemColorMode(
  enabled: boolean,
  serverFallback: ResolvedColorMode,
): ResolvedColorMode {
  const subscribe = useCallback(
    (notify: () => void) => {
      if (!enabled || typeof window === 'undefined' || typeof window.matchMedia !== 'function') {
        return removeNoop
      }
      const mediaQuery = window.matchMedia(darkModeQuery)
      mediaQuery.addEventListener('change', notify)
      return () => mediaQuery.removeEventListener('change', notify)
    },
    [enabled],
  )
  const getSnapshot = useCallback(
    () => (enabled ? readSystemMode(serverFallback) : serverFallback),
    [enabled, serverFallback],
  )
  const getServerSnapshot = useCallback(() => serverFallback, [serverFallback])

  return useSyncExternalStore(subscribe, getSnapshot, getServerSnapshot)
}
