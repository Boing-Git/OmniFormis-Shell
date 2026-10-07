import {
  forwardRef,
  useEffect,
  useId,
  useMemo,
  useRef,
  useState,
  type CSSProperties,
  type ForwardedRef,
  type KeyboardEventHandler,
  type ReactElement,
} from 'react'
import { createPortal } from 'react-dom'
import { composeRefs } from '../../internal/composeRefs'
import { TextFieldChrome } from '../../internal/TextFieldChrome'
import { useAnchoredOverlay } from '../../internal/useAnchoredOverlay'
import { useControllableState } from '../../internal/useControllableState'
import type { SelectOption, SelectProps } from './Select.types'

interface SelectComponent {
  (props: SelectProps): ReactElement | null
  displayName?: string
}

const TYPEAHEAD_RESET_MS = 500

function enabledIndicesOf(options: readonly SelectOption[]): number[] {
  const indices: number[] = []
  options.forEach((option, index) => {
    if (!option.disabled) indices.push(index)
  })
  return indices
}

/** A fixed chevron, not a Material Symbols glyph — see ADR 0017: baking in a
 * font dependency the consumer has not opted into would break "font loading
 * remains consumer-owned." Rendered through TextFieldChrome's own
 * `trailingIcon` slot, so it inherits the same enabled/disabled/error color
 * handling with no new token. */
function SelectChevron() {
  return (
    <svg
      className="m3e-select__chevron"
      viewBox="0 0 24 24"
      width="24"
      height="24"
      fill="none"
      stroke="currentColor"
      strokeWidth={2}
      strokeLinecap="round"
      strokeLinejoin="round"
      aria-hidden="true"
    >
      <path d="M6 9l6 6 6-6" />
    </svg>
  )
}

