import {
  Icon,
  Material3Provider,
  Surface,
  Text,
} from '@language-lit/material3-expressive'
import { createTheme } from '@language-lit/material3-expressive/theme'
import { ClientSmoke } from './client-smoke'

const serverTheme = createTheme({ density: { scale: -1 } })

export default function Page() {
  return (
    <Material3Provider theme={serverTheme} colorMode="system" systemModeFallback="light">
      <Surface as="main" color="surface" tonalElevation={0}>
        <Text as="h1" variant="displaySmall" emphasis="emphasized">
          <Icon
            source="verified"
            decorative={false}
            label="Verified"
            roundness={100}
          />{' '}
          Material 3 Expressive React v1 SSR fixture
        </Text>
        <ClientSmoke />
      </Surface>
    </Material3Provider>
  )
}
