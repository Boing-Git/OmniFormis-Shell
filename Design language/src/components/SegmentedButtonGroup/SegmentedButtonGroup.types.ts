import type { ComponentPropsWithRef, ReactNode } from 'react'

export interface SegmentedButtonGroupSegment {
  readonly value: string
  /** Rendered inside a native `label`; also the control's accessible name. */
  readonly label: ReactNode
  /**
   * Shown only while this segment is unselected, crossfading with the
   * built-in checkmark on selection. Omit to show only the checkmark,
   * revealed with a fade+scale entrance instead of a crossfade.
   */
  readonly icon?: ReactNode
  readonly disabled?: boolean
}

interface SegmentedButtonGroupOwnProps {
  readonly segments: readonly SegmentedButtonGroupSegment[]
  readonly disabled?: boolean
  /** Shared native `name` for every segment's control. Auto-generated when omitted. */
  readonly name?: string
}

interface SegmentedButtonGroupSingleOwnProps {
  /** `false` (default) renders one native radio per segment: mutually exclusive selection. */
  readonly multiple?: false
  readonly value?: string
  readonly defaultValue?: string
  readonly onValueChange?: (value: string) => void
}

interface SegmentedButtonGroupMultipleOwnProps {
  /** `true` renders one native checkbox per segment: independent selection. */
  readonly multiple: true
  readonly value?: readonly string[]
  readonly defaultValue?: readonly string[]
  readonly onValueChange?: (value: readonly string[]) => void
}

type SegmentedButtonGroupNativeProps = Omit<ComponentPropsWithRef<'div'>, 'children' | 'role'>

/**
 * Props for a native Material segmented button group. Single-choice mode
 * (default) renders a native radio group; `multiple: true` renders
 * independent native checkboxes. Segment content and selection are entirely
 * declared through `segments` and `value`/`defaultValue` — there is no
 * children-based composition.
 */
export type SegmentedButtonGroupProps = SegmentedButtonGroupOwnProps &
  (SegmentedButtonGroupSingleOwnProps | SegmentedButtonGroupMultipleOwnProps) &
  SegmentedButtonGroupNativeProps