function SelectRender(
  {
    options,
    value,
    defaultValue = '',
    onValueChange,
    label,
    variant = 'filled',
    leadingIcon,
    supportingText,
    error = false,
    disabled = false,
    open,
    defaultOpen = false,
    onOpenChange,
    className,
    style,
    id: idProp,
    name,
    'aria-describedby': ariaDescribedByProp,
    onKeyDown: onKeyDownProp,
    onClick: onClickProp,
    ...inputProps
  }: SelectProps,
  forwardedRef: ForwardedRef<HTMLInputElement>,
) {
  const generatedId = useId()
  const fieldId = idProp ?? generatedId
  const listboxId = `${fieldId}-listbox`
  const supportingTextId = supportingText != null ? `${fieldId}-supporting-text` : undefined
  const resolvedAriaDescribedBy =
    [ariaDescribedByProp, supportingTextId].filter(Boolean).join(' ') || undefined

  const [resolvedValue, setValue] = useControllableState({
    value,
    defaultValue,
    onChange: onValueChange,
  })
  const [resolvedOpen, setOpen] = useControllableState({
    value: open,
    defaultValue: defaultOpen,
    onChange: onOpenChange,
  })

  const triggerRef = useRef<HTMLInputElement | null>(null)
  const optionRefs = useRef<(HTMLDivElement | null)[]>([])
  const typeaheadRef = useRef<{ buffer: string; timeout: ReturnType<typeof setTimeout> | undefined }>({
    buffer: '',
    timeout: undefined,
  })

  const enabledIndices = useMemo(() => enabledIndicesOf(options), [options])
  const selectedIndex = useMemo(
    () => options.findIndex((option) => option.value === resolvedValue),
    [options, resolvedValue],
  )
  const [activeIndex, setActiveIndex] = useState(() =>
    selectedIndex >= 0 ? selectedIndex : (enabledIndices[0] ?? 0),
  )

  const {
    mounted,
    entered,
    popoverRef,
    style: overlayStyle,
    handleTransitionEnd,
  } = useAnchoredOverlay({
    open: resolvedOpen,
    anchorRef: triggerRef,
    onRequestClose: () => setOpen(false),
    matchAnchorWidth: true,
  })

  useEffect(() => {
    if (!mounted) return
    if (!optionRefs.current[activeIndex]) return
    optionRefs.current[activeIndex]?.scrollIntoView({ block: 'nearest' })
  }, [mounted, activeIndex])

  const openAt = (index: number) => {
    setActiveIndex(index)
    setOpen(true)
  }

  const moveActive = (step: 1 | -1) => {
    if (enabledIndices.length === 0) return
    const position = enabledIndices.indexOf(activeIndex)
    const nextPosition =
      position === -1 ? 0 : (position + step + enabledIndices.length) % enabledIndices.length
    setActiveIndex(enabledIndices[nextPosition])
  }

  const commit = (index: number) => {
    const option = options[index]
    if (!option || option.disabled) return
    setValue(option.value)
    setOpen(false)
  }

  const handleKeyDown: KeyboardEventHandler<HTMLInputElement> = (event) => {
    onKeyDownProp?.(event)
    if (event.defaultPrevented || disabled) return

    if (!resolvedOpen) {
      switch (event.key) {
        case 'ArrowDown':
        case 'Enter':
        case ' ':
          event.preventDefault()
          openAt(selectedIndex >= 0 ? selectedIndex : (enabledIndices[0] ?? 0))
          return
        case 'ArrowUp':
          event.preventDefault()
          openAt(selectedIndex >= 0 ? selectedIndex : (enabledIndices[enabledIndices.length - 1] ?? 0))
          return
        default:
          return
      }
    }

    switch (event.key) {
      case 'ArrowDown':
        event.preventDefault()
        moveActive(1)
        return
      case 'ArrowUp':
        event.preventDefault()
        moveActive(-1)
        return
      case 'Home':
        event.preventDefault()
        if (enabledIndices.length > 0) setActiveIndex(enabledIndices[0])
        return
      case 'End':
        event.preventDefault()
        if (enabledIndices.length > 0) setActiveIndex(enabledIndices[enabledIndices.length - 1])
        return
      case 'Enter':
      case ' ':
        event.preventDefault()
        commit(activeIndex)
        return
      case 'Tab':
        setOpen(false)
        return
      default:
        if (event.key.length === 1 && !event.altKey && !event.ctrlKey && !event.metaKey) {
          const state = typeaheadRef.current
          clearTimeout(state.timeout)
          state.buffer += event.key.toLowerCase()
          state.timeout = setTimeout(() => {
            state.buffer = ''
          }, TYPEAHEAD_RESET_MS)
          const position = enabledIndices.indexOf(activeIndex)
          const ordered = [...enabledIndices.slice(position + 1), ...enabledIndices.slice(0, position + 1)]
          const match = ordered.find((index) => options[index].label.toLowerCase().startsWith(state.buffer))
          if (match !== undefined) setActiveIndex(match)
        }
    }
  }

  const selectedOption = selectedIndex >= 0 ? options[selectedIndex] : undefined
  const mergedClassName = className ? `m3e-select ${className}` : 'm3e-select'

  return (
    <>
      {name != null && <input type="hidden" name={name} value={resolvedValue} />}
      <TextFieldChrome
        className={mergedClassName}
        style={style as CSSProperties}
        variant={variant}
        label={label}
        leadingIcon={leadingIcon}
        trailingIcon={<SelectChevron />}
        supportingText={supportingText}
        supportingTextId={supportingTextId}
        error={error}
        disabled={disabled}
        fieldId={fieldId}
      >
        <input
          {...inputProps}
          ref={composeRefs(forwardedRef, triggerRef)}
          id={fieldId}
          type="text"
          className="m3e-text-field__input"
          readOnly
          disabled={disabled}
          value={selectedOption?.label ?? ''}
          placeholder=" "
          role="combobox"
          aria-haspopup="listbox"
          aria-expanded={resolvedOpen}
          aria-controls={listboxId}
          aria-activedescendant={mounted ? `${fieldId}-option-${activeIndex}` : undefined}
          aria-autocomplete="none"
          aria-describedby={resolvedAriaDescribedBy}
          onClick={(event) => {
            onClickProp?.(event)
            if (event.defaultPrevented || disabled) return
            setOpen(!resolvedOpen)
          }}
          onKeyDown={handleKeyDown}
        />
      </TextFieldChrome>
      {mounted &&
        createPortal(
          <div
            ref={popoverRef}
            id={listboxId}
            role="listbox"
            aria-label={typeof label === 'string' ? label : undefined}
            className="m3e-menu m3e-select__listbox"
            data-m3e-open={entered}
            style={{ ...overlayStyle }}
            onTransitionEnd={handleTransitionEnd}
          >
            {options.map((option, index) => (
              <div
                key={option.value}
                ref={(node) => {
                  optionRefs.current[index] = node
                }}
                id={`${fieldId}-option-${index}`}
                role="option"
                aria-selected={index === selectedIndex}
                aria-disabled={option.disabled || undefined}
                className="m3e-menu__item m3e-select__option"
                data-m3e-checked={index === selectedIndex}
                data-m3e-active={index === activeIndex}
                onMouseEnter={() => {
                  if (!option.disabled) setActiveIndex(index)
                }}
                onClick={() => commit(index)}
              >
                {option.label}
              </div>
            ))}
          </div>,
          document.body,
        )}
    </>
  )
}

const ForwardedSelect = forwardRef<HTMLInputElement, SelectProps>(SelectRender)
ForwardedSelect.displayName = 'Select'

export const Select = ForwardedSelect as SelectComponent
