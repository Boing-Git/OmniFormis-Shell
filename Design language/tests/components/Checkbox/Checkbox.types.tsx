import { createRef } from 'react'
import { Checkbox } from '../../../src/components/Checkbox'

const inputRef = createRef<HTMLInputElement>()

;<Checkbox ref={inputRef} name="terms" value="accepted" required form="signup-form" />
;<Checkbox defaultChecked indeterminate onCheckedChange={() => undefined} />
;<Checkbox checked onCheckedChange={() => undefined} />

// @ts-expect-error a controlled checkbox must report its changes
;<Checkbox checked />

// @ts-expect-error controlled and uncontrolled state cannot be combined
;<Checkbox checked defaultChecked onCheckedChange={() => undefined} />

// @ts-expect-error Checkbox owns its own visual content
;<Checkbox>Label</Checkbox>

// @ts-expect-error the input type is fixed
;<Checkbox type="radio" />
