import type { ComponentPropsWithRef, MouseEventHandler, ReactNode } from 'react'

interface FabMenuOwnProps {
  /** The menu's items — `FabMenuItem` elements. */
  readonly children: ReactNode
  /** Accessible name for the trigger FAB. */
  readonly triggerLabel: string
  /** The trigger FAB's icon while collapsed. */
  readonly icon: ReactNode
  /** The trigger FAB's icon while expanded (conventionally a close glyph). */
  readonly closeIcon: ReactNode
  /** Controlled expanded state. */
  readonly expanded?: boolean
  /** Initial expanded state when uncontrolled. */
  readonly defaultExpanded?: boolean
  readonly onExpandedChange?: (expanded: boolean) => void
}

type FabMenuNativeProps = Omit<ComponentPropsWithRef<'div'>, keyof FabMenuOwnProps>

export type FabMenuProps = FabMenuOwnProps & FabMenuNativeProps

interface FabMenuItemOwnProps {
  /** The item's label. */
  readonly children: ReactNode
  /** Decorative visual rendered before the label. */
  readonly icon?: ReactNode
  readonly onClick?: MouseEventHandler<HTMLButtonElement>
  readonly disabled?: boolean
}

type FabMenuItemNativeProps = Omit<
  ComponentPropsWithRef<'button'>,
  keyof FabMenuItemOwnProps | 'type'
>

export type FabMenuItemProps = FabMenuItemOwnProps & FabMenuItemNativeProps
