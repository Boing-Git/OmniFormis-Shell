import {
  Children,
  Fragment,
  forwardRef,
  isValidElement,
  type ButtonHTMLAttributes,
  type ElementType,
  type ForwardedRef,
  type HTMLAttributes,
  type KeyboardEventHandler,
  type MouseEventHandler,
  type ReactElement,
  type ReactNode,
} from 'react'
import type {
  CardElement,
  CardVariant,
  InteractiveCardProps,
  PassiveCardProps,
} from './Card.types'

interface CardImplementationProps
  extends Omit<ButtonHTMLAttributes<HTMLButtonElement>, 'aria-pressed'> {
  readonly as?: CardElement
  readonly interactive?: boolean
  readonly variant?: CardVariant
  readonly 'aria-pressed'?: boolean | 'false' | 'true' | 'mixed'
}

interface CardComponent {
  (props: InteractiveCardProps): ReactElement | null
  <TElement extends CardElement = 'article'>(
    props: PassiveCardProps<TElement>,
  ): ReactElement | null
  displayName?: string
}

const UNSAFE_BUTTON_DESCENDANTS = new Set([
  'button',
  'details',
  'embed',
  'iframe',
  'input',
  'label',
  'select',
  'summary',
  'textarea',
])

const NON_PHRASING_ELEMENTS = new Set([
  'address',
  'article',
  'aside',
  'blockquote',
  'div',
  'dl',
  'fieldset',
  'figcaption',
  'figure',
  'footer',
  'form',
  'h1',
  'h2',
  'h3',
  'h4',
  'h5',
  'h6',
  'header',
  'hgroup',
  'hr',
  'main',
  'nav',
  'ol',
  'p',
  'pre',
  'section',
  'table',
  'ul',
])

function warn(message: string): void {
  if (typeof process !== 'undefined' && process.env.NODE_ENV !== 'production') {
    console.warn(`Card: ${message}`)
  }
}

function hasUnsafeButtonContent(children: ReactNode): boolean {
  let unsafe = false

  Children.forEach(children, (child) => {
    if (unsafe || !isValidElement(child)) return

    if (child.type === Fragment) {
      const props = child.props as { readonly children?: ReactNode }
      unsafe = hasUnsafeButtonContent(props.children)
      return
    }

    if (typeof child.type !== 'string') return

    const props = child.props as {
      readonly children?: ReactNode
      readonly contentEditable?: boolean | 'false' | 'true'
      readonly controls?: boolean
      readonly href?: string
      readonly tabIndex?: number
      readonly useMap?: string
    }
    unsafe =
      UNSAFE_BUTTON_DESCENDANTS.has(child.type) ||
      NON_PHRASING_ELEMENTS.has(child.type) ||
      (child.type === 'a' && props.href !== undefined) ||
      ((child.type === 'audio' || child.type === 'video') && props.controls === true) ||
      ((child.type === 'img' || child.type === 'object') && props.useMap !== undefined) ||
      props.tabIndex !== undefined ||
      (props.contentEditable !== undefined &&
        props.contentEditable !== false &&
        props.contentEditable !== 'false')

    if (!unsafe) unsafe = hasUnsafeButtonContent(props.children)
  })

  return unsafe
}

function warnForInvalidProps({
  as,
  interactive,
  disabled,
  type,
  onClick,
  onDoubleClick,
  onKeyDown,
  onKeyUp,
  onKeyPress,
  tabIndex,
  autoFocus,
  ariaPressed,
  children,
}: {
  readonly as: CardElement | undefined
  readonly interactive: boolean
  readonly disabled: boolean | undefined
  readonly type: ButtonHTMLAttributes<HTMLButtonElement>['type']
  readonly onClick: MouseEventHandler<HTMLButtonElement> | undefined
  readonly onDoubleClick: MouseEventHandler<HTMLButtonElement> | undefined
  readonly onKeyDown: KeyboardEventHandler<HTMLButtonElement> | undefined
  readonly onKeyUp: KeyboardEventHandler<HTMLButtonElement> | undefined
  readonly onKeyPress: KeyboardEventHandler<HTMLButtonElement> | undefined
  readonly tabIndex: number | undefined
  readonly autoFocus: boolean | undefined
  readonly ariaPressed: boolean | 'false' | 'true' | 'mixed' | undefined
  readonly children: ReactNode
}): void {
  if (interactive && as !== undefined) {
    warn('interactive cards always render a native button; remove the `as` prop.')
  }
  if (
    !interactive &&
    (disabled !== undefined ||
      type !== undefined ||
      onClick !== undefined ||
      onDoubleClick !== undefined ||
      onKeyDown !== undefined ||
      onKeyUp !== undefined ||
      onKeyPress !== undefined ||
      tabIndex !== undefined ||
      autoFocus !== undefined)
  ) {
    warn(
      'button, focus, and activation props require interactive={true}; passive cards discard them.',
    )
  }
  if (ariaPressed !== undefined) {
    warn(
      'Card does not own toggle state; remove aria-pressed and use a dedicated selection control.',
    )
  }
  if (interactive && hasUnsafeButtonContent(children)) {
    warn(
      'interactive card children must be phrasing content without links, controls, focusable descendants, or block elements. Use a passive Card when content owns nested actions or rich structure.',
    )
  }
}

function CardRender(
  {
    as,
    interactive = false,
    variant = 'filled',
    children,
    className,
    disabled,
    type,
    onClick,
    onDoubleClick,
    onKeyDown,
    onKeyUp,
    onKeyPress,
    tabIndex,
    autoFocus,
    'aria-pressed': ariaPressed,
    ...elementProps
  }: CardImplementationProps,
  forwardedRef: ForwardedRef<HTMLElement>,
) {
  warnForInvalidProps({
    as,
    interactive,
    disabled,
    type,
    onClick,
    onDoubleClick,
    onKeyDown,
    onKeyUp,
    onKeyPress,
    tabIndex,
    autoFocus,
    ariaPressed,
    children,
  })

  const mergedClassName = className ? `m3e-card ${className}` : 'm3e-card'
  const content = <span className="m3e-card__content">{children}</span>

  if (interactive) {
    return (
      <button
        {...elementProps}
        ref={forwardedRef as ForwardedRef<HTMLButtonElement>}
        type={type ?? 'button'}
        disabled={disabled ?? false}
        className={mergedClassName}
        onClick={onClick}
        onDoubleClick={onDoubleClick}
        onKeyDown={onKeyDown}
        onKeyUp={onKeyUp}
        onKeyPress={onKeyPress}
        tabIndex={tabIndex}
        autoFocus={autoFocus}
        data-m3e-variant={variant}
        data-m3e-interactive="true"
        data-m3e-disabled={disabled ?? false}
      >
        {content}
      </button>
    )
  }

  const Element = (as ?? 'article') as ElementType
  return (
    <Element
      {...(elementProps as HTMLAttributes<HTMLElement>)}
      ref={forwardedRef}
      className={mergedClassName}
      data-m3e-variant={variant}
      data-m3e-interactive="false"
    >
      <div className="m3e-card__content">{children}</div>
    </Element>
  )
}

const ForwardedCard = forwardRef<HTMLElement, CardImplementationProps>(CardRender)
ForwardedCard.displayName = 'Card'

export const Card = ForwardedCard as CardComponent
