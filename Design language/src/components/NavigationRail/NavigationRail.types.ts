import type { ComponentPropsWithRef, ReactNode } from 'react'
import type { NavigationItem } from '../NavigationBar'

export type { NavigationItem }

interface NavigationRailOwnProps {
  readonly items: readonly NavigationItem[]
  readonly value?: string
  readonly defaultValue?: string
  readonly onValueChange?: (value: string) => void
  /** A consumer-owned region above the items, typically a FAB or menu button, matching the pinned source's own `header` slot. */
  readonly header?: ReactNode
}

type NavigationRailNativeProps = Omit<ComponentPropsWithRef<'nav'>, keyof NavigationRailOwnProps | 'children'>

export type NavigationRailProps = NavigationRailOwnProps & NavigationRailNativeProps
