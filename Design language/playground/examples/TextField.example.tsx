import { useState } from 'react'
import { Icon, Surface, Text, TextField } from '@language-lit/material3-expressive'

export function TextFieldExample() {
  const [name, setName] = useState('')
  const [email, setEmail] = useState('ada@example.com')
  const [query, setQuery] = useState('')

  return (
    <Surface
      as="section"
      aria-labelledby="text-field-example-title"
      color="surface-container-low"
      shape="extra-large"
      className="text-field-example"
    >
      <Text as="h2" id="text-field-example-title" variant="titleLarge" emphasis="emphasized">
        Text fields
      </Text>
      <Text as="p" variant="bodyMedium">
        Native inputs with a floating label driven by true focus and value
        state, in both the filled and outlined variants.
      </Text>

      <div className="text-field-example__row">
        <TextField
          label="Full name"
          value={name}
          onChange={(event) => setName(event.currentTarget.value)}
          supportingText="As it appears on your ticket"
        />
        <TextField
          variant="outlined"
          label="Email"
          type="email"
          value={email}
          onChange={(event) => setEmail(event.currentTarget.value)}
          leadingIcon={<Icon source="mail" />}
        />
      </div>

      <div className="text-field-example__row">
        <TextField
          variant="outlined"
          label="Search"
          type="search"
          value={query}
          onChange={(event) => setQuery(event.currentTarget.value)}
          trailingIcon={<Icon source="search" />}
        />
        <TextField
          label="Promo code"
          error
          defaultValue="EXPIRED10"
          supportingText="This code has expired"
        />
      </div>

      <div className="text-field-example__row">
        <TextField label="Unavailable" disabled defaultValue="Locked" />
        <TextField variant="outlined" label="Unavailable" disabled placeholder="Locked" />
      </div>

      <div className="text-field-example__row">
        <TextField
          label="Password"
          type="password"
          leadingIcon={<Icon source="lock" />}
          defaultValue="hunter2"
        />
        <TextField label="Phone" type="tel" placeholder="(555) 123-4567" />
        <TextField variant="outlined" label="Website" type="url" placeholder="https://example.com" />
        <TextField label="Quantity" type="number" defaultValue="1" />
      </div>

      <div className="text-field-example__row">
        <TextField
          variant="outlined"
          label="Coupon"
          error
          defaultValue="EXPIRED10"
          supportingText="This code has expired"
        />
        <TextField
          variant="outlined"
          label="Card number"
          error
          leadingIcon={<Icon source="credit_card" />}
          defaultValue="4111 1111 1111 1111"
          supportingText="This card was declined"
        />
        <TextField
          label="Locked field"
          disabled
          error
          defaultValue="Invalid"
          supportingText="Contact support"
        />
      </div>
    </Surface>
  )
}
