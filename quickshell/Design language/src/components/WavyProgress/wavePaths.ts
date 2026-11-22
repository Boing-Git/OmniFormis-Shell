/**
 * Static progress-wave geometry derived from the pinned AndroidX revision.
 *
 * LinearWavyProgressModifiers builds a quadratic path at maximum amplitude,
 * reserving half the active stroke on both sides of the 10px container, then
 * scales only that path geometry for the amplitude transition. The stroke
 * itself remains 4px. Generating the repeated commands once at module load is
 * deterministic for SSR and keeps the source relationship readable without a
 * 2400px hand-authored polyline.
 *
 * CircularWavyProgressModifiers builds `RoundedPolygon.circle(9)` and
 * `RoundedPolygon.star(9, innerRadius=.75, rounding=.35/.4,
 * innerRounding=.5)`, normalizes them, matches their cubics with `Morph`,
 * scales them by `size - stroke` (44px), and recenters them in the 48px
 * canvas. The two constants below are the matched Morph endpoints produced by
 * the faithful offline RoundedPolygon/Morph port documented in ADR 0022. They
 * intentionally have identical cubic structure so CSS can interpolate `d`
 * exactly as the source interpolates each matched cubic.
 */

export const LINEAR_WAVE_VIEWBOX_WIDTH = 2440
export const LINEAR_WAVE_VIEWBOX_HEIGHT = 10

const LINEAR_STROKE_WIDTH = 4
const LINEAR_CENTER_Y = LINEAR_WAVE_VIEWBOX_HEIGHT / 2
const LINEAR_MAX_CENTERLINE_AMPLITUDE = (LINEAR_WAVE_VIEWBOX_HEIGHT - LINEAR_STROKE_WIDTH) / 2

function createLinearWavePath(wavelength: number, amplitude: number): string {
  const halfWavelength = wavelength / 2
  const controlOffset = amplitude * 2
  const parts = [`M 0 ${LINEAR_CENTER_Y}`]
  let anchorX = halfWavelength
  let controlX = halfWavelength / 2
  let direction = 1

  while (anchorX <= LINEAR_WAVE_VIEWBOX_WIDTH) {
    parts.push(
      `Q ${controlX} ${LINEAR_CENTER_Y + direction * controlOffset} ${anchorX} ${LINEAR_CENTER_Y}`,
    )
    anchorX += halfWavelength
    controlX += halfWavelength
    direction *= -1
  }

  return parts.join(' ')
}

export const LINEAR_WAVE_PATH_DETERMINATE = createLinearWavePath(
  40,
  LINEAR_MAX_CENTERLINE_AMPLITUDE,
)
export const LINEAR_FLAT_PATH_DETERMINATE = createLinearWavePath(40, 0)
export const LINEAR_WAVE_PATH_INDETERMINATE = createLinearWavePath(
  20,
  LINEAR_MAX_CENTERLINE_AMPLITUDE,
)

