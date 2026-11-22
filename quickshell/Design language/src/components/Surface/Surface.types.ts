import type { ComponentPropsWithRef, ReactNode } from 'react'

/** Passive block and landmark elements that can validly own Surface styling. */
export const SURFACE_ELEMENTS = [
  'div',
  'section',
  'article',
  'aside',
  'main',
  'header',
  'footer',
  'nav',
] as const

export const SURFACE_COLORS = [
  'surface',
  'surface-dim',
  'surface-bright',
  'surface-container-lowest',
  'surface-container-low',
  'surface-container',
  'surface-container-high',
  'surface-container-highest',
  'primary',
  'primary-container',
  'primary-fixed',
  'primary-fixed-dim',
  'secondary',
  'secondary-container',
  'secondary-fixed',
  'secondary-fixed-dim',
  'tertiary',
  'tertiary-container',
  'tertiary-fixed',
  'tertiary-fixed-dim',
  'error',
  'error-container',
  'inverse-surface',
] as const

export const SURFACE_SHAPES = [
  'none',
  'extra-small',
  'extra-small-top',
  'small',
  'medium',
  'large',
  'large-start',
  'large-end',
  'large-top',
  'large-increased',
  'extra-large',
  'extra-large-top',
  'extra-large-increased',
  'extra-extra-large',
  'full',
] as const

export const SURFACE_ELEVATIONS = [0, 1, 2, 3, 4, 5] as const

export type SurfaceElement = (typeof SURFACE_ELEMENTS)[number]
export type SurfaceColor = (typeof SURFACE_COLORS)[number]
export type SurfaceShape = (typeof SURFACE_SHAPES)[number]
export type SurfaceElevation = (typeof SURFACE_ELEVATIONS)[number]

interface SurfaceOwnProps {
  readonly children?: ReactNode
  /** Material container color role. Its paired content role is applied too. */
  readonly color?: SurfaceColor
  /** Tonal elevation applied only when `color="surface"`. */
  readonly tonalElevation?: SurfaceElevation
  /** Visual shadow elevation. This does not change stacking order. */
  readonly shadowElevation?: SurfaceElevation
  /** Material system corner role used to clip the container and its content. */
  readonly shape?: SurfaceShape
}

type SurfaceElementProp<TElement extends SurfaceElement> = TElement extends 'div'
  ? { readonly as?: TElement }
  : { readonly as: TElement }

/**
 * Props for a passive Material surface. The generic element narrows native
 * attributes and the forwarded ref while keeping interactive elements out of
 * the polymorphic contract.
 */
export type SurfaceProps<TElement extends SurfaceElement = 'div'> = SurfaceOwnProps &
  SurfaceElementProp<TElement> &
  Omit<ComponentPropsWithRef<TElement>, keyof SurfaceOwnProps | 'as' | 'color'>
