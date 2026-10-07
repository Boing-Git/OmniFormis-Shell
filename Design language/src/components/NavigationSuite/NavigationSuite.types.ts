import type { ComponentPropsWithRef, ReactNode } from 'react'
import type { NavigationItem } from '../NavigationBar'

export type { NavigationItem }

interface NavigationSuiteOwnProps {
  readonly items: readonly NavigationItem[]
  readonly value?: string
  readonly defaultValue?: string
  readonly onValueChange?: (value: string) => void
  /** Passed to `NavigationRail` when that layout is active; ignored otherwise. */
  readonly header?: ReactNode
}

type NavigationSuiteNativeProps = Omit<
  ComponentPropsWithRef<'div'>,
  keyof NavigationSuiteOwnProps | 'children'
>

export type NavigationSuiteProps = NavigationSuiteOwnProps & NavigationSuiteNativeProps
