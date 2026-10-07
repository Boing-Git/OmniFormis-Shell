'use client'

import {
  createContext,
  useCallback,
  useContext,
  useEffect,
  useMemo,
  useState,
  type ReactNode,
} from 'react'
import {
  Material3Provider,
  useResolvedColorMode,
  type ColorMode,
} from '@language-lit/material3-expressive'
import { createTheme, type Material3Theme } from '@language-lit/material3-expressive/theme'
import { buildPalette, defaultSourceColor } from '../theme/palette'

interface SiteThemeValue {
  sourceColor: string
  setSourceColor: (color: string) => void
  colorMode: ColorMode
  setColorMode: (mode: ColorMode) => void
  /** Present when the generated palette failed the library's own validation. */
  themeError: string | null
  resetTheme: () => void
  isCustomized: boolean
}

const SiteThemeContext = createContext<SiteThemeValue | null>(null)

export function useSiteTheme(): SiteThemeValue {
  const value = useContext(SiteThemeContext)
  if (!value) throw new Error('useSiteTheme must be used inside SiteProviders')
  return value
}

const storageKey = 'm3e-site-theme'

interface StoredPreferences {
  sourceColor?: string
  colorMode?: ColorMode
}

function readStored(): StoredPreferences {
  if (typeof window === 'undefined') return {}
  try {
    return JSON.parse(window.localStorage.getItem(storageKey) ?? '{}') as StoredPreferences
  } catch {
    return {}
  }
}

/**
 * Mirrors the provider's resolved color mode onto the document element.
 *
 * The theme scope is a div inside `body`, so the browser canvas, scrollbars,
 * and native form controls have no way to know which palette the page settled
 * on. `color-scheme` is the one signal they read. This is the site adapting to
 * the library's deliberate choice not to mutate the document root.
 */
function ColorSchemeSync() {
  const mode = useResolvedColorMode()

  useEffect(() => {
    const previous = document.documentElement.style.colorScheme
    document.documentElement.style.colorScheme = mode
    return () => {
      document.documentElement.style.colorScheme = previous
    }
  }, [mode])

  return null
}

export function SiteProviders({ children }: { children: ReactNode }) {
  // The first client render must match the server markup, so preferences load
  // in an effect rather than during render. `systemModeFallback` gives the
  // server a deterministic snapshot; static CSS still paints the browser's
  // real scheme before hydration.
  const [sourceColor, setSourceColorState] = useState(defaultSourceColor)
  const [colorMode, setColorModeState] = useState<ColorMode>('system')

  useEffect(() => {
    const stored = readStored()
    if (stored.sourceColor) setSourceColorState(stored.sourceColor)
    if (stored.colorMode) setColorModeState(stored.colorMode)
  }, [])

  const persist = useCallback((next: StoredPreferences) => {
    try {
      window.localStorage.setItem(
        storageKey,
        JSON.stringify({ ...readStored(), ...next }),
      )
    } catch {
      // A site preference is not worth failing a render over.
    }
  }, [])

  const setSourceColor = useCallback(
    (color: string) => {
      setSourceColorState(color)
      persist({ sourceColor: color })
    },
    [persist],
  )

  const setColorMode = useCallback(
    (mode: ColorMode) => {
      setColorModeState(mode)
      persist({ colorMode: mode })
    },
    [persist],
  )

  const resetTheme = useCallback(() => {
    setSourceColor(defaultSourceColor)
  }, [setSourceColor])

  // `createTheme` validates the complete resulting theme, including role-pair
  // contrast. A generated palette that fails is reported rather than swallowed:
  // the library rejecting an inaccessible theme is a feature worth showing.
  const { theme, themeError } = useMemo((): {
    theme: Material3Theme | undefined
    themeError: string | null
  } => {
    if (sourceColor === defaultSourceColor) return { theme: undefined, themeError: null }
    try {
      return {
        theme: createTheme({ reference: { palette: buildPalette(sourceColor) } }),
        themeError: null,
      }
    } catch (error) {
      return {
        theme: undefined,
        themeError: error instanceof Error ? error.message : String(error),
      }
    }
  }, [sourceColor])

  const value = useMemo(
    (): SiteThemeValue => ({
      sourceColor,
      setSourceColor,
      colorMode,
      setColorMode,
      themeError,
      resetTheme,
      isCustomized: sourceColor !== defaultSourceColor,
    }),
    [sourceColor, setSourceColor, colorMode, setColorMode, themeError, resetTheme],
  )

  return (
    <SiteThemeContext.Provider value={value}>
      <Material3Provider
        theme={theme}
        colorMode={colorMode}
        systemModeFallback="light"
        className="site-theme"
      >
        <ColorSchemeSync />
        {children}
      </Material3Provider>
    </SiteThemeContext.Provider>
  )
}
