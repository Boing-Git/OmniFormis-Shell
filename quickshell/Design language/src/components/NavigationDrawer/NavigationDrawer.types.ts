import type { ComponentPropsWithRef, Ref } from 'react'
import type { NavigationItem } from '../NavigationBar'

export type { NavigationItem }

export type NavigationDrawerVariant = 'modal' | 'dismissible' | 'permanent'

interface NavigationDrawerOwnProps {
  readonly items: readonly NavigationItem[]
  readonly value?: string
  readonly defaultValue?: string
  readonly onValueChange?: (value: string) => void
  /**
   * `'modal'` (default): a temporary overlay drawer using the same native
   * `<dialog>` technique `Dialog` uses. `'dismissible'`: a non-modal panel
   * that collapses in place, participating in normal document flow.
   * `'permanent'`: always visible, no open/close state at all —
   * `open`/`defaultOpen`/`onOpenChange` are ignored.
   */
  readonly variant?: NavigationDrawerVariant
  /** Controlled visibility. Ignored when `variant` is `'permanent'`. */
  readonly open?: boolean
  /** Initial visibility when uncontrolled. Ignored when `variant` is `'permanent'`. */
  readonly defaultOpen?: boolean
  readonly onOpenChange?: (open: boolean) => void
}

type NavigationDrawerNativeProps = Omit<
  ComponentPropsWithRef<'div'>,
  keyof NavigationDrawerOwnProps | 'children' | 'ref'
>

export type NavigationDrawerProps = NavigationDrawerOwnProps &
  NavigationDrawerNativeProps & {
    /** The root element is a `<dialog>` for `variant="modal"` and a plain `<div>` otherwise. */
    readonly ref?: Ref<HTMLElement>
  }
