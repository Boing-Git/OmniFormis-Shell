import { createContext, useContext } from 'react'
import { defaultTheme } from './theme'
import type { Material3Theme, ResolvedColorMode } from './theme.types'

export const Material3ThemeContext = createContext<Material3Theme>(defaultTheme)
export const ResolvedColorModeContext = createContext<ResolvedColorMode>('light')

export function useMaterial3Theme(): Material3Theme {
  return useContext(Material3ThemeContext)
}

export function useResolvedColorMode(): ResolvedColorMode {
  return useContext(ResolvedColorModeContext)
}
