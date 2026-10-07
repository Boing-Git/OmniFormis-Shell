import { createRef } from 'react'
import { TextArea } from '../../../src/components/TextArea'

const controlRef = createRef<HTMLTextAreaElement>()

;<TextArea ref={controlRef} label="Notes" name="notes" rows={4} required form="review-form" />
;<TextArea variant="outlined" label="Feedback" leadingIcon={<span />} />
;<TextArea label="Notes" error supportingText="Required" />

// @ts-expect-error label is required
;<TextArea />

// @ts-expect-error TextArea owns its own visual content
;<TextArea label="Notes">Content</TextArea>
