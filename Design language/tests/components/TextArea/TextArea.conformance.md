# TextArea conformance

Task: T14
Status: conformant
Reviewed: 2026-07-21

## Primary references

Shares its full primary-source basis with `TextField` — see
`tests/components/TextField/TextField.conformance.md` for the pinned
revision, blob hashes, and reference URLs. `TextArea`'s own basis for being a
thin multiline variant rather than a separately duplicated component:

- Pinned `TextField.kt`/`OutlinedTextField.kt` at revision
  `225f50d42bf0adeb2abf4b6109befb5ab6ce4efc` define **no distinct multiline
  composable**. Multiline is `lineLimits = TextFieldLineLimits.MultiLine(...)`
  (state-based overload) or `singleLine=false`/`maxLines`/`minLines` (legacy
  overload) on the exact same `TextField`/`OutlinedTextField` composables,
  sharing 100% of the label/cutout/indicator/icon/supporting-text decoration
  machinery (`TextFieldDefaults`/`OutlinedTextFieldDefaults`,
  `CommonDecorationBox`).
- `SecureTextField.kt`/`OutlinedSecureTextField` (same revision) is the
  pinned source's own precedent for this exact pattern: it builds a
  specialized input mode by swapping `BasicTextField` for
  `BasicSecureTextField` while reusing the identical decoration layer
  unchanged. `TextArea` mirrors that precedent on the web: a native
  `textarea` swapped in for `input` under the shared `TextFieldChrome`
  primitive, not a separately duplicated component tree.
- Pinned first-party Material Web TextArea resize guidance and field resize
  propagation, accessed 2026-07-20:
  <https://github.com/material-components/material-web/blob/b4de401eb665ec63474f39319a4ba8f2145974cc/docs/components/text-field.md#textarea>
  and
  <https://github.com/material-components/material-web/blob/b4de401eb665ec63474f39319a4ba8f2145974cc/field/internal/_shared.scss>

Supported Material baseline: AndroidX Material 3 branch revision
`225f50d42bf0adeb2abf4b6109befb5ab6ce4efc`, adapted to a native `textarea`
associated with a native `label`.

## Anatomy and content

Identical to `TextField`'s anatomy (one label, one indicator or notched
outline, optional leading/trailing icons, optional supporting/error text),
substituting a native `textarea` for the native `input`, both rendered
through the same internal `TextFieldChrome` primitive and the same
`.m3e-text-field__input` class so all shared CSS applies unchanged. Height
follows the native `rows` attribute and the browser's own vertical resize
handle. The shared top/content/bottom grid keeps the complete field at its
56px minimum while `rows` and native resizing grow the middle content row.
Auto-growing height is out of scope. Horizontally, the textarea occupies the
shared middle content region between 16px ordinary or 52px icon-bearing edge
regions, so its caret never depends on native-control inline padding to avoid
an icon.

## Variants, shape, color, and size

Identical token mapping to `TextField` — both consume the single T14
`text-field` component-token registration; there is no separate `text-area`
registration, matching the pinned source having no separate token set for
multiline. See `TextField.conformance.md` for the full mapping.

## States and motion

Identical to `TextField`, including vertically centered leading/trailing icon
slots: the pinned measure policy applies `Alignment.CenterVertically` to both
icons regardless of `singleLine`. The resting label follows the source's
multiline branch and starts at the ordinary 16px top padding rather than
centering across all rows. Once focused or populated it moves to the same
filled or outlined destination as TextField.

## Component token mapping

Shares the T14 `text-field` registration with `TextField` in full. No
TextArea-specific tokens exist.

## DOM, forms, and behavior

Identical structure to `TextField`, with `data-m3e-multiline="true"` on the
root (driving the resting-label placement branch above) and no `type` prop,
since native `textarea` has no `type` attribute. `rows`, `cols`, `wrap`, and
every other native `textarea` attribute forward directly. Native vertical
resize (`resize: vertical`) is retained as a deliberate, native web
affordance. `rows` supplies the middle row's initial height; the grid adds the
filled 24px/8px or outlined 16px/16px structural edge regions, and its
one-line content floor produces the shared 56px minimum. The shared
transparent associated label retains whole-field click-to-focus behavior in
the start/end regions outside the textarea's middle grid track.

## Accessible name, description, role, state, and keyboard

Identical to `TextField`: native `label`/`htmlFor` association,
`aria-describedby` composition, and `aria-invalid` on `error`. Typing,
selection, caret, and multiline navigation (Enter for newline) are entirely
browser-owned.

## Bidirectional, forced-color, and adaptive behavior

Identical to `TextField`.

## Web-specific deviations

Shares every deviation already recorded for `TextField`. Native vertical
resize remains the web-only affordance described above; unlike the first-party
Material Web custom element, which propagates resizing through its field
container, this native-React adaptation keeps the handle on the actual
`textarea` while the surrounding shared grid owns the fixed Material edge
regions.
