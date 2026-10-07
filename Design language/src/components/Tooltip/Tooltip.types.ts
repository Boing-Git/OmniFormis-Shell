import type { ComponentPropsWithRef, ReactNode, RefObject } from 'react'

export type TooltipVariant = 'plain' | 'rich'
export type TooltipPlacement = 'top' | 'bottom' | 'start' | 'end'

interface TooltipOwnProps {
  /**
   * The already-rendered trigger element this tooltip describes. Unlike
   * `Menu`/`Select`, `Tooltip` wires its own `anchorRef` interaction
   * (hover, focus, `Escape`) — hover/focus tooltip triggering is a single,
   * standardized interaction with no app-specific ambiguity, so the
   * consumer does not need to (and should not) wire it by hand.
   */
  readonly anchorRef: RefObject<HTMLElement | null>
  /** The tooltip's body content. Must stay non-interactive — see `variant`. */
  readonly content: ReactNode
  /**
   * `'rich'` adds an optional `subhead` above `content` and uses a larger
   * container. Both variants are always non-interactive: `role="tooltip"`
   * disallows focusable/interactive descendants, so the pinned source's
   * rich-tooltip action button has no web equivalent here (see ADR 0018).
   */
  readonly variant?: TooltipVariant
  /** `'rich'`-only. Rendered above `content` when present. */
  readonly subhead?: ReactNode
  /** Preferred side, resolved to physical left/right for `'start'`/`'end'`. Defaults to `'top'`. */
  readonly placement?: TooltipPlacement
  /** Controlled visibility. Omit for uncontrolled `defaultOpen`. */
  readonly open?: boolean
  /** Initial visibility when uncontrolled. Defaults to `false`. */
  readonly defaultOpen?: boolean
  /** Called whenever the tooltip shows or hides itself. */
  readonly onOpenChange?: (open: boolean) => void
}

export type TooltipProps = TooltipOwnProps &
  Omit<ComponentPropsWithRef<'div'>, keyof TooltipOwnProps | 'children'>
