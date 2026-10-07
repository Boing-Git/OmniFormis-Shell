import {
  Children,
  cloneElement,
  forwardRef,
  isValidElement,
  useId,
  useRef,
  type CSSProperties,
  type ForwardedRef,
  type KeyboardEvent,
  type ReactElement,
} from 'react'
import { useControllableState } from '../../internal/useControllableState'
import type { FabMenuItemProps, FabMenuProps } from './FabMenu.types'

interface FabMenuComponent {
  (props: FabMenuProps): ReactElement | null
  displayName?: string
}

interface FabMenuItemComponent {
  (props: FabMenuItemProps): ReactElement | null
  displayName?: string
}

function FabMenuItemRender(
  { children, icon, onClick, disabled = false, className, style, ...buttonProps }: FabMenuItemProps,
  forwardedRef: ForwardedRef<HTMLButtonElement>,
) {
  return (
    <button
      {...buttonProps}
      ref={forwardedRef}
      type="button"
      disabled={disabled}
      onClick={onClick}
      className={className ? `m3e-fab-menu-item ${className}` : 'm3e-fab-menu-item'}
    >
      {icon !== undefined && icon !== null ? (
        <span className="m3e-fab-menu-item__icon" aria-hidden="true">
          {icon}
        </span>
      ) : null}
      <span className="m3e-fab-menu-item__label">{children}</span>
    </button>
  )
}

const ForwardedFabMenuItem = forwardRef<HTMLButtonElement, FabMenuItemProps>(FabMenuItemRender)
ForwardedFabMenuItem.displayName = 'FabMenuItem'

export const FabMenuItem = ForwardedFabMenuItem as FabMenuItemComponent

const STAGGER_STEP_MS = 40

function FabMenuRender(
  {
    children,
    triggerLabel,
    icon,
    closeIcon,
    expanded,
    defaultExpanded = false,
    onExpandedChange,
    className,
    style,
    ...divProps
  }: FabMenuProps,
  forwardedRef: ForwardedRef<HTMLDivElement>,
) {
  const [resolvedExpanded, setExpanded] = useControllableState({
    value: expanded,
    defaultValue: defaultExpanded,
    onChange: onExpandedChange,
  })
  const itemsId = useId()
  const firstItemRef = useRef<HTMLButtonElement | null>(null)

  const items = Children.toArray(children).filter(isValidElement)

  const handleTriggerKeyDown = (event: KeyboardEvent<HTMLButtonElement>) => {
    if (!resolvedExpanded) return
    if (event.key === 'ArrowDown' || (event.key === 'Tab' && !event.shiftKey)) {
      if (items.length === 0) return
      event.preventDefault()
      firstItemRef.current?.focus()
    }
  }

  return (
    <div
      {...divProps}
      ref={forwardedRef}
      className={className ? `m3e-fab-menu ${className}` : 'm3e-fab-menu'}
      style={style as CSSProperties}
      data-m3e-expanded={resolvedExpanded}
    >
      <div className="m3e-fab-menu__items" id={itemsId} inert={!resolvedExpanded || undefined}>
        {items.map((item, index) => {
          const element = item as ReactElement<{ ref?: ForwardedRef<HTMLButtonElement> }>
          const delay = (items.length - 1 - index) * STAGGER_STEP_MS
          return (
            <div
              key={element.key ?? index}
              className="m3e-fab-menu__item-slot"
              style={{ transitionDelay: `${delay}ms` }}
            >
              {index === 0
                ? cloneElement(element, { ref: firstItemRef })
                : element}
            </div>
          )
        })}
      </div>
      <button
        type="button"
        className="m3e-fab-menu__trigger"
        aria-label={triggerLabel}
        aria-expanded={resolvedExpanded}
        aria-haspopup="true"
        aria-controls={itemsId}
        onClick={() => setExpanded(!resolvedExpanded)}
        onKeyDown={handleTriggerKeyDown}
      >
        <span className="m3e-fab-menu__trigger-icon" data-m3e-icon="default" aria-hidden="true">
          {icon}
        </span>
        <span className="m3e-fab-menu__trigger-icon" data-m3e-icon="close" aria-hidden="true">
          {closeIcon}
        </span>
      </button>
    </div>
  )
}

const ForwardedFabMenu = forwardRef<HTMLDivElement, FabMenuProps>(FabMenuRender)
ForwardedFabMenu.displayName = 'FabMenu'

export const FabMenu = ForwardedFabMenu as FabMenuComponent
