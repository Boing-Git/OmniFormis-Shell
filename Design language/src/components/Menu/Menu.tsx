import {
  forwardRef,
  useEffect,
  useMemo,
  useRef,
  useState,
  type CSSProperties,
  type ForwardedRef,
  type HTMLAttributes,
  type KeyboardEventHandler,
  type ReactElement,
  type RefObject,
} from 'react'
import { createPortal } from 'react-dom'
import { composeRefs } from '../../internal/composeRefs'
import { useAnchoredOverlay } from '../../internal/useAnchoredOverlay'
import { useControllableState } from '../../internal/useControllableState'
import type { MenuItem, MenuProps } from './Menu.types'

interface MenuImplementationProps extends Omit<HTMLAttributes<HTMLDivElement>, 'children'> {
  readonly open?: boolean
  readonly defaultOpen?: boolean
  readonly onOpenChange?: (open: boolean) => void
  readonly anchorRef: RefObject<HTMLElement | null>
  readonly items: readonly MenuItem[]
}

interface MenuComponent {
  (props: MenuProps): ReactElement | null
  displayName?: string
}

const TYPEAHEAD_RESET_MS = 500

function enabledIndicesOf(items: readonly MenuItem[]): number[] {
  const indices: number[] = []
  items.forEach((item, index) => {
    if (!item.disabled) indices.push(index)
  })
  return indices
}

function MenuRender(
  {
    open,
    defaultOpen = false,
    onOpenChange,
    anchorRef,
    items,
    className,
    style,
    id: idProp,
    ...divProps
  }: MenuImplementationProps,
  forwardedRef: ForwardedRef<HTMLDivElement>,
) {
  const [resolvedOpen, setOpen] = useControllableState({
    value: open,
    defaultValue: defaultOpen,
    onChange: onOpenChange,
  })

  const {
    mounted,
    entered,
    popoverRef,
    style: overlayStyle,
    handleTransitionEnd,
    restoreFocus,
  } = useAnchoredOverlay({
    open: resolvedOpen,
    anchorRef,
    onRequestClose: () => setOpen(false),
  })

  const itemRefs = useRef<(HTMLDivElement | null)[]>([])
  const [activeIndex, setActiveIndex] = useState(0)
  const typeaheadRef = useRef<{ buffer: string; timeout: ReturnType<typeof setTimeout> | undefined }>({
    buffer: '',
    timeout: undefined,
  })

  const enabledIndices = useMemo(() => enabledIndicesOf(items), [items])

  // Move real DOM focus to the first enabled item once the menu mounts,
  // matching the APG menu-button pattern's own real-focus-movement model
  // (roving tabindex, not aria-activedescendant).
  useEffect(() => {
    if (!mounted) return
    const first = enabledIndices[0]
    if (first === undefined) return
    setActiveIndex(first)
    itemRefs.current[first]?.focus()
    // Intentionally mount-only: re-focusing on every items-array identity
    // change would steal focus back from a user already navigating.
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [mounted])

  if (!mounted) return null

  const moveFocus = (index: number) => {
    setActiveIndex(index)
    itemRefs.current[index]?.focus()
  }

  const focusRelative = (step: 1 | -1) => {
    if (enabledIndices.length === 0) return
    const position = enabledIndices.indexOf(activeIndex)
    const nextPosition =
      position === -1 ? 0 : (position + step + enabledIndices.length) % enabledIndices.length
    moveFocus(enabledIndices[nextPosition])
  }

  const activate = (item: MenuItem) => {
    if (item.disabled) return
    if (item.checked !== undefined) {
      item.onCheckedChange?.(!item.checked)
      return
    }
    item.onSelect?.()
    restoreFocus()
    setOpen(false)
  }

  const handleKeyDown: KeyboardEventHandler<HTMLDivElement> = (event) => {
    switch (event.key) {
      case 'ArrowDown':
        event.preventDefault()
        focusRelative(1)
        return
      case 'ArrowUp':
        event.preventDefault()
        focusRelative(-1)
        return
      case 'Home':
        event.preventDefault()
        if (enabledIndices.length > 0) moveFocus(enabledIndices[0])
        return
      case 'End':
        event.preventDefault()
        if (enabledIndices.length > 0) moveFocus(enabledIndices[enabledIndices.length - 1])
        return
      case 'Enter':
      case ' ':
        event.preventDefault()
        if (items[activeIndex]) activate(items[activeIndex])
        return
      case 'Tab':
        // Do not preventDefault: the browser's own default tab-order
        // change should proceed uninterrupted, matching the APG
        // menu-button pattern's own "Tab moves focus on and closes the
        // menu" behavior — no focus trap here, unlike Dialog.
        setOpen(false)
        return
      default:
        if (event.key.length === 1 && !event.altKey && !event.ctrlKey && !event.metaKey) {
          const state = typeaheadRef.current
          clearTimeout(state.timeout)
          state.buffer += event.key.toLowerCase()
          state.timeout = setTimeout(() => {
            state.buffer = ''
          }, TYPEAHEAD_RESET_MS)
          const position = enabledIndices.indexOf(activeIndex)
          const ordered = [...enabledIndices.slice(position + 1), ...enabledIndices.slice(0, position + 1)]
          const match = ordered.find((index) => {
            const { label } = items[index]
            return typeof label === 'string' && label.toLowerCase().startsWith(state.buffer)
          })
          if (match !== undefined) moveFocus(match)
        }
    }
  }

  return createPortal(
    <div
      {...divProps}
      ref={composeRefs(forwardedRef, popoverRef)}
      id={idProp}
      role="menu"
      className={className ? `m3e-menu ${className}` : 'm3e-menu'}
      data-m3e-open={entered}
      style={{ ...overlayStyle, ...(style as CSSProperties) }}
      onTransitionEnd={handleTransitionEnd}
      onKeyDown={handleKeyDown}
    >
      {items.map((item, index) => {
        const isCheckable = item.checked !== undefined
        return (
          <div
            key={item.value}
            ref={(node) => {
              itemRefs.current[index] = node
            }}
            role={isCheckable ? 'menuitemcheckbox' : 'menuitem'}
            aria-checked={isCheckable ? item.checked : undefined}
            aria-disabled={item.disabled || undefined}
            tabIndex={index === activeIndex ? 0 : -1}
            className="m3e-menu__item"
            data-m3e-checked={isCheckable ? item.checked : undefined}
            onClick={() => activate(item)}
            onFocus={() => setActiveIndex(index)}
          >
            {item.leadingIcon != null && (
              <span className="m3e-menu__item-icon" data-m3e-position="leading" aria-hidden="true">
                {item.leadingIcon}
              </span>
            )}
            <span className="m3e-menu__item-label">{item.label}</span>
            {item.trailingIcon != null && (
              <span className="m3e-menu__item-icon" data-m3e-position="trailing" aria-hidden="true">
                {item.trailingIcon}
              </span>
            )}
          </div>
        )
      })}
    </div>,
    document.body,
  )
}

const ForwardedMenu = forwardRef<HTMLDivElement, MenuImplementationProps>(MenuRender)
ForwardedMenu.displayName = 'Menu'

export const Menu = ForwardedMenu as MenuComponent
