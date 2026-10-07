import { useState } from 'react'
import {
  Button,
  FloatingActionButton,
  Icon,
  Surface,
  Text,
  type FloatingActionButtonElevation,
  type FloatingActionButtonSize,
} from '@language-lit/material3-expressive'

const sizes: readonly FloatingActionButtonSize[] = ['standard', 'medium', 'large']
const elevations: readonly FloatingActionButtonElevation[] = ['default', 'lowered', 'none']

export function FloatingActionButtonExample() {
  const [actionsOpen, setActionsOpen] = useState(false)
  const [extended, setExtended] = useState(true)

  return (
    <Surface
      as="section"
      aria-labelledby="fab-example-title"
      color="surface-container-low"
      shape="extra-large"
      className="fab-example"
    >
      <Text as="h2" id="fab-example-title" variant="titleLarge" emphasis="emphasized">
        Expressive floating action buttons
      </Text>
      <Text as="p" variant="bodyMedium">
        Native promoted actions with size-aware extension, elevation, and toggle motion.
      </Text>
      <div className="fab-example__row" aria-label="Floating action button sizes">
        {sizes.map((size) => (
          <FloatingActionButton
            key={size}
            aria-label={`${size} create`}
            icon={<Icon source="add" />}
            size={size}
          />
        ))}
      </div>
      <div className="fab-example__row" aria-label="Extended floating action buttons">
        {sizes.map((size) => (
          <FloatingActionButton
            key={size}
            icon={<Icon source="edit" />}
            label={`${size} compose`}
            size={size}
            expanded={extended}
            elevation={size === 'medium' ? 'lowered' : 'default'}
          />
        ))}
      </div>
      <div className="fab-example__row" aria-label="Floating action button elevations">
        {elevations.map((elevation) => (
          <FloatingActionButton
            key={elevation}
            aria-label={`${elevation} elevation create`}
            icon={<Icon source="add" />}
            elevation={elevation}
          />
        ))}
      </div>
      <FloatingActionButton
        icon={<Icon source="edit" />}
        label="Statically collapsed compose"
        expanded={false}
      />
      <div className="fab-example__row" aria-label="Toggle floating action button sizes">
        {sizes.map((size) => (
          <FloatingActionButton
            key={size}
            aria-label={`${size} toggle bookmark`}
            icon={<Icon source="bookmark" />}
            selectedIcon={<Icon source="bookmark" fill={1} />}
            size={size}
            toggle
            defaultSelected={size !== 'standard'}
          />
        ))}
      </div>
      <div className="fab-example__row">
        <FloatingActionButton
          aria-label="Creation actions"
          icon={<Icon source="add" />}
          selectedIcon={<Icon source="close" />}
          size="large"
          toggle
          selected={actionsOpen}
          onSelectedChange={setActionsOpen}
        />
        <Button variant="text" onClick={() => setExtended((value) => !value)}>
          {extended ? 'Collapse' : 'Expand'} labels
        </Button>
        <FloatingActionButton
          aria-label="Unavailable"
          icon={<Icon source="block" />}
          disabled
        />
        <FloatingActionButton
          icon={<Icon source="edit" />}
          label="Disabled compose"
          size="large"
          disabled
        />
        <FloatingActionButton
          aria-label="Disabled toggle bookmark"
          icon={<Icon source="bookmark" />}
          selectedIcon={<Icon source="bookmark" fill={1} />}
          size="medium"
          toggle
          defaultSelected
          disabled
        />
      </div>
    </Surface>
  )
}
