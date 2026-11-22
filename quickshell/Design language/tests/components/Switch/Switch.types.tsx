import { createRef } from 'react'
import { Switch } from '../../../src/components/Switch'

const inputRef = createRef<HTMLInputElement>()

;<Switch ref={inputRef} name="notifications" value="on" required form="settings-form" />
;<Switch defaultChecked thumbIcon={<span />} onCheckedChange={() => undefined} />
;<Switch checked onCheckedChange={() => undefined} />

// @ts-expect-error a controlled switch must report its changes
;<Switch checked />

// @ts-expect-error controlled and uncontrolled state cannot be combined
;<Switch checked defaultChecked onCheckedChange={() => undefined} />

// @ts-expect-error Switch owns its own visual content
;<Switch>Label</Switch>

// @ts-expect-error the input type is fixed
;<Switch type="radio" />

// @ts-expect-error the accessible role is fixed
;<Switch role="checkbox" />
