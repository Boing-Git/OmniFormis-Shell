# Motion

The token foundation owns standard and Expressive spring inputs. T07 adds their
deterministic CSS projection in `tokens/css.ts`: every semantic slot emits its
damping ratio, stiffness, calculated settlement duration, and sampled
`linear()` easing. Components consume those scoped variables and define an
explicit reduced-motion outcome.

A later task may add a runtime adapter only when a behavior cannot be expressed
with this precompiled CSS path. Runtime animation must not duplicate or silently
diverge from the token projection.
