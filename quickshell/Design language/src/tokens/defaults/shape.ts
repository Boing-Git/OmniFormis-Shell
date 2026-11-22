import type { ShapeScheme } from '../schema'

export const defaultShape = {
  cornerValues: {
    none: '0px',
    extraSmall: '4px',
    small: '8px',
    medium: '12px',
    large: '16px',
    largeIncreased: '20px',
    extraLarge: '28px',
    extraLargeIncreased: '32px',
    extraExtraLarge: '48px',
  },
  corners: {
    cornerNone: '0px',
    cornerExtraSmall: '4px',
    cornerExtraSmallTop: '4px 4px 0px 0px',
    cornerSmall: '8px',
    cornerMedium: '12px',
    cornerLarge: '16px',
    cornerLargeStart: '16px 0px 0px 16px',
    cornerLargeEnd: '0px 16px 16px 0px',
    cornerLargeTop: '16px 16px 0px 0px',
    cornerLargeIncreased: '20px',
    cornerExtraLarge: '28px',
    cornerExtraLargeTop: '28px 28px 0px 0px',
    cornerExtraLargeIncreased: '32px',
    cornerExtraExtraLarge: '48px',
    cornerFull: '9999px',
  },
} satisfies ShapeScheme
