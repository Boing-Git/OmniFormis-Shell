import type { HTMLAttributes, ReactNode } from 'react'
import type {
  ColorMode,
  Material3Theme,
  ResolvedColorMode,
} from '../theme.types'

export interface Material3ProviderProps extends HTMLAttributes<HTMLDivElement> {
  readonly children?: ReactNode
  readonly theme?: Material3Theme
  readonly colorMode?: ColorMode
  /** The deterministic server and hydration snapshot used for system mode. */
  readonly systemModeFallback?: ResolvedColorMode
  /**
   * Initializes the resolved-mode data attribute before hydration. Static CSS
   * already applies the correct visual system scheme without this script.
   */
  readonly preventColorSchemeFlash?: boolean
  /** CSP nonce applied only to the optional initialization script. */
  readonly nonce?: string
}
