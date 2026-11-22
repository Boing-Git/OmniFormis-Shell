import React from 'react'
import { createRoot } from 'react-dom/client'
import {
  Material3Provider,
  createTheme,
  defaultTokenSet,
  generateTokenCss,
  validateTokenSet,
} from '@language-lit/material3-expressive'
import '@language-lit/material3-expressive/styles.css'
import { ButtonExample } from '../examples/Button.example'
import { ButtonGroupExample } from '../examples/ButtonGroup.example'
import { CardExample } from '../examples/Card.example'
import { CheckboxExample } from '../examples/Checkbox.example'
import { CircularProgressExample } from '../examples/CircularProgress.example'
import { DialogExample } from '../examples/Dialog.example'
import { FabMenuExample } from '../examples/FabMenu.example'
import { FloatingActionButtonExample } from '../examples/FloatingActionButton.example'
import { FloatingToolbarExample } from '../examples/FloatingToolbar.example'
import { IconExample } from '../examples/Icon.example'
import { IconButtonExample } from '../examples/IconButton.example'
import { LinearProgressExample } from '../examples/LinearProgress.example'
import { LoadingIndicatorExample } from '../examples/LoadingIndicator.example'
import { MenuExample } from '../examples/Menu.example'
import { NavigationBarExample } from '../examples/NavigationBar.example'
import { NavigationDrawerExample } from '../examples/NavigationDrawer.example'
import { NavigationRailExample } from '../examples/NavigationRail.example'
import { NavigationSuiteExample } from '../examples/NavigationSuite.example'
import { RadioExample } from '../examples/Radio.example'
import { SegmentedButtonGroupExample } from '../examples/SegmentedButtonGroup.example'
import { SelectExample } from '../examples/Select.example'
import { SnackbarExample } from '../examples/Snackbar.example'
import { SplitButtonExample } from '../examples/SplitButton.example'
import { SurfaceExample } from '../examples/Surface.example'
import { SwitchExample } from '../examples/Switch.example'
import { TabsExample } from '../examples/Tabs.example'
import { TextExample } from '../examples/Text.example'
import { TextAreaExample } from '../examples/TextArea.example'
import { TextFieldExample } from '../examples/TextField.example'
import { TooltipExample } from '../examples/Tooltip.example'
import { WavyProgressExample } from '../examples/WavyProgress.example'
import './playground.css'

const root = document.getElementById('root')
const workbenchTheme = createTheme({ density: { scale: -1 } })
let runtimeErrorCount = 0

function reportRuntimeError() {
  runtimeErrorCount += 1
  const status = document.getElementById('v1-runtime-status')
  if (status) status.textContent = `Runtime errors: ${runtimeErrorCount}`
}

window.addEventListener('error', reportRuntimeError)
window.addEventListener('unhandledrejection', reportRuntimeError)

if (!root) throw new Error('Missing playground root element')

// vite.dev.config.ts aliases the styles.css import to the authored-only
// source file (no build step to generate the token custom-properties
// layer), so inject it here to keep live-source dev mode fully styled.
if (import.meta.env.DEV) {
  const tokenStyle = document.createElement('style')
  tokenStyle.textContent = generateTokenCss(defaultTokenSet)
  document.head.appendChild(tokenStyle)
}

createRoot(root).render(
  <React.StrictMode>
    <Material3Provider theme={workbenchTheme} colorMode="system">
      <main className="workbench">
        <h1>Material 3 Expressive React v1</h1>
        <p>Framework-neutral theme runtime ready.</p>
        <output>
          Material {defaultTokenSet.metadata.materialVersion}:{' '}
          {validateTokenSet(defaultTokenSet).success ? 'valid' : 'invalid'}
        </output>
        <output id="v1-runtime-status">Runtime errors: {runtimeErrorCount}</output>
        <SurfaceExample />
        <TextExample />
        <IconExample />
        <IconButtonExample />
        <FloatingActionButtonExample />
        <ButtonExample />
        <ButtonGroupExample />
        <SplitButtonExample />
        <CardExample />
        <CheckboxExample />
        <RadioExample />
        <SwitchExample />
        <TextFieldExample />
        <TextAreaExample />
        <SegmentedButtonGroupExample />
        <DialogExample />
        <MenuExample />
        <SelectExample />
        <TooltipExample />
        <SnackbarExample />
        <TabsExample />
        <NavigationBarExample />
        <NavigationRailExample />
        <NavigationDrawerExample />
        <NavigationSuiteExample />
        <LinearProgressExample />
        <CircularProgressExample />
        <WavyProgressExample />
        <LoadingIndicatorExample />
        <FloatingToolbarExample />
        <FabMenuExample />
      </main>
    </Material3Provider>
  </React.StrictMode>,
)
