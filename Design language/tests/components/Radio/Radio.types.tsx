import { createRef } from 'react'
import { Radio } from '../../../src/components/Radio'

const inputRef = createRef<HTMLInputElement>()

;<Radio ref={inputRef} name="plan" value="pro" required form="checkout-form" />
;<Radio name="plan" defaultChecked onCheckedChange={() => undefined} />
;<Radio name="plan" checked onCheckedChange={() => undefined} />

// @ts-expect-error name is required so grouping is always possible
;<Radio />

// @ts-expect-error a controlled radio must report its changes
;<Radio name="plan" checked />

// @ts-expect-error controlled and uncontrolled state cannot be combined
;<Radio name="plan" checked defaultChecked onCheckedChange={() => undefined} />

// @ts-expect-error Radio owns its own visual content
;<Radio name="plan">Label</Radio>

// @ts-expect-error the input type is fixed
;<Radio name="plan" type="checkbox" />
