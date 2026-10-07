import {
  forwardRef,
  type ButtonHTMLAttributes,
  type ForwardedRef,
  type MouseEvent,
  type ReactElement,
  type ReactNode,
} from 'react'
import { composeEventHandlers } from '../../internal/composeEventHandlers'
import { useControllableState } from '../../internal/useControllableState'
import type {
  IconButtonProps,
  IconButtonShape,
  IconButtonSize,
  IconButtonVariant,
  IconButtonWidth,
} from './IconButton.types'

interface IconButtonImplementationProps
  extends Omit<ButtonHTMLAttributes<HTMLButtonElement>, 'aria-pressed' | 'children'> {
  readonly children: ReactNode
  readonly variant?: IconButtonVariant
  readonly size?: IconButtonSize
  readonly width?: IconButtonWidth
  readonly shape?: IconButtonShape
  readonly toggle?: boolean
  readonly selected?: boolean
  readonly defaultSelected?: boolean
  readonly onSelectedChange?: (selected: boolean) => void
  readonly selectedIcon?: ReactNode
}

interface IconButtonComponent {
  (props: IconButtonProps): ReactElement | null
  displayName?: string
}

function warn(message: string): void {
  if (typeof process !== 'undefined' && process.env.NODE_ENV !== 'production') {
    console.warn(`IconButton: ${message}`)
  }
}

function warnForInvalidProps({
  toggle,
  selected,
  defaultSelected,
  onSelectedChange,
  selectedIcon,
  ariaLabel,
  ariaLabelledBy,
}: {
  readonly toggle: boolean
  readonly selected: boolean | undefined
  readonly defaultSelected: boolean | undefined
  readonly onSelectedChange: ((selected: boolean) => void) | undefined
  readonly selectedIcon: ReactNode
  readonly ariaLabel: string | undefined
  readonly ariaLabelledBy: string | undefined
}): void {
  if (!ariaLabel?.trim() && !ariaLabelledBy?.trim()) {
    warn('provide a non-empty aria-label or aria-labelledby so the icon-only button has an accessible name.')
  }
  if (!toggle && (selected !== undefined || defaultSelected !== undefined || selectedIcon != null)) {
    warn('selected, defaultSelected, and selectedIcon require toggle={true}.')
  }
  if (selected !== undefined && defaultSelected !== undefined) {
    warn('use either selected or defaultSelected, not both.')
  }
  if (toggle && selected !== undefined && onSelectedChange === undefined) {
    warn('a controlled selected value requires onSelectedChange.')
  }
}

function IconButtonRender(
  {
    children,
    variant = 'standard',
    size = 'small',
    width = 'uniform',
    shape = 'round',
    toggle = false,
    selected,
    defaultSelected,
    onSelectedChange,
    selectedIcon,
    type = 'button',
    disabled = false,
    className,
    onClick,
    'aria-label': ariaLabel,
    'aria-labelledby': ariaLabelledBy,
    ...buttonProps
  }: IconButtonImplementationProps,
  forwardedRef: ForwardedRef<HTMLButtonElement>,
) {
  warnForInvalidProps({
    toggle,
    selected,
    defaultSelected,
    onSelectedChange,
    selectedIcon,
    ariaLabel,
    ariaLabelledBy,
  })

  const [resolvedSelected, setSelected] = useControllableState({
    value: toggle ? selected : undefined,
    defaultValue: toggle ? (defaultSelected ?? false) : false,
    onChange: toggle ? onSelectedChange : undefined,
  })
  const hasSelectedIcon = toggle && selectedIcon !== undefined && selectedIcon !== null
  const mergedClassName = className
    ? `m3e-icon-button ${className}`
    : 'm3e-icon-button'
  const handleClick = composeEventHandlers<MouseEvent<HTMLButtonElement>>(
    onClick,
    toggle ? () => setSelected(!resolvedSelected) : undefined,
  )

  return (
    <button
      {...buttonProps}
      ref={forwardedRef}
      type={type}
      disabled={disabled}
      aria-label={ariaLabel}
      aria-labelledby={ariaLabelledBy}
      aria-pressed={toggle ? resolvedSelected : undefined}
      className={mergedClassName}
      onClick={handleClick}
      data-m3e-variant={variant}
      data-m3e-size={size}
      data-m3e-width={width}
      data-m3e-shape={shape}
      data-m3e-toggle={toggle}
      data-m3e-selected={toggle ? resolvedSelected : undefined}
      data-m3e-has-selected-icon={hasSelectedIcon}
      data-m3e-disabled={disabled}
    >
      <span className="m3e-icon-button__container" aria-hidden="true">
        <span className="m3e-icon-button__icon" data-m3e-icon-state="default">
          {children}
        </span>
        {hasSelectedIcon ? (
          <span className="m3e-icon-button__icon" data-m3e-icon-state="selected">
            {selectedIcon}
          </span>
        ) : null}
      </span>
    </button>
  )
}

const ForwardedIconButton = forwardRef<HTMLButtonElement, IconButtonProps>(IconButtonRender)
ForwardedIconButton.displayName = 'IconButton'

export const IconButton = ForwardedIconButton as IconButtonComponent
