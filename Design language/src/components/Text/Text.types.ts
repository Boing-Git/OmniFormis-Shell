import type { ComponentPropsWithRef, ReactNode } from 'react'
import type { TypographyEmphasis, TypographyRoleName } from '../../tokens'

/**
 * Bounded native text elements. Interactive elements are intentionally absent;
 * links and controls keep their own purpose-built contracts.
 */
export const TEXT_ELEMENTS = [
  'span',
  'p',
  'div',
  'h1',
  'h2',
  'h3',
  'h4',
  'h5',
  'h6',
  'label',
  'legend',
  'strong',
  'em',
  'small',
  'blockquote',
  'figcaption',
] as const

export type TextElement = (typeof TEXT_ELEMENTS)[number]
export type TextVariant = TypographyRoleName
export type TextEmphasis = TypographyEmphasis

interface TextOwnProps {
  readonly children?: ReactNode
  /** Material type-scale role. This never determines the rendered element. */
  readonly variant?: TextVariant
  /** Baseline or Material 3 Expressive emphasized counterpart of the role. */
  readonly emphasis?: TextEmphasis
}

type TextElementProp<TElement extends TextElement> = TElement extends 'span'
  ? { readonly as?: TElement }
  : { readonly as: TElement }

/**
 * Props for theme-backed Material text. The generic element narrows native
 * attributes and the forwarded ref independently from the visual type role.
 */
export type TextProps<TElement extends TextElement = 'span'> = TextOwnProps &
  TextElementProp<TElement> &
  Omit<ComponentPropsWithRef<TElement>, keyof TextOwnProps | 'as'>
