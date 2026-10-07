import type { StateScheme } from '../schema'

export const defaultState = {
  disabled: 0.38,
  dragged: 0.16,
  focus: 0.1,
  hover: 0.08,
  pressed: 0.1,
} satisfies StateScheme
