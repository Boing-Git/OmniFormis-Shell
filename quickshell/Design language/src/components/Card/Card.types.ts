import type { ComponentPropsWithRef, ReactNode } from 'react'

/** Current Material Card emphasis variants. */
export type CardVariant = 'filled' | 'elevated' | 'outlined'

/** Passive elements that can validly own a Card container. */
export type CardElement = 'article' | 'div' | 'section' | 'aside'

interface CardOwnProps {
  /** Generic consumer-owned card content. Card does not impose content slots or padding. */
  readonly children?: ReactNode
  /** Material filled, elevated, or outlined visual treatment. */
  readonly variant?: CardVariant
}

type CardElementProp<TElement extends CardElement> = TElement extends 'article'
  ? { readonly as?: TElement }
  : { readonly as: TElement }

type PassiveCardInteractionProps = {
  readonly interactive?: false
  readonly disabled?: never
  readonly type?: never
  readonly onClick?: never
  readonly onDoubleClick?: never
  readonly onKeyDown?: never
  readonly onKeyUp?: never
  readonly onKeyPress?: never
  readonly tabIndex?: never
  readonly autoFocus?: never
  readonly 'aria-pressed'?: never
}

export type PassiveCardProps<TElement extends CardElement = 'article'> =
  CardOwnProps &
    CardElementProp<TElement> &
    PassiveCardInteractionProps &
    Omit<
      ComponentPropsWithRef<TElement>,
      | keyof CardOwnProps
      | keyof PassiveCardInteractionProps
      | 'as'
      | 'children'
    >

export type InteractiveCardProps = CardOwnProps &
  {
    /** Render a whole-card native button. Its descendants must be non-interactive phrasing content. */
    readonly interactive: true
    readonly as?: never
  } &
  Omit<ComponentPropsWithRef<'button'>, keyof CardOwnProps | 'aria-pressed' | 'as' | 'children'>

/**
 * Props for a Material Card. Passive cards accept bounded container semantics;
 * `interactive` cards use a native button and its corresponding native props.
 */
export type CardProps<TElement extends CardElement = 'article'> =
  | PassiveCardProps<TElement>
  | InteractiveCardProps
