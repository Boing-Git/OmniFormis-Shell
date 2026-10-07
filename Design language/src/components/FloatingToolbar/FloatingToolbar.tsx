import {
  Children,
  cloneElement,
  forwardRef,
  isValidElement,
  useRef,
  useState,
  type CSSProperties,
  type ForwardedRef,
  type KeyboardEventHandler,
  type ReactElement,
} from 'react'
import { composeRefs } from '../../internal/composeRefs'
import { useControllableState } from '../../internal/useControllableState'
import type { FloatingToolbarProps } from './FloatingToolbar.types'

interface FloatingToolbarComponent {
  (props: FloatingToolbarProps): ReactElement | null
  displayName?: string
}

function FloatingToolbarRender(
  {
    children,
    orientation = 'horizontal',
    variant = 'standard',
    expanded,
    defaultExpanded = true,
    onExpandedChange,
    className,
    style,
    ...divProps
  }: FloatingToolbarProps,
  forwardedRef: ForwardedRef<HTMLDivElement>,
) {
  const [resolvedExpanded] = useControllableState({
    value: expanded,
    defaultValue: defaultExpanded,
    onChange: onExpandedChange,
  })

  const itemRefs = useRef<(HTMLElement | null)[]>([])
  const [activeIndex, setActiveIndex] = useState(0)
  const items = Children.toArray(children).filter(isValidElement)
  const forward = orientation === 'horizontal' ? 'ArrowRight' : 'ArrowDown'
  const backward = orientation === 'horizontal' ? 'ArrowLeft' : 'ArrowUp'

  const focusAt = (index: number) => {
    setActiveIndex(index)
    itemRefs.current[index]?.focus()
  }

  const handleKeyDown: KeyboardEventHandler<HTMLDivElement> = (event) => {
    if (items.length === 0) return
    switch (event.key) {
      case forward:
        event.preventDefault()
        focusAt((activeIndex + 1) % items.length)
        return
      case backward:
        event.preventDefault()
        focusAt((activeIndex - 1 + items.length) % items.length)
        return
      case 'Home':
        event.preventDefault()
        focusAt(0)
        return
      case 'End':
        event.preventDefault()
        focusAt(items.length - 1)
        return
      default:
        return
    }
  }

  return (
    <div
      {...divProps}
      ref={forwardedRef}
      role="toolbar"
      aria-orientation={orientation}
      className={className ? `m3e-floating-toolbar ${className}` : 'm3e-floating-toolbar'}
      style={style as CSSProperties}
      data-m3e-orientation={orientation}
      data-m3e-variant={variant}
      data-m3e-expanded={resolvedExpanded}
      onKeyDown={handleKeyDown}
    >
      <div className="m3e-floating-toolbar__content">
        {items.map((item, index) => {
          const element = item as ReactElement<{
            tabIndex?: number
            ref?: ForwardedRef<HTMLElement>
          }>
          return cloneElement(element, {
            key: element.key ?? index,
            tabIndex: index === activeIndex ? 0 : -1,
            ref: composeRefs<HTMLElement>(element.props.ref, (node) => {
              itemRefs.current[index] = node
            }),
          })
        })}
      </div>
    </div>
  )
}

const ForwardedFloatingToolbar = forwardRef<HTMLDivElement, FloatingToolbarProps>(
  FloatingToolbarRender,
)
ForwardedFloatingToolbar.displayName = 'FloatingToolbar'

export const FloatingToolbar = ForwardedFloatingToolbar as FloatingToolbarComponent
