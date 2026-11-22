import {
  Children,
  forwardRef,
  type ButtonHTMLAttributes,
  type ForwardedRef,
  type MouseEvent,
  type ReactElement,
  type ReactNode,
} from 'react'
import { composeEventHandlers } from '../../internal/composeEventHandlers'
import { useControllableState } from '../../internal/useControllableState'
import { Text } from '../Text'
import type {
  FloatingActionButtonElevation,
  FloatingActionButtonProps,
  FloatingActionButtonSize,
} from './FloatingActionButton.types'

interface FloatingActionButtonImplementationProps
  extends Omit<ButtonHTMLAttributes<HTMLButtonElement>, 'aria-pressed' | 'children'> {
  readonly icon: ReactNode
  readonly label?: ReactNode
  readonly expanded?: boolean
  readonly size?: FloatingActionButtonSize
  readonly elevation?: FloatingActionButtonElevation
  readonly toggle?: boolean
  readonly selected?: boolean
  readonly defaultSelected?: boolean
  readonly onSelectedChange?: (selected: boolean) => void
  readonly selectedIcon?: ReactNode
}

interface FloatingActionButtonComponent {
  (props: FloatingActionButtonProps): ReactElement | null
  displayName?: string
}

const textVariantBySize = {
  standard: 'titleMedium',
  medium: 'titleLarge',
  large: 'headlineSmall',
} as const

function hasTextContent(content: ReactNode): boolean {
  let hasContent = false
  Children.forEach(content, (child) => {
    if (hasContent || child === null || child === undefined || typeof child === 'boolean') return
    if (typeof child === 'string') {
      hasContent = child.trim().length > 0
      return
    }
    hasContent = true
  })
  return hasContent
}

function warn(message: string): void {
  if (typeof process !== 'undefined' && process.env.NODE_ENV !== 'production') {
    console.warn(`FloatingActionButton: ${message}`)
  }
}

function warnForInvalidProps({
  label,
  expanded,
  toggle,
  selected,
  defaultSelected,
  onSelectedChange,
  selectedIcon,
  elevation,
  ariaLabel,
  ariaLabelledBy,
}: {
  readonly label: ReactNode
  readonly expanded: boolean | undefined
  readonly toggle: boolean
  readonly selected: boolean | undefined
  readonly defaultSelected: boolean | undefined
  readonly onSelectedChange: ((selected: boolean) => void) | undefined
  readonly selectedIcon: ReactNode
  readonly elevation: FloatingActionButtonElevation | undefined
  readonly ariaLabel: string | undefined
  readonly ariaLabelledBy: string | undefined
}): void {
  if (!hasTextContent(label) && !ariaLabel?.trim() && !ariaLabelledBy?.trim()) {
    warn('provide a non-empty label, aria-label, or aria-labelledby so the button has an accessible name.')
  }
  if (expanded !== undefined && !hasTextContent(label)) {
    warn('expanded requires a non-empty label.')
  }
  if (toggle && hasTextContent(label)) {
    warn('toggle FABs are icon-only; remove label and expanded.')
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
  if (toggle && elevation !== undefined) {
    warn('toggle FAB elevation is fixed to Material Level 3; remove elevation.')
  }
}

function FloatingActionButtonRender(
  {
    icon,
    label,
    expanded,
    size = 'standard',
    elevation,
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
  }: FloatingActionButtonImplementationProps,
  forwardedRef: ForwardedRef<HTMLButtonElement>,
) {
  warnForInvalidProps({
    label,
    expanded,
    toggle,
    selected,
    defaultSelected,
    onSelectedChange,
    selectedIcon,
    elevation,
    ariaLabel,
    ariaLabelledBy,
  })

  const [resolvedSelected, setSelected] = useControllableState({
    value: toggle ? selected : undefined,
    defaultValue: toggle ? (defaultSelected ?? false) : false,
    onChange: toggle ? onSelectedChange : undefined,
  })
  const extended = !toggle && hasTextContent(label)
  const resolvedExpanded = extended ? (expanded ?? true) : false
  const resolvedElevation = toggle ? 'default' : (elevation ?? 'default')
  const hasSelectedIcon = toggle && selectedIcon !== undefined && selectedIcon !== null
  const mergedClassName = className ? `m3e-fab ${className}` : 'm3e-fab'
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
      data-m3e-size={size}
      data-m3e-elevation={resolvedElevation}
      data-m3e-extended={extended}
      data-m3e-expanded={extended ? resolvedExpanded : undefined}
      data-m3e-toggle={toggle}
      data-m3e-selected={toggle ? resolvedSelected : undefined}
      data-m3e-has-selected-icon={hasSelectedIcon}
      data-m3e-disabled={disabled}
    >
      <span className="m3e-fab__container">
        <span className="m3e-fab__icon" data-m3e-icon-state="default" aria-hidden="true">
          {icon}
        </span>
        {hasSelectedIcon ? (
          <span className="m3e-fab__icon" data-m3e-icon-state="selected" aria-hidden="true">
            {selectedIcon}
          </span>
        ) : null}
        {extended ? (
          <Text
            as="span"
            variant={textVariantBySize[size]}
            className="m3e-fab__label"
          >
            {label}
          </Text>
        ) : null}
      </span>
    </button>
  )
}

const ForwardedFloatingActionButton = forwardRef<
  HTMLButtonElement,
  FloatingActionButtonProps
>(FloatingActionButtonRender)
ForwardedFloatingActionButton.displayName = 'FloatingActionButton'

export const FloatingActionButton =
  ForwardedFloatingActionButton as FloatingActionButtonComponent
