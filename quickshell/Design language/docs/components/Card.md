# Card

`Card` groups one coherent subject using current Material filled, elevated, or
outlined treatment. Its discriminated API keeps rich passive containment and
whole-card native button behavior separate.

```tsx
import { Button, Card } from '@language-lit/material3-expressive'
import '@language-lit/material3-expressive/styles.css'

<Card variant="filled">
  <h2>Course progress</h2>
  <p>Eight of twelve lessons complete.</p>
  <Button variant="text">Continue</Button>
</Card>
```

## Contract

- `variant` is `filled` (default), `elevated`, or `outlined`.
- Passive mode is the default. It renders an `article` and accepts `as="div"`,
  `section`, or `aside` when those semantics better match the document.
- Passive Card does not accept activation, focus, disabled, toggle, or form
  props. Its content may own headings, paragraphs, links, buttons, and other
  rich structure.
- `interactive` renders a native `<button type="button">`. Its button ref,
  submit/reset type, form owner, name/value, disabled state, ARIA/data
  attributes, and native handlers are preserved.
- Card owns no content padding, typography, media layout, or named slots.
  Consumers compose those through children and normal class/style props.

## Whole-card actions

Use interactive mode only when the entire card is one action:

```tsx
<Card interactive variant="elevated" onClick={openLesson}>
  <span>Open lesson</span>
  <small>12 minutes</small>
</Card>
```

A native HTML button may contain phrasing content only and cannot contain links,
buttons, inputs, focusable descendants, or rich block structure. Development
builds warn for unsafe intrinsic descendants that React can inspect. Custom
components remain the consumer's responsibility because their rendered DOM is
opaque to Card.

When a card needs headings, paragraphs, or nested actions, use passive Card and
place purpose-built controls inside it. Card deliberately does not use a
`div role="button"`, an invisible overlay link, or synthetic keyboard handlers.
Link-card navigation and routing adapters are outside this task.

## Variants and state

| Variant | Container | Rest / focus / press | Hover | Outline |
| --- | --- | ---: | ---: | --- |
| `filled` | surface-container-highest | Level 0 | Level 1 | none |
| `elevated` | surface-container-low | Level 1 | Level 2 | none |
| `outlined` | surface | Level 0 | Level 1 | outline-variant, 1px |

All variants use the medium corner and on-surface content. Outlined focus uses
on-surface for its border. Interactive cards add Material hover, focus, and
pressed state layers and reserve the theme's 48px minimum target. Disabled
colors, outlines, and elevation follow the pinned first-party token files.
Passive cards have no disabled state because they remain ordinary content.

Current AndroidX has no separate Expressive Card overload or Expressive card
size/shape morph. This implementation therefore keeps current Card geometry and
uses the theme's Expressive default-effects projection for container, border,
and shadow transitions plus fast-effects for the state layer. Reduced motion
makes those changes immediate.

## Accessibility

The selected passive element owns document semantics; Card adds no role or tab
stop. Interactive mode relies on native button naming, pointer, Enter, Space,
focus, form, and disabled behavior. It does not expose `aria-pressed`, selected,
checked, or draggable state.

`:focus-visible` uses a token-backed secondary focus ring. Forced-colors mode
uses Canvas/CanvasText, Highlight focus, GrayText disabled treatment, and an
explicit border while removing translucent state layers and authored shadows.
Logical sizing and `text-align: start` follow RTL without DOM reordering.

## Tokens and boundaries

Card registers searchable `--m3e-comp-card-*` variables for:

- minimum target, medium shape, focus ring, and disabled content;
- filled/elevated/outlined container and content colors;
- resting, hover, focus, pressed, and disabled shadows;
- outlined normal/hover/focus/pressed/disabled borders;
- variant-specific disabled container composition.

Theme overrides remain scoped to `Material3Provider`; Card injects no runtime
styles. It imports no Next.js, Vite, router, animation library,
or private application code.
