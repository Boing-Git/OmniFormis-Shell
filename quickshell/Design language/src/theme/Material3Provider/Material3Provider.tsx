'use client'

import { useMemo, type CSSProperties } from 'react'
import { useSystemColorMode } from '../color-mode-store'
import { Material3ThemeContext, ResolvedColorModeContext } from '../contexts'
import { createThemeStyleOverrides } from '../style-overrides'
import { defaultTheme, parseTheme } from '../theme'
import type { ResolvedColorMode } from '../theme.types'
import type { Material3ProviderProps } from './Material3Provider.types'

const initializeColorMode = `(function(){var s=document.currentScript;if(!s)return;var e=s.parentElement;if(!e)return;var m=e.getAttribute("data-m3e-color-mode");var r=m==="system"?(window.matchMedia&&window.matchMedia("(prefers-color-scheme: dark)").matches?"dark":"light"):m;if(r)e.setAttribute("data-m3e-resolved-color-mode",r)})()`

export function Material3Provider({
  children,
  theme,
  colorMode = 'system',
  systemModeFallback = 'light',
  preventColorSchemeFlash = false,
  nonce,
  className,
  style,
  suppressHydrationWarning,
  ...elementProps
}: Material3ProviderProps) {
  const parsedTheme = useMemo(
    () => (theme === undefined || theme === defaultTheme ? defaultTheme : parseTheme(theme)),
    [theme],
  )
  const systemMode = useSystemColorMode(colorMode === 'system', systemModeFallback)
  const resolvedMode: ResolvedColorMode = colorMode === 'system' ? systemMode : colorMode
  const themeStyle = useMemo(
    () => createThemeStyleOverrides(parsedTheme, colorMode),
    [colorMode, parsedTheme],
  )
  const mergedStyle = { ...themeStyle, ...style } as CSSProperties
  const mergedClassName = className ? `m3e-theme ${className}` : 'm3e-theme'

  return (
    <Material3ThemeContext.Provider value={parsedTheme}>
      <ResolvedColorModeContext.Provider value={resolvedMode}>
        <div
          {...elementProps}
          className={mergedClassName}
          style={mergedStyle}
          data-m3e-color-mode={colorMode}
          data-m3e-resolved-color-mode={resolvedMode}
          suppressHydrationWarning={
            suppressHydrationWarning ?? (preventColorSchemeFlash && colorMode === 'system')
          }
        >
          {preventColorSchemeFlash ? (
            <script nonce={nonce} dangerouslySetInnerHTML={{ __html: initializeColorMode }} />
          ) : null}
          {children}
        </div>
      </ResolvedColorModeContext.Provider>
    </Material3ThemeContext.Provider>
  )
}
