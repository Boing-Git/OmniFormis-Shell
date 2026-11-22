import {
  forwardRef,
  useEffect,
  useState,
  type CSSProperties,
  type ForwardedRef,
  type ReactElement,
} from 'react'
import { useControllableState } from '../../internal/useControllableState'
import { NavigationBar } from '../NavigationBar'
import { NavigationDrawer } from '../NavigationDrawer'
import { NavigationRail } from '../NavigationRail'
import type { NavigationSuiteProps } from './NavigationSuite.types'

interface NavigationSuiteComponent {
  (props: NavigationSuiteProps): ReactElement | null
  displayName?: string
}

type WidthTier = 'compact' | 'medium' | 'expanded'

// The pinned source's own real Compact/Medium/Expanded width breakpoints
// (WindowSizeClassHelper.kt: 0 / 600 / 840dp) — see ADR for why this task
// maps all three tiers to Bar/Rail/Drawer, diverging from the pinned
// source's own `calculateFromAdaptiveInfo`, which never auto-selects a
// drawer at all.
const MEDIUM_BREAKPOINT_PX = 600
const EXPANDED_BREAKPOINT_PX = 840

// SSR/pre-hydration has no real viewport to measure, so this renders the
// 'compact' tier (NavigationBar) until a client effect corrects it — the
// same "renders a reasonable default before a real measurement is
// available" category Tabs' indicator and Snackbar's auto-dismiss timing
// both already established in different forms.
function useWidthTier(): WidthTier {
  const [tier, setTier] = useState<WidthTier>('compact')

  useEffect(() => {
    const mediumQuery = window.matchMedia(`(min-width: ${MEDIUM_BREAKPOINT_PX}px)`)
    const expandedQuery = window.matchMedia(`(min-width: ${EXPANDED_BREAKPOINT_PX}px)`)
    const update = () => {
      setTier(expandedQuery.matches ? 'expanded' : mediumQuery.matches ? 'medium' : 'compact')
    }
    update()
    mediumQuery.addEventListener('change', update)
    expandedQuery.addEventListener('change', update)
    return () => {
      mediumQuery.removeEventListener('change', update)
      expandedQuery.removeEventListener('change', update)
    }
  }, [])

  return tier
}

function NavigationSuiteRender(
  { items, value, defaultValue, onValueChange, header, className, style, id: idProp, ...divProps }: NavigationSuiteProps,
  forwardedRef: ForwardedRef<HTMLDivElement>,
) {
  const tier = useWidthTier()
  const [resolvedValue, setValue] = useControllableState({
    value,
    defaultValue: defaultValue ?? items[0]?.value ?? '',
    onChange: onValueChange,
  })

  return (
    <div
      {...divProps}
      ref={forwardedRef}
      id={idProp}
      className={className ? `m3e-navigation-suite ${className}` : 'm3e-navigation-suite'}
      style={style as CSSProperties}
      data-m3e-tier={tier}
    >
      {tier === 'compact' && (
        <NavigationBar items={items} value={resolvedValue} onValueChange={setValue} />
      )}
      {tier === 'medium' && (
        <NavigationRail items={items} value={resolvedValue} onValueChange={setValue} header={header} />
      )}
      {tier === 'expanded' && (
        <NavigationDrawer
          items={items}
          value={resolvedValue}
          onValueChange={setValue}
          variant="permanent"
        />
      )}
    </div>
  )
}

const ForwardedNavigationSuite = forwardRef<HTMLDivElement, NavigationSuiteProps>(NavigationSuiteRender)
ForwardedNavigationSuite.displayName = 'NavigationSuite'

export const NavigationSuite = ForwardedNavigationSuite as NavigationSuiteComponent
