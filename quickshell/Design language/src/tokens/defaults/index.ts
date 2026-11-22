import type { FoundationTokenSet } from '../schema'
import { parseTokenSet } from '../validation'
import { defaultButtonTokens } from './button'
import { defaultButtonGroupTokens } from './button-group'
import { defaultCardTokens } from './card'
import { defaultCheckboxTokens } from './checkbox'
import { defaultCircularProgressTokens } from './circular-progress'
import { defaultDarkColorScheme, defaultLightColorScheme, defaultPalette } from './color'
import { defaultDensity } from './density'
import { defaultDialogTokens } from './dialog'
import { defaultElevation } from './elevation'
import { defaultFabMenuTokens } from './fab-menu'
import { defaultFloatingActionButtonTokens } from './floating-action-button'
import { defaultFloatingToolbarTokens } from './floating-toolbar'
import { defaultIconTokens } from './icon'
import { defaultIconButtonTokens } from './icon-button'
import { defaultLinearProgressTokens } from './linear-progress'
import { defaultLoadingIndicatorTokens } from './loading-indicator'
import { defaultMenuTokens } from './menu'
import { defaultMotion } from './motion'
import { defaultNavigationBarTokens } from './navigation-bar'
import { defaultNavigationDrawerTokens } from './navigation-drawer'
import { defaultNavigationRailTokens } from './navigation-rail'
import { defaultRadioTokens } from './radio'
import { defaultSegmentedButtonGroupTokens } from './segmented-button-group'
import { defaultShape } from './shape'
import { defaultSnackbarTokens } from './snackbar'
import { defaultSplitButtonTokens } from './split-button'
import { defaultState } from './state'
import { defaultSurfaceTokens } from './surface'
import { defaultSwitchTokens } from './switch'
import { defaultTabsTokens } from './tabs'
import { defaultTextFieldTokens } from './text-field'
import { defaultTooltipTokens } from './tooltip'
import { defaultTypography } from './typography'
import { defaultWavyProgressTokens } from './wavy-progress'

const defaultTokenSetInput = {
  metadata: {
    schemaVersion: 1,
    materialVersion: '34.0.21',
    sources: [
      {
        id: 'material-web-tokens',
        url: 'https://github.com/material-components/material-web/tree/b4de401eb665ec63474f39319a4ba8f2145974cc/tokens/versions/latest/sass',
        revision: 'b4de401eb665ec63474f39319a4ba8f2145974cc',
        accessed: '2026-07-19',
      },
      {
        id: 'androidx-material3',
        url: 'https://android.googlesource.com/platform/frameworks/support/+/0be207d91046b7376beeef5544d331a02d6fa87c/compose/material3/material3/src/commonMain/kotlin/androidx/compose/material3',
        revision: '0be207d91046b7376beeef5544d331a02d6fa87c',
        accessed: '2026-07-19',
      },
    ],
  },
  reference: {
    palette: defaultPalette,
    typeface: {
      brand: ['Roboto', 'sans-serif'],
      plain: ['Roboto', 'sans-serif'],
      weight: {
        regular: 400,
        medium: 500,
        bold: 700,
      },
    },
  },
  system: {
    color: {
      light: defaultLightColorScheme,
      dark: defaultDarkColorScheme,
    },
    typography: defaultTypography,
    shape: defaultShape,
    motion: defaultMotion,
    elevation: defaultElevation,
    state: defaultState,
    density: defaultDensity,
  },
  componentTokens: [
    defaultSurfaceTokens,
    defaultIconTokens,
    defaultButtonTokens,
    defaultButtonGroupTokens,
    defaultIconButtonTokens,
    defaultFloatingActionButtonTokens,
    defaultFloatingToolbarTokens,
    defaultFabMenuTokens,
    defaultCardTokens,
    defaultCheckboxTokens,
    defaultRadioTokens,
    defaultSwitchTokens,
    defaultTextFieldTokens,
    defaultSegmentedButtonGroupTokens,
    defaultDialogTokens,
    defaultMenuTokens,
    defaultTooltipTokens,
    defaultSnackbarTokens,
    defaultSplitButtonTokens,
    defaultTabsTokens,
    defaultNavigationBarTokens,
    defaultNavigationRailTokens,
    defaultNavigationDrawerTokens,
    defaultLinearProgressTokens,
    defaultCircularProgressTokens,
    defaultWavyProgressTokens,
    defaultLoadingIndicatorTokens,
  ],
} satisfies FoundationTokenSet

export const defaultTokenSet = parseTokenSet(defaultTokenSetInput)
