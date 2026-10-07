'use client'

import { useMemo } from 'react'
import { Text } from '@language-lit/material3-expressive'
import { buildPalette } from '../theme/palette'
import { useSiteTheme } from '../app/providers'

const displayTones = [10, 20, 30, 40, 50, 60, 70, 80, 90, 95, 99] as const
const displayFamilies = [
  { key: 'primary', label: 'Primary' },
  { key: 'secondary', label: 'Secondary' },
  { key: 'tertiary', label: 'Tertiary' },
  { key: 'neutral-variant', label: 'Neutral variant' },
] as const

/**
 * The site's signature element: the live tonal palettes the current theme is
 * generated from. Changing the source color rewrites these swatches and the
 * rest of the page at the same time, which is the claim the site is making.
 */
export function Ramp({ showTones = true }: { showTones?: boolean }) {
  const { sourceColor } = useSiteTheme()
  const palette = useMemo(() => buildPalette(sourceColor), [sourceColor])

  return (
    <div className="ramp" style={{ ['--ramp-columns' as string]: displayTones.length }}>
      {displayFamilies.map((family) => (
        <div key={family.key}>
          <span className="ramp__label">{family.label}</span>
          <div className="ramp__row">
            {displayTones.map((tone) => (
              <div
                key={tone}
                className="ramp__swatch"
                style={{ background: palette[`${family.key}-${tone}`] }}
                title={`${family.key}-${tone} · ${palette[`${family.key}-${tone}`]}`}
              />
            ))}
          </div>
        </div>
      ))}
      {showTones && (
        <div className="ramp__row" aria-hidden>
          {displayTones.map((tone) => (
            <div key={tone} className="ramp__tone">
              {tone}
            </div>
          ))}
        </div>
      )}
      <Text as="p" variant="bodySmall" className="visually-hidden">
        Tonal palettes generated from the source color {sourceColor}.
      </Text>
    </div>
  )
}

/** A single-row ramp used as a section rule. */
export function RampRule({ family = 'primary' }: { family?: string }) {
  const { sourceColor } = useSiteTheme()
  const palette = useMemo(() => buildPalette(sourceColor), [sourceColor])
  return (
    <div className="ramp-rule" aria-hidden>
      {displayTones.map((tone) => (
        <span key={tone} style={{ background: palette[`${family}-${tone}`] }} />
      ))}
    </div>
  )
}

/** The four-tone brand mark in the app bar. */
export function BrandMark() {
  const { sourceColor } = useSiteTheme()
  const palette = useMemo(() => buildPalette(sourceColor), [sourceColor])
  return (
    <span className="bar__mark" aria-hidden>
      {[40, 70, 60, 90].map((tone) => (
        <span key={tone} style={{ background: palette[`primary-${tone}`] }} />
      ))}
    </span>
  )
}
