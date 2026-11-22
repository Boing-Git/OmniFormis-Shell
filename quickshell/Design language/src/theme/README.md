# Theme runtime

`theme.ts` is the single conversion boundary between the public theme shape and
the validated foundation-token set. Theme creation and extension always pass
through that boundary and return deeply frozen values.

`Material3Provider/` owns the public React provider. It renders one scoped
`.m3e-theme` element, never changes the document root, and keeps theme data and
resolved color mode in separate contexts. Static token CSS handles visual system
mode before hydration; the browser subscription exists to keep the narrow
resolved-mode context current.

Provider-specific helpers remain in this directory. Components consume the
public hooks and token variables instead of reading these helpers directly.
