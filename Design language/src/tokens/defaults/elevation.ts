import type { CssLength, ElevationLevel, ElevationScheme, ShadowLayer } from '../schema'

const layer = (
  x: CssLength,
  y: CssLength,
  blur: CssLength,
  spread: CssLength,
  opacity: number,
): ShadowLayer => ({ x, y, blur, spread, opacity })

const level = (
  dp: CssLength,
  tonalOverlayOpacity: number,
  key: ShadowLayer,
  ambient: ShadowLayer,
): ElevationLevel => ({ dp, tonalOverlayOpacity, shadow: { key, ambient } })

export const defaultElevation = {
  level0: level(
    '0px',
    0.02,
    layer('0px', '0px', '0px', '0px', 0.3),
    layer('0px', '0px', '0px', '0px', 0.15),
  ),
  level1: level(
    '1px',
    0.051192,
    layer('0px', '1px', '2px', '0px', 0.3),
    layer('0px', '1px', '3px', '1px', 0.15),
  ),
  level2: level(
    '3px',
    0.082383,
    layer('0px', '1px', '2px', '0px', 0.3),
    layer('0px', '2px', '6px', '2px', 0.15),
  ),
  level3: level(
    '6px',
    0.107566,
    layer('0px', '1px', '3px', '0px', 0.3),
    layer('0px', '4px', '8px', '3px', 0.15),
  ),
  level4: level(
    '8px',
    0.118875,
    layer('0px', '2px', '3px', '0px', 0.3),
    layer('0px', '6px', '10px', '4px', 0.15),
  ),
  level5: level(
    '12px',
    0.135423,
    layer('0px', '4px', '4px', '0px', 0.3),
    layer('0px', '8px', '12px', '6px', 0.15),
  ),
} satisfies ElevationScheme
