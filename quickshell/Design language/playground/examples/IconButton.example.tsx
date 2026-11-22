import { useState } from 'react'
import {
  Icon,
  IconButton,
  Surface,
  Text,
  type IconButtonSize,
  type IconButtonVariant,
  type IconButtonWidth,
} from '@language-lit/material3-expressive'

const variants: readonly IconButtonVariant[] = ['standard', 'filled', 'tonal', 'outlined']
const sizes: readonly IconButtonSize[] = [
  'extra-small',
  'small',
  'medium',
  'large',
  'extra-large',
]
const widths: readonly IconButtonWidth[] = ['narrow', 'uniform', 'wide']

export function IconButtonExample() {
  const [favorite, setFavorite] = useState(false)

  return (
    <Surface
      as="section"
      aria-labelledby="icon-button-example-title"
      color="surface-container-low"
      shape="extra-large"
      className="icon-button-example"
    >
      <Text as="h2" id="icon-button-example-title" variant="titleLarge" emphasis="emphasized">
        Expressive icon buttons
      </Text>
      <Text as="p" variant="bodyMedium">
        Native momentary and toggle actions with five sizes and shape-changing selection.
      </Text>
      <div className="icon-button-example__row" aria-label="Icon button variants">
        {variants.map((variant) => (
          <IconButton key={variant} aria-label={`${variant} add`} variant={variant}>
            <Icon source="add" />
          </IconButton>
        ))}
      </div>
      <div className="icon-button-example__row" aria-label="Icon button widths">
        {widths.map((width) => (
          <IconButton key={width} aria-label={`${width} search`} variant="outlined" width={width}>
            <Icon source="search" />
          </IconButton>
        ))}
      </div>
      <div className="icon-button-example__row" aria-label="Icon button widths (filled, toggle)">
        {widths.map((width) => (
          <IconButton
            key={width}
            aria-label={`${width} bookmark toggle`}
            variant="filled"
            width={width}
            toggle
            defaultSelected={width === 'wide'}
            selectedIcon={<Icon source="bookmark" fill={1} />}
          >
            <Icon source="bookmark" />
          </IconButton>
        ))}
      </div>
      <div className="icon-button-example__row" aria-label="Square-shaped icon button variants">
        {variants.map((variant) => (
          <IconButton
            key={variant}
            aria-label={`${variant} square edit`}
            variant={variant}
            shape="square"
          >
            <Icon source="edit" />
          </IconButton>
        ))}
      </div>
      <div className="icon-button-example__row" aria-label="Icon button toggle variants">
        <IconButton
          aria-label="Standard toggle bold"
          variant="standard"
          toggle
          defaultSelected
          selectedIcon={<Icon source="format_bold" fill={1} />}
        >
          <Icon source="format_bold" />
        </IconButton>
        <IconButton
          aria-label="Outlined toggle italic"
          variant="outlined"
          toggle
          defaultSelected
          selectedIcon={<Icon source="format_italic" fill={1} />}
        >
          <Icon source="format_italic" />
        </IconButton>
      </div>
      <div className="icon-button-example__row" aria-label="Disabled icon button variants">
        {variants
          .filter((variant) => variant !== 'standard')
          .map((variant) => (
            <IconButton
              key={variant}
              aria-label={`Disabled ${variant}`}
              variant={variant}
              disabled
            >
              <Icon source="block" />
            </IconButton>
          ))}
      </div>
      <IconButton
        aria-label="Disabled selected favorite"
        variant="filled"
        toggle
        defaultSelected
        disabled
        selectedIcon={<Icon source="favorite" fill={1} />}
      >
        <Icon source="favorite" />
      </IconButton>
      <div className="icon-button-example__sizes" aria-label="Expressive icon button sizes">
        {sizes.map((size) => (
          <IconButton
            key={size}
            aria-label={`${size} favorite`}
            variant="tonal"
            size={size}
            shape={size === 'medium' ? 'square' : 'round'}
            toggle
            defaultSelected={size === 'large'}
            selectedIcon={<Icon source="favorite" fill={1} />}
          >
            <Icon source="favorite" />
          </IconButton>
        ))}
      </div>
      <IconButton
        aria-label="Favorite"
        variant="filled"
        toggle
        selected={favorite}
        onSelectedChange={setFavorite}
        selectedIcon={<Icon source="favorite" fill={1} />}
      >
        <Icon source="favorite" />
      </IconButton>
      <IconButton aria-label="Unavailable" disabled>
        <Icon source="block" />
      </IconButton>
    </Surface>
  )
}
