import type { ComponentPropsWithRef, ReactNode } from 'react'

/**
 * The shared navigation-item shape used by `NavigationBar`,
 * `NavigationRail`, `NavigationDrawer`, and `NavigationSuite` — defined
 * once here since these four are explicitly designed to interoperate
 * (`NavigationSuite` composes the other three directly), unlike any prior
 * pair of v1 components, which only ever shared visual styling.
 */
export interface NavigationItem {
  readonly value: string
  readonly label: ReactNode
  readonly icon: ReactNode
  /** Shown instead of `icon` while this item is the selected one. Omit to reuse `icon` for both states. */
  readonly selectedIcon?: ReactNode
  readonly disabled?: boolean
  /** Renders this item as a real `<a href>` instead of `<button>`, the same link-safe pattern `Tabs` already uses. */
  readonly href?: string
}

interface NavigationBarOwnProps {
  readonly items: readonly NavigationItem[]
  /** Controlled selected value. Omit for uncontrolled `defaultValue`. */
  readonly value?: string
  /** Initial selected value when uncontrolled. Defaults to the first item's value. */
  readonly defaultValue?: string
  readonly onValueChange?: (value: string) => void
}

type NavigationBarNativeProps = Omit<ComponentPropsWithRef<'nav'>, keyof NavigationBarOwnProps | 'children'>

export type NavigationBarProps = NavigationBarOwnProps & NavigationBarNativeProps