export const CIRCULAR_CIRCLE_PATH = [
  'M 44.1566 16.6636',
  'C 44.5527 17.752 44.8578 18.8644 45.072 19.9898',
  'C 45.5766 22.6415 45.5762 25.3654 45.0707 28.0169',
  'C 44.8566 29.14 44.5519 30.2502 44.1566 31.3364',
  'C 43.7604 32.4247 43.2792 33.473 42.7198 34.4728',
  'C 41.4019 36.8285 39.6507 38.9149 37.5591 40.6211',
  'C 36.6731 41.3439 35.7261 41.9984 34.7251 42.5764',
  'C 33.7221 43.1555 32.6795 43.6492 31.6084 44.0555',
  'C 29.0846 45.0129 26.4021 45.4855 23.703 45.4482',
  'C 22.5598 45.4323 21.4136 45.325 20.2752 45.1243',
  'C 19.1346 44.9232 18.0187 44.6312 16.9369 44.254',
  'C 14.3882 43.3652 12.0295 42.0029 9.9859 40.2393',
  'C 9.1203 39.4923 8.3112 38.6734 7.5682 37.7879',
  'C 6.8237 36.9007 6.1565 35.9597 5.5704 34.9754',
  'C 4.1892 32.6563 3.258 30.0965 2.8261 27.432',
  'C 2.6432 26.3033 2.5498 25.1559 2.5498 24',
  'C 2.5498 22.8418 2.6435 21.6921 2.8272 20.5613',
  'C 3.2599 17.897 4.192 15.3375 5.5738 13.0187',
  'C 6.1592 12.0365 6.8252 11.0976 7.5682 10.2121',
  'C 8.3127 9.3249 9.1235 8.5044 9.991 7.7562',
  'C 12.0351 5.9933 14.3943 4.6318 16.9434 3.7437',
  'C 18.0231 3.3676 19.1369 3.0764 20.2752 2.8757',
  'C 21.4158 2.6746 22.5643 2.5672 23.7098 2.5517',
  'C 26.4088 2.5152 29.0913 2.9887 31.6148 3.9469',
  'C 32.6837 4.3528 33.724 4.8457 34.7251 5.4236',
  'C 35.7281 6.0027 36.6769 6.6587 37.5644 7.3832',
  'C 39.6554 9.0901 41.406 11.177 42.7231 13.5331',
  'C 43.2811 14.5311 43.7612 15.5774 44.1566 16.6636',
  'Z',
].join(' ')

export const CIRCULAR_WAVE_PATH = [
  'M 41.7652 17.5002',
  'C 42.1599 18.5844 42.8259 19.5699 43.7251 20.3511',
  'C 45.943 22.2782 45.943 25.7218 43.7251 27.6489',
  'C 42.8259 28.4301 42.1599 29.4156 41.7652 30.4998',
  'C 41.3706 31.584 41.2474 32.767 41.4341 33.9435',
  'C 41.8944 36.8453 39.6808 39.4833 36.7431 39.5339',
  'C 35.5522 39.5544 34.4085 39.8811 33.4093 40.458',
  'C 32.4101 41.0349 31.5553 41.862 30.942 42.8832',
  'C 29.4294 45.402 26.038 46 23.7551 44.1504',
  'C 22.8296 43.4006 21.7435 42.9157 20.6072 42.7154',
  'C 19.4709 42.515 18.2845 42.5992 17.1583 42.9872',
  'C 14.3805 43.9445 11.3982 42.2226 10.8383 39.3383',
  'C 10.6113 38.169 10.0909 37.0995 9.3492 36.2156',
  'C 8.6076 35.3317 7.6447 34.6336 6.5325 34.2069',
  'C 3.7893 33.1547 2.6115 29.9187 4.0365 27.3493',
  'C 4.6143 26.3076 4.9031 25.1538 4.9031 24',
  'C 4.9031 22.8462 4.6143 21.6924 4.0365 20.6507',
  'C 2.6115 18.0813 3.7893 14.8453 6.5325 13.7931',
  'C 7.6447 13.3664 8.6076 12.6683 9.3492 11.7844',
  'C 10.0909 10.9005 10.6113 9.831 10.8383 8.6617',
  'C 11.3982 5.7774 14.3805 4.0555 17.1583 5.0128',
  'C 18.2845 5.4008 19.4709 5.485 20.6072 5.2846',
  'C 21.7435 5.0843 22.8296 4.5994 23.7551 3.8496',
  'C 26.038 2 29.4294 2.598 30.942 5.1168',
  'C 31.5553 6.138 32.4101 6.9651 33.4093 7.542',
  'C 34.4085 8.1189 35.5522 8.4456 36.7431 8.4661',
  'C 39.6808 8.5167 41.8944 11.1547 41.4341 14.0565',
  'C 41.2474 15.233 41.3706 16.416 41.7652 17.5002',
  'Z',
].join(' ')
