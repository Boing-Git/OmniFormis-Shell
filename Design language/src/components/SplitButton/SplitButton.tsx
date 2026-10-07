import { forwardRef, type CSSProperties, type ForwardedRef, type ReactElement } from 'react'
import { useControllableState } from '../../internal/useControllableState'
import { Text } from '../Text'
import type { SplitButtonProps } from './SplitButton.types'

interface SplitButtonComponent {
  (props: SplitButtonProps): ReactElement | null
  displayName?: string
}

const textVariantBySize = {
  'extra-small': 'labelLarge',
  small: 'labelLarge',
  medium: 'titleMedium',
  large: 'headlineSmall',
  'extra-large': 'headlineLarge',
} as const

function SplitButtonRender(
  {
    children,
    variant = 'filled',
    size = 'small',
    leadingIcon,
    onClick,
    trailingIcon,
    trailingLabel,
    selected,
    defaultSelected,
    onSelectedChange,
    disabled = false,
    className,
    style,
    ...divProps
  }: SplitButtonProps,
  forwardedRef: ForwardedRef<HTMLDivElement>,
) {
  const [resolvedSelected, setSelected] = useControllableState({
    value: selected,
    defaultValue: defaultSelected ?? false,
    onChange: onSelectedChange,
  })

  return (
    <div
      {...divProps}
      ref={forwardedRef}
      role="group"
      className={className ? `m3e-split-button ${className}` : 'm3e-split-button'}
      style={style as CSSProperties}
      data-m3e-variant={variant}
      data-m3e-size={size}
    >
      <button
        type="button"
        className="m3e-split-button__leading"
        onClick={onClick}
        disabled={disabled}
      >
        {leadingIcon !== undefined && leadingIcon !== null ? (
          <span className="m3e-split-button__icon" aria-hidden="true">
            {leadingIcon}
          </span>
        ) : null}
        <Text as="span" variant={textVariantBySize[size]} className="m3e-split-button__label">
          {children}
        </Text>
      </button>
      <button
        type="button"
        className="m3e-split-button__trailing"
        aria-label={trailingLabel}
        aria-pressed={resolvedSelected}
        onClick={() => setSelected(!resolvedSelected)}
        disabled={disabled}
        data-m3e-selected={resolvedSelected}
      >
        <span className="m3e-split-button__icon" aria-hidden="true">
          {trailingIcon}
        </span>
      </button>
    </div>
  )
}

const ForwardedSplitButton = forwardRef<HTMLDivElement, SplitButtonProps>(SplitButtonRender)
ForwardedSplitButton.displayName = 'SplitButton'

export const SplitButton = ForwardedSplitButton as SplitButtonComponent
