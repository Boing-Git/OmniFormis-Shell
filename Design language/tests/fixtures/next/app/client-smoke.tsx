'use client'

import {
  Button,
  Card,
  Checkbox,
  Dialog,
  FloatingActionButton,
  Icon,
  IconButton,
  Menu,
  NavigationBar,
  NavigationDrawer,
  NavigationRail,
  NavigationSuite,
  Radio,
  SegmentedButtonGroup,
  Select,
  Snackbar,
  Surface,
  Switch,
  Tabs,
  Text,
  TextArea,
  TextField,
  Tooltip,
  defaultTokenSet,
  useResolvedColorMode,
  validateTokenSet,
  type IconSourceProps,
} from '@language-lit/material3-expressive'
import { useRef } from 'react'

function ClientMark(props: IconSourceProps) {
  return (
    <svg {...props} viewBox="0 0 24 24">
      <path d="M4 4h16v16H4Z" />
    </svg>
  )
}

export function ClientSmoke() {
  const mode = useResolvedColorMode()
  const surfaceRef = useRef<HTMLElementTagNameMap['article'] | null>(null)
  const textRef = useRef<HTMLParagraphElement | null>(null)
  const iconRef = useRef<HTMLSpanElement | null>(null)
  const buttonRef = useRef<HTMLButtonElement | null>(null)
  const cardRef = useRef<HTMLElementTagNameMap['article'] | null>(null)
  const cardButtonRef = useRef<HTMLButtonElement | null>(null)
  const checkboxRef = useRef<HTMLInputElement | null>(null)
  const radioRef = useRef<HTMLInputElement | null>(null)
  const switchRef = useRef<HTMLInputElement | null>(null)
  const iconButtonRef = useRef<HTMLButtonElement | null>(null)
  const fabRef = useRef<HTMLButtonElement | null>(null)
  const textFieldRef = useRef<HTMLInputElement | null>(null)
  const textAreaRef = useRef<HTMLTextAreaElement | null>(null)
  const segmentedButtonGroupRef = useRef<HTMLDivElement | null>(null)
  const dialogRef = useRef<HTMLDialogElement | null>(null)
  const menuAnchorRef = useRef<HTMLButtonElement | null>(null)
  const menuRef = useRef<HTMLDivElement | null>(null)
  const selectRef = useRef<HTMLInputElement | null>(null)
  const tooltipAnchorRef = useRef<HTMLButtonElement | null>(null)
  const tooltipRef = useRef<HTMLDivElement | null>(null)
  const snackbarRef = useRef<HTMLDivElement | null>(null)
  const tabsRef = useRef<HTMLDivElement | null>(null)
  const navigationBarRef = useRef<HTMLElement | null>(null)
  const navigationRailRef = useRef<HTMLElement | null>(null)
  const navigationDrawerRef = useRef<HTMLElement | null>(null)
  const navigationSuiteRef = useRef<HTMLDivElement | null>(null)
  return (
    <Surface as="article" ref={surfaceRef} color="surface-container" shape="medium">
      <Text as="p" ref={textRef} variant="bodyMedium">
        <output>
          Material {defaultTokenSet.metadata.materialVersion}:{' '}
          {validateTokenSet(defaultTokenSet).success ? 'valid' : 'invalid'} ({mode})
        </output>
      </Text>
      <Icon
        ref={iconRef}
        source={ClientMark}
      />
      <Button
        ref={buttonRef}
        variant="tonal"
        size="medium"
        leadingIcon={<Icon source="add" />}
        onClick={() => buttonRef.current?.setAttribute('data-activated', 'true')}
      >
        Client action
      </Button>
      <Card ref={cardRef} variant="filled">
        <Text as="h2" variant="titleMedium">Fixture card</Text>
        <Text as="p" variant="bodySmall">Passive rich content</Text>
      </Card>
      <Card
        interactive
        ref={cardButtonRef}
        variant="outlined"
        onClick={() => cardButtonRef.current?.setAttribute('data-activated', 'true')}
      >
        <span>Open fixture card</span>
      </Card>
      <label>
        <Checkbox
          ref={checkboxRef}
          name="fixture-preferences"
          value="mixed"
          indeterminate
          defaultChecked={false}
          onCheckedChange={(checked) =>
            checkboxRef.current?.setAttribute('data-fixture-checked', String(checked))
          }
        />
        Fixture checkbox
      </label>
      <label>
        <Radio
          ref={radioRef}
          name="fixture-plan"
          value="pro"
          defaultChecked
          onCheckedChange={(checked) =>
            radioRef.current?.setAttribute('data-fixture-checked', String(checked))
          }
        />
        Fixture radio
      </label>
      <label>
        <Switch
          ref={switchRef}
          name="fixture-notifications"
          defaultChecked
          onCheckedChange={(checked) =>
            switchRef.current?.setAttribute('data-fixture-checked', String(checked))
          }
        />
        Fixture switch
      </label>
      <IconButton
        ref={iconButtonRef}
        aria-label="Favorite"
        variant="outlined"
        toggle
        defaultSelected
        selectedIcon={<Icon source="favorite" fill={1} />}
        onSelectedChange={(selected) =>
          iconButtonRef.current?.setAttribute('data-fixture-selected', String(selected))
        }
      >
        <Icon source="favorite" />
      </IconButton>
      <FloatingActionButton
        ref={fabRef}
        aria-label="Creation actions"
        icon={<Icon source="add" />}
        selectedIcon={<Icon source="close" />}
        size="medium"
        toggle
        defaultSelected
        onSelectedChange={(selected) =>
          fabRef.current?.setAttribute('data-fixture-selected', String(selected))
        }
      />
      <TextField
        ref={textFieldRef}
        variant="outlined"
        label="Fixture field"
        name="fixture-field"
        leadingIcon={<Icon source="search" />}
        supportingText="Fixture supporting text"
        onChange={(event) =>
          textFieldRef.current?.setAttribute('data-fixture-value', event.currentTarget.value)
        }
      />
      <TextArea
        ref={textAreaRef}
        label="Fixture notes"
        name="fixture-notes"
        rows={3}
        onChange={(event) =>
          textAreaRef.current?.setAttribute('data-fixture-value', event.currentTarget.value)
        }
      />
      <SegmentedButtonGroup
        ref={segmentedButtonGroupRef}
        aria-label="Fixture view"
        name="fixture-view"
        segments={[
          { value: 'day', label: 'Day' },
          { value: 'week', label: 'Week' },
        ]}
        defaultValue="day"
        onValueChange={(value) =>
          segmentedButtonGroupRef.current?.setAttribute('data-fixture-value', value)
        }
      />
      <Dialog
        ref={dialogRef}
        title="Fixture dialog"
        defaultOpen
        onOpenChange={(open) =>
          dialogRef.current?.setAttribute('data-fixture-open', String(open))
        }
      >
        Fixture dialog content
      </Dialog>
      <Button ref={menuAnchorRef} variant="outlined">
        Fixture menu
      </Button>
      <Menu
        ref={menuRef}
        anchorRef={menuAnchorRef}
        defaultOpen
        items={[
          { value: 'copy', label: 'Copy', onSelect: () => menuRef.current?.setAttribute('data-fixture-selected', 'copy') },
          { value: 'paste', label: 'Paste', onSelect: () => menuRef.current?.setAttribute('data-fixture-selected', 'paste') },
        ]}
        onOpenChange={(open) => menuRef.current?.setAttribute('data-fixture-open', String(open))}
      />
      <Select
        ref={selectRef}
        label="Fixture select"
        name="fixture-select"
        options={[
          { value: 'apple', label: 'Apple' },
          { value: 'cherry', label: 'Cherry' },
        ]}
        defaultValue="apple"
        onValueChange={(value) => selectRef.current?.setAttribute('data-fixture-value', value)}
      />
      <Button ref={tooltipAnchorRef} variant="outlined">
        Fixture tooltip anchor
      </Button>
      <Tooltip
        ref={tooltipRef}
        anchorRef={tooltipAnchorRef}
        content="Fixture tooltip content"
        defaultOpen
        onOpenChange={(open) => tooltipRef.current?.setAttribute('data-fixture-open', String(open))}
      />
      <Snackbar
        ref={snackbarRef}
        message="Fixture snackbar"
        dismissible
        defaultOpen
        onOpenChange={(open) => snackbarRef.current?.setAttribute('data-fixture-open', String(open))}
      />
      <Tabs
        ref={tabsRef}
        aria-label="Fixture tabs"
        items={[
          { value: 'one', label: 'One', panel: <span>One content</span> },
          { value: 'two', label: 'Two', panel: <span>Two content</span> },
        ]}
        onValueChange={(value) => tabsRef.current?.setAttribute('data-fixture-value', value)}
      />
      <NavigationBar
        ref={navigationBarRef}
        aria-label="Fixture navigation bar"
        items={[
          { value: 'one', label: 'One', icon: <Icon source="home" /> },
          { value: 'two', label: 'Two', icon: <Icon source="favorite" /> },
        ]}
        onValueChange={(value) => navigationBarRef.current?.setAttribute('data-fixture-value', value)}
      />
      <NavigationRail
        ref={navigationRailRef}
        aria-label="Fixture navigation rail"
        items={[
          { value: 'one', label: 'One', icon: <Icon source="home" /> },
          { value: 'two', label: 'Two', icon: <Icon source="favorite" /> },
        ]}
        onValueChange={(value) => navigationRailRef.current?.setAttribute('data-fixture-value', value)}
      />
      <NavigationDrawer
        ref={navigationDrawerRef}
        aria-label="Fixture navigation drawer"
        variant="permanent"
        items={[
          { value: 'one', label: 'One', icon: <Icon source="home" /> },
          { value: 'two', label: 'Two', icon: <Icon source="favorite" /> },
        ]}
        onValueChange={(value) => navigationDrawerRef.current?.setAttribute('data-fixture-value', value)}
      />
      <NavigationSuite
        ref={navigationSuiteRef}
        aria-label="Fixture navigation suite"
        items={[
          { value: 'one', label: 'One', icon: <Icon source="home" /> },
          { value: 'two', label: 'Two', icon: <Icon source="favorite" /> },
        ]}
        onValueChange={(value) => navigationSuiteRef.current?.setAttribute('data-fixture-value', value)}
      />
    </Surface>
  )
}
