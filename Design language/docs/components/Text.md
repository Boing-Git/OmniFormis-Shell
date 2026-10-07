# Text

`Text` applies the complete Material 3 type scale to an explicitly selected
native HTML element. Visual typography and document semantics are independent.

```tsx
import { Text } from '@language-lit/material3-expressive'
import '@language-lit/material3-expressive/styles.css'

<Text as="h1" variant="displayLarge" emphasis="emphasized">
  Account
</Text>
<Text as="p" variant="bodyLarge">
  The heading level comes from `as`; the visual scale comes from `variant`.
</Text>
```

## Contract

- `as` defaults to `span`. It accepts `span`, `p`, `div`, `h1`–`h6`, `label`,
  `legend`, `strong`, `em`, `small`, `blockquote`, or `figcaption`.
- `variant` defaults to `bodyLarge` and accepts every Material display,
  headline, title, body, and label size: `Large`, `Medium`, and `Small`.
- `emphasis` defaults to `baseline`. `emphasized` selects the current Material 3
  Expressive counterpart of the same role.
- Native attributes, ARIA/data attributes, styles, classes, handlers, children,
  and a correctly narrowed ref are forwarded to the selected element.
- Text removes the selected element's user-agent margin so the same visual role
  has predictable component layout. It does not change its native display mode.

`variant="displayLarge"` does not create a heading. Choose `as="h1"` through
`as="h6"` from the page's actual document structure. Conversely, a real heading
may use a smaller visual role without losing its heading level.

## Expressive type scale

The 15 roles are:

- `displayLarge`, `displayMedium`, `displaySmall`
- `headlineLarge`, `headlineMedium`, `headlineSmall`
- `titleLarge`, `titleMedium`, `titleSmall`
- `bodyLarge`, `bodyMedium`, `bodySmall`
- `labelLarge`, `labelMedium`, `labelSmall`

Every role has baseline and emphasized styling. The emphasized scale is not a
generic bold switch: it is a separately themeable Material scale. A theme may
change its family, weight, size, line height, tracking, or variable axes without
changing the baseline counterpart.

## Typography tokens and fonts

Text resolves the selected role directly through
`--m3e-sys-typescale-{emphasis}-{kebab-role}-*` variables for font family, weight,
size, line height, letter spacing, and the `CRSV`, `FILL`, `GRAD`, `HEXP`,
`ROND`, `opsz`, `slnt`, `wdth`, and `wght` axes. There are no Text component
tokens because first-party Text consumes the system type scale and inherited
content color directly.

Rendering Text never downloads or injects a font. Applications own their font
files and `@font-face` declarations, then set `theme.reference.typeface.brand`
and `.plain`. A font ignores variable axes it does not support; use a capable
variable font to realize the full configured axis treatment.

Text inherits `color` from its surroundings. A `Surface` supplies the matching
Material content color, while ordinary consumer CSS can override color and
other presentation when a deliberate exception is needed.

## Accessibility and adaptation

Text adds no role, focus stop, keyboard behavior, accessible state, or
interaction. Native headings, labels, legends, and text-level semantics remain
authoritative. Use `label` only with a valid form-control relationship, and keep
heading levels structurally correct regardless of visual role.

The component has no motion, physical-direction layout, breakpoint, or forced-
color override. Browser text scaling, writing direction, forced colors, and
consumer responsive CSS remain active. Automatic text fitting and truncation are
layout policies rather than Expressive type roles and are outside this
foundation API.
