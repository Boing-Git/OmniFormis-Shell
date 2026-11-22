import {
  forwardRef,
  type ElementType,
  type ForwardedRef,
  type HTMLAttributes,
  type ReactElement,
} from 'react'
import type {
  TextElement,
  TextEmphasis,
  TextProps,
  TextVariant,
} from './Text.types'

interface TextImplementationProps extends HTMLAttributes<HTMLElement> {
  readonly as?: TextElement
  readonly variant?: TextVariant
  readonly emphasis?: TextEmphasis
}

interface TextComponent {
  <TElement extends TextElement = 'span'>(props: TextProps<TElement>): ReactElement | null
  displayName?: string
}

function TextRender(
  {
    as = 'span',
    variant = 'bodyLarge',
    emphasis = 'baseline',
    className,
    ...elementProps
  }: TextImplementationProps,
  forwardedRef: ForwardedRef<HTMLElement>,
) {
  const Element = as as ElementType
  const mergedClassName = className ? `m3e-text ${className}` : 'm3e-text'

  return (
    <Element
      {...elementProps}
      ref={forwardedRef}
      className={mergedClassName}
      data-m3e-variant={variant}
      data-m3e-emphasis={emphasis}
    />
  )
}

const ForwardedText = forwardRef<HTMLElement, TextImplementationProps>(TextRender)
ForwardedText.displayName = 'Text'

export const Text = ForwardedText as TextComponent
