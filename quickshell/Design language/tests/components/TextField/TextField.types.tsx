import { createRef } from 'react'
import { TextField } from '../../../src/components/TextField'

const inputRef = createRef<HTMLInputElement>()

;<TextField ref={inputRef} label="Full name" name="fullName" required form="signup-form" />
;<TextField label="Email" type="email" />
;<TextField
  variant="outlined"
  label="Search"
  leadingIcon={<span />}
  trailingIcon={<span />}
/>
;<TextField label="Promo code" error supportingText="This code has expired" />

// @ts-expect-error label is required
;<TextField />

// @ts-expect-error the input type is restricted to text-like values
;<TextField label="Name" type="checkbox" />

// @ts-expect-error TextField owns its own visual content
;<TextField label="Name">Content</TextField>
