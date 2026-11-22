/** Server-safe theme data entry. React providers and hooks live in `./index`. */
export {
  ThemeValidationError,
  createTheme,
  defaultTheme,
  extendTheme,
  parseTheme,
  validateTheme,
} from './theme'
export type {
  ColorMode,
  Material3Theme,
  Material3ThemeOverrides,
  ResolvedColorMode,
  ThemeValidationResult,
} from './theme.types'
