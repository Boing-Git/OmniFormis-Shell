import { useState } from 'react'
import {
  Icon,
  Surface,
  Switch,
  Text,
} from '@language-lit/material3-expressive'

export function SwitchExample() {
  const [notifications, setNotifications] = useState(true)
  const [wifi, setWifi] = useState(false)

  return (
    <Surface
      as="section"
      aria-labelledby="switch-example-title"
      color="surface-container-low"
      shape="extra-large"
      className="switch-example"
    >
      <Text as="h2" id="switch-example-title" variant="titleLarge" emphasis="emphasized">
        Switches
      </Text>
      <Text as="p" variant="bodyMedium">
        A native, role-mapped control with pressed-shape motion and an
        optional thumb icon.
      </Text>

      <div className="switch-example__group">
        <label className="switch-example__row">
          <Switch checked={notifications} onCheckedChange={setNotifications} />
          <Text as="span" variant="bodyLarge">
            Notifications
          </Text>
        </label>
        <label className="switch-example__row">
          <Switch
            checked={wifi}
            onCheckedChange={setWifi}
            thumbIcon={<Icon source={wifi ? 'check' : 'close'} />}
          />
          <Text as="span" variant="bodyLarge">
            Wi-Fi
          </Text>
        </label>
        <label className="switch-example__row">
          <Switch defaultChecked thumbIcon={<Icon source="check" />} />
          <Text as="span" variant="bodyLarge">
            Do not disturb
          </Text>
        </label>
      </div>

      <div className="switch-example__group">
        <label className="switch-example__row">
          <Switch disabled />
          <Text as="span" variant="bodyLarge">
            Unavailable
          </Text>
        </label>
        <label className="switch-example__row">
          <Switch disabled defaultChecked />
          <Text as="span" variant="bodyLarge">
            Unavailable and on
          </Text>
        </label>
        <label className="switch-example__row">
          <Switch disabled defaultChecked thumbIcon={<Icon source="check" />} />
          <Text as="span" variant="bodyLarge">
            Unavailable and on, with icon
          </Text>
        </label>
      </div>
    </Surface>
  )
}
