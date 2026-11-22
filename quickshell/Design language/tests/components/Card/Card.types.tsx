import { createRef } from 'react'
import { Card } from '../../../src/components/Card'

const sectionRef = createRef<HTMLElementTagNameMap['section']>()
const buttonRef = createRef<HTMLButtonElement>()

;<Card as="section" ref={sectionRef}>Passive</Card>
;<Card interactive ref={buttonRef} type="submit" form="example-form">Interactive</Card>

// @ts-expect-error passive cards do not accept disabled button state
;<Card disabled>Invalid passive state</Card>

// @ts-expect-error passive cards do not accept activation handlers
;<Card onClick={() => undefined}>Invalid passive action</Card>

// @ts-expect-error interactive cards always render a button and cannot select `as`
;<Card interactive as="section">Invalid interactive element</Card>

// @ts-expect-error Card does not expose selected state
;<Card interactive selected>Invalid selected state</Card>
