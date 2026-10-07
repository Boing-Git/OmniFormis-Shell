import type { ComponentPropsWithRef, ReactNode, RefObject } from 'react'

export interface MenuItem {
  /** A stable identifier for this item. Not rendered. */
  readonly value: string
  /** The item's label. Typeahead only matches items whose label is a plain string. */
  readonly label: ReactNode
  /** Called when this item is activated. Ignored when `checked` is defined — see `onCheckedChange`. */
  readonly onSelect?: () => void
  readonly leadingIcon?: ReactNode
  readonly trailingIcon?: ReactNode
  readonly disabled?: boolean
  /**
   * Defining `checked` (even `false`) renders `role="menuitemcheckbox"`
   * instead of `role="menuitem"` and keeps the menu open on activation,
   * matching the APG menu-button pattern's own checkbox-item example.
   */
  readonly checked?: boolean
  readonly onCheckedChange?: (checked: boolean) => void
}

interface MenuOwnProps {
  /** Controlled open state. Omit for uncontrolled `defaultOpen`. */
  readonly open?: boolean
  /** Initial open state when uncontrolled. Defaults to `false`. */
  readonly defaultOpen?: boolean
  /** Called whenever the menu closes itself: Escape, an outside click, Tab, or an item activation. */
  readonly onOpenChange?: (open: boolean) => void
  /**
   * The already-rendered trigger element this menu is anchored to. The
   * consumer owns and renders the trigger itself — matching Dialog's own
   * trigger-agnostic precedent — and is responsible for that trigger's own
   * `aria-haspopup="menu"`/`aria-expanded`/click wiring.
   */
  readonly anchorRef: RefObject<HTMLElement | null>
  /** The menu's items, in display order. */
  readonly items: readonly MenuItem[]
}

export type MenuProps = MenuOwnProps &
  Omit<ComponentPropsWithRef<'div'>, keyof MenuOwnProps | 'children'>
