import {
  Children,
  forwardRef,
  type ButtonHTMLAttributes,
  type ForwardedRef,
  type ReactElement,
  type ReactNode,
} from 'react'
import { Text } from '../Text'
import type {
  ButtonProps,
  ButtonShape,
  ButtonSize,
  ButtonVariant,
  ButtonWidth,
} from './Button.types'

interface ButtonImplementationProps extends ButtonHTMLAttributes<HTMLButtonElement> {
  readonly variant?: ButtonVariant
  readonly size?: ButtonSize
  readonly width?: ButtonWidth
  readonly shape?: ButtonShape
  readonly leadingIcon?: ReactNode
  readonly trailingIcon?: ReactNode
}

interface ButtonComponent {
  (props: ButtonProps): ReactElement | null
  displayName?: string
}

const textVariantBySize = {
  'extra-small': 'labelLarge',
  small: 'labelLarge',
  medium: 'titleMedium',
  large: 'headlineSmall',
  'extra-large': 'headlineLarge',
} as const

function hasVisibleContent(children: ReactNode): boolean {
  let hasContent = false
  Children.forEach(children, (child) => {
    if (hasContent || child === null || child === undefined || typeof child === 'boolean') return
    if (typeof child === 'string') {
      hasContent = child.trim().length > 0
      return
    }
    hasContent = true
  })
  return hasContent
}

function warnForMissingName(
  children: ReactNode,
  ariaLabel: string | undefined,
  ariaLabelledBy: string | undefined,
): void {
  if (
    typeof process !== 'undefined' &&
    process.env.NODE_ENV !== 'production' &&
    !hasVisibleContent(children) &&
    !ariaLabel?.trim() &&
    !ariaLabelledBy?.trim()
  ) {
    console.warn(
      'Button: provide non-empty label content, aria-label, or aria-labelledby so the native button has an accessible name.',
    )
  }
}

function ButtonRender(
  {
    children,
    variant = 'filled',
    size = 'small',
    width = 'fit',
    shape = 'round',
    leadingIcon,
    trailingIcon,
    type = 'button',
    disabled = false,
    className,
    'aria-label': ariaLabel,
    'aria-labelledby': ariaLabelledBy,
    ...buttonProps
  }: ButtonImplementationProps,
  forwardedRef: ForwardedRef<HTMLButtonElement>,
) {
  warnForMissingName(children, ariaLabel, ariaLabelledBy)
  const mergedClassName = className ? `m3e-button ${className}` : 'm3e-button'

  return (
    <button
      {...buttonProps}
      ref={forwardedRef}
      type={type}
      disabled={disabled}
      aria-label={ariaLabel}
      aria-labelledby={ariaLabelledBy}
      className={mergedClassName}
      data-m3e-variant={variant}
      data-m3e-size={size}
      data-m3e-width={width}
      data-m3e-shape={shape}
      data-m3e-disabled={disabled}
    >
      <span className="m3e-button__container">
        {leadingIcon !== undefined && leadingIcon !== null ? (
          <span className="m3e-button__icon" data-m3e-position="leading" aria-hidden="true">
            {leadingIcon}
          </span>
        ) : null}
        <Text
          as="span"
          variant={textVariantBySize[size]}
          className="m3e-button__label"
        >
          {children}
        </Text>
        {trailingIcon !== undefined && trailingIcon !== null ? (
          <span className="m3e-button__icon" data-m3e-position="trailing" aria-hidden="true">
            {trailingIcon}
          </span>
        ) : null}
      </span>
    </button>
  )
}

const ForwardedButton = forwardRef<HTMLButtonElement, ButtonProps>(ButtonRender)
ForwardedButton.displayName = 'Button'

export const Button = ForwardedButton as ButtonComponent
