# TextArea

`TextArea` is a native `textarea` sharing every part of `TextField`'s field
chrome — label, indicator/outline, icon slots, supporting/error text — since
the pinned source itself has no distinct multiline composable: multiline is
`TextField`/`OutlinedTextField` with `singleLine=false`, reusing the exact
same decoration layer. `TextArea` mirrors that on the web instead of
duplicating a second component tree.

```tsx
import { TextArea } from '@language-lit/material3-expressive'
import '@language-lit/material3-expressive/styles.css'

<TextArea
  label="Feedback"
  rows={4}
  value={feedback}
  onChange={(event) => setFeedback(event.currentTarget.value)}
  supportingText="Tell us what worked and what didn't"
/>
```

## Contract

Identical to `TextField`'s contract (see `TextField.md`), substituting a
native `textarea` for the native `input`. There is no `type` prop — native
`textarea` has none — and every other native `textarea` attribute (`rows`,
`cols`, `wrap`, `maxLength`, …) forwards directly. Native vertical resize
(`resize: vertical`) is kept as a deliberate web affordance. `rows` determines
the native content-row height; the shared field grid adds the Material top and
bottom regions and keeps the complete container at its 56px minimum.
Auto-growing height is out of scope.

## Multiline layout

An empty resting label starts at the ordinary 16px top padding instead of
centering across all rows. Leading/trailing icon slots remain vertically
centered across the container. Both choices follow the pinned measure
policy's explicit multiline-label branch and shared icon placement. On the
inline axis, the native textarea occupies the same middle content region as
TextField: 16px is reserved at an ordinary edge and 52px at an icon edge, so
native textarea padding resets cannot place its caret beneath an icon.
The same grid owns the block axis: filled textarea content starts after the
24px label region and leaves 8px below, while outlined content has 16px above
and below. A downstream `textarea { padding: 0 }` reset therefore changes
neither the first content line nor the label relationship. `rows` and native
vertical resizing grow the middle content row rather than either edge region.

## Variants, states, and accessibility

`variant="filled"` and `variant="outlined"` use the same state and color
contract as `TextField`. Empty, populated, focused, disabled, required, invalid,
and error presentation follows the native textarea plus the shared field chrome.
Controlled and uncontrolled values, form submission/reset, selection, browser
spellcheck, and keyboard editing remain native behavior.

Provide a visible `label`. Supporting and error text are connected to the native
textarea through the same generated description relationships as `TextField`.
Focus indication remains visible in forced-colors mode, and label placement does
not depend on animation under reduced motion.

## Tokens and boundaries

`TextArea` consumes the exact same `--m3e-comp-text-field-*` registration as
`TextField` — there is no separate `text-area` token set, matching the
pinned source having no separate tokens for multiline.

Theme overrides remain scoped to `Material3Provider`; `TextArea` injects no
runtime styles. It imports no Next.js, Vite, router, animation
library, or private application code.
