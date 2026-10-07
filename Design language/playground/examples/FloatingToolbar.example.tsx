import { useState } from 'react'
import { Button, FloatingToolbar, Icon, IconButton, Surface, Text } from '@language-lit/material3-expressive'

export function FloatingToolbarExample() {
  const [collapsibleExpanded, setCollapsibleExpanded] = useState(true)

  return (
    <Surface
      as="section"
      aria-labelledby="floating-toolbar-example-title"
      color="surface-container-low"
      shape="extra-large"
      className="floating-toolbar-example"
    >
      <Text as="h2" id="floating-toolbar-example-title" variant="titleLarge" emphasis="emphasized">
        Floating toolbar
      </Text>
      <Text as="p" variant="bodyMedium">
        Arrow keys move roving focus between items; Home/End jump to the
        ends. Standard and vibrant color pairings, horizontal and
        vertical orientation.
      </Text>

      <div className="floating-toolbar-example__row">
        <FloatingToolbar aria-label="Standard formatting">
          <IconButton aria-label="Bold">
            <Icon source="format_bold" />
          </IconButton>
          <IconButton aria-label="Italic">
            <Icon source="format_italic" />
          </IconButton>
          <IconButton aria-label="Underline">
            <Icon source="format_underlined" />
          </IconButton>
        </FloatingToolbar>

        <FloatingToolbar aria-label="Vibrant alignment" variant="vibrant">
          <IconButton aria-label="Align left">
            <Icon source="format_align_left" />
          </IconButton>
          <IconButton aria-label="Align center">
            <Icon source="format_align_center" />
          </IconButton>
          <IconButton aria-label="Align right">
            <Icon source="format_align_right" />
          </IconButton>
        </FloatingToolbar>

        <FloatingToolbar aria-label="Vertical actions" orientation="vertical">
          <IconButton aria-label="Add">
            <Icon source="add" />
          </IconButton>
          <IconButton aria-label="Remove">
            <Icon source="remove" />
          </IconButton>
        </FloatingToolbar>

        <FloatingToolbar aria-label="Vibrant vertical actions" orientation="vertical" variant="vibrant">
          <IconButton aria-label="Add">
            <Icon source="add" />
          </IconButton>
          <IconButton aria-label="Remove">
            <Icon source="remove" />
          </IconButton>
        </FloatingToolbar>
      </div>

      <div className="floating-toolbar-example__row">
        <Button variant="outlined" onClick={() => setCollapsibleExpanded((expanded) => !expanded)}>
          {collapsibleExpanded ? 'Collapse' : 'Expand'} toolbar
        </Button>
        <FloatingToolbar
          aria-label="Collapsible formatting"
          expanded={collapsibleExpanded}
          onExpandedChange={setCollapsibleExpanded}
        >
          <IconButton aria-label="Bold">
            <Icon source="format_bold" />
          </IconButton>
          <IconButton aria-label="Italic">
            <Icon source="format_italic" />
          </IconButton>
        </FloatingToolbar>
      </div>
    </Surface>
  )
}
