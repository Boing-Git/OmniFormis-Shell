import { forwardRef, type CSSProperties, type ForwardedRef, type ReactElement } from 'react'
import { useControllableState } from '../../internal/useControllableState'
import type { NavigationRailProps } from './NavigationRail.types'

interface NavigationRailComponent {
  (props: NavigationRailProps): ReactElement | null
  displayName?: string
}

function NavigationRailRender(
  { items, value, defaultValue, onValueChange, header, className, style, ...navProps }: NavigationRailProps,
  forwardedRef: ForwardedRef<HTMLElement>,
) {
  const [resolvedValue, setValue] = useControllableState({
    value,
    defaultValue: defaultValue ?? items[0]?.value ?? '',
    onChange: onValueChange,
  })

  return (
    <nav
      {...navProps}
      ref={forwardedRef}
      className={className ? `m3e-navigation-rail ${className}` : 'm3e-navigation-rail'}
      style={style as CSSProperties}
    >
      {header != null && <div className="m3e-navigation-rail__header">{header}</div>}
      <div className="m3e-navigation-rail__items">
        {items.map((item) => {
          const selected = item.value === resolvedValue
          const handleActivate = () => {
            if (item.disabled) return
            setValue(item.value)
          }
          const sharedProps = {
            className: 'm3e-navigation-rail__item',
            'aria-current': selected ? ('page' as const) : undefined,
            'aria-disabled': item.disabled || undefined,
            'data-m3e-selected': selected,
          }
          const content = (
            <>
              <span className="m3e-navigation-rail__indicator" aria-hidden="true">
                <span className="m3e-navigation-rail__icon" aria-hidden="true">
                  {selected && item.selectedIcon != null ? item.selectedIcon : item.icon}
                </span>
              </span>
              <span className="m3e-navigation-rail__label">{item.label}</span>
            </>
          )
          return item.href != null ? (
            // A disabled link omits `href` (anchors have no native disabled
            // state), which also strips the implicit link role — `role="link"`
            // keeps it identifiable to assistive technology as a (disabled)
            // link rather than generic content.
            <a
              {...sharedProps}
              key={item.value}
              role="link"
              href={item.disabled ? undefined : item.href}
              onClick={handleActivate}
            >
              {content}
            </a>
          ) : (
            <button
              {...sharedProps}
              key={item.value}
              type="button"
              disabled={item.disabled}
              onClick={handleActivate}
            >
              {content}
            </button>
          )
        })}
      </div>
    </nav>
  )
}

const ForwardedNavigationRail = forwardRef<HTMLElement, NavigationRailProps>(NavigationRailRender)
ForwardedNavigationRail.displayName = 'NavigationRail'

export const NavigationRail = ForwardedNavigationRail as NavigationRailComponent
