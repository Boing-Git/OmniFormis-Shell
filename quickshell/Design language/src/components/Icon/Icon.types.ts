import type {
  ComponentPropsWithoutRef,
  ComponentType,
  CSSProperties,
} from 'react'

export type MaterialSymbolStyle = 'outlined' | 'rounded' | 'sharp'

/**
 * Props passed to a consumer-provided SVG source. Source components must
 * forward these values to their root `<svg>` so Icon can size the artwork and
 * keep its visual subtree out of the accessibility tree.
 */
export interface IconSourceProps {
  readonly className: string
  readonly 'aria-hidden': true
  readonly focusable: 'false'
}

/** A React component that renders one SVG icon and accepts Icon's adapter props. */
export type IconSource = ComponentType<IconSourceProps>

interface IconCommonProps {
  /** Visual size in CSS pixels. The sourced Material default is 24. */
  readonly size?: number
  /** Mirrors directional artwork only when the surrounding direction is RTL. */
  readonly mirrored?: boolean
  readonly style?: CSSProperties
}

interface SvgIconProps {
  readonly source: IconSource
  readonly symbolStyle?: never
  readonly fill?: never
  readonly weight?: never
  readonly grade?: never
  readonly opticalSize?: never
  readonly roundness?: never
}

interface MaterialSymbolIconProps {
  /** Material Symbols ligature name or codepoint supplied by the consumer font. */
  readonly source: string
  readonly symbolStyle?: MaterialSymbolStyle
  /** Material Symbols `FILL` axis, from 0 through 1. */
  readonly fill?: number
  /** Material Symbols `wght` axis, from 100 through 700. */
  readonly weight?: number
  /** Material Symbols `GRAD` axis, from -50 through 200. */
  readonly grade?: number
  /** Material Symbols `opsz` axis, from 20 through 48. */
  readonly opticalSize?: number
  /** Expressive Material Symbols `ROND` axis, from 0 through 100. */
  readonly roundness?: number
}

type IconAccessibilityProps =
  | {
      /** Decorative icons are hidden from assistive technology by default. */
      readonly decorative?: true
      readonly label?: never
    }
  | {
      /** Meaningful standalone icons expose one named image role. */
      readonly decorative: false
      readonly label: string
    }

type IconNativeProps = Omit<
  ComponentPropsWithoutRef<'span'>,
  | 'aria-hidden'
  | 'aria-label'
  | 'aria-labelledby'
  | 'children'
  | 'dangerouslySetInnerHTML'
  | 'role'
  | 'style'
  | 'tabIndex'
>

/**
 * Props for a passive Material icon. Pass a string for a Material Symbols glyph
 * or a React SVG source component for framework- and vendor-neutral artwork.
 */
export type IconProps = IconNativeProps &
  IconCommonProps &
  IconAccessibilityProps &
  (SvgIconProps | MaterialSymbolIconProps)
