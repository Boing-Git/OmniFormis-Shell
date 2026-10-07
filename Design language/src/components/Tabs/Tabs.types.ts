import type { ComponentPropsWithRef, ReactNode } from 'react'

export type TabsVariant = 'primary' | 'secondary'

export interface TabItem {
  readonly value: string
  readonly label?: ReactNode
  readonly icon?: ReactNode
  readonly disabled?: boolean
  /**
   * Renders this tab as a real `<a role="tab" href={href}>` instead of a
   * `<button role="tab">`, for router-driven navigation tabs. Arrow-key
   * movement still updates the local selected/indicator state, but actual
   * navigation is left entirely to the browser's native anchor behavior
   * (Enter or click) — arrow keys never synthesize a navigation.
   */
  readonly href?: string
  /**
   * Renders one `role="tabpanel"` region for this tab when it is selected.
   * Omit for a pure link-tabs usage where a router owns the destination
   * content — if no item defines `panel`, `Tabs` renders no tabpanel
   * region at all.
   */
  readonly panel?: ReactNode
}

interface TabsOwnProps {
  readonly items: readonly TabItem[]
  /** `'primary'` (default): short content-hugging indicator, primary-tinted active content. `'secondary'`: full-width underline, onSurface-tinted active content. */
  readonly variant?: TabsVariant
  /** Controlled selected value. Omit for uncontrolled `defaultValue`. */
  readonly value?: string
  /** Initial selected value when uncontrolled. Defaults to the first item's value. */
  readonly defaultValue?: string
  readonly onValueChange?: (value: string) => void
  /** Horizontally scrolling tab list instead of an evenly distributed fixed row. Defaults to `false`. */
  readonly scrollable?: boolean
}

type TabsNativeProps = Omit<ComponentPropsWithRef<'div'>, keyof TabsOwnProps | 'children'>

export type TabsProps = TabsOwnProps & TabsNativeProps
