import { useState } from 'react'
import {
  Button,
  Card,
  Surface,
  Text,
  type CardVariant,
} from '@language-lit/material3-expressive'

const variants: readonly CardVariant[] = ['filled', 'elevated', 'outlined']

export function CardExample() {
  const [openedCard, setOpenedCard] = useState('none')

  return (
    <Surface
      as="section"
      aria-labelledby="card-example-title"
      color="surface-container-low"
      shape="extra-large"
      className="card-example"
    >
      <Text as="h2" id="card-example-title" variant="titleLarge" emphasis="emphasized">
        Material cards
      </Text>
      <Text as="p" variant="bodyMedium">
        Passive rich containers and native whole-card actions share sourced variants.
      </Text>
      <div className="card-example__grid">
        {variants.map((variant) => (
          <Card key={variant} variant={variant} className="card-example__item">
            <Text as="h3" variant="titleMedium" emphasis="emphasized">
              {variant} information
            </Text>
            <Text as="p" variant="bodyMedium">
              Rich passive content may contain its own structure and actions.
            </Text>
            <Button variant="text" size="extra-small">
              Card action
            </Button>
          </Card>
        ))}
      </div>
      <Text as="h3" variant="titleMedium" emphasis="emphasized">
        Passive card elements
      </Text>
      <div className="card-example__grid">
        <Card as="div" variant="filled" className="card-example__item">
          <Text as="h4" variant="titleSmall" emphasis="emphasized">
            div card
          </Text>
          <Text as="p" variant="bodyMedium">
            Passive card rendered as a native div.
          </Text>
        </Card>
        <Card as="section" variant="elevated" className="card-example__item">
          <Text as="h4" variant="titleSmall" emphasis="emphasized">
            section card
          </Text>
          <Text as="p" variant="bodyMedium">
            Passive card rendered as a native section.
          </Text>
        </Card>
        <Card as="aside" variant="outlined" className="card-example__item">
          <Text as="h4" variant="titleSmall" emphasis="emphasized">
            aside card
          </Text>
          <Text as="p" variant="bodyMedium">
            Passive card rendered as a native aside.
          </Text>
        </Card>
      </div>
      <div className="card-example__grid">
        {variants.map((variant) => (
          <Card
            key={variant}
            interactive
            variant={variant}
            className="card-example__item"
            onClick={() => setOpenedCard(variant)}
          >
            <Text as="span" variant="titleMedium" emphasis="emphasized">
              Open {variant} card
            </Text>
            <Text as="small" variant="bodySmall">
              Native button behavior
            </Text>
          </Card>
        ))}
        {variants.map((variant) => (
          <Card
            key={`disabled-${variant}`}
            interactive
            disabled
            variant={variant}
            className="card-example__item"
          >
            Unavailable {variant} card
          </Card>
        ))}
      </div>
      <Text as="span" role="status" variant="bodySmall" aria-live="polite">
        Last opened: {openedCard}
      </Text>
    </Surface>
  )
}
