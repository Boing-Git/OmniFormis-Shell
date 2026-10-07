import type { MotionScheme, SpringMotionSpec } from '../schema'

const spring = (dampingRatio: number, stiffness: number): SpringMotionSpec => ({
  kind: 'spring',
  dampingRatio,
  stiffness,
})

export const defaultMotion = {
  standard: {
    fast: {
      spatial: spring(0.9, 1400),
      effects: spring(1, 3800),
    },
    default: {
      spatial: spring(0.9, 700),
      effects: spring(1, 1600),
    },
    slow: {
      spatial: spring(0.9, 300),
      effects: spring(1, 800),
    },
  },
  expressive: {
    fast: {
      spatial: spring(0.6, 800),
      effects: spring(1, 3800),
    },
    default: {
      spatial: spring(0.8, 380),
      effects: spring(1, 1600),
    },
    slow: {
      spatial: spring(0.8, 200),
      effects: spring(1, 800),
    },
  },
} satisfies MotionScheme
